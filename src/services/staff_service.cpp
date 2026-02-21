#include "services/staff_service.h"

#include <QDateTime>

#include "repositories/ipersonnel_repository.h"

StaffService::StaffService(IPersonnelRepository* profRepo)
    : m_profRepo(profRepo)
{
}

Result<QList<Professeur>> StaffService::getAllProfesseurs()
{
    return m_profRepo->getAll();
}

Result<int> StaffService::createProfesseur(const Professeur& prof)
{
    if (prof.nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom ne peut pas etre vide.");
    }
    if (prof.valeurBase < 0.0) {
        return Result<int>::error("La valeur de base ne peut pas etre negative.");
    }

    Professeur p = prof;
    p.nom = p.nom.trimmed();
    p.prenom = p.prenom.trimmed();
    p.telephone = p.telephone.trimmed();
    p.adresse = p.adresse.trimmed();
    p.poste = p.poste.isEmpty() ? "Enseignant" : p.poste;
    p.modePaie = p.modePaie.isEmpty() ? "Heure" : p.modePaie;
    // Synchroniser prixHeureActuel avec valeurBase pour compatibilité
    p.prixHeureActuel = p.valeurBase;

    return m_profRepo->create(p);
}

Result<bool> StaffService::updateProfesseur(const Professeur& prof)
{
    if (prof.nom.trimmed().isEmpty()) {
        return Result<bool>::error("Le nom ne peut pas etre vide.");
    }
    if (prof.valeurBase < 0.0) {
        return Result<bool>::error("La valeur de base ne peut pas etre negative.");
    }

    Professeur p = prof;
    // Synchroniser prixHeureActuel avec valeurBase pour compatibilité
    p.prixHeureActuel = p.valeurBase;

    return m_profRepo->update(p);
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

Result<double> StaffService::calculateSommeDue(int personnelId, int mois, int annee)
{
    if (mois < 1 || mois > 12) {
        return Result<double>::error("Le mois doit etre compris entre 1 et 12.");
    }
    if (annee < 2000) {
        return Result<double>::error("L'annee n'est pas valide.");
    }

    auto personnelResult = m_profRepo->getById(personnelId);
    if (!personnelResult.isOk()) {
        return Result<double>::error(personnelResult.errorMessage());
    }

    const auto& personnelOpt = personnelResult.value();
    if (!personnelOpt.has_value()) {
        return Result<double>::error("Personnel introuvable.");
    }

    const Professeur& personnel = personnelOpt.value();

    if (personnel.modePaie == "Fixe") {
        // Salaire fixe mensuel
        return Result<double>::success(personnel.valeurBase);
    } else {
        // Mode horaire : utiliser heuresTravailes * valeurBase
        // Note : Dans le futur, on pourra interroger une table sessions
        // pour compter les heures réellement travaillées ce mois-là
        double total = personnel.heuresTravailes * personnel.valeurBase;
        return Result<double>::success(total);
    }
}
