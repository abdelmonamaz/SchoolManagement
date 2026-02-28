#include "services/staff_service.h"

#include <QDate>

#include "repositories/ipersonnel_repository.h"
#include "repositories/icontrat_repository.h"
#include "repositories/iseance_repository.h"

StaffService::StaffService(IPersonnelRepository* profRepo, IContratRepository* contratRepo,
                           ISeanceRepository* seanceRepo)
    : m_profRepo(profRepo), m_contratRepo(contratRepo), m_seanceRepo(seanceRepo)
{
}

Result<QList<Personnel>> StaffService::getAllPersonnel()
{
    return m_profRepo->getAll();
}

Result<int> StaffService::createPersonnel(const Personnel& prof)
{
    if (prof.nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom ne peut pas etre vide.");
    }

    Personnel p = prof;
    p.nom = p.nom.trimmed();
    p.prenom = p.prenom.trimmed();
    p.telephone = p.telephone.trimmed();
    p.adresse = p.adresse.trimmed();

    return m_profRepo->create(p);
}

Result<bool> StaffService::updatePersonnel(const Personnel& prof)
{
    if (prof.nom.trimmed().isEmpty()) {
        return Result<bool>::error("Le nom ne peut pas etre vide.");
    }

    return m_profRepo->update(prof);
}

Result<bool> StaffService::deletePersonnel(int id)
{
    return m_profRepo->remove(id);
}

Result<QList<QPair<Personnel, Contrat>>> StaffService::getPersonnelWithActiveContrat(const QDate& date)
{
    auto contratsResult = m_contratRepo->getActiveContrats(date);
    if (!contratsResult.isOk())
        return Result<QList<QPair<Personnel, Contrat>>>::error(contratsResult.errorMessage());

    QList<QPair<Personnel, Contrat>> result;
    for (const auto& contrat : contratsResult.value()) {
        auto personnelResult = m_profRepo->getById(contrat.personnelId);
        if (!personnelResult.isOk())
            continue;
        auto opt = personnelResult.value();
        if (!opt.has_value())
            continue;
        result.append({opt.value(), contrat});
    }
    return Result<QList<QPair<Personnel, Contrat>>>::success(result);
}

Result<QList<QPair<Personnel, Contrat>>> StaffService::getPersonnelForMonth(int mois, int annee)
{
    QDate firstDay(annee, mois, 1);
    QDate lastDay = firstDay.addMonths(1).addDays(-1);

    auto contratsResult = m_contratRepo->getContratsForPeriod(firstDay, lastDay);
    if (!contratsResult.isOk())
        return Result<QList<QPair<Personnel, Contrat>>>::error(contratsResult.errorMessage());

    QList<QPair<Personnel, Contrat>> result;
    for (const auto& contrat : contratsResult.value()) {
        auto personnelResult = m_profRepo->getById(contrat.personnelId);
        if (!personnelResult.isOk())
            continue;
        auto opt = personnelResult.value();
        if (!opt.has_value())
            continue;
        result.append({opt.value(), contrat});
    }
    return Result<QList<QPair<Personnel, Contrat>>>::success(result);
}

Result<int> StaffService::createContrat(const Contrat& contrat)
{
    if (contrat.personnelId <= 0)
        return Result<int>::error("ID du personnel invalide.");
    if (!contrat.dateDebut.isValid())
        return Result<int>::error("La date de début est requise.");
    if (contrat.dateFin.isValid() && contrat.dateDebut > contrat.dateFin)
        return Result<int>::error("La date de début doit être antérieure ou égale à la date de fin.");
    if (contrat.valeurBase < 0.0)
        return Result<int>::error("La valeur de base ne peut pas être négative.");

    // Check for overlap with existing contracts
    auto overlapResult = m_contratRepo->hasOverlap(contrat.personnelId, contrat.dateDebut, contrat.dateFin);
    if (overlapResult.isOk() && overlapResult.value()) {
        return Result<int>::error("Chevauchement de dates détecté avec un contrat existant. "
                                  "Veuillez modifier les dates ou clôturer l'ancien contrat d'abord.");
    }

    return m_contratRepo->create(contrat);
}

Result<bool> StaffService::updateContrat(const Contrat& contrat)
{
    if (!contrat.dateDebut.isValid())
        return Result<bool>::error("La date de début est requise.");
    if (contrat.dateFin.isValid() && contrat.dateDebut > contrat.dateFin)
        return Result<bool>::error("La date de début doit être antérieure ou égale à la date de fin.");
    if (contrat.valeurBase < 0.0)
        return Result<bool>::error("La valeur de base ne peut pas être négative.");

    // Check for overlap, excluding the current contract itself
    auto overlapResult = m_contratRepo->hasOverlap(contrat.personnelId, contrat.dateDebut, contrat.dateFin, contrat.id);
    if (overlapResult.isOk() && overlapResult.value()) {
        return Result<bool>::error("Chevauchement de dates détecté avec un contrat existant. "
                                   "Veuillez modifier les dates.");
    }

    return m_contratRepo->update(contrat);
}

Result<bool> StaffService::deleteContrat(int contratId)
{
    return m_contratRepo->remove(contratId);
}

Result<QList<Contrat>> StaffService::getContratHistorique(int personnelId)
{
    return m_contratRepo->getByPersonnelId(personnelId);
}

Result<int> StaffService::countContrats(int personnelId)
{
    return m_contratRepo->countByPersonnelId(personnelId);
}

Result<bool> StaffService::hasActiveContrat(int personnelId, const QDate& date)
{
    auto result = m_contratRepo->getActiveContrat(personnelId, date);
    if (!result.isOk())
        return Result<bool>::error(result.errorMessage());
    return Result<bool>::success(result.value().has_value());
}

Result<int> StaffService::getTotalMinutesForMonth(int profId, int mois, int annee)
{
    QDate from(annee, mois, 1);
    QDate to = from.addMonths(1).addDays(-1);
    return m_seanceRepo->getTotalMinutesByProf(profId, from, to);
}

Result<int> StaffService::getTotalJoursForMonth(int personnelId, int mois, int annee)
{
    QDate refDate = QDate(annee, mois, 1).addMonths(1).addDays(-1);
    auto contratResult = m_contratRepo->getActiveContrat(personnelId, refDate);
    if (!contratResult.isOk() || !contratResult.value().has_value())
        return Result<int>::success(0);

    const Contrat& contrat = contratResult.value().value();
    int mask = contrat.joursTravail > 0 ? contrat.joursTravail : 31;

    // Plage effective : max(dateDebut, 1er du mois) → min(dateFin, dernier du mois)
    QDate from = QDate(annee, mois, 1);
    QDate to   = from.addMonths(1).addDays(-1);
    if (contrat.dateDebut > from) from = contrat.dateDebut;
    if (contrat.dateFin.isValid() && contrat.dateFin < to) to = contrat.dateFin;

    int count = 0;
    for (QDate d = from; d <= to; d = d.addDays(1)) {
        int bit = 1 << (d.dayOfWeek() - 1); // dayOfWeek(): 1=Lun..7=Dim → bit 0..6
        if (mask & bit) ++count;
    }
    return Result<int>::success(count);
}

Result<double> StaffService::calculateSommeDue(int personnelId, int mois, int annee)
{
    if (mois < 1 || mois > 12)
        return Result<double>::error("Le mois doit etre compris entre 1 et 12.");
    if (annee < 2000)
        return Result<double>::error("L'annee n'est pas valide.");

    // Use last day of month so contracts starting mid-month are found
    QDate refDate = QDate(annee, mois, 1).addMonths(1).addDays(-1);
    auto contratResult = m_contratRepo->getActiveContrat(personnelId, refDate);
    if (!contratResult.isOk())
        return Result<double>::error(contratResult.errorMessage());

    if (!contratResult.value().has_value())
        return Result<double>::error("Aucun contrat actif pour cette periode.");

    const Contrat& contrat = contratResult.value().value();

    if (contrat.modePaie == "Fixe") {
        return Result<double>::success(contrat.valeurBase);
    }

    if (contrat.modePaie == "Jour") {
        auto joursResult = getTotalJoursForMonth(personnelId, mois, annee);
        if (!joursResult.isOk())
            return Result<double>::error(joursResult.errorMessage());
        return Result<double>::success(joursResult.value() * contrat.valeurBase);
    }

    // Hourly mode: calculate from sessions
    auto minutesResult = getTotalMinutesForMonth(personnelId, mois, annee);
    if (!minutesResult.isOk())
        return Result<double>::error(minutesResult.errorMessage());

    double hours = minutesResult.value() / 60.0;
    double total = hours * contrat.valeurBase;
    return Result<double>::success(total);
}
