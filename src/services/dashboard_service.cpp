#include "services/dashboard_service.h"

#include <algorithm>
#include <numeric>

#include <QDate>
#include <QDateTime>
#include <QPair>
#include <QVariantMap>

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

Result<double> DashboardService::getSchoolAverageForYear(int anneeId)
{
    auto seancesResult = m_seanceRepo->getAll();
    if (!seancesResult.isOk()) {
        return Result<double>::error(seancesResult.errorMessage());
    }

    QList<double> allNotes;

    for (const auto& seance : seancesResult.value()) {
        if (anneeId > 0 && seance.anneeScolaireId != anneeId) continue;

        auto partResult = m_participationRepo->getBySeanceId(seance.id);
        if (!partResult.isOk()) continue;

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

Result<QList<Participation>> DashboardService::getRecentGradesForYear(int anneeId, int limit)
{
    auto seancesResult = m_seanceRepo->getAll();
    if (!seancesResult.isOk()) {
        return Result<QList<Participation>>::error(seancesResult.errorMessage());
    }

    QList<Participation> graded;

    for (const auto& seance : seancesResult.value()) {
        if (anneeId > 0 && seance.anneeScolaireId != anneeId) continue;

        auto partResult = m_participationRepo->getBySeanceId(seance.id);
        if (!partResult.isOk()) continue;

        for (const auto& p : partResult.value()) {
            if (p.note >= 0.0) {
                graded.append(p);
            }
        }
    }

    std::sort(graded.begin(), graded.end(),
              [](const Participation& a, const Participation& b) {
                  return a.id > b.id;
              });

    if (graded.size() > limit) {
        graded = graded.mid(0, limit);
    }

    return Result<QList<Participation>>::success(std::move(graded));
}

Result<QList<Seance>> DashboardService::getUpcomingExamsForYear(int anneeId, int limit)
{
    QDateTime now = QDateTime::currentDateTime();

    auto result = m_seanceRepo->getAll();
    if (!result.isOk()) {
        return result;
    }

    QList<Seance> exams;

    std::copy_if(result.value().begin(), result.value().end(), std::back_inserter(exams),
                 [&now, anneeId](const Seance& s) {
                     if (anneeId > 0 && s.anneeScolaireId != anneeId) return false;
                     return s.typeSeance == GS::CategorieSeance::Examen
                         && s.dateHeureDebut > now;
                 });

    std::sort(exams.begin(), exams.end(),
              [](const Seance& a, const Seance& b) {
                  return a.dateHeureDebut < b.dateHeureDebut;
              });

    if (exams.size() > limit) {
        exams = exams.mid(0, limit);
    }

    return Result<QList<Seance>>::success(std::move(exams));
}

Result<QVariantList> DashboardService::getAbsencesByMonth(int anneeId)
{
    auto seancesResult = m_seanceRepo->getAll();
    if (!seancesResult.isOk())
        return Result<QVariantList>::error(seancesResult.errorMessage());

    // Count absences per (year, month)
    QMap<QPair<int,int>, int> absencesMap;

    for (const auto& seance : seancesResult.value()) {
        if (anneeId > 0 && seance.anneeScolaireId != anneeId) continue;

        auto partResult = m_participationRepo->getBySeanceId(seance.id);
        if (!partResult.isOk()) continue;

        int month = seance.dateHeureDebut.date().month();
        int year  = seance.dateHeureDebut.date().year();

        for (const auto& p : partResult.value()) {
            if (p.statut == GS::TypePresence::Absent)
                absencesMap[{year, month}]++;
        }
    }

    static const QStringList monthLabels = {
        QString(), "Jan", "Fév", "Mar", "Avr", "Mai", "Jun",
        "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"
    };

    QDate today = QDate::currentDate();
    QVariantList result;

    for (int i = 5; i >= 0; i--) {
        QDate d = today.addMonths(-i);
        int m = d.month();
        int y = d.year();
        result.append(QVariantMap{
            {"label", monthLabels[m]},
            {"value", absencesMap.value({y, m}, 0)}
        });
    }

    return Result<QVariantList>::success(result);
}

Result<QVariantList> DashboardService::getLevelPerformanceData(
    int activeYearId,
    int closedYearId,
    const QMap<int,int>& classeToNiveauId,
    const QMap<int,QString>& niveauNoms,
    const QMap<int,int>& niveauYears)
{
    auto seancesResult = m_seanceRepo->getAll();
    if (!seancesResult.isOk())
        return Result<QVariantList>::error(seancesResult.errorMessage());

    struct NiveauStats {
        double sumActive = 0; int countActive = 0;
        double sumClosed = 0; int countClosed = 0;
    };
    QMap<QString, NiveauStats> statsByNom;

    for (const auto& seance : seancesResult.value()) {
        bool isActive = (activeYearId > 0 && seance.anneeScolaireId == activeYearId);
        bool isClosed = (closedYearId > 0 && seance.anneeScolaireId == closedYearId);
        if (!isActive && !isClosed) continue;

        int niveauId = classeToNiveauId.value(seance.classeId, 0);
        if (niveauId == 0) continue;

        QString nom = niveauNoms.value(niveauId);
        if (nom.isEmpty()) continue;

        auto partResult = m_participationRepo->getBySeanceId(seance.id);
        if (!partResult.isOk()) continue;

        for (const auto& p : partResult.value()) {
            if (p.note < 0.0) continue;
            auto& st = statsByNom[nom];
            if (isActive) { st.sumActive += p.note; st.countActive++; }
            else           { st.sumClosed += p.note; st.countClosed++; }
        }
    }

    // Collect active-year niveau names (ordered)
    QStringList activeNoms;
    for (auto it = niveauYears.cbegin(); it != niveauYears.cend(); ++it) {
        if (it.value() == activeYearId) {
            QString nom = niveauNoms.value(it.key());
            if (!nom.isEmpty() && !activeNoms.contains(nom))
                activeNoms.append(nom);
        }
    }
    activeNoms.sort();

    QVariantList result;
    for (const QString& nom : activeNoms) {
        const auto& st = statsByNom.value(nom);
        double activeAvg = st.countActive > 0 ? st.sumActive / st.countActive : 0.0;
        double closedAvg = st.countClosed > 0 ? st.sumClosed / st.countClosed : 0.0;
        result.append(QVariantMap{
            {"label", nom},
            {"values", QVariantList{closedAvg, activeAvg}}
        });
    }

    return Result<QVariantList>::success(result);
}

int DashboardService::getActiveSchoolYearId()
{
    return m_seanceRepo->getActiveSchoolYearId();
}

int DashboardService::getPreviousClosedSchoolYearId()
{
    return m_seanceRepo->getPreviousClosedSchoolYearId();
}
