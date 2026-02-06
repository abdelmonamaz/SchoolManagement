#include "controllers/finance_controller.h"
#include "services/finance_service.h"

static QString statutProjetToString(GS::StatutProjet s) {
    switch (s) {
        case GS::StatutProjet::EnCours: return QStringLiteral("En cours");
        case GS::StatutProjet::Termine: return QStringLiteral("Terminé");
        case GS::StatutProjet::EnPause: return QStringLiteral("En pause");
    }
    return QStringLiteral("En cours");
}

static QVariantMap paiementToMap(const PaiementMensualite& p) {
    return {
        {"id", p.id}, {"eleveId", p.eleveId}, {"montantPaye", p.montantPaye},
        {"datePaiement", p.datePaiement.toString(Qt::ISODate)},
        {"moisConcerne", p.moisConcerne}, {"anneeConcernee", p.anneeConcernee}
    };
}

static QVariantMap projetToMap(const Projet& p) {
    return {
        {"id", p.id}, {"nom", p.nom}, {"description", p.description},
        {"objectifFinancier", p.objectifFinancier},
        {"statut", statutProjetToString(p.statut)}
    };
}

static QVariantMap donateurToMap(const Donateur& d) {
    return {{"id", d.id}, {"nom", d.nom}, {"telephone", d.telephone}, {"adresse", d.adresse}};
}

static QVariantMap donToMap(const Don& d) {
    return {
        {"id", d.id}, {"donateurId", d.donateurId}, {"projetId", d.projetId},
        {"montant", d.montant}, {"dateDon", d.dateDon.toString(Qt::ISODate)}
    };
}

FinanceController::FinanceController(FinanceService* service, QObject* parent)
    : QObject(parent), m_service(service) {}

void FinanceController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

// ─── Paiements ───

void FinanceController::loadPaymentsByMonth(int month, int year) {
    setLoading(true);
    auto result = m_service->getPaymentsByMonth(month, year);
    if (result.isOk()) {
        m_payments.clear();
        for (const auto& p : result.value()) m_payments.append(paiementToMap(p));
        emit paymentsChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void FinanceController::loadPaymentsByStudent(int eleveId) {
    setLoading(true);
    auto result = m_service->getPaymentsByStudent(eleveId);
    if (result.isOk()) {
        m_payments.clear();
        for (const auto& p : result.value()) m_payments.append(paiementToMap(p));
        emit paymentsChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void FinanceController::recordPayment(const QVariantMap& data) {
    auto result = m_service->recordPayment(
        data.value("eleveId").toInt(),
        data.value("montant").toDouble(),
        data.value("mois").toInt(),
        data.value("annee").toInt());
    if (result.isOk()) emit operationSucceeded("Paiement enregistré");
    else emit operationFailed(result.errorMessage());
}

void FinanceController::deletePayment(int id) {
    auto result = m_service->deletePayment(id);
    if (result.isOk()) emit operationSucceeded("Paiement supprimé");
    else emit operationFailed(result.errorMessage());
}

// ─── Projets ───

void FinanceController::loadProjets() {
    setLoading(true);
    auto result = m_service->getAllProjets();
    if (result.isOk()) {
        m_projets.clear();
        for (const auto& p : result.value()) m_projets.append(projetToMap(p));
        emit projetsChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void FinanceController::createProjet(const QVariantMap& data) {
    auto result = m_service->createProjet(
        data.value("nom").toString(),
        data.value("description").toString(),
        data.value("objectifFinancier").toDouble());
    if (result.isOk()) {
        emit operationSucceeded("Projet créé");
        loadProjets();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void FinanceController::updateProjet(int id, const QVariantMap& data) {
    Projet p;
    p.id = id;
    p.nom = data.value("nom").toString();
    p.description = data.value("description").toString();
    p.objectifFinancier = data.value("objectifFinancier").toDouble();
    auto statut = data.value("statut").toString();
    if (statut == QStringLiteral("Terminé")) p.statut = GS::StatutProjet::Termine;
    else if (statut == QStringLiteral("En pause")) p.statut = GS::StatutProjet::EnPause;
    else p.statut = GS::StatutProjet::EnCours;
    auto result = m_service->updateProjet(p);
    if (result.isOk()) {
        emit operationSucceeded("Projet mis à jour");
        loadProjets();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void FinanceController::deleteProjet(int id) {
    auto result = m_service->deleteProjet(id);
    if (result.isOk()) {
        emit operationSucceeded("Projet supprimé");
        loadProjets();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

// ─── Donateurs & Dons ───

void FinanceController::loadDonateurs() {
    setLoading(true);
    auto result = m_service->getAllDonateurs();
    if (result.isOk()) {
        m_donateurs.clear();
        for (const auto& d : result.value()) m_donateurs.append(donateurToMap(d));
        emit donateursChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void FinanceController::createDonateur(const QVariantMap& data) {
    auto result = m_service->createDonateur(
        data.value("nom").toString(),
        data.value("telephone").toString(),
        data.value("adresse").toString());
    if (result.isOk()) {
        emit operationSucceeded("Donateur ajouté");
        loadDonateurs();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void FinanceController::loadDonsByProjet(int projetId) {
    setLoading(true);
    auto result = m_service->getDonsByProjet(projetId);
    if (result.isOk()) {
        m_dons.clear();
        for (const auto& d : result.value()) m_dons.append(donToMap(d));
        emit donsChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void FinanceController::recordDon(const QVariantMap& data) {
    auto result = m_service->recordDon(
        data.value("donateurId").toInt(),
        data.value("projetId").toInt(),
        data.value("montant").toDouble());
    if (result.isOk()) emit operationSucceeded("Don enregistré");
    else emit operationFailed(result.errorMessage());
}
