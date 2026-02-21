#pragma once

#include <QList>
#include <QString>

#include "common/result.h"
#include "models/paiement.h"
#include "models/finance.h"

class IPaiementRepository;
class IProjetRepository;
class IDonateurRepository;
class IDonRepository;
class IPaiementPersonnelRepository;

class FinanceService {
public:
    FinanceService(IPaiementRepository* paiementRepo, IProjetRepository* projetRepo,
                   IDonateurRepository* donateurRepo, IDonRepository* donRepo,
                   IPaiementPersonnelRepository* paiementPersonnelRepo);

    // Paiements mensuels
    Result<QList<PaiementMensualite>> getPaymentsByMonth(int month, int year);
    Result<QList<PaiementMensualite>> getPaymentsByStudent(int eleveId);
    Result<int> recordPayment(int eleveId, double montant, int mois, int annee);
    Result<bool> deletePayment(int id);

    // Projets & Dons
    Result<QList<Projet>> getAllProjets();
    Result<int> createProjet(const QString& nom, const QString& desc, double objectif);
    Result<bool> updateProjet(const Projet& projet);
    Result<bool> deleteProjet(int id);

    Result<QList<Donateur>> getAllDonateurs();
    Result<int> createDonateur(const QString& nom, const QString& telephone, const QString& adresse);

    Result<QList<Don>> getDonsByProjet(int projetId);
    Result<int> recordDon(int donateurId, int projetId, double montant);
    Result<double> getProjetTotalDons(int projetId);

    // Paiements personnel
    Result<std::optional<PaiementMensuelPersonnel>>
        getPersonnelPayment(int personnelId, int mois, int annee);
    Result<QList<PaiementMensuelPersonnel>>
        getAllPersonnelPaymentsForMonth(int mois, int annee);
    Result<bool> savePersonnelPayment(const PaiementMensuelPersonnel& paiement);

private:
    IPaiementRepository* m_paiementRepo;
    IProjetRepository* m_projetRepo;
    IDonateurRepository* m_donateurRepo;
    IDonRepository* m_donRepo;
    IPaiementPersonnelRepository* m_paiementPersonnelRepo;
};
