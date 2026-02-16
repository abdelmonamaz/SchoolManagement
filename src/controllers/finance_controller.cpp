#include "controllers/finance_controller.h"
#include "services/finance_service.h"
#include "database/database_worker.h"

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

FinanceController::FinanceController(FinanceService* service, DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &FinanceController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &FinanceController::onQueryError);
}

void FinanceController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

// ─── Paiements ───

void FinanceController::loadPaymentsByMonth(int month, int year) {
    setLoading(true);
    m_worker->submit("Finance.loadPaymentsByMonth", [svc = m_service, month, year]() -> QVariant {
        auto result = svc->getPaymentsByMonth(month, year);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(paiementToMap(p));
        return list;
    });
}

void FinanceController::loadPaymentsByStudent(int eleveId) {
    setLoading(true);
    m_worker->submit("Finance.loadPaymentsByStudent", [svc = m_service, eleveId]() -> QVariant {
        auto result = svc->getPaymentsByStudent(eleveId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(paiementToMap(p));
        return list;
    });
}

void FinanceController::recordPayment(const QVariantMap& data) {
    m_worker->submit("Finance.recordPayment", [svc = m_service, data]() -> QVariant {
        auto result = svc->recordPayment(
            data.value("eleveId").toInt(),
            data.value("montant").toDouble(),
            data.value("mois").toInt(),
            data.value("annee").toInt());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::deletePayment(int id) {
    m_worker->submit("Finance.deletePayment", [svc = m_service, id]() -> QVariant {
        auto result = svc->deletePayment(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Projets ───

void FinanceController::loadProjets() {
    setLoading(true);
    m_worker->submit("Finance.loadProjets", [svc = m_service]() -> QVariant {
        auto result = svc->getAllProjets();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(projetToMap(p));
        return list;
    });
}

void FinanceController::createProjet(const QVariantMap& data) {
    m_worker->submit("Finance.createProjet", [svc = m_service, data]() -> QVariant {
        auto result = svc->createProjet(
            data.value("nom").toString(),
            data.value("description").toString(),
            data.value("objectifFinancier").toDouble());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::updateProjet(int id, const QVariantMap& data) {
    m_worker->submit("Finance.updateProjet", [svc = m_service, id, data]() -> QVariant {
        Projet p;
        p.id = id;
        p.nom = data.value("nom").toString();
        p.description = data.value("description").toString();
        p.objectifFinancier = data.value("objectifFinancier").toDouble();
        auto statut = data.value("statut").toString();
        if (statut == QStringLiteral("Terminé")) p.statut = GS::StatutProjet::Termine;
        else if (statut == QStringLiteral("En pause")) p.statut = GS::StatutProjet::EnPause;
        else p.statut = GS::StatutProjet::EnCours;
        auto result = svc->updateProjet(p);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::deleteProjet(int id) {
    m_worker->submit("Finance.deleteProjet", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteProjet(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Donateurs & Dons ───

void FinanceController::loadDonateurs() {
    setLoading(true);
    m_worker->submit("Finance.loadDonateurs", [svc = m_service]() -> QVariant {
        auto result = svc->getAllDonateurs();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& d : result.value()) list.append(donateurToMap(d));
        return list;
    });
}

void FinanceController::createDonateur(const QVariantMap& data) {
    m_worker->submit("Finance.createDonateur", [svc = m_service, data]() -> QVariant {
        auto result = svc->createDonateur(
            data.value("nom").toString(),
            data.value("telephone").toString(),
            data.value("adresse").toString());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::loadDonsByProjet(int projetId) {
    setLoading(true);
    m_worker->submit("Finance.loadDonsByProjet", [svc = m_service, projetId]() -> QVariant {
        auto result = svc->getDonsByProjet(projetId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& d : result.value()) list.append(donToMap(d));
        return list;
    });
}

void FinanceController::recordDon(const QVariantMap& data) {
    m_worker->submit("Finance.recordDon", [svc = m_service, data]() -> QVariant {
        auto result = svc->recordDon(
            data.value("donateurId").toInt(),
            data.value("projetId").toInt(),
            data.value("montant").toDouble());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Async result handlers ───

void FinanceController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Finance.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    // Payments
    if (queryId == "Finance.loadPaymentsByMonth" || queryId == "Finance.loadPaymentsByStudent") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_payments = result.toList(); emit paymentsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Finance.recordPayment") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Paiement enregistré");
    }
    else if (queryId == "Finance.deletePayment") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Paiement supprimé");
    }
    // Projets
    else if (queryId == "Finance.loadProjets") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_projets = result.toList(); emit projetsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Finance.createProjet") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Projet créé"); loadProjets(); }
    }
    else if (queryId == "Finance.updateProjet") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Projet mis à jour"); loadProjets(); }
    }
    else if (queryId == "Finance.deleteProjet") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Projet supprimé"); loadProjets(); }
    }
    // Donateurs
    else if (queryId == "Finance.loadDonateurs") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_donateurs = result.toList(); emit donateursChanged(); }
        setLoading(false);
    }
    else if (queryId == "Finance.createDonateur") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Donateur ajouté"); loadDonateurs(); }
    }
    // Dons
    else if (queryId == "Finance.loadDonsByProjet") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_dons = result.toList(); emit donsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Finance.recordDon") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Don enregistré");
    }
}

void FinanceController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Finance.")) return;

    if (queryId.startsWith("Finance.load")) {
        m_errorMessage = error; emit errorMessageChanged();
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
