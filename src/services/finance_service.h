#pragma once

#include <QList>
#include <QString>
#include <QVariantMap>

#include "common/result.h"
#include "models/paiement.h"
#include "models/finance.h"

class IPaiementRepository;
class IProjetRepository;
class IDonateurRepository;
class IDonRepository;
class IPaiementPersonnelRepository;
class ITarifMensualiteRepository;
class IDepenseRepository;

class FinanceService {
public:
    FinanceService(IPaiementRepository* paiementRepo, IProjetRepository* projetRepo,
                   IDonateurRepository* donateurRepo, IDonRepository* donRepo,
                   IPaiementPersonnelRepository* paiementPersonnelRepo,
                   ITarifMensualiteRepository* tarifRepo,
                   IDepenseRepository* depenseRepo,
                   const QString& connectionName = QString());

    // Paiements mensuels
    Result<QList<PaiementMensualite>> getPaymentsByMonth(int month, int year);
    Result<QList<PaiementMensualite>> getPaymentsByStudent(int eleveId);
    Result<int>  recordPayment(int eleveId, double montant, int mois, int annee, const QDate& datePaiement = QDate::currentDate(), const QString& justificatifPath = QString());
    Result<int>  overwritePayment(int eleveId, double montant, int mois, int annee, const QDate& datePaiement = QDate::currentDate(), const QString& justificatifPath = QString());
    Result<bool> updatePayment(int id, double newMontant, const QDate& datePaiement = QDate::currentDate(), const QString& justificatifPath = QString());
    Result<bool> deletePayment(int id);

    // Projets & Dons
    Result<QList<Projet>> getAllProjets();
    Result<int>  createProjet(const QString& nom, const QString& desc, double objectif);
    Result<bool> updateProjet(const Projet& projet);
    Result<bool> deleteProjet(int id);

    Result<QList<Donateur>> getAllDonateurs();
    Result<int> createDonateur(const Donateur& donateur);

    Result<QList<Don>> getAllDons();
    Result<QList<Don>> getDonsByProjet(int projetId);
    Result<int>    recordDon(const Don& don);
    Result<bool>   updateDon(int id, const Don& don);
    Result<bool>   deleteDon(int id);
    Result<double> getProjetTotalDons(int projetId);

    // Dépenses
    Result<QList<Depense>> getDepensesByMonth(int month, int year);
    Result<int>  createDepense(const Depense& depense);
    Result<bool> updateDepense(int id, const Depense& depense);
    Result<bool> deleteDepense(int id);

    // Donateurs — mise à jour
    Result<bool> updateDonateur(int id, const Donateur& donateur);

    // Bilan financier
    Result<QVariantMap> getAnnualBalance(int year);
    Result<QVariantMap> getTotalBalance();

    // Tarifs mensualités
    Result<QList<TarifMensualite>> getTarifsForYear(const QString& anneeScolaire);

    // Paiements personnel
    Result<std::optional<PaiementMensuelPersonnel>>
        getPersonnelPayment(int personnelId, int mois, int annee);
    Result<QList<PaiementMensuelPersonnel>>
        getAllPersonnelPaymentsForMonth(int mois, int annee);
    Result<bool> savePersonnelPayment(const PaiementMensuelPersonnel& paiement);

private:
    IPaiementRepository*         m_paiementRepo;
    IProjetRepository*           m_projetRepo;
    IDonateurRepository*         m_donateurRepo;
    IDonRepository*              m_donRepo;
    IPaiementPersonnelRepository* m_paiementPersonnelRepo;
    ITarifMensualiteRepository*  m_tarifRepo;
    IDepenseRepository*          m_depenseRepo;
    QString                      m_connectionName;
};
