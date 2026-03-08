#include "controllers/setup_controller.h"
#include "database/database_manager.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

static const QString kSetupConn = QStringLiteral("gs_setup_main");

SetupController::SetupController(const QString& dbPath, QObject* parent)
    : QObject(parent)
    , m_connectionName(kSetupConn)
{
    // Ouvrir une connexion dédiée sur le main thread
    if (!QSqlDatabase::contains(kSetupConn)) {
        DatabaseManager::initialize(dbPath, kSetupConn);
    }
    checkInitialized();
}

// ── Vérifie si le wizard a déjà été complété ──────────────────────────────

void SetupController::checkInitialized()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.exec(QStringLiteral(
        "SELECT app_initialized, nom_association, adresse, exercice_debut, exercice_fin, age_passage_adulte "
        "FROM association_config LIMIT 1"));

    bool init = false;
    if (q.next()) {
        init = q.value(0).toInt() == 1;
        int age = q.value(5).toInt();
        m_associationData = {
            {"nomAssociation",   q.value(1).toString()},
            {"adresse",          q.value(2).toString()},
            {"exerciceDebut",    q.value(3).toString()},
            {"exerciceFin",      q.value(4).toString()},
            {"agePassageAdulte", age > 0 ? age : 12}
        };
        emit associationDataChanged();
    }

    if (m_initialized != init) {
        m_initialized = init;
        emit isInitializedChanged();
    }

    if (init) loadActiveTarifs();
}

// ── Tarifs de l'année active ──────────────────────────────────────────────

void SetupController::loadActiveTarifs()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.exec(QStringLiteral(
        "SELECT id, libelle, tarif_jeune, tarif_adulte, "
        "       frais_inscription_jeune, frais_inscription_adulte, "
        "       date_debut, date_fin "
        "FROM annees_scolaires "
        "WHERE statut = 'Active' AND valide = 1 LIMIT 1"));

    QVariantMap tarifs;
    if (q.next()) {
        tarifs = {
            {"id",                     q.value(0).toInt()},
            {"libelle",                q.value(1).toString()},
            {"tarifJeune",             q.value(2).toDouble()},
            {"tarifAdulte",            q.value(3).toDouble()},
            {"fraisInscriptionJeune",  q.value(4).toDouble()},
            {"fraisInscriptionAdulte", q.value(5).toDouble()},
            {"dateDebut",              q.value(6).toString()},
            {"dateFin",                q.value(7).toString()}
        };
    }
    if (m_activeTarifs != tarifs) {
        m_activeTarifs = tarifs;
        emit activeTarifsChanged();
    }
}

bool SetupController::updateTarifs(const QVariantMap& data)
{
    auto db = QSqlDatabase::database(m_connectionName);

    // 1. Mettre à jour l'année scolaire active
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE annees_scolaires SET "
        "  tarif_jeune               = ?, "
        "  tarif_adulte              = ?, "
        "  frais_inscription_jeune   = ?, "
        "  frais_inscription_adulte  = ?, "
        "  date_modification         = datetime('now') "
        "WHERE statut = 'Active' AND valide = 1"));
    q.addBindValue(data.value("tarifJeune",             0.0).toDouble());
    q.addBindValue(data.value("tarifAdulte",            0.0).toDouble());
    q.addBindValue(data.value("fraisInscriptionJeune",  0.0).toDouble());
    q.addBindValue(data.value("fraisInscriptionAdulte", 0.0).toDouble());

    if (!q.exec()) {
        qWarning() << "[SetupController] updateTarifs error:" << q.lastError().text();
        emit operationFailed(q.lastError().text());
        return false;
    }

    // 2. Synchroniser tarifs_mensualites (utilise annee_scolaire_id FK)
    QSqlQuery libQuery(db);
    libQuery.exec(QStringLiteral(
        "SELECT id FROM annees_scolaires "
        "WHERE statut = 'Active' AND valide = 1 LIMIT 1"));
    if (libQuery.next()) {
        int anneeId = libQuery.value(0).toInt();
        QSqlQuery insTarif(db);
        insTarif.prepare(QStringLiteral(
            "INSERT OR REPLACE INTO tarifs_mensualites "
            "(categorie, annee_scolaire_id, montant) VALUES (?, ?, ?)"));
        insTarif.addBindValue(QStringLiteral("Jeune"));
        insTarif.addBindValue(anneeId);
        insTarif.addBindValue(data.value("tarifJeune", 0.0).toDouble());
        insTarif.exec();
        insTarif.addBindValue(QStringLiteral("Adulte"));
        insTarif.addBindValue(anneeId);
        insTarif.addBindValue(data.value("tarifAdulte", 0.0).toDouble());
        insTarif.exec();
    }

    loadActiveTarifs();
    return true;
}

// ── Étape 1 : Enregistrement de l'association ────────────────────────────

bool SetupController::saveAssociation(const QVariantMap& data)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE association_config SET "
        "  nom_association     = ?, "
        "  adresse             = ?, "
        "  exercice_debut      = ?, "
        "  exercice_fin        = ?, "
        "  age_passage_adulte  = ?, "
        "  date_modification   = datetime('now') "
        "WHERE id = (SELECT MIN(id) FROM association_config)"));
    q.addBindValue(data.value("nomAssociation").toString());
    q.addBindValue(data.value("adresse").toString());
    q.addBindValue(data.value("exerciceDebut", "01-01").toString());
    q.addBindValue(data.value("exerciceFin",   "12-31").toString());
    q.addBindValue(data.value("agePassageAdulte", 12).toInt());

    if (!q.exec()) {
        qWarning() << "[SetupController] saveAssociation error:" << q.lastError().text();
        emit operationFailed(q.lastError().text());
        return false;
    }

    m_associationData = data;
    emit associationDataChanged();
    return true;
}

// ── Étape 2 : Catalogue des niveaux ──────────────────────────────────────

void SetupController::loadNiveaux()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.exec(QStringLiteral(
        "SELECT id, nom, COALESCE(parent_level_id, 0) "
        "FROM niveaux WHERE valide = 1 ORDER BY id"));

    QVariantList list;
    while (q.next()) {
        list.append(QVariantMap{
            {"id",            q.value(0).toInt()},
            {"nom",           q.value(1).toString()},
            {"parentLevelId", q.value(2).toInt()}
        });
    }
    m_niveaux = list;
    emit niveauxChanged();
}

int SetupController::createNiveau(const QString& nom, int parentLevelId)
{
    if (nom.trimmed().isEmpty()) {
        emit operationFailed(QStringLiteral("Le nom du niveau ne peut pas être vide."));
        return -1;
    }

    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    if (parentLevelId > 0) {
        q.prepare(QStringLiteral(
            "INSERT INTO niveaux (nom, parent_level_id) VALUES (?, ?)"));
        q.addBindValue(nom.trimmed());
        q.addBindValue(parentLevelId);
    } else {
        q.prepare(QStringLiteral("INSERT INTO niveaux (nom) VALUES (?)"));
        q.addBindValue(nom.trimmed());
    }

    if (!q.exec()) {
        qWarning() << "[SetupController] createNiveau error:" << q.lastError().text();
        emit operationFailed(q.lastError().text());
        return -1;
    }

    int newId = q.lastInsertId().toInt();
    loadNiveaux();
    return newId;
}

bool SetupController::updateNiveau(int id, const QString& nom, int parentLevelId)
{
    if (nom.trimmed().isEmpty()) {
        emit operationFailed(QStringLiteral("Le nom du niveau ne peut pas être vide."));
        return false;
    }

    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE niveaux SET nom = ?, parent_level_id = NULLIF(?, 0), "
        "date_modification = datetime('now') WHERE id = ? AND valide = 1"));
    q.addBindValue(nom.trimmed());
    q.addBindValue(parentLevelId);
    q.addBindValue(id);

    if (!q.exec()) {
        qWarning() << "[SetupController] updateNiveau error:" << q.lastError().text();
        emit operationFailed(q.lastError().text());
        return false;
    }

    loadNiveaux();
    return true;
}

bool SetupController::deleteNiveau(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE niveaux SET valide = 0, "
        "date_invalidation = datetime('now'), "
        "date_modification = datetime('now') "
        "WHERE id = ?"));
    q.addBindValue(id);

    if (!q.exec()) {
        qWarning() << "[SetupController] deleteNiveau error:" << q.lastError().text();
        emit operationFailed(q.lastError().text());
        return false;
    }

    // Détacher les niveaux enfants qui pointaient vers ce niveau supprimé
    QSqlQuery fix(db);
    fix.prepare(QStringLiteral(
        "UPDATE niveaux SET parent_level_id = NULL WHERE parent_level_id = ?"));
    fix.addBindValue(id);
    fix.exec();

    loadNiveaux();
    return true;
}

// ── Étape 3 : Première année scolaire + finalisation ─────────────────────

bool SetupController::completeSetup(const QVariantMap& anneeData)
{
    auto db = QSqlDatabase::database(m_connectionName);

    // 1. Créer (ou mettre à jour) la première année scolaire
    QSqlQuery insAnnee(db);
    insAnnee.prepare(QStringLiteral(
        "INSERT INTO annees_scolaires "
        "  (libelle, date_debut, date_fin, tarif_jeune, tarif_adulte, "
        "   frais_inscription_jeune, frais_inscription_adulte, statut) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, 'Active') "
        "ON CONFLICT(libelle) DO UPDATE SET "
        "  date_debut                = excluded.date_debut, "
        "  date_fin                  = excluded.date_fin, "
        "  tarif_jeune               = excluded.tarif_jeune, "
        "  tarif_adulte              = excluded.tarif_adulte, "
        "  frais_inscription_jeune   = excluded.frais_inscription_jeune, "
        "  frais_inscription_adulte  = excluded.frais_inscription_adulte, "
        "  statut                    = 'Active', "
        "  date_modification         = datetime('now')"));
    insAnnee.addBindValue(anneeData.value("libelle").toString());
    insAnnee.addBindValue(anneeData.value("dateDebut").toString());
    insAnnee.addBindValue(anneeData.value("dateFin").toString());
    insAnnee.addBindValue(anneeData.value("tarifJeune", 0.0).toDouble());
    insAnnee.addBindValue(anneeData.value("tarifAdulte", 0.0).toDouble());
    insAnnee.addBindValue(anneeData.value("fraisInscriptionJeune", 0.0).toDouble());
    insAnnee.addBindValue(anneeData.value("fraisInscriptionAdulte", 0.0).toDouble());

    if (!insAnnee.exec()) {
        qWarning() << "[SetupController] completeSetup (annee) error:" << insAnnee.lastError().text();
        emit operationFailed(insAnnee.lastError().text());
        return false;
    }

    // Récupérer l'id de l'année créée
    QSqlQuery idQuery(db);
    idQuery.prepare(QStringLiteral("SELECT id FROM annees_scolaires WHERE libelle = ?"));
    idQuery.addBindValue(anneeData.value("libelle").toString());
    if (!idQuery.exec() || !idQuery.next()) {
        emit operationFailed(QStringLiteral("Impossible de retrouver l'année scolaire créée."));
        return false;
    }
    int anneeId = idQuery.value(0).toInt();

    // 2. Lier tous les niveaux actifs (valide = 1) à cette année
    QSqlQuery allNiveaux(db);
    allNiveaux.exec(QStringLiteral("SELECT id FROM niveaux WHERE valide = 1"));
    QSqlQuery insLien(db);
    insLien.prepare(QStringLiteral(
        "INSERT OR IGNORE INTO niveaux_actifs_par_annee (annee_scolaire_id, niveau_id) "
        "VALUES (?, ?)"));
    while (allNiveaux.next()) {
        insLien.addBindValue(anneeId);
        insLien.addBindValue(allNiveaux.value(0).toInt());
        insLien.exec();
    }

    // 3. Marquer l'application comme initialisée
    QSqlQuery markInit(db);
    markInit.exec(QStringLiteral(
        "UPDATE association_config SET app_initialized = 1, "
        "date_modification = datetime('now') "
        "WHERE id = (SELECT MIN(id) FROM association_config)"));

    if (markInit.lastError().isValid()) {
        qWarning() << "[SetupController] completeSetup (mark init) error:" << markInit.lastError().text();
        emit operationFailed(markInit.lastError().text());
        return false;
    }

    // 4. Synchroniser les tarifs dans tarifs_mensualites (utilise annee_scolaire_id FK)
    // L'année scolaire vient d'être créée ci-dessus, on récupère son id via le libelle
    QString libelle = anneeData.value("libelle").toString();
    QSqlQuery anneeIdQuery(db);
    anneeIdQuery.prepare(QStringLiteral("SELECT id FROM annees_scolaires WHERE libelle = ? AND valide = 1 LIMIT 1"));
    anneeIdQuery.addBindValue(libelle);
    anneeIdQuery.exec();
    if (anneeIdQuery.next()) {
        int anneeId = anneeIdQuery.value(0).toInt();
        QSqlQuery insTarif(db);
        insTarif.prepare(QStringLiteral(
            "INSERT OR REPLACE INTO tarifs_mensualites (categorie, annee_scolaire_id, montant) VALUES (?, ?, ?)"));
        insTarif.addBindValue(QStringLiteral("Jeune"));
        insTarif.addBindValue(anneeId);
        insTarif.addBindValue(anneeData.value("tarifJeune", 0.0).toDouble());
        insTarif.exec();
        insTarif.addBindValue(QStringLiteral("Adulte"));
        insTarif.addBindValue(anneeId);
        insTarif.addBindValue(anneeData.value("tarifAdulte", 0.0).toDouble());
        insTarif.exec();
    }

    m_initialized = true;
    emit isInitializedChanged();
    loadActiveTarifs();
    emit setupCompleted();
    return true;
}

// ── Recalcul des catégories élèves ────────────────────────────────────────

int SetupController::recalculeCategories(int agePassage)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE eleves SET categorie = CASE "
        "  WHEN ("
        "    CAST(strftime('%Y','now') AS INTEGER) - CAST(strftime('%Y', date_naissance) AS INTEGER)"
        "    - CASE WHEN strftime('%m-%d','now') < strftime('%m-%d', date_naissance) THEN 1 ELSE 0 END"
        "  ) < :age THEN 'Jeune' ELSE 'Adulte' "
        "END "
        "WHERE valide = 1 AND date_naissance IS NOT NULL AND date_naissance != ''"));
    q.bindValue(QStringLiteral(":age"), agePassage);

    if (!q.exec()) {
        qWarning() << "[SetupController] recalculeCategories error:" << q.lastError().text();
        emit operationFailed(q.lastError().text());
        return -1;
    }

    int count = q.numRowsAffected();
    qInfo() << "[SetupController] recalculeCategories: updated" << count << "eleves with agePassage=" << agePassage;
    emit categoriesRecalculees(count);
    return count;
}
