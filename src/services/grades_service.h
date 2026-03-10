#pragma once

#include <QList>
#include <QPair>
#include <QVariantMap>

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

    // Bulletin: grouped grades per matière for a student in a class/year
    Result<QVariantMap> buildBulletinData(int eleveId, int classeId, int anneeId);

private:
    IParticipationRepository* m_participationRepo;
    ISeanceRepository* m_seanceRepo;
};
