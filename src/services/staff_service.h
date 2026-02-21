#pragma once

#include <QList>
#include <QString>

#include "common/result.h"
#include "models/professeur.h"

class IPersonnelRepository;

class StaffService {
public:
    explicit StaffService(IPersonnelRepository* profRepo);

    Result<QList<Personnel>> getAllPersonnel();
    Result<int> createPersonnel(const Personnel& p);
    Result<bool> updatePersonnel(const Personnel& p);
    Result<bool> deletePersonnel(int id);
    Result<bool> updateTarif(int profId, double nouveauPrix);
    Result<QList<TarifPersonnelHistorique>> getTarifHistorique(int profId);

    double calculateMonthlySalary(const Personnel& p, int totalHours);
    Result<double> calculateSommeDue(int personnelId, int mois, int annee);

private:
    IPersonnelRepository* m_profRepo;
};
