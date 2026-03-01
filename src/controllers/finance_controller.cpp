#include "controllers/finance_controller.h"
#include "services/finance_service.h"
#include "database/database_worker.h"

#include <QFile>
#include <QTextStream>

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
        {"moisConcerne", p.moisConcerne}, {"anneeConcernee", p.anneeConcernee},
        {"justificatifPath", p.justificatifPath}
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
    return {
        {"id", d.id}, {"nom", d.nom}, {"telephone", d.telephone}, {"adresse", d.adresse},
        {"typePersonne", d.typePersonne}, {"cin", d.cin}, {"raisonSociale", d.raisonSociale},
        {"matriculeFiscal", d.matriculeFiscal}, {"representantLegal", d.representantLegal}
    };
}

static QVariantMap donToMap(const Don& d) {
    double montantEffectif = (d.natureDon == QStringLiteral("Nature")) ? d.valeurEstimee : d.montant;
    return {
        {"id", d.id}, {"donateurId", d.donateurId}, {"projetId", d.projetId},
        {"montant", d.montant}, {"dateDon", d.dateDon.toString(Qt::ISODate)},
        {"natureDon", d.natureDon}, {"modePaiement", d.modePaiement},
        {"descriptionMateriel", d.descriptionMateriel}, {"valeurEstimee", d.valeurEstimee},
        {"etatMateriel", d.etatMateriel}, {"justificatifPath", d.justificatifPath},
        {"montantEffectif", montantEffectif}
    };
}

static QVariantMap tarifToMap(const TarifMensualite& t) {
    return {{"id", t.id}, {"categorie", t.categorie},
            {"anneeScolaire", t.anneeScolaire}, {"montant", t.montant}};
}

static QString anneeScolaireForMonth(int month, int year) {
    if (month >= 9)
        return QString("%1-%2").arg(year).arg(year + 1);
    return QString("%1-%2").arg(year - 1).arg(year);
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
            data.value("annee").toInt(),
            QDate::fromString(data.value("datePaiement").toString(), Qt::ISODate),
            data.value("justificatifPath").toString().trimmed());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::overwritePayment(const QVariantMap& data) {
    m_worker->submit("Finance.overwritePayment", [svc = m_service, data]() -> QVariant {
        auto result = svc->overwritePayment(
            data.value("eleveId").toInt(),
            data.value("montant").toDouble(),
            data.value("mois").toInt(),
            data.value("annee").toInt(),
            QDate::fromString(data.value("datePaiement").toString(), Qt::ISODate),
            data.value("justificatifPath").toString().trimmed());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::updatePayment(int id, const QVariantMap& data) {
    m_worker->submit("Finance.updatePayment", [svc = m_service, id, data]() -> QVariant {
        auto result = svc->updatePayment(id, data.value("montant").toDouble(),
            QDate::fromString(data.value("datePaiement").toString(), Qt::ISODate),
            data.value("justificatifPath").toString().trimmed());
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
        Donateur d;
        d.nom               = data.value("nom").toString().trimmed();
        d.telephone         = data.value("telephone").toString().trimmed();
        d.adresse           = data.value("adresse").toString().trimmed();
        d.typePersonne      = data.value("typePersonne", QStringLiteral("Physique")).toString();
        d.cin               = data.value("cin").toString().trimmed();
        d.raisonSociale     = data.value("raisonSociale").toString().trimmed();
        d.matriculeFiscal   = data.value("matriculeFiscal").toString().trimmed();
        d.representantLegal = data.value("representantLegal").toString().trimmed();
        auto result = svc->createDonateur(d);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::loadAllDons() {
    setLoading(true);
    m_worker->submit("Finance.loadAllDons", [svc = m_service]() -> QVariant {
        auto result = svc->getAllDons();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& d : result.value()) list.append(donToMap(d));
        return list;
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
        Don d;
        d.donateurId          = data.value("donateurId").toInt();
        d.projetId            = data.value("projetId").toInt();
        d.montant             = data.value("montant").toDouble();
        d.dateDon             = QDate::fromString(data.value("dateDon").toString(), Qt::ISODate);
        if (!d.dateDon.isValid()) d.dateDon = QDate::currentDate();
        d.natureDon           = data.value("natureDon",    QStringLiteral("Numéraire")).toString();
        d.modePaiement        = data.value("modePaiement", QStringLiteral("Espèces")).toString();
        d.descriptionMateriel = data.value("descriptionMateriel").toString().trimmed();
        d.valeurEstimee       = data.value("valeurEstimee").toDouble();
        d.etatMateriel        = data.value("etatMateriel", QStringLiteral("Neuf")).toString();
        d.justificatifPath    = data.value("justificatifPath").toString().trimmed();
        auto result = svc->recordDon(d);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::updateDon(int id, const QVariantMap& data) {
    m_worker->submit("Finance.updateDon", [svc = m_service, id, data]() -> QVariant {
        Don d;
        d.donateurId          = data.value("donateurId").toInt();
        d.projetId            = data.value("projetId").toInt();
        d.montant             = data.value("montant").toDouble();
        d.dateDon             = QDate::fromString(data.value("dateDon").toString(), Qt::ISODate);
        if (!d.dateDon.isValid()) d.dateDon = QDate::currentDate();
        d.natureDon           = data.value("natureDon",    QStringLiteral("Numéraire")).toString();
        d.modePaiement        = data.value("modePaiement", QStringLiteral("Espèces")).toString();
        d.descriptionMateriel = data.value("descriptionMateriel").toString().trimmed();
        d.valeurEstimee       = data.value("valeurEstimee").toDouble();
        d.etatMateriel        = data.value("etatMateriel", QStringLiteral("Neuf")).toString();
        d.justificatifPath    = data.value("justificatifPath").toString().trimmed();
        auto result = svc->updateDon(id, d);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Dépenses ───

static QVariantMap depenseToMap(const Depense& d) {
    return {
        {"id", d.id}, {"libelle", d.libelle}, {"montant", d.montant},
        {"date", d.date.toString(Qt::ISODate)}, {"categorie", d.categorie},
        {"justificatifPath", d.justificatifPath}, {"notes", d.notes}
    };
}

void FinanceController::loadDepensesByMonth(int month, int year) {
    setLoading(true);
    m_worker->submit("Finance.loadDepensesByMonth", [svc = m_service, month, year]() -> QVariant {
        auto result = svc->getDepensesByMonth(month, year);
        if (!result.isOk()) return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& d : result.value()) list.append(depenseToMap(d));
        return list;
    });
}

void FinanceController::createDepense(const QVariantMap& data) {
    m_worker->submit("Finance.createDepense", [svc = m_service, data]() -> QVariant {
        Depense d;
        d.libelle          = data.value("libelle").toString().trimmed();
        d.montant          = data.value("montant").toDouble();
        d.date             = QDate::fromString(data.value("date").toString(), Qt::ISODate);
        if (!d.date.isValid()) d.date = QDate::currentDate();
        d.categorie        = data.value("categorie", QStringLiteral("Autre")).toString();
        d.justificatifPath = data.value("justificatifPath").toString().trimmed();
        d.notes            = data.value("notes").toString().trimmed();
        auto result = svc->createDepense(d);
        if (!result.isOk()) return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::updateDepense(int id, const QVariantMap& data) {
    m_worker->submit("Finance.updateDepense", [svc = m_service, id, data]() -> QVariant {
        Depense d;
        d.libelle          = data.value("libelle").toString().trimmed();
        d.montant          = data.value("montant").toDouble();
        d.date             = QDate::fromString(data.value("date").toString(), Qt::ISODate);
        if (!d.date.isValid()) d.date = QDate::currentDate();
        d.categorie        = data.value("categorie", QStringLiteral("Autre")).toString();
        d.justificatifPath = data.value("justificatifPath").toString().trimmed();
        d.notes            = data.value("notes").toString().trimmed();
        auto result = svc->updateDepense(id, d);
        if (!result.isOk()) return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::deleteDepense(int id) {
    m_worker->submit("Finance.deleteDepense", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteDepense(id);
        if (!result.isOk()) return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Donateurs — mise à jour ───

void FinanceController::updateDonateur(int id, const QVariantMap& data) {
    m_worker->submit("Finance.updateDonateur", [svc = m_service, id, data]() -> QVariant {
        Donateur d;
        d.nom               = data.value("nom").toString().trimmed();
        d.telephone         = data.value("telephone").toString().trimmed();
        d.adresse           = data.value("adresse").toString().trimmed();
        d.typePersonne      = data.value("typePersonne", QStringLiteral("Physique")).toString();
        d.cin               = data.value("cin").toString().trimmed();
        d.raisonSociale     = data.value("raisonSociale").toString().trimmed();
        d.matriculeFiscal   = data.value("matriculeFiscal").toString().trimmed();
        d.representantLegal = data.value("representantLegal").toString().trimmed();
        auto result = svc->updateDonateur(id, d);
        if (!result.isOk()) return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::exportDonateursCSV(const QString& filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit operationFailed("Impossible d'ouvrir le fichier : " + filePath);
        return;
    }
    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8);
    out << "\xEF\xBB\xBF"; // BOM UTF-8 (pour Excel)
    out << "ID;Nom;Type;CIN;Raison Sociale;Matricule Fiscal;Representant Legal;Telephone;Adresse\n";
    auto csvField = [](const QString& s) -> QString {
        return "\"" + s.trimmed().replace(QLatin1Char('"'), QStringLiteral("\"\"")) + "\"";
    };
    for (const auto& v : m_donateurs) {
        const auto d = v.toMap();
        out << d.value("id").toString()                        << ";"
            << csvField(d.value("nom").toString())             << ";"
            << csvField(d.value("typePersonne").toString())    << ";"
            << csvField(d.value("cin").toString())             << ";"
            << csvField(d.value("raisonSociale").toString())   << ";"
            << csvField(d.value("matriculeFiscal").toString()) << ";"
            << csvField(d.value("representantLegal").toString())<< ";"
            << csvField(d.value("telephone").toString())        << ";"
            << csvField(d.value("adresse").toString())          << "\n";
    }
    file.close();
    emit operationSucceeded("CSV.exported");
}

// ─── Tarifs ───

void FinanceController::loadTarifs(int month, int year) {
    QString annee = anneeScolaireForMonth(month, year);
    m_worker->submit("Finance.loadTarifs", [svc = m_service, annee]() -> QVariant {
        auto result = svc->getTarifsForYear(annee);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& t : result.value()) list.append(tarifToMap(t));
        return list;
    });
}

// ─── Personnel payments (journal) ───

void FinanceController::loadPersonnelPaymentsForJournal(int month, int year) {
    setLoading(true);
    m_worker->submit("Finance.loadPersonnelPaymentsForJournal", [svc = m_service, month, year]() -> QVariant {
        auto result = svc->getAllPersonnelPaymentsForMonth(month, year);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) {
            list.append(QVariantMap{
                {"id", p.id},
                {"personnelId", p.personnelId},
                {"mois", p.mois},
                {"annee", p.annee},
                {"sommeDue", p.sommeDue},
                {"sommePaye", p.sommePaye},
                {"dateModification", p.dateModification.date().toString(Qt::ISODate)},
                {"datePaiement", p.datePaiement},
                {"justificatifPath", p.justificatifPath}
            });
        }
        return list;
    });
}

// ─── Bilan financier ───

void FinanceController::loadAnnualBalance(int year) {
    m_worker->submit("Finance.loadAnnualBalance", [svc = m_service, year]() -> QVariant {
        auto result = svc->getAnnualBalance(year);
        if (!result.isOk()) return QVariantMap{{"error", result.errorMessage()}};
        return result.value();
    });
}

void FinanceController::loadTotalBalance() {
    m_worker->submit("Finance.loadTotalBalance", [svc = m_service]() -> QVariant {
        auto result = svc->getTotalBalance();
        if (!result.isOk()) return QVariantMap{{"error", result.errorMessage()}};
        return result.value();
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
    else if (queryId == "Finance.overwritePayment") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Paiement remplacé");
    }
    else if (queryId == "Finance.updatePayment") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Paiement modifié");
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
    else if (queryId == "Finance.loadAllDons" || queryId == "Finance.loadDonsByProjet") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_dons = result.toList(); emit donsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Finance.recordDon") {
        if (isError) emit operationFailed(map["error"].toString());
        else { loadAllDons(); emit operationSucceeded("Don enregistré"); }
    }
    else if (queryId == "Finance.updateDon") {
        if (isError) emit operationFailed(map["error"].toString());
        else { loadAllDons(); emit operationSucceeded("Don modifié"); }
    }
    // Dépenses
    else if (queryId == "Finance.loadDepensesByMonth") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_depenses = result.toList(); emit depensesChanged(); }
        setLoading(false);
    }
    else if (queryId == "Finance.createDepense") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Depense.created");
    }
    else if (queryId == "Finance.updateDepense") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Depense.updated");
    }
    else if (queryId == "Finance.deleteDepense") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Depense.deleted");
    }
    // Donateurs — mise à jour
    else if (queryId == "Finance.updateDonateur") {
        if (isError) emit operationFailed(map["error"].toString());
        else { loadDonateurs(); emit operationSucceeded("Donateur.updated"); }
    }
    // Tarifs
    else if (queryId == "Finance.loadTarifs") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_tarifs = result.toList(); emit tarifsChanged(); }
    }
    // Personnel payments (journal)
    else if (queryId == "Finance.loadPersonnelPaymentsForJournal") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_personnelPaymentsForJournal = result.toList(); emit personnelPaymentsForJournalChanged(); }
        setLoading(false);
    }
    // Bilan financier
    else if (queryId == "Finance.loadAnnualBalance") {
        if (!isError) { m_annualBalance = result.toMap(); emit annualBalanceChanged(); }
    }
    else if (queryId == "Finance.loadTotalBalance") {
        if (!isError) { m_totalBalance = result.toMap(); emit totalBalanceChanged(); }
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
