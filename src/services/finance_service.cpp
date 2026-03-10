#include "services/finance_service.h"

#include <QDate>
#include <QDebug>

#include "repositories/ipaiement_repository.h"
#include "repositories/ifinance_repository.h"
#include "repositories/ipaiement_personnel_repository.h"

FinanceService::FinanceService(IPaiementRepository* paiementRepo, IProjetRepository* projetRepo,
                               IDonateurRepository* donateurRepo, IDonRepository* donRepo,
                               IPaiementPersonnelRepository* paiementPersonnelRepo,
                               ITarifMensualiteRepository* tarifRepo,
                               IDepenseRepository* depenseRepo,
                               IFinanceBalanceRepository* balanceRepo)
    : m_paiementRepo(paiementRepo)
    , m_projetRepo(projetRepo)
    , m_donateurRepo(donateurRepo)
    , m_donRepo(donRepo)
    , m_paiementPersonnelRepo(paiementPersonnelRepo)
    , m_tarifRepo(tarifRepo)
    , m_depenseRepo(depenseRepo)
    , m_balanceRepo(balanceRepo)
{
}

// --- Paiements mensuels ---

Result<QList<PaiementMensualite>> FinanceService::getPaymentsByMonth(int month, int year)
{
    return m_paiementRepo->getByMonth(month, year);
}

Result<QList<PaiementMensualite>> FinanceService::getPaymentsByStudent(int eleveId)
{
    return m_paiementRepo->getByEleveId(eleveId);
}

Result<int> FinanceService::recordPayment(int eleveId, double montant, int mois, int annee, const QDate& datePaiement, const QString& justificatifPath)
{
    if (montant <= 0.0) {
        return Result<int>::error("Le montant du paiement doit etre superieur a zero.");
    }
    if (mois < 1 || mois > 12) {
        return Result<int>::error("Le mois doit etre compris entre 1 et 12.");
    }
    if (annee < 2000) {
        return Result<int>::error("L'annee n'est pas valide.");
    }

    PaiementMensualite p;
    p.eleveId = eleveId;
    p.montantPaye = montant;
    p.datePaiement = datePaiement.isValid() ? datePaiement : QDate::currentDate();
    p.moisConcerne = mois;
    p.anneeConcernee = annee;
    p.justificatifPath = justificatifPath;
    return m_paiementRepo->create(p);
}

Result<int> FinanceService::overwritePayment(int eleveId, double montant, int mois, int annee, const QDate& datePaiement, const QString& justificatifPath)
{
    if (montant <= 0.0)
        return Result<int>::error("Le montant du paiement doit etre superieur a zero.");
    if (mois < 1 || mois > 12)
        return Result<int>::error("Le mois doit etre compris entre 1 et 12.");
    if (annee < 2000)
        return Result<int>::error("L'annee n'est pas valide.");

    auto delResult = m_paiementRepo->deleteByEleveAndMonth(eleveId, mois, annee);
    if (!delResult.isOk())
        return Result<int>::error(delResult.errorMessage());

    PaiementMensualite p;
    p.eleveId        = eleveId;
    p.montantPaye    = montant;
    p.datePaiement   = datePaiement.isValid() ? datePaiement : QDate::currentDate();
    p.moisConcerne   = mois;
    p.anneeConcernee = annee;
    p.justificatifPath = justificatifPath;
    return m_paiementRepo->create(p);
}

Result<bool> FinanceService::updatePayment(int id, double newMontant, const QDate& datePaiement, const QString& justificatifPath)
{
    if (newMontant < 0.0)
        return Result<bool>::error("Le montant ne peut pas etre negatif.");
    auto existing = m_paiementRepo->getById(id);
    if (!existing.isOk())
        return Result<bool>::error(existing.errorMessage());
    if (!existing.value().has_value())
        return Result<bool>::error("Paiement introuvable.");
    PaiementMensualite p = existing.value().value();
    p.montantPaye = newMontant;
    if (datePaiement.isValid()) {
        p.datePaiement = datePaiement;
    }
    p.justificatifPath = justificatifPath;
    return m_paiementRepo->update(p);
}

Result<bool> FinanceService::deletePayment(int id)
{
    return m_paiementRepo->remove(id);
}

// --- Projets ---

Result<QList<Projet>> FinanceService::getAllProjets()
{
    auto result = m_projetRepo->getAll();
    if (result.isOk()) {
        QList<Projet> projets = result.value();
        for (int i = 0; i < projets.size(); ++i) {
            auto donResult = m_donRepo->getByProjetId(projets[i].id);
            if (donResult.isOk()) {
                double total = 0.0;
                for (const auto& don : donResult.value()) {
                    if (don.natureDon == "Nature") {
                        total += don.valeurEstimee;
                    } else {
                        total += don.montant;
                    }
                }
                projets[i].totalDons = total;
            }
        }
        return Result<QList<Projet>>::success(projets);
    }
    return result;
}

Result<int> FinanceService::createProjet(const Projet& projet)
{
    if (projet.nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom du projet ne peut pas etre vide.");
    }
    if (projet.objectifFinancier <= 0.0) {
        return Result<int>::error("L'objectif financier doit etre superieur a 0.");
    }
    return m_projetRepo->create(projet);
}

Result<bool> FinanceService::updateProjet(const Projet& projet)
{
    if (projet.nom.trimmed().isEmpty()) {
        return Result<bool>::error("Le nom du projet ne peut pas etre vide.");
    }

    return m_projetRepo->update(projet);
}

Result<bool> FinanceService::deleteProjet(int id)
{
    return m_projetRepo->remove(id);
}

// --- Donateurs ---

Result<QList<Donateur>> FinanceService::getAllDonateurs()
{
    return m_donateurRepo->getAll();
}

Result<int> FinanceService::createDonateur(const Donateur& donateur)
{
    if (donateur.nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom du donateur ne peut pas etre vide.");
    }
    return m_donateurRepo->create(donateur);
}

// --- Dons ---

Result<QList<Don>> FinanceService::getAllDons()
{
    return m_donRepo->getAll();
}

Result<QList<Don>> FinanceService::getDonsByProjet(int projetId)
{
    return m_donRepo->getByProjetId(projetId);
}

Result<int> FinanceService::recordDon(const Don& don)
{
    // Compare against "Nature" (ASCII-only) to avoid any MSVC encoding issues
    const bool isNature = (don.natureDon == QLatin1String("Nature"));
    if (isNature && don.valeurEstimee <= 0.0) {
        return Result<int>::error("La valeur estimee du don en nature doit etre superieure a zero.");
    }
    if (!isNature && don.montant <= 0.0) {
        return Result<int>::error("Le montant du don doit etre superieur a zero.");
    }
    return m_donRepo->create(don);
}

Result<bool> FinanceService::updateDon(int id, const Don& don)
{
    const bool isNature = (don.natureDon == QLatin1String("Nature"));
    if (isNature && don.valeurEstimee <= 0.0)
        return Result<bool>::error("La valeur estimee du don en nature doit etre superieure a zero.");
    if (!isNature && don.montant <= 0.0)
        return Result<bool>::error("Le montant du don doit etre superieur a zero.");
    Don d = don;
    d.id = id;
    return m_donRepo->update(d);
}

Result<bool> FinanceService::deleteDon(int id)
{
    return m_donRepo->remove(id);
}

Result<double> FinanceService::getProjetTotalDons(int projetId)
{
    return m_donRepo->getTotalByProjet(projetId);
}

// --- Dépenses ---

Result<QList<Depense>> FinanceService::getDepensesByMonth(int month, int year)
{
    return m_depenseRepo->getByMonth(month, year);
}

Result<int> FinanceService::createDepense(const Depense& depense)
{
    if (depense.libelle.trimmed().isEmpty())
        return Result<int>::error("Le libelle de la depense ne peut pas etre vide.");
    if (depense.montant <= 0.0)
        return Result<int>::error("Le montant de la depense doit etre superieur a zero.");
    return m_depenseRepo->create(depense);
}

Result<bool> FinanceService::updateDepense(int id, const Depense& depense)
{
    if (depense.libelle.trimmed().isEmpty())
        return Result<bool>::error("Le libelle de la depense ne peut pas etre vide.");
    if (depense.montant <= 0.0)
        return Result<bool>::error("Le montant de la depense doit etre superieur a zero.");
    Depense d = depense;
    d.id = id;
    return m_depenseRepo->update(d);
}

Result<bool> FinanceService::deleteDepense(int id)
{
    return m_depenseRepo->remove(id);
}

// --- Donateurs — mise à jour ---

Result<bool> FinanceService::updateDonateur(int id, const Donateur& donateur)
{
    if (donateur.nom.trimmed().isEmpty())
        return Result<bool>::error("Le nom du donateur ne peut pas etre vide.");
    Donateur d = donateur;
    d.id = id;
    return m_donateurRepo->update(d);
}

// --- Tarifs mensualités ---

Result<QList<TarifMensualite>> FinanceService::getTarifsForYear(const QString& anneeScolaireLibelle)
{
    return m_tarifRepo->getByYear(anneeScolaireLibelle);
}

Result<QList<TarifMensualite>> FinanceService::getTarifsForYearId(int anneeScolaireId)
{
    return m_tarifRepo->getByYearId(anneeScolaireId);
}

// --- Paiements personnel ---

Result<std::optional<PaiementMensuelPersonnel>>
FinanceService::getPersonnelPayment(int personnelId, int mois, int annee)
{
    if (mois < 1 || mois > 12) {
        return Result<std::optional<PaiementMensuelPersonnel>>::error(
            "Le mois doit etre compris entre 1 et 12.");
    }
    if (annee < 2000) {
        return Result<std::optional<PaiementMensuelPersonnel>>::error(
            "L'annee n'est pas valide.");
    }

    return m_paiementPersonnelRepo->getByPersonnelAndMonth(personnelId, mois, annee);
}

Result<QList<PaiementMensuelPersonnel>>
FinanceService::getAllPersonnelPaymentsForMonth(int mois, int annee)
{
    if (mois < 1 || mois > 12) {
        return Result<QList<PaiementMensuelPersonnel>>::error(
            "Le mois doit etre compris entre 1 et 12.");
    }
    if (annee < 2000) {
        return Result<QList<PaiementMensuelPersonnel>>::error(
            "L'annee n'est pas valide.");
    }

    return m_paiementPersonnelRepo->getByMonth(mois, annee);
}

Result<bool> FinanceService::savePersonnelPayment(const PaiementMensuelPersonnel& paiement)
{
    if (paiement.personnelId <= 0) {
        return Result<bool>::error("L'ID du personnel n'est pas valide.");
    }
    if (paiement.mois < 1 || paiement.mois > 12) {
        return Result<bool>::error("Le mois doit etre compris entre 1 et 12.");
    }
    if (paiement.annee < 2000) {
        return Result<bool>::error("L'annee n'est pas valide.");
    }
    if (paiement.sommeDue < 0.0 || paiement.sommePaye < 0.0) {
        return Result<bool>::error("Les montants ne peuvent pas etre negatifs.");
    }

    return m_paiementPersonnelRepo->upsert(paiement);
}

// --- Bilan financier ---

Result<QVariantMap> FinanceService::getAnnualBalance(int year)
{
    return Result<QVariantMap>::success(
        m_balanceRepo->computeBalance(QString::number(year)));
}

Result<QVariantMap> FinanceService::getBalanceForAccountingYear(int year, int month)
{
    QVariantMap config = m_balanceRepo->getExerciceConfig();
    QString debutVal = config.value(QStringLiteral("exerciceDebut"), QStringLiteral("01-01")).toString();
    QString finVal   = config.value(QStringLiteral("exerciceFin"),   QStringLiteral("12-31")).toString();

    qInfo() << "[Balance] getBalanceForAccountingYear: year=" << year << " month=" << month
            << " debutVal=" << debutVal << " finVal=" << finVal;

    QString dateFrom, dateTo, libelle;

    if (debutVal.length() >= 8) {
        // Full date (YYYY-MM-DD): use directly
        dateFrom = debutVal;
        dateTo   = finVal;
        int startYear = dateFrom.left(4).toInt();
        int endYear   = dateTo.left(4).toInt();
        libelle = (startYear == endYear)
                  ? QString::number(startYear)
                  : QString("%1-%2").arg(startYear).arg(endYear);
        qInfo() << "[Balance]   full-date mode: dateFrom=" << dateFrom << " dateTo=" << dateTo;
    } else {
        // Legacy MM-DD: reconstruct year from selected month/year
        int debutMonth = debutVal.left(2).toInt();
        int finMonth   = finVal.left(2).toInt();
        int startYear  = (month < debutMonth) ? year - 1 : year;
        int endYear    = (finMonth < debutMonth) ? startYear + 1 : startYear;
        dateFrom = QString::number(startYear) + "-" + debutVal;
        dateTo   = QString::number(endYear)   + "-" + finVal;
        libelle  = (startYear == endYear)
                   ? QString::number(startYear)
                   : QString("%1-%2").arg(startYear).arg(endYear);
        qInfo() << "[Balance]   MM-DD mode: dateFrom=" << dateFrom << " dateTo=" << dateTo;
    }

    auto balance = m_balanceRepo->computeBalanceForRange(dateFrom, dateTo);
    balance[QStringLiteral("libelle")]   = libelle;
    balance[QStringLiteral("dateDebut")] = dateFrom;
    balance[QStringLiteral("dateFin")]   = dateTo;
    qInfo() << "[Balance]   libelle=" << libelle;
    return Result<QVariantMap>::success(balance);
}

Result<QVariantMap> FinanceService::getBalanceForDateRange(const QString& dateDebut, const QString& dateFin)
{
    if (dateDebut.isEmpty() || dateFin.isEmpty())
        return Result<QVariantMap>::error("Plage de dates invalide.");
    return Result<QVariantMap>::success(
        m_balanceRepo->computeBalanceForRange(dateDebut, dateFin));
}

Result<QVariantMap> FinanceService::getTotalBalance()
{
    return Result<QVariantMap>::success(
        m_balanceRepo->computeBalance(QString()));
}
