#include "controllers/schooling_controller.h"
#include "services/schooling_service.h"

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

SchoolingController::SchoolingController(SchoolingService* service, QObject* parent)
    : QObject(parent), m_service(service) {}

void SchoolingController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void SchoolingController::setError(const QString& e) {
    m_errorMessage = e;
    emit errorMessageChanged();
}

void SchoolingController::loadNiveaux() {
    setLoading(true);
    auto result = m_service->getAllNiveaux();
    if (result.isOk()) {
        m_niveaux.clear();
        for (const auto& n : result.value()) m_niveaux.append(niveauToMap(n));
        emit niveauxChanged();
    } else {
        setError(result.errorMessage());
    }
    setLoading(false);
}

void SchoolingController::loadClassesByNiveau(int niveauId) {
    setLoading(true);
    auto result = m_service->getClassesByNiveau(niveauId);
    if (result.isOk()) {
        m_classes.clear();
        for (const auto& c : result.value()) m_classes.append(classeToMap(c));
        emit classesChanged();
    } else {
        setError(result.errorMessage());
    }
    setLoading(false);
}

void SchoolingController::loadMatieresByNiveau(int niveauId) {
    setLoading(true);
    auto result = m_service->getMatieresByNiveau(niveauId);
    if (result.isOk()) {
        m_matieres.clear();
        for (const auto& m : result.value()) m_matieres.append(matiereToMap(m));
        emit matieresChanged();
    } else {
        setError(result.errorMessage());
    }
    setLoading(false);
}

void SchoolingController::loadSalles() {
    setLoading(true);
    auto result = m_service->getAllSalles();
    if (result.isOk()) {
        m_salles.clear();
        for (const auto& s : result.value()) m_salles.append(salleToMap(s));
        emit sallesChanged();
    } else {
        setError(result.errorMessage());
    }
    setLoading(false);
}

void SchoolingController::createNiveau(const QString& nom) {
    auto result = m_service->createNiveau(nom);
    if (result.isOk()) {
        emit operationSucceeded("Niveau créé");
        loadNiveaux();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::updateNiveau(int id, const QString& nom) {
    auto result = m_service->updateNiveau(id, nom);
    if (result.isOk()) {
        emit operationSucceeded("Niveau mis à jour");
        loadNiveaux();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::deleteNiveau(int id) {
    auto result = m_service->deleteNiveau(id);
    if (result.isOk()) {
        emit operationSucceeded("Niveau supprimé");
        loadNiveaux();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::createClasse(const QString& nom, int niveauId) {
    auto result = m_service->createClasse(nom, niveauId);
    if (result.isOk()) {
        emit operationSucceeded("Classe créée");
        loadClassesByNiveau(niveauId);
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::updateClasse(int id, const QString& nom, int niveauId) {
    auto result = m_service->updateClasse(id, nom, niveauId);
    if (result.isOk()) {
        emit operationSucceeded("Classe mise à jour");
        loadClassesByNiveau(niveauId);
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::deleteClasse(int id) {
    auto result = m_service->deleteClasse(id);
    if (result.isOk()) {
        emit operationSucceeded("Classe supprimée");
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::createMatiere(const QString& nom, int niveauId) {
    auto result = m_service->createMatiere(nom, niveauId);
    if (result.isOk()) {
        emit operationSucceeded("Matière créée");
        loadMatieresByNiveau(niveauId);
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::deleteMatiere(int id) {
    auto result = m_service->deleteMatiere(id);
    if (result.isOk()) {
        emit operationSucceeded("Matière supprimée");
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::createSalle(const QVariantMap& data) {
    auto result = m_service->createSalle(
        data.value("nom").toString(),
        data.value("capaciteChaises").toInt(),
        data.value("equipement").toString());
    if (result.isOk()) {
        emit operationSucceeded("Salle créée");
        loadSalles();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::updateSalle(int id, const QVariantMap& data) {
    auto result = m_service->updateSalle(id,
        data.value("nom").toString(),
        data.value("capaciteChaises").toInt(),
        data.value("equipement").toString());
    if (result.isOk()) {
        emit operationSucceeded("Salle mise à jour");
        loadSalles();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void SchoolingController::deleteSalle(int id) {
    auto result = m_service->deleteSalle(id);
    if (result.isOk()) {
        emit operationSucceeded("Salle supprimée");
        loadSalles();
    } else {
        emit operationFailed(result.errorMessage());
    }
}
