#include "services/staff_service.h"

#include <QDateTime>

#include "repositories/iprof_repository.h"

StaffService::StaffService(IProfesseurRepository* profRepo)
    : m_profRepo(profRepo)
{
}

Result<QList<Professeur>> StaffService::getAllProfesseurs()
{
    return m_profRepo->getAll();
}

Result<int> StaffService::createProfesseur(const QString& nom, const QString& prenom,
                                            const QString& telephone, const QString& adresse,
                                            double prixHeure)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom du professeur ne peut pas etre vide.");
    }
    if (prenom.trimmed().isEmpty()) {
        return Result<int>::error("Le prenom du professeur ne peut pas etre vide.");
    }
    if (prixHeure < 0.0) {
        return Result<int>::error("Le prix par heure ne peut pas etre negatif.");
    }

    Professeur p;
    p.nom = nom.trimmed();
    p.prenom = prenom.trimmed();
    p.telephone = telephone.trimmed();
    p.adresse = adresse.trimmed();
    p.prixHeureActuel = prixHeure;
    p.statut = GS::StatutProf::Actif;
    return m_profRepo->create(p);
}

Result<bool> StaffService::updateProfesseur(const Professeur& prof)
{
    if (prof.nom.trimmed().isEmpty()) {
        return Result<bool>::error("Le nom du professeur ne peut pas etre vide.");
    }
    if (prof.prenom.trimmed().isEmpty()) {
        return Result<bool>::error("Le prenom du professeur ne peut pas etre vide.");
    }

    return m_profRepo->update(prof);
}

Result<bool> StaffService::deleteProfesseur(int id)
{
    return m_profRepo->remove(id);
}

Result<bool> StaffService::updateTarif(int profId, double nouveauPrix)
{
    if (nouveauPrix < 0.0) {
        return Result<bool>::error("Le nouveau prix ne peut pas etre negatif.");
    }

    // Fetch the current professor
    auto profResult = m_profRepo->getById(profId);
    if (!profResult.isOk()) {
        return Result<bool>::error(profResult.errorMessage());
    }

    const auto& optProf = profResult.value();
    if (!optProf.has_value()) {
        return Result<bool>::error("Professeur introuvable.");
    }

    // Record the tariff change in history
    TarifProfHistorique tarif;
    tarif.profId = profId;
    tarif.nouveauPrix = nouveauPrix;
    tarif.dateChangement = QDateTime::currentDateTime();

    auto histResult = m_profRepo->addTarifHistorique(tarif);
    if (!histResult.isOk()) {
        return Result<bool>::error(histResult.errorMessage());
    }

    // Update the professor's current rate
    Professeur updated = optProf.value();
    updated.prixHeureActuel = nouveauPrix;
    return m_profRepo->update(updated);
}

Result<QList<TarifProfHistorique>> StaffService::getTarifHistorique(int profId)
{
    return m_profRepo->getTarifHistorique(profId);
}

double StaffService::calculateMonthlySalary(const Professeur& prof, int totalHours)
{
    return prof.prixHeureActuel * totalHours;
}
