#include "controllers/finance_controller.h"
#include "services/finance_service.h"
#include "database/database_worker.h"

#include <QFile>
#include <QTextStream>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QLocale>
#include <QDate>

// ── CSV helpers ─────────────────────────────────────────────────────────────
static QString csvQ(const QString& s) {
    return "\"" + s.trimmed().replace(QLatin1Char('"'), QStringLiteral("\"\"")) + "\"";
}
// Open a file for CSV export: UTF-16 LE with BOM, binary mode (no text-mode \n mangling).
static bool openCsvUtf16(QFile& f, QTextStream& out) {
    if (!f.open(QIODevice::WriteOnly)) return false;
    f.write("\xFF\xFE", 2);          // UTF-16 LE BOM written as raw bytes
    out.setDevice(&f);
    out.setEncoding(QStringConverter::Utf16LE);
    return true;
}
static void writeCsvTitle(QTextStream& out, const QString& title, const QString& assoc) {
    if (!assoc.isEmpty()) out << csvQ("Association : " + assoc) << "\r\n";
    out << csvQ(title) << "\r\n\r\n";
}
static QString frMonth(int month, int year) {
    return QLocale(QLocale::French).toString(QDate(year, month, 1), "MMMM yyyy");
}

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
        {"justificatifPath", p.justificatifPath}, {"numeroRecu", p.numeroRecu}
    };
}

static QVariantMap projetToMap(const Projet& p) {
    return {
        {"id", p.id}, {"nom", p.nom}, {"description", p.description},
        {"objectifFinancier", p.objectifFinancier},
        {"statut", statutProjetToString(p.statut)},
        {"dateDebut", p.dateDebut.isValid() ? p.dateDebut.toString(Qt::ISODate) : ""},
        {"dateFin", p.dateFin.isValid() ? p.dateFin.toString(Qt::ISODate) : ""},
        {"totalDons", p.totalDons}
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
        {"numeroRecu", d.numeroRecu}, {"montantEffectif", montantEffectif}
    };
}

static QVariantMap tarifToMap(const TarifMensualite& t) {
    return {{"id", t.id}, {"categorie", t.categorie},
            {"anneeScolaireId", t.anneeScolaireId}, {"montant", t.montant}};
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
            data.value("justificatifPath").toString().trimmed(),
            data.value("numeroRecu").toString().trimmed());
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
            data.value("justificatifPath").toString().trimmed(),
            data.value("numeroRecu").toString().trimmed());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::updatePayment(int id, const QVariantMap& data) {
    m_worker->submit("Finance.updatePayment", [svc = m_service, id, data]() -> QVariant {
        auto result = svc->updatePayment(id, data.value("montant").toDouble(),
            QDate::fromString(data.value("datePaiement").toString(), Qt::ISODate),
            data.value("justificatifPath").toString().trimmed(),
            data.value("numeroRecu").toString().trimmed());
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
        Projet p;
        p.nom = data.value("nom").toString();
        p.description = data.value("description").toString();
        p.objectifFinancier = data.value("objectifFinancier").toDouble();
        p.statut = GS::StatutProjet::EnCours; // default
        if (data.contains("dateDebut")) {
            p.dateDebut = QDate::fromString(data.value("dateDebut").toString(), Qt::ISODate);
        }
        if (data.contains("dateFin")) {
            p.dateFin = QDate::fromString(data.value("dateFin").toString(), Qt::ISODate);
        }
        auto result = svc->createProjet(p);
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
        if (data.contains("dateDebut")) {
            p.dateDebut = QDate::fromString(data.value("dateDebut").toString(), Qt::ISODate);
        }
        if (data.contains("dateFin")) {
            p.dateFin = QDate::fromString(data.value("dateFin").toString(), Qt::ISODate);
        }
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
        d.numeroRecu          = data.value("numeroRecu").toString().trimmed();
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
        d.numeroRecu          = data.value("numeroRecu").toString().trimmed();
        auto result = svc->updateDon(id, d);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void FinanceController::deleteDon(int id) {
    m_worker->submit("Finance.deleteDon", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteDon(id);
        if (!result.isOk()) return QVariantMap{{"error", result.errorMessage()}};
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

void FinanceController::loadAnnualBalanceForAccountingYear(int year, int month) {
    m_worker->submit("Finance.loadAnnualBalanceForAccountingYear", [svc = m_service, year, month]() -> QVariant {
        auto result = svc->getBalanceForAccountingYear(year, month);
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

// ─── Exports légaux CSV ───

void FinanceController::exportMonthlyPaiementsCSV(int month, int year, const QString& nomAssociation, const QString& filePath) {
    QString conn = m_worker->connectionName();
    m_worker->submit("Finance.exportMonthlyPaiements", [conn, month, year, nomAssociation, filePath]() -> QVariant {
        auto db = QSqlDatabase::database(conn);
        if (!db.isOpen()) return QVariantMap{{"error", "DB not open"}};
        QSqlQuery q(db);
        q.prepare(
            "SELECT COALESCE(pm.numero_recu,''), pm.date_paiement,"
            "       e.prenom||' '||e.nom, COALESCE(e.cin_eleve,''),"
            "       pm.mois_concerne, pm.annee_concernee, pm.montant_paye"
            " FROM paiements_mensualites pm"
            " JOIN eleves e ON pm.eleve_id = e.id"
            " WHERE pm.valide=1 AND pm.mois_concerne=? AND pm.annee_concernee=?"
            " ORDER BY pm.date_paiement, e.nom");
        q.addBindValue(month); q.addBindValue(year);
        if (!q.exec()) return QVariantMap{{"error", q.lastError().text()}};
        QFile f(filePath); QTextStream out;
        if (!openCsvUtf16(f, out)) return QVariantMap{{"error","Impossible d'ouvrir le fichier"}};
        writeCsvTitle(out, QString("Registre des paiements de scolarité — ") + frMonth(month,year), nomAssociation);
        out << csvQ("N° Reçu") << ";" << csvQ("Date") << ";" << csvQ("Nom Élève") << ";"
            << csvQ("CIN Élève") << ";" << csvQ("Mois Concerné") << ";" << csvQ("Montant Payé (DT)") << "\r\n";
        double total=0; int n=0;
        while (q.next()) {
            out << csvQ(q.value(0).toString()) << ";" << q.value(1).toString() << ";"
                << csvQ(q.value(2).toString()) << ";" << csvQ(q.value(3).toString()) << ";"
                << q.value(4).toString() << "/" << q.value(5).toString() << ";"
                << QString::number(q.value(6).toDouble(),'f',2) << "\r\n";
            total += q.value(6).toDouble(); n++;
        }
        out << "\r\n;;;;;" << csvQ("TOTAL : "+QString::number(total,'f',2)+" DT") << "\r\n";
        f.close();
        return QVariantMap{{"exportSuccess",true},{"count",n}};
    });
}

void FinanceController::exportMonthlyDonsCSV(int month, int year, const QString& nomAssociation, const QString& filePath) {
    QString conn = m_worker->connectionName();
    m_worker->submit("Finance.exportMonthlyDons", [conn, month, year, nomAssociation, filePath]() -> QVariant {
        auto db = QSqlDatabase::database(conn);
        if (!db.isOpen()) return QVariantMap{{"error","DB not open"}};
        QSqlQuery q(db);
        q.prepare(
            "SELECT COALESCE(d.numero_recu,''), d.date_don, don.nom,"
            "       COALESCE(don.type_personne,'Physique'),"
            "       CASE WHEN COALESCE(don.type_personne,'Physique')='Morale'"
            "            THEN COALESCE(don.matricule_fiscal,'') ELSE COALESCE(don.cin,'') END,"
            "       d.nature_don,"
            "       CASE WHEN d.nature_don='Nature' THEN d.valeur_estimee ELSE d.montant END,"
            "       COALESCE(d.mode_paiement,'Espèces'), COALESCE(d.description_materiel,''),"
            "       COALESCE(p.nom,'Général')"
            " FROM dons d"
            " JOIN donateurs don ON d.donateur_id=don.id"
            " LEFT JOIN projets p ON d.projet_id=p.id"
            " WHERE d.valide=1"
            "   AND CAST(strftime('%m',d.date_don) AS INTEGER)=?"
            "   AND CAST(strftime('%Y',d.date_don) AS INTEGER)=?"
            " ORDER BY d.date_don");
        q.addBindValue(month); q.addBindValue(year);
        if (!q.exec()) return QVariantMap{{"error",q.lastError().text()}};
        QFile f(filePath); QTextStream out;
        if (!openCsvUtf16(f, out)) return QVariantMap{{"error","Impossible d'ouvrir le fichier"}};
        writeCsvTitle(out, QString("Registre des dons — ") + frMonth(month,year), nomAssociation);
        out << csvQ("N° Reçu") << ";" << csvQ("Date") << ";" << csvQ("Donateur") << ";"
            << csvQ("Type") << ";" << csvQ("CIN / Matricule Fiscal") << ";"
            << csvQ("Nature Don") << ";" << csvQ("Montant (DT)") << ";"
            << csvQ("Mode Paiement") << ";" << csvQ("Description") << ";" << csvQ("Projet") << "\r\n";
        double total=0; int n=0;
        while (q.next()) {
            out << csvQ(q.value(0).toString()) << ";" << q.value(1).toString() << ";"
                << csvQ(q.value(2).toString()) << ";" << csvQ(q.value(3).toString()) << ";"
                << csvQ(q.value(4).toString()) << ";" << csvQ(q.value(5).toString()) << ";"
                << QString::number(q.value(6).toDouble(),'f',2) << ";"
                << csvQ(q.value(7).toString()) << ";" << csvQ(q.value(8).toString()) << ";"
                << csvQ(q.value(9).toString()) << "\r\n";
            total += q.value(6).toDouble(); n++;
        }
        out << "\r\n;;;;;;" << csvQ("TOTAL : "+QString::number(total,'f',2)+" DT") << "\r\n";
        f.close();
        return QVariantMap{{"exportSuccess",true},{"count",n}};
    });
}

void FinanceController::exportMonthlyDepensesCSV(int month, int year, const QString& nomAssociation, const QString& filePath) {
    QString conn = m_worker->connectionName();
    m_worker->submit("Finance.exportMonthlyDepenses", [conn, month, year, nomAssociation, filePath]() -> QVariant {
        auto db = QSqlDatabase::database(conn);
        if (!db.isOpen()) return QVariantMap{{"error","DB not open"}};
        QSqlQuery q(db);
        q.prepare(
            "SELECT date, libelle, categorie, montant, COALESCE(notes,'')"
            " FROM depenses"
            " WHERE valide=1"
            "   AND CAST(strftime('%m',date) AS INTEGER)=?"
            "   AND CAST(strftime('%Y',date) AS INTEGER)=?"
            " ORDER BY date");
        q.addBindValue(month); q.addBindValue(year);
        if (!q.exec()) return QVariantMap{{"error",q.lastError().text()}};
        QFile f(filePath); QTextStream out;
        if (!openCsvUtf16(f, out)) return QVariantMap{{"error","Impossible d'ouvrir le fichier"}};
        writeCsvTitle(out, QString("Registre des dépenses — ") + frMonth(month,year), nomAssociation);
        out << csvQ("Date") << ";" << csvQ("Libellé") << ";" << csvQ("Catégorie") << ";"
            << csvQ("Montant (DT)") << ";" << csvQ("Notes") << "\r\n";
        double total=0; int n=0;
        while (q.next()) {
            out << q.value(0).toString() << ";" << csvQ(q.value(1).toString()) << ";"
                << csvQ(q.value(2).toString()) << ";" << QString::number(q.value(3).toDouble(),'f',2) << ";"
                << csvQ(q.value(4).toString()) << "\r\n";
            total += q.value(3).toDouble(); n++;
        }
        out << "\r\n;;;" << csvQ("TOTAL : "+QString::number(total,'f',2)+" DT") << "\r\n";
        f.close();
        return QVariantMap{{"exportSuccess",true},{"count",n}};
    });
}

void FinanceController::exportMonthlySalairesCSV(int month, int year, const QString& nomAssociation, const QString& filePath) {
    QString conn = m_worker->connectionName();
    m_worker->submit("Finance.exportMonthlySalaires", [conn, month, year, nomAssociation, filePath]() -> QVariant {
        auto db = QSqlDatabase::database(conn);
        if (!db.isOpen()) return QVariantMap{{"error","DB not open"}};
        QSqlQuery q(db);
        q.prepare(
            "SELECT per.prenom||' '||per.nom, pp.somme_due, pp.somme_payee,"
            "       MAX(0.0, pp.somme_due-pp.somme_payee), COALESCE(pp.date_paiement,'')"
            " FROM paiements_personnel pp"
            " JOIN personnel per ON pp.personnel_id=per.id"
            " WHERE pp.valide=1 AND pp.mois=? AND pp.annee=?"
            " ORDER BY per.nom");
        q.addBindValue(month); q.addBindValue(year);
        if (!q.exec()) return QVariantMap{{"error",q.lastError().text()}};
        QFile f(filePath); QTextStream out;
        if (!openCsvUtf16(f, out)) return QVariantMap{{"error","Impossible d'ouvrir le fichier"}};
        writeCsvTitle(out, QString("Registre des salaires — ") + frMonth(month,year), nomAssociation);
        out << csvQ("Nom") << ";" << csvQ("Somme Due (DT)") << ";"
            << csvQ("Somme Payée (DT)") << ";" << csvQ("Reste (DT)") << ";"
            << csvQ("Date Paiement") << "\r\n";
        double totalDue=0, totalPaid=0; int n=0;
        while (q.next()) {
            out << csvQ(q.value(0).toString()) << ";"
                << QString::number(q.value(1).toDouble(),'f',2) << ";"
                << QString::number(q.value(2).toDouble(),'f',2) << ";"
                << QString::number(q.value(3).toDouble(),'f',2) << ";"
                << q.value(4).toString() << "\r\n";
            totalDue += q.value(1).toDouble(); totalPaid += q.value(2).toDouble(); n++;
        }
        out << "\r\n;" << csvQ(QString("DU : ")+QString::number(totalDue,'f',2)+" DT") << ";"
            << csvQ(QString("PAYE : ")+QString::number(totalPaid,'f',2)+" DT") << ";;\r\n";
        f.close();
        return QVariantMap{{"exportSuccess",true},{"count",n}};
    });
}

void FinanceController::exportRegistreDonsAnnuelCSV(const QString& dateFrom, const QString& dateTo, const QString& nomAssociation, const QString& filePath) {
    QString conn = m_worker->connectionName();
    m_worker->submit("Finance.exportRegistreDonsAnnuel", [conn, dateFrom, dateTo, nomAssociation, filePath]() -> QVariant {
        auto db = QSqlDatabase::database(conn);
        if (!db.isOpen()) return QVariantMap{{"error","DB not open"}};
        QSqlQuery q(db);
        q.prepare(
            "SELECT COALESCE(d.numero_recu,''), d.date_don, don.nom,"
            "       COALESCE(don.type_personne,'Physique'),"
            "       CASE WHEN COALESCE(don.type_personne,'Physique')='Morale'"
            "            THEN COALESCE(don.matricule_fiscal,'') ELSE COALESCE(don.cin,'') END,"
            "       COALESCE(don.raison_sociale,''), COALESCE(don.representant_legal,''),"
            "       COALESCE(don.telephone,''), COALESCE(don.adresse,''),"
            "       d.nature_don,"
            "       CASE WHEN d.nature_don='Nature' THEN d.valeur_estimee ELSE d.montant END,"
            "       COALESCE(d.mode_paiement,'Espèces'), COALESCE(d.description_materiel,''),"
            "       COALESCE(p.nom,'Général')"
            " FROM dons d"
            " JOIN donateurs don ON d.donateur_id=don.id"
            " LEFT JOIN projets p ON d.projet_id=p.id"
            " WHERE d.valide=1 AND d.date_don>=? AND d.date_don<=?"
            " ORDER BY d.date_don");
        q.addBindValue(dateFrom); q.addBindValue(dateTo);
        if (!q.exec()) return QVariantMap{{"error",q.lastError().text()}};
        QFile f(filePath); QTextStream out;
        if (!openCsvUtf16(f, out)) return QVariantMap{{"error","Impossible d'ouvrir le fichier"}};
        writeCsvTitle(out, QString("Registre annuel des dons — Du ")+dateFrom+" au "+dateTo, nomAssociation);
        out << csvQ("N° Reçu") << ";" << csvQ("Date") << ";" << csvQ("Donateur") << ";"
            << csvQ("Type") << ";" << csvQ("CIN / Matricule Fiscal") << ";"
            << csvQ("Raison Sociale") << ";" << csvQ("Representant Legal") << ";"
            << csvQ("Telephone") << ";" << csvQ("Adresse") << ";" << csvQ("Nature Don") << ";"
            << csvQ("Montant Effectif (DT)") << ";" << csvQ("Mode Paiement") << ";"
            << csvQ("Description") << ";" << csvQ("Projet") << "\r\n";
        double total=0; int n=0;
        while (q.next()) {
            out << csvQ(q.value(0).toString()) << ";" << q.value(1).toString() << ";";
            for (int i=2; i<=9; i++) out << csvQ(q.value(i).toString()) << ";";
            out << QString::number(q.value(10).toDouble(),'f',2) << ";"
                << csvQ(q.value(11).toString()) << ";" << csvQ(q.value(12).toString()) << ";"
                << csvQ(q.value(13).toString()) << "\r\n";
            total += q.value(10).toDouble(); n++;
        }
        out << "\r\n;;;;;;;;;;" << csvQ("TOTAL : "+QString::number(total,'f',2)+" DT") << "\r\n";
        f.close();
        return QVariantMap{{"exportSuccess",true},{"count",n}};
    });
}

void FinanceController::exportLivreCaisseCSV(const QString& dateFrom, const QString& dateTo, const QString& nomAssociation, const QString& filePath) {
    QString conn = m_worker->connectionName();
    m_worker->submit("Finance.exportLivreCaisse", [conn, dateFrom, dateTo, nomAssociation, filePath]() -> QVariant {
        auto db = QSqlDatabase::database(conn);
        if (!db.isOpen()) return QVariantMap{{"error","DB not open"}};
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "SELECT pm.date_paiement,'Paiement scolarité',"
            "       e.prenom||' '||e.nom, pm.montant_paye, 0.0"
            " FROM paiements_mensualites pm JOIN eleves e ON pm.eleve_id=e.id"
            " WHERE pm.valide=1 AND pm.date_paiement>=? AND pm.date_paiement<=?"

            " UNION ALL"
            " SELECT ie.date_inscription,'Frais inscription',"
            "       e.prenom||' '||e.nom, ie.montant_inscription, 0.0"
            " FROM inscriptions_eleves ie JOIN eleves e ON ie.eleve_id=e.id"
            " WHERE ie.valide=1 AND ie.frais_inscription_paye=1"
            "   AND ie.date_inscription>=? AND ie.date_inscription<=?"

            " UNION ALL"
            " SELECT d.date_don,'Don',don.nom,"
            "       CASE WHEN d.nature_don='Nature' THEN d.valeur_estimee ELSE d.montant END, 0.0"
            " FROM dons d JOIN donateurs don ON d.donateur_id=don.id"
            " WHERE d.valide=1 AND d.date_don>=? AND d.date_don<=?"

            " UNION ALL"
            " SELECT dep.date,'Dépense — '||dep.categorie,dep.libelle, 0.0,dep.montant"
            " FROM depenses dep"
            " WHERE dep.valide=1 AND dep.date>=? AND dep.date<=?"

            " UNION ALL"
            " SELECT COALESCE(pp.date_paiement,pp.date_modification),'Salaire personnel',"
            "       per.prenom||' '||per.nom, 0.0, pp.somme_payee"
            " FROM paiements_personnel pp JOIN personnel per ON pp.personnel_id=per.id"
            " WHERE pp.valide=1 AND pp.somme_payee>0"
            "   AND COALESCE(pp.date_paiement,pp.date_modification)>=?"
            "   AND COALESCE(pp.date_paiement,pp.date_modification)<=?"

            " ORDER BY 1"));
        for (int i=0; i<5; i++) { q.addBindValue(dateFrom); q.addBindValue(dateTo); }
        if (!q.exec()) return QVariantMap{{"error",q.lastError().text()}};
        QFile f(filePath); QTextStream out;
        if (!openCsvUtf16(f, out)) return QVariantMap{{"error","Impossible d'ouvrir le fichier"}};
        writeCsvTitle(out, QString("Livre de caisse — Du ")+dateFrom+" au "+dateTo, nomAssociation);
        out << csvQ("Date") << ";" << csvQ("Type Operation") << ";" << csvQ("Libelle") << ";"
            << csvQ("Entree (DT)") << ";" << csvQ("Sortie (DT)") << ";" << csvQ("Solde (DT)") << "\r\n";
        double solde=0; int n=0;
        while (q.next()) {
            double entree=q.value(3).toDouble(), sortie=q.value(4).toDouble();
            solde += entree - sortie;
            out << q.value(0).toString() << ";" << csvQ(q.value(1).toString()) << ";"
                << csvQ(q.value(2).toString()) << ";"
                << (entree>0 ? QString::number(entree,'f',2) : "") << ";"
                << (sortie>0 ? QString::number(sortie,'f',2) : "") << ";"
                << QString::number(solde,'f',2) << "\r\n";
            n++;
        }
        f.close();
        return QVariantMap{{"exportSuccess",true},{"count",n}};
    });
}

void FinanceController::exportBilanExerciceCSV(const QString& dateFrom, const QString& dateTo, const QString& nomAssociation, const QString& filePath) {
    m_worker->submit("Finance.exportBilanExercice", [svc=m_service, dateFrom, dateTo, nomAssociation, filePath]() -> QVariant {
        auto res = svc->getBalanceForDateRange(dateFrom, dateTo);
        if (!res.isOk()) return QVariantMap{{"error",res.errorMessage()}};
        auto bal = res.value();
        QFile f(filePath); QTextStream out;
        if (!openCsvUtf16(f, out)) return QVariantMap{{"error","Impossible d'ouvrir le fichier"}};
        auto dt = [](double v){ return QString::number(v,'f',2)+" DT"; };
        writeCsvTitle(out, QString("Bilan de l'exercice — Du ")+dateFrom+" au "+dateTo, nomAssociation);
        out << csvQ("ENTREES") << "\r\n";
        out << csvQ("Scolarite (paiements mensuels)") << ";" << dt(bal["scolarite"].toDouble()) << "\r\n";
        out << csvQ("Frais d'inscription") << ";" << dt(bal["inscriptions"].toDouble()) << "\r\n";
        out << csvQ("Dons et donations") << ";" << dt(bal["dons"].toDouble()) << "\r\n";
        out << csvQ("TOTAL ENTREES") << ";" << csvQ(dt(bal["entrees"].toDouble())) << "\r\n\r\n";
        out << csvQ("SORTIES") << "\r\n";
        out << csvQ("Depenses diverses") << ";" << dt(bal["depenses"].toDouble()) << "\r\n";
        out << csvQ("Salaires du personnel") << ";" << dt(bal["salaires"].toDouble()) << "\r\n";
        out << csvQ("TOTAL SORTIES") << ";" << csvQ(dt(bal["sorties"].toDouble())) << "\r\n\r\n";
        double solde = bal["solde"].toDouble();
        out << csvQ("SOLDE NET") << ";" << csvQ(dt(solde)) << "\r\n";
        out << csvQ("Resultat") << ";" << csvQ(solde>=0 ? "EXCEDENT" : "DEFICIT") << "\r\n";
        f.close();
        return QVariantMap{{"exportSuccess",true}};
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
        else { loadAllDons(); loadProjets(); emit operationSucceeded("Don enregistré"); }
    }
    else if (queryId == "Finance.updateDon") {
        if (isError) emit operationFailed(map["error"].toString());
        else { loadAllDons(); loadProjets(); emit operationSucceeded("Don mis à jour"); }
    }
    else if (queryId == "Finance.deleteDon") {
        if (isError) emit operationFailed(map["error"].toString());
        else { loadAllDons(); loadProjets(); emit operationSucceeded("Don supprimé"); }
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
    else if (queryId == "Finance.loadAnnualBalance"
             || queryId == "Finance.loadAnnualBalanceForAccountingYear") {
        if (!isError) { m_annualBalance = result.toMap(); emit annualBalanceChanged(); }
    }
    else if (queryId == "Finance.loadTotalBalance") {
        if (!isError) { m_totalBalance = result.toMap(); emit totalBalanceChanged(); }
    }
    else if (queryId.startsWith("Finance.export")) {
        if (isError) emit exportFailed(map["error"].toString());
        else {
            int count = map.value("count", -1).toInt();
            QString msg = count >= 0
                ? QString::number(count) + " enregistrement(s) exportés avec succès"
                : "Export terminé avec succès";
            emit exportSucceeded(msg);
        }
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
