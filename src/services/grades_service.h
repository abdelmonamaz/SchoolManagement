#pragma once

#include <QList>
#include <QPair>

#include "common/result.h"
#include "models/seance.h"

class IParticipationRepository;
class ISeanceRepository;

class GradesService {
public:
    GradesService(IParticipationRepository* participationRepo, ISeanceRepository* seanceRepo);

    Result<QList<Participation>> getGradesBySeance(int seanceId);
    Result<QList<Participation>> getGradesByStudent(int eleveId);
    Result<bool> saveGrade(int participationId, double note);
    Result<bool> saveGrades(const QList<QPair<int, double>>& grades);
    Result<double> calculateAverage(int seanceId);
    Result<double> calculateStudentAverage(int eleveId);

private:
    IParticipationRepository* m_participationRepo;
    ISeanceRepository* m_seanceRepo;
};
