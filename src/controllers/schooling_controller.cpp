#include "controllers/schooling_controller.h"
#include "services/schooling_service.h"
#include "database/database_worker.h"

static QVariantMap niveauToMap(const Niveau& n) {
    return {{"id", n.id}, {"nom", n.nom}};
}

static QVariantMap classeToMap(const Classe& c) {
    return {{"id", c.id}, {"nom", c.nom}, {"niveauId", c.niveauId}};
}

static QVariantMap matiereToMap(const Matiere& m) {
    return {{"id", m.id}, {"nom", m.nom}, {"niveauId", m.niveauId}};
}

static QVariantMap salleToMap(const Salle& s) {
    return {{"id", s.id}, {"nom", s.nom}, {"capaciteChaises", s.capaciteChaises}, {"equipement", s.equipement}};
}

static QVariantMap equipementToMap(const Equipement& e) {
    return {{"id", e.id}, {"nom", e.nom}};
}

SchoolingController::SchoolingController(SchoolingService* service, DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &SchoolingController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &SchoolingController::onQueryError);
}

void SchoolingController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void SchoolingController::setError(const QString& e) {
    m_errorMessage = e;
    emit errorMessageChanged();
}

// ─── Load methods ───

void SchoolingController::loadNiveaux() {
    setLoading(true);
    m_worker->submit("Schooling.loadNiveaux", [svc = m_service]() -> QVariant {
        auto result = svc->getAllNiveaux();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& n : result.value()) list.append(niveauToMap(n));
        return list;
    });
}

void SchoolingController::loadAllClasses() {
    m_worker->submit("Schooling.loadAllClasses", [svc = m_service]() -> QVariant {
        auto result = svc->getAllClasses();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& c : result.value()) list.append(classeToMap(c));
        return list;
    });
}

void SchoolingController::loadClassesByNiveau(int niveauId) {
    setLoading(true);
    m_worker->submit("Schooling.loadClasses", [svc = m_service, niveauId]() -> QVariant {
        auto result = svc->getClassesByNiveau(niveauId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& c : result.value()) list.append(classeToMap(c));
        return list;
    });
}

void SchoolingController::loadMatieresByNiveau(int niveauId) {
    setLoading(true);
    m_worker->submit("Schooling.loadMatieres", [svc = m_service, niveauId]() -> QVariant {
        auto result = svc->getMatieresByNiveau(niveauId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& m : result.value()) list.append(matiereToMap(m));
        return list;
    });
}

void SchoolingController::loadSalles() {
    setLoading(true);
    m_worker->submit("Schooling.loadSalles", [svc = m_service]() -> QVariant {
        auto result = svc->getAllSalles();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& s : result.value()) list.append(salleToMap(s));
        return list;
    });
}

void SchoolingController::loadEquipements() {
    setLoading(true);
    m_worker->submit("Schooling.loadEquipements", [svc = m_service]() -> QVariant {
        auto result = svc->getAllEquipements();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& e : result.value()) list.append(equipementToMap(e));
        return list;
    });
}

// ─── Niveau CRUD ───

void SchoolingController::createNiveau(const QString& nom) {
    m_worker->submit("Schooling.createNiveau", [svc = m_service, nom]() -> QVariant {
        auto result = svc->createNiveau(nom);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void SchoolingController::updateNiveau(int id, const QString& nom) {
    m_worker->submit("Schooling.updateNiveau", [svc = m_service, id, nom]() -> QVariant {
        auto result = svc->updateNiveau(id, nom);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void SchoolingController::deleteNiveau(int id) {
    m_worker->submit("Schooling.deleteNiveau", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteNiveau(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Classe CRUD ───

void SchoolingController::createClasse(const QString& nom, int niveauId) {
    m_worker->submit("Schooling.createClasse:" + QString::number(niveauId),
        [svc = m_service, nom, niveauId]() -> QVariant {
            auto result = svc->createClasse(nom, niveauId);
            if (!result.isOk())
                return QVariantMap{{"error", result.errorMessage()}};
            return QVariantMap{{"success", true}};
        });
}

void SchoolingController::updateClasse(int id, const QString& nom, int niveauId) {
    m_worker->submit("Schooling.updateClasse:" + QString::number(niveauId),
        [svc = m_service, id, nom, niveauId]() -> QVariant {
            auto result = svc->updateClasse(id, nom, niveauId);
            if (!result.isOk())
                return QVariantMap{{"error", result.errorMessage()}};
            return QVariantMap{{"success", true}};
        });
}

void SchoolingController::deleteClasse(int id) {
    m_worker->submit("Schooling.deleteClasse", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteClasse(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Matiere CRUD ───

void SchoolingController::createMatiere(const QString& nom, int niveauId) {
    m_worker->submit("Schooling.createMatiere:" + QString::number(niveauId),
        [svc = m_service, nom, niveauId]() -> QVariant {
            auto result = svc->createMatiere(nom, niveauId);
            if (!result.isOk())
                return QVariantMap{{"error", result.errorMessage()}};
            return QVariantMap{{"success", true}};
        });
}

void SchoolingController::deleteMatiere(int id) {
    m_worker->submit("Schooling.deleteMatiere", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteMatiere(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Salle CRUD ───

void SchoolingController::createSalle(const QVariantMap& data) {
    m_worker->submit("Schooling.createSalle", [svc = m_service, data]() -> QVariant {
        auto result = svc->createSalle(
            data.value("nom").toString(),
            data.value("capaciteChaises").toInt(),
            data.value("equipement").toString());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void SchoolingController::updateSalle(int id, const QVariantMap& data) {
    m_worker->submit("Schooling.updateSalle", [svc = m_service, id, data]() -> QVariant {
        auto result = svc->updateSalle(id,
            data.value("nom").toString(),
            data.value("capaciteChaises").toInt(),
            data.value("equipement").toString());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void SchoolingController::deleteSalle(int id) {
    m_worker->submit("Schooling.deleteSalle", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteSalle(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Equipement CRUD ───

void SchoolingController::createEquipement(const QString& nom) {
    m_worker->submit("Schooling.createEquipement", [svc = m_service, nom]() -> QVariant {
        auto result = svc->createEquipement(nom);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void SchoolingController::deleteEquipement(int id) {
    m_worker->submit("Schooling.deleteEquipement", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteEquipement(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Async result handlers ───

void SchoolingController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Schooling.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    // ── Load queries ──
    if (queryId == "Schooling.loadNiveaux") {
        if (isError) setError(map["error"].toString());
        else { m_niveaux = result.toList(); emit niveauxChanged(); }
        setLoading(false);
    }
    else if (queryId == "Schooling.loadAllClasses") {
        if (isError) setError(map["error"].toString());
        else { m_allClasses = result.toList(); emit allClassesChanged(); }
    }
    else if (queryId == "Schooling.loadClasses") {
        if (isError) setError(map["error"].toString());
        else { m_classes = result.toList(); emit classesChanged(); }
        setLoading(false);
    }
    else if (queryId == "Schooling.loadMatieres") {
        if (isError) setError(map["error"].toString());
        else { m_matieres = result.toList(); emit matieresChanged(); }
        setLoading(false);
    }
    else if (queryId == "Schooling.loadSalles") {
        if (isError) setError(map["error"].toString());
        else { m_salles = result.toList(); emit sallesChanged(); }
        setLoading(false);
    }
    else if (queryId == "Schooling.loadEquipements") {
        if (isError) setError(map["error"].toString());
        else { m_equipements = result.toList(); emit equipementsChanged(); }
        setLoading(false);
    }
    // ── Niveau mutations ──
    else if (queryId == "Schooling.createNiveau" || queryId == "Schooling.updateNiveau" || queryId == "Schooling.deleteNiveau") {
        if (isError) emit operationFailed(map["error"].toString());
        else {
            QString msg = queryId.contains("create") ? "Niveau créé"
                        : queryId.contains("update") ? "Niveau mis à jour"
                        : "Niveau supprimé";
            emit operationSucceeded(msg);
            loadNiveaux();
        }
    }
    // ── Classe mutations ──
    else if (queryId.startsWith("Schooling.createClasse:") || queryId.startsWith("Schooling.updateClasse:")) {
        if (isError) emit operationFailed(map["error"].toString());
        else {
            int niveauId = queryId.mid(queryId.indexOf(':') + 1).toInt();
            emit operationSucceeded(queryId.contains("create") ? "Classe créée" : "Classe mise à jour");
            loadClassesByNiveau(niveauId);
        }
    }
    else if (queryId == "Schooling.deleteClasse") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Classe supprimée");
    }
    // ── Matiere mutations ──
    else if (queryId.startsWith("Schooling.createMatiere:")) {
        if (isError) emit operationFailed(map["error"].toString());
        else {
            int niveauId = queryId.mid(queryId.indexOf(':') + 1).toInt();
            emit operationSucceeded("Matière créée");
            loadMatieresByNiveau(niveauId);
        }
    }
    else if (queryId == "Schooling.deleteMatiere") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Matière supprimée");
    }
    // ── Salle mutations ──
    else if (queryId == "Schooling.createSalle" || queryId == "Schooling.updateSalle" || queryId == "Schooling.deleteSalle") {
        if (isError) emit operationFailed(map["error"].toString());
        else {
            QString msg = queryId.contains("create") ? "Salle créée"
                        : queryId.contains("update") ? "Salle mise à jour"
                        : "Salle supprimée";
            emit operationSucceeded(msg);
            loadSalles();
        }
    }
    // ── Equipement mutations ──
    else if (queryId == "Schooling.createEquipement" || queryId == "Schooling.deleteEquipement") {
        if (isError) emit operationFailed(map["error"].toString());
        else {
            QString msg = queryId.contains("create") ? "Équipement créé" : "Équipement supprimé";
            emit operationSucceeded(msg);
            loadEquipements();
        }
    }
}

void SchoolingController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Schooling.")) return;

    if (queryId.startsWith("Schooling.load")) {
        setError(error);
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
