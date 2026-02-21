#pragma once

#include <QList>
#include <QString>

#include "common/result.h"
#include "models/professeur.h"

class IPersonnelRepository;

class StaffService {
public:
    explicit StaffService(IPersonnelRepository* profRepo);

    Result<QList<Professeur>> getAllProfesseurs();
    Result<int> createProfesseur(const Professeur& prof);
    Result<bool> updateProfesseur(const Professeur& prof);
    Result<bool> deleteProfesseur(int id);
    Result<bool> updateTarif(int profId, double nouveauPrix);
    Result<QList<TarifProfHistorique>> getTarifHistorique(int profId);

    double calculateMonthlySalary(const Professeur& prof, int totalHours);
    Result<double> calculateSommeDue(int personnelId, int mois, int annee);

private:
    IPersonnelRepository* m_profRepo;
};
