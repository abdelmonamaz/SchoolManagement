#pragma once

#include <QDate>
#include <QList>
#include <QPair>
#include <QString>

#include "common/result.h"
#include "models/professeur.h"

class IPersonnelRepository;
class IContratRepository;
class ISeanceRepository;

class StaffService {
public:
    StaffService(IPersonnelRepository* profRepo, IContratRepository* contratRepo,
                 ISeanceRepository* seanceRepo);

    // Personnel (identity data)
    Result<QList<Personnel>> getAllPersonnel();
    Result<int> createPersonnel(const Personnel& p);
    Result<bool> updatePersonnel(const Personnel& p);
    Result<bool> deletePersonnel(int id);

    // Personnel with active contract for a given date
    Result<QList<QPair<Personnel, Contrat>>> getPersonnelWithActiveContrat(const QDate& date);

    // Personnel with contract overlapping the given month
    Result<QList<QPair<Personnel, Contrat>>> getPersonnelForMonth(int mois, int annee);

    // Contrats
    Result<int> createContrat(const Contrat& contrat);
    Result<bool> updateContrat(const Contrat& contrat);
    Result<bool> deleteContrat(int contratId);
    Result<QList<Contrat>> getContratHistorique(int personnelId);
    Result<int> countContrats(int personnelId);

    // Salary calculation
    Result<double> calculateSommeDue(int personnelId, int mois, int annee);

    // Contract check
    Result<bool> hasActiveContrat(int personnelId, const QDate& date);

    // Hours/days calculation
    Result<int> getTotalMinutesForMonth(int profId, int mois, int annee);
    Result<int> getTotalJoursForMonth(int personnelId, int mois, int annee);

private:
    IPersonnelRepository* m_profRepo;
    IContratRepository* m_contratRepo;
    ISeanceRepository* m_seanceRepo;
};
