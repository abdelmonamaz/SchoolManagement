#include "controllers/staff_controller.h"
#include "services/staff_service.h"

static QString statutProfToString(GS::StatutProf s) {
    return s == GS::StatutProf::EnConge ? QStringLiteral("En congé") : QStringLiteral("Actif");
}

static GS::StatutProf stringToStatutProf(const QString& s) {
    return s == QStringLiteral("En congé") ? GS::StatutProf::EnConge : GS::StatutProf::Actif;
}

static QVariantMap profToMap(const Professeur& p) {
    return {
        {"id", p.id}, {"nom", p.nom}, {"prenom", p.prenom},
        {"telephone", p.telephone}, {"adresse", p.adresse},
        {"statut", statutProfToString(p.statut)}, {"prixHeureActuel", p.prixHeureActuel}
    };
}

StaffController::StaffController(StaffService* service, QObject* parent)
    : QObject(parent), m_service(service) {}

void StaffController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void StaffController::loadProfesseurs() {
    setLoading(true);
    auto result = m_service->getAllProfesseurs();
    if (result.isOk()) {
        m_professeurs.clear();
        for (const auto& p : result.value()) m_professeurs.append(profToMap(p));
        emit professeursChanged();
    } else {
        m_errorMessage = result.errorMessage();
        emit errorMessageChanged();
    }
    setLoading(false);
}

void StaffController::createProfesseur(const QVariantMap& data) {
    auto result = m_service->createProfesseur(
        data.value("nom").toString(),
        data.value("prenom").toString(),
        data.value("telephone").toString(),
        data.value("adresse").toString(),
        data.value("prixHeureActuel").toDouble());
    if (result.isOk()) {
        emit operationSucceeded("Enseignant ajouté");
        loadProfesseurs();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void StaffController::updateProfesseur(int id, const QVariantMap& data) {
    Professeur p;
    p.id = id;
    p.nom = data.value("nom").toString();
    p.prenom = data.value("prenom").toString();
    p.telephone = data.value("telephone").toString();
    p.adresse = data.value("adresse").toString();
    p.statut = stringToStatutProf(data.value("statut").toString());
    p.prixHeureActuel = data.value("prixHeureActuel").toDouble();
    auto result = m_service->updateProfesseur(p);
    if (result.isOk()) {
        emit operationSucceeded("Enseignant mis à jour");
        loadProfesseurs();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void StaffController::deleteProfesseur(int id) {
    auto result = m_service->deleteProfesseur(id);
    if (result.isOk()) {
        emit operationSucceeded("Enseignant supprimé");
        loadProfesseurs();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void StaffController::updateTarif(int profId, double nouveauPrix) {
    auto result = m_service->updateTarif(profId, nouveauPrix);
    if (result.isOk()) {
        emit operationSucceeded("Tarif mis à jour");
        loadProfesseurs();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

double StaffController::getMonthlySalary(int hours, double rate) {
    Professeur p;
    p.prixHeureActuel = rate;
    return m_service->calculateMonthlySalary(p, hours);
}
