#include "services/dashboard_service.h"

#include <algorithm>
#include <numeric>

#include <QDateTime>

#include "repositories/ieleve_repository.h"
#include "repositories/iseance_repository.h"
#include "repositories/iniveau_repository.h"

DashboardService::DashboardService(IEleveRepository* eleveRepo, ISeanceRepository* seanceRepo,
                                   IParticipationRepository* participationRepo,
                                   IMatiereRepository* matiereRepo)
    : m_eleveRepo(eleveRepo)
    , m_seanceRepo(seanceRepo)
    , m_participationRepo(participationRepo)
    , m_matiereRepo(matiereRepo)
{
}

Result<int> DashboardService::getTotalStudents()
{
    return m_eleveRepo->countAll();
}

Result<int> DashboardService::getActiveCoursesCount()
{
    QDateTime todayStart = QDateTime::currentDateTime();
    todayStart.setTime(QTime(0, 0, 0));

    QDateTime todayEnd = todayStart;
    todayEnd.setTime(QTime(23, 59, 59));

    auto result = m_seanceRepo->getByDateRange(todayStart, todayEnd);
    if (!result.isOk()) {
        return Result<int>::error(result.errorMessage());
    }

    return Result<int>::success(result.value().size());
}

Result<double> DashboardService::getAverageAttendanceRate()
{
    QDateTime todayStart = QDateTime::currentDateTime();
    todayStart.setTime(QTime(0, 0, 0));

    QDateTime todayEnd = todayStart;
    todayEnd.setTime(QTime(23, 59, 59));

    auto seancesResult = m_seanceRepo->getByDateRange(todayStart, todayEnd);
    if (!seancesResult.isOk()) {
        return Result<double>::error(seancesResult.errorMessage());
    }

    const auto& seances = seancesResult.value();
    if (seances.isEmpty()) {
        return Result<double>::success(0.0);
    }

    int totalParticipations = 0;
    int presentCount = 0;

    for (const auto& seance : seances) {
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

Result<double> DashboardService::getSchoolAverage()
{
    auto seancesResult = m_seanceRepo->getAll();
    if (!seancesResult.isOk()) {
        return Result<double>::error(seancesResult.errorMessage());
    }

    const auto& seances = seancesResult.value();
    QList<double> allNotes;

    for (const auto& seance : seances) {
        auto partResult = m_participationRepo->getBySeanceId(seance.id);
        if (!partResult.isOk()) {
            continue;
        }

        for (const auto& p : partResult.value()) {
            if (p.note >= 0.0) {
                allNotes.append(p.note);
            }
        }
    }

    if (allNotes.isEmpty()) {
        return Result<double>::success(0.0);
    }

    double sum = std::accumulate(allNotes.begin(), allNotes.end(), 0.0);
    return Result<double>::success(sum / allNotes.size());
}

Result<QList<Seance>> DashboardService::getLiveSessions()
{
    QDateTime now = QDateTime::currentDateTime();

    QDateTime todayStart = now;
    todayStart.setTime(QTime(0, 0, 0));

    QDateTime todayEnd = todayStart;
    todayEnd.setTime(QTime(23, 59, 59));

    auto result = m_seanceRepo->getByDateRange(todayStart, todayEnd);
    if (!result.isOk()) {
        return result;
    }

    const auto& seances = result.value();
    QList<Seance> live;

    std::copy_if(seances.begin(), seances.end(), std::back_inserter(live),
                 [&now](const Seance& s) {
                     QDateTime end = s.dateHeureDebut.addSecs(s.dureeMinutes * 60);
                     return s.dateHeureDebut <= now && end >= now;
                 });

    return Result<QList<Seance>>::success(std::move(live));
}

Result<QList<Participation>> DashboardService::getRecentGrades(int limit)
{
    auto seancesResult = m_seanceRepo->getAll();
    if (!seancesResult.isOk()) {
        return Result<QList<Participation>>::error(seancesResult.errorMessage());
    }

    QList<Participation> graded;

    for (const auto& seance : seancesResult.value()) {
        auto partResult = m_participationRepo->getBySeanceId(seance.id);
        if (!partResult.isOk()) {
            continue;
        }

        for (const auto& p : partResult.value()) {
            if (p.note >= 0.0) {
                graded.append(p);
            }
        }
    }

    // Sort by id descending (most recent first)
    std::sort(graded.begin(), graded.end(),
              [](const Participation& a, const Participation& b) {
                  return a.id > b.id;
              });

    if (graded.size() > limit) {
        graded = graded.mid(0, limit);
    }

    return Result<QList<Participation>>::success(std::move(graded));
}

Result<QList<Seance>> DashboardService::getUpcomingExams(int limit)
{
    QDateTime now = QDateTime::currentDateTime();

    // Fetch all seances and filter for future exams
    auto result = m_seanceRepo->getAll();
    if (!result.isOk()) {
        return result;
    }

    const auto& seances = result.value();
    QList<Seance> exams;

    std::copy_if(seances.begin(), seances.end(), std::back_inserter(exams),
                 [&now](const Seance& s) {
                     return s.typeSeance == GS::CategorieSeance::Examen
                         && s.dateHeureDebut > now;
                 });

    // Sort by date ascending (nearest first)
    std::sort(exams.begin(), exams.end(),
              [](const Seance& a, const Seance& b) {
                  return a.dateHeureDebut < b.dateHeureDebut;
              });

    if (exams.size() > limit) {
        exams = exams.mid(0, limit);
    }

    return Result<QList<Seance>>::success(std::move(exams));
}
