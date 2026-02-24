#include "services/attendance_service.h"

#include <algorithm>
#include <QDebug>

#include "repositories/iseance_repository.h"
#include "repositories/ieleve_repository.h"

AttendanceService::AttendanceService(ISeanceRepository* seanceRepo,
                                     IParticipationRepository* participationRepo,
                                     IEleveRepository* eleveRepo)
    : m_seanceRepo(seanceRepo)
    , m_participationRepo(participationRepo)
    , m_eleveRepo(eleveRepo)
{
}

Result<QList<Seance>> AttendanceService::getSeancesByDateRange(const QDateTime& from, const QDateTime& to)
{
    return m_seanceRepo->getByDateRange(from, to);
}

Result<QList<Seance>> AttendanceService::getSeancesByClasse(int classeId)
{
    return m_seanceRepo->getByClasseId(classeId);
}

Result<int> AttendanceService::createSeance(const Seance& seance)
{
    if (seance.dureeMinutes <= 0) {
        return Result<int>::error("La duree de la seance doit etre superieure a zero.");
    }
    if (!seance.dateHeureDebut.isValid()) {
        return Result<int>::error("La date de la seance n'est pas valide.");
    }

    // Check for conflicts
    qDebug() << "createSeance: checking conflicts for profId=" << seance.profId
             << "salleId=" << seance.salleId << "classeId=" << seance.classeId
             << "date=" << seance.dateHeureDebut.toString(Qt::ISODate)
             << "duree=" << seance.dureeMinutes;
    auto conflictsResult = m_seanceRepo->checkConflicts(seance);
    if (!conflictsResult.isOk()) {
        qWarning() << "createSeance: checkConflicts error:" << conflictsResult.errorMessage();
        return Result<int>::error(conflictsResult.errorMessage());
    }
    if (!conflictsResult.value().isEmpty()) {
        qWarning() << "createSeance: conflicts found:" << conflictsResult.value();
        return Result<int>::error(conflictsResult.value().join("\n"));
    }
    qDebug() << "createSeance: no conflicts, creating session";

    return m_seanceRepo->create(seance);
}

Result<bool> AttendanceService::updateSeance(const Seance& seance)
{
    if (seance.dureeMinutes <= 0) {
        return Result<bool>::error("La duree de la seance doit etre superieure a zero.");
    }
    if (!seance.dateHeureDebut.isValid()) {
        return Result<bool>::error("La date de la seance n'est pas valide.");
    }

    // Check for conflicts (excluding the session being updated)
    auto conflictsResult = m_seanceRepo->checkConflicts(seance, seance.id);
    if (!conflictsResult.isOk())
        return Result<bool>::error(conflictsResult.errorMessage());
    if (!conflictsResult.value().isEmpty())
        return Result<bool>::error(conflictsResult.value().join("\n"));

    return m_seanceRepo->update(seance);
}

Result<bool> AttendanceService::deleteSeance(int id)
{
    return m_seanceRepo->remove(id);
}

Result<QList<Participation>> AttendanceService::getParticipationsBySeance(int seanceId)
{
    return m_participationRepo->getBySeanceId(seanceId);
}

Result<int> AttendanceService::recordParticipation(const Participation& p)
{
    return m_participationRepo->create(p);
}

Result<bool> AttendanceService::updateParticipation(const Participation& p)
{
    return m_participationRepo->update(p);
}

Result<bool> AttendanceService::deleteParticipation(int id)
{
    return m_participationRepo->remove(id);
}

Result<bool> AttendanceService::setPresenceValide(int seanceId, bool valide)
{
    return m_seanceRepo->setPresenceValide(seanceId, valide);
}

Result<double> AttendanceService::getAttendanceRate(int classeId, const QDateTime& from,
                                                     const QDateTime& to)
{
    // Get seances for this class in the date range
    auto seancesResult = m_seanceRepo->getByClasseId(classeId);
    if (!seancesResult.isOk()) {
        return Result<double>::error(seancesResult.errorMessage());
    }

    const auto& allSeances = seancesResult.value();

    // Filter seances within the date range
    QList<Seance> filtered;
    std::copy_if(allSeances.begin(), allSeances.end(), std::back_inserter(filtered),
                 [&from, &to](const Seance& s) {
                     return s.dateHeureDebut >= from && s.dateHeureDebut <= to;
                 });

    if (filtered.isEmpty()) {
        return Result<double>::success(0.0);
    }

    int totalParticipations = 0;
    int presentCount = 0;

    for (const auto& seance : filtered) {
        auto partResult = m_participationRepo->getBySeanceId(seance.id);
        if (!partResult.isOk()) {
            continue;
        }

        const auto& participations = partResult.value();
        totalParticipations += participations.size();

        presentCount += std::count_if(participations.begin(), participations.end(),
                                       [](const Participation& p) {
                                           return p.statut == GS::TypePresence::Present;
                                       });
    }

    if (totalParticipations == 0) {
        return Result<double>::success(0.0);
    }

    double rate = (static_cast<double>(presentCount) / totalParticipations) * 100.0;
    return Result<double>::success(rate);
}
