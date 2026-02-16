#include "controllers/staff_controller.h"
#include "services/staff_service.h"
#include "database/database_worker.h"

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

StaffController::StaffController(StaffService* service, DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &StaffController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &StaffController::onQueryError);
}

void StaffController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void StaffController::loadProfesseurs() {
    setLoading(true);
    m_worker->submit("Staff.loadProfesseurs", [svc = m_service]() -> QVariant {
        auto result = svc->getAllProfesseurs();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(profToMap(p));
        return list;
    });
}

void StaffController::createProfesseur(const QVariantMap& data) {
    m_worker->submit("Staff.createProfesseur", [svc = m_service, data]() -> QVariant {
        auto result = svc->createProfesseur(
            data.value("nom").toString(),
            data.value("prenom").toString(),
            data.value("telephone").toString(),
            data.value("adresse").toString(),
            data.value("prixHeureActuel").toDouble());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::updateProfesseur(int id, const QVariantMap& data) {
    m_worker->submit("Staff.updateProfesseur", [svc = m_service, id, data]() -> QVariant {
        Professeur p;
        p.id = id;
        p.nom = data.value("nom").toString();
        p.prenom = data.value("prenom").toString();
        p.telephone = data.value("telephone").toString();
        p.adresse = data.value("adresse").toString();
        p.statut = stringToStatutProf(data.value("statut").toString());
        p.prixHeureActuel = data.value("prixHeureActuel").toDouble();
        auto result = svc->updateProfesseur(p);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::deleteProfesseur(int id) {
    m_worker->submit("Staff.deleteProfesseur", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteProfesseur(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::updateTarif(int profId, double nouveauPrix) {
    m_worker->submit("Staff.updateTarif", [svc = m_service, profId, nouveauPrix]() -> QVariant {
        auto result = svc->updateTarif(profId, nouveauPrix);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

double StaffController::getMonthlySalary(int hours, double rate) {
    Professeur p;
    p.prixHeureActuel = rate;
    return m_service->calculateMonthlySalary(p, hours);
}

void StaffController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Staff.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    if (queryId == "Staff.loadProfesseurs") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_professeurs = result.toList(); emit professeursChanged(); }
        setLoading(false);
    }
    else if (queryId == "Staff.createProfesseur") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Enseignant ajouté"); loadProfesseurs(); }
    }
    else if (queryId == "Staff.updateProfesseur") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Enseignant mis à jour"); loadProfesseurs(); }
    }
    else if (queryId == "Staff.deleteProfesseur") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Enseignant supprimé"); loadProfesseurs(); }
    }
    else if (queryId == "Staff.updateTarif") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Tarif mis à jour"); loadProfesseurs(); }
    }
}

void StaffController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Staff.")) return;

    if (queryId == "Staff.loadProfesseurs") {
        m_errorMessage = error; emit errorMessageChanged();
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
