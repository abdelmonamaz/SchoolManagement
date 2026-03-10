#include "controllers/setup_controller.h"
#include "database/database_worker.h"
#include "repositories/iniveau_repository.h"
#include "repositories/isetup_repository.h"

#include <QDebug>

// Helper: convert a Niveau list to the QVariantList format expected by QML.
static QVariantList niveauxToList(const QList<Niveau>& niveaux)
{
    QVariantList list;
    list.reserve(niveaux.size());
    for (const auto& n : niveaux) {
        list.append(QVariantMap{
            {"id",            n.id},
            {"nom",           n.nom},
            {"parentLevelId", n.parentLevelId}
        });
    }
    return list;
}

SetupController::SetupController(INiveauRepository* niveauRepo,
                                 IAssociationRepository* assocRepo,
                                 ISetupSchoolYearRepository* schoolYearRepo,
                                 DatabaseWorker* worker,
                                 QObject* parent)
    : QObject(parent)
    , m_niveauRepo(niveauRepo)
    , m_assocRepo(assocRepo)
    , m_schoolYearRepo(schoolYearRepo)
    , m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &SetupController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError,     this, &SetupController::onQueryError);
    checkInitialized();
}

// ── Vérifie si le wizard a déjà été complété ──────────────────────────────

void SetupController::checkInitialized()
{
    m_worker->submit(QStringLiteral("Setup.checkInitialized"),
        [assocRepo = m_assocRepo, schoolYearRepo = m_schoolYearRepo]() -> QVariant
    {
        QVariantMap config = assocRepo->getConfig();
        if (config.isEmpty()) return QVariantMap{};

        QVariantMap result;
        result["initialized"]    = config.value("initialized");
        result["associationData"] = config.value("associationData");

        if (config.value("initialized").toBool()) {
            QVariantMap tarifs = schoolYearRepo->getActiveYearTarifs();
            if (!tarifs.isEmpty())
                result["activeTarifs"] = tarifs;
        }
        return result;
    });
}

// ── Étape 1 : Enregistrement de l'association ────────────────────────────

void SetupController::saveAssociation(const QVariantMap& data)
{
    m_worker->submit(QStringLiteral("Setup.saveAssociation"),
        [assocRepo = m_assocRepo, data]() -> QVariant
    {
        auto res = assocRepo->saveAssociation(data);
        if (!res.isOk()) return QVariantMap{{"error", res.errorMessage()}};
        return QVariantMap{{"ok", true}, {"data", data}};
    });
}

// ── Étape 2 : Catalogue des niveaux ──────────────────────────────────────

void SetupController::loadNiveaux()
{
    m_worker->submit(QStringLiteral("Setup.loadNiveaux"),
        [niveauRepo = m_niveauRepo]() -> QVariant
    {
        auto res = niveauRepo->getAllGlobal();
        if (!res.isOk()) return QVariantMap{{"error", res.errorMessage()}};
        return niveauxToList(res.value());
    });
}

void SetupController::createNiveau(const QString& nom, int parentLevelId)
{
    if (nom.trimmed().isEmpty()) {
        emit operationFailed(QStringLiteral("Le nom du niveau ne peut pas être vide."));
        return;
    }

    const QString trimmedNom = nom.trimmed();
    m_worker->submit(QStringLiteral("Setup.createNiveau"),
        [niveauRepo = m_niveauRepo, trimmedNom, parentLevelId]() -> QVariant
    {
        Niveau n;
        n.nom          = trimmedNom;
        n.parentLevelId = parentLevelId;
        auto res = niveauRepo->create(n);
        if (!res.isOk()) return QVariantMap{{"error", res.errorMessage()}};
        int newId = res.value();

        auto allRes = niveauRepo->getAllGlobal();
        QVariantList list;
        if (allRes.isOk()) list = niveauxToList(allRes.value());
        return QVariantMap{{"newId", newId}, {"niveaux", list}};
    });
}

void SetupController::updateNiveau(int id, const QString& nom, int parentLevelId)
{
    if (nom.trimmed().isEmpty()) {
        emit operationFailed(QStringLiteral("Le nom du niveau ne peut pas être vide."));
        return;
    }

    const QString trimmedNom = nom.trimmed();
    m_worker->submit(QStringLiteral("Setup.updateNiveau"),
        [niveauRepo = m_niveauRepo, id, trimmedNom, parentLevelId]() -> QVariant
    {
        Niveau n;
        n.id            = id;
        n.nom           = trimmedNom;
        n.parentLevelId = parentLevelId;
        auto res = niveauRepo->update(n);
        if (!res.isOk()) return QVariantMap{{"error", res.errorMessage()}};

        auto allRes = niveauRepo->getAllGlobal();
        QVariantList list;
        if (allRes.isOk()) list = niveauxToList(allRes.value());
        return QVariantMap{{"niveaux", list}};
    });
}

void SetupController::deleteNiveau(int id)
{
    m_worker->submit(QStringLiteral("Setup.deleteNiveau"),
        [niveauRepo = m_niveauRepo, id]() -> QVariant
    {
        auto res = niveauRepo->removeAndDetachChildren(id);
        if (!res.isOk()) return QVariantMap{{"error", res.errorMessage()}};

        auto allRes = niveauRepo->getAllGlobal();
        QVariantList list;
        if (allRes.isOk()) list = niveauxToList(allRes.value());
        return QVariantMap{{"niveaux", list}};
    });
}

// ── Étape 3 : Première année scolaire + finalisation ─────────────────────

void SetupController::completeSetup(const QVariantMap& anneeData)
{
    m_worker->submit(QStringLiteral("Setup.completeSetup"),
        [assocRepo = m_assocRepo, schoolYearRepo = m_schoolYearRepo, anneeData]() -> QVariant
    {
        // 1. Create / update the first school year
        auto idRes = schoolYearRepo->upsertAnneeScolaire(anneeData);
        if (!idRes.isOk()) return QVariantMap{{"error", idRes.errorMessage()}};
        const int anneeId = idRes.value();

        // 2. Link all valid niveaux to this year
        auto linkRes = schoolYearRepo->linkAllNiveauxToAnnee(anneeId);
        if (!linkRes.isOk()) return QVariantMap{{"error", linkRes.errorMessage()}};

        // 3. Mark application as initialized
        auto markRes = assocRepo->markInitialized();
        if (!markRes.isOk()) return QVariantMap{{"error", markRes.errorMessage()}};

        // 4. Sync tarifs_mensualites
        auto syncRes = schoolYearRepo->syncTarifs(
            anneeId,
            anneeData.value("tarifJeune",  0.0).toDouble(),
            anneeData.value("tarifAdulte", 0.0).toDouble());
        if (!syncRes.isOk()) return QVariantMap{{"error", syncRes.errorMessage()}};

        // 5. Return active tarifs
        return QVariantMap{{"ok", true}, {"activeTarifs", schoolYearRepo->getActiveYearTarifs()}};
    });
}

// ── Mise à jour des tarifs ────────────────────────────────────────────────

void SetupController::updateTarifs(const QVariantMap& data)
{
    m_worker->submit(QStringLiteral("Setup.updateTarifs"),
        [schoolYearRepo = m_schoolYearRepo, data]() -> QVariant
    {
        auto res = schoolYearRepo->updateActiveTarifs(data);
        if (!res.isOk()) return QVariantMap{{"error", res.errorMessage()}};
        return QVariantMap{{"ok", true}, {"activeTarifs", schoolYearRepo->getActiveYearTarifs()}};
    });
}

// ── Recalcul des catégories élèves ────────────────────────────────────────

void SetupController::recalculeCategories(int agePassage)
{
    m_worker->submit(QStringLiteral("Setup.recalculeCategories"),
        [assocRepo = m_assocRepo, agePassage]() -> QVariant
    {
        auto res = assocRepo->recalculeCategories(agePassage);
        if (!res.isOk()) return QVariantMap{{"error", res.errorMessage()}};
        return QVariantMap{{"count", res.value()}};
    });
}

// ── Dispatching des résultats ─────────────────────────────────────────────

void SetupController::onQueryCompleted(const QString& queryId, const QVariant& result)
{
    if (queryId == QLatin1String("Setup.checkInitialized")) {
        const auto map = result.toMap();
        const bool init = map.value("initialized").toBool();
        if (map.contains("associationData")) {
            m_associationData = map.value("associationData").toMap();
            emit associationDataChanged();
        }
        if (m_initialized != init) {
            m_initialized = init;
            emit isInitializedChanged();
        }
        if (map.contains("activeTarifs")) {
            QVariantMap tarifs = map.value("activeTarifs").toMap();
            if (m_activeTarifs != tarifs) {
                m_activeTarifs = tarifs;
                emit activeTarifsChanged();
            }
        }
        // Signal that the initial check is done — QML can now decide
        // whether to open the wizard based on isInitialized.
        if (m_isChecking) {
            m_isChecking = false;
            emit isCheckingChanged();
        }
        return;
    }

    if (queryId == QLatin1String("Setup.saveAssociation")) {
        const auto map = result.toMap();
        if (map.contains("error")) {
            qWarning() << "[SetupController] saveAssociation error:" << map.value("error").toString();
            emit operationFailed(map.value("error").toString());
            return;
        }
        m_associationData = map.value("data").toMap();
        emit associationDataChanged();
        return;
    }

    if (queryId == QLatin1String("Setup.loadNiveaux")) {
        const auto map = result.toMap();
        if (map.contains("error")) {
            emit operationFailed(map.value("error").toString());
            return;
        }
        m_niveaux = result.toList();
        emit niveauxChanged();
        return;
    }

    if (queryId == QLatin1String("Setup.createNiveau")) {
        const auto map = result.toMap();
        if (map.contains("error")) {
            qWarning() << "[SetupController] createNiveau error:" << map.value("error").toString();
            emit operationFailed(map.value("error").toString());
            return;
        }
        m_niveaux = map.value("niveaux").toList();
        emit niveauxChanged();
        emit niveauCreated(map.value("newId").toInt());
        return;
    }

    if (queryId == QLatin1String("Setup.updateNiveau") ||
        queryId == QLatin1String("Setup.deleteNiveau")) {
        const auto map = result.toMap();
        if (map.contains("error")) {
            qWarning() << "[SetupController]" << queryId << "error:" << map.value("error").toString();
            emit operationFailed(map.value("error").toString());
            return;
        }
        m_niveaux = map.value("niveaux").toList();
        emit niveauxChanged();
        return;
    }

    if (queryId == QLatin1String("Setup.completeSetup")) {
        const auto map = result.toMap();
        if (map.contains("error")) {
            qWarning() << "[SetupController] completeSetup error:" << map.value("error").toString();
            emit operationFailed(map.value("error").toString());
            return;
        }
        m_initialized = true;
        emit isInitializedChanged();
        const QVariantMap tarifs = map.value("activeTarifs").toMap();
        if (m_activeTarifs != tarifs) {
            m_activeTarifs = tarifs;
            emit activeTarifsChanged();
        }
        emit setupCompleted();
        return;
    }

    if (queryId == QLatin1String("Setup.updateTarifs")) {
        const auto map = result.toMap();
        if (map.contains("error")) {
            qWarning() << "[SetupController] updateTarifs error:" << map.value("error").toString();
            emit operationFailed(map.value("error").toString());
            return;
        }
        const QVariantMap tarifs = map.value("activeTarifs").toMap();
        if (m_activeTarifs != tarifs) {
            m_activeTarifs = tarifs;
            emit activeTarifsChanged();
        }
        return;
    }

    if (queryId == QLatin1String("Setup.recalculeCategories")) {
        const auto map = result.toMap();
        if (map.contains("error")) {
            qWarning() << "[SetupController] recalculeCategories error:" << map.value("error").toString();
            emit operationFailed(map.value("error").toString());
            return;
        }
        const int count = map.value("count").toInt();
        qInfo() << "[SetupController] recalculeCategories: updated" << count << "eleves";
        emit categoriesRecalculees(count);
        return;
    }
}

void SetupController::onQueryError(const QString& queryId, const QString& error)
{
    if (!queryId.startsWith(QLatin1String("Setup."))) return;
    qWarning() << "[SetupController] Query error" << queryId << ":" << error;
    emit operationFailed(error);
}
