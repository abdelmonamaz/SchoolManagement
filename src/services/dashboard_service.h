#pragma once

#include <QList>

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
    Result<double> getSchoolAverage();
    Result<QList<Seance>> getLiveSessions();
    Result<QList<Participation>> getRecentGrades(int limit = 10);
    Result<QList<Seance>> getUpcomingExams(int limit = 5);

private:
    IEleveRepository* m_eleveRepo;
    ISeanceRepository* m_seanceRepo;
    IParticipationRepository* m_participationRepo;
    IMatiereRepository* m_matiereRepo;
};
