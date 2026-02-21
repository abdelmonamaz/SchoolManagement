#include "services/finance_service.h"

#include <QDate>

#include "repositories/ipaiement_repository.h"
#include "repositories/ifinance_repository.h"
#include "repositories/ipaiement_personnel_repository.h"

FinanceService::FinanceService(IPaiementRepository* paiementRepo, IProjetRepository* projetRepo,
                               IDonateurRepository* donateurRepo, IDonRepository* donRepo,
                               IPaiementPersonnelRepository* paiementPersonnelRepo)
    : m_paiementRepo(paiementRepo)
    , m_projetRepo(projetRepo)
    , m_donateurRepo(donateurRepo)
    , m_donRepo(donRepo)
    , m_paiementPersonnelRepo(paiementPersonnelRepo)
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

Result<int> FinanceService::recordPayment(int eleveId, double montant, int mois, int annee)
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
    p.datePaiement = QDate::currentDate();
    p.moisConcerne = mois;
    p.anneeConcernee = annee;
    return m_paiementRepo->create(p);
}

Result<bool> FinanceService::deletePayment(int id)
{
    return m_paiementRepo->remove(id);
}

// --- Projets ---

Result<QList<Projet>> FinanceService::getAllProjets()
{
    return m_projetRepo->getAll();
}

Result<int> FinanceService::createProjet(const QString& nom, const QString& desc, double objectif)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom du projet ne peut pas etre vide.");
    }
    if (objectif <= 0.0) {
        return Result<int>::error("L'objectif financier doit etre superieur a zero.");
    }

    Projet p;
    p.nom = nom.trimmed();
    p.description = desc.trimmed();
    p.objectifFinancier = objectif;
    p.statut = GS::StatutProjet::EnCours;
    return m_projetRepo->create(p);
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

Result<int> FinanceService::createDonateur(const QString& nom, const QString& telephone,
                                            const QString& adresse)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom du donateur ne peut pas etre vide.");
    }

    Donateur d;
    d.nom = nom.trimmed();
    d.telephone = telephone.trimmed();
    d.adresse = adresse.trimmed();
    return m_donateurRepo->create(d);
}

// --- Dons ---

Result<QList<Don>> FinanceService::getDonsByProjet(int projetId)
{
    return m_donRepo->getByProjetId(projetId);
}

Result<int> FinanceService::recordDon(int donateurId, int projetId, double montant)
{
    if (montant <= 0.0) {
        return Result<int>::error("Le montant du don doit etre superieur a zero.");
    }

    Don d;
    d.donateurId = donateurId;
    d.projetId = projetId;
    d.montant = montant;
    d.dateDon = QDate::currentDate();
    return m_donRepo->create(d);
}

Result<double> FinanceService::getProjetTotalDons(int projetId)
{
    return m_donRepo->getTotalByProjet(projetId);
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
