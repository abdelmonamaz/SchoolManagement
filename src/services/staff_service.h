#pragma once

#include <QList>
#include <QString>

#include "common/result.h"
#include "models/professeur.h"

class IProfesseurRepository;

class StaffService {
public:
    explicit StaffService(IProfesseurRepository* profRepo);

    Result<QList<Professeur>> getAllProfesseurs();
    Result<int> createProfesseur(const QString& nom, const QString& prenom, const QString& telephone,
                                  const QString& adresse, double prixHeure);
    Result<bool> updateProfesseur(const Professeur& prof);
    Result<bool> deleteProfesseur(int id);
    Result<bool> updateTarif(int profId, double nouveauPrix);
    Result<QList<TarifProfHistorique>> getTarifHistorique(int profId);

    double calculateMonthlySalary(const Professeur& prof, int totalHours);

private:
    IProfesseurRepository* m_profRepo;
};
