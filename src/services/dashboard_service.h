#pragma once

#include <QList>
#include <QMap>
#include <QString>
#include <QVariantList>

#include "common/result.h"
#include "models/seance.h"

class IEleveRepository;
class ISeanceRepository;
class IParticipationRepository;
class IMatiereRepository;

class DashboardService {
public:
    DashboardService(IEleveRepository* eleveRepo, ISeanceRepository* seanceRepo,
                     IParticipationRepository* participationRepo, IMatiereRepository* matiereRepo);

    Result<int> getTotalStudents();
    Result<int> getActiveCoursesCount();
    Result<double> getAverageAttendanceRate();

    // School average scoped to a specific year (pass 0 to use all years)
    Result<double> getSchoolAverageForYear(int anneeId);

    Result<QList<Seance>> getLiveSessions();

    // Recent grades scoped to a specific year
    Result<QList<Participation>> getRecentGradesForYear(int anneeId, int limit = 10);

    // Upcoming exams scoped to a specific year
    Result<QList<Seance>> getUpcomingExamsForYear(int anneeId, int limit = 5);

    // Absences grouped by month for last 6 months (within anneeId year)
    Result<QVariantList> getAbsencesByMonth(int anneeId);

    // Level performance: [{label, values:[closedAvg, activeAvg]}]
    // classeToNiveauId: classeId → niveauId
    // niveauNoms: niveauId → nom
    // niveauYears: niveauId → anneeScolaireId
    Result<QVariantList> getLevelPerformanceData(
        int activeYearId,
        int closedYearId,
        const QMap<int,int>& classeToNiveauId,
        const QMap<int,QString>& niveauNoms,
        const QMap<int,int>& niveauYears);

    // Active and previous closed year IDs
    int getActiveSchoolYearId();
    int getPreviousClosedSchoolYearId();

private:
    IEleveRepository* m_eleveRepo;
    ISeanceRepository* m_seanceRepo;
    IParticipationRepository* m_participationRepo;
    IMatiereRepository* m_matiereRepo;
};
