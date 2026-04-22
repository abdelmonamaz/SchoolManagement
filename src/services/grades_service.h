#pragma once

#include <QList>
#include <QPair>
#include <QVariantMap>

#include "common/result.h"
#include "models/seance.h"

class IParticipationRepository;
class ISeanceRepository;
class IMatiereRepository;

class GradesService {
public:
    GradesService(IParticipationRepository* participationRepo, ISeanceRepository* seanceRepo,
                  IMatiereRepository* matiereRepo);

    Result<QList<Participation>> getGradesBySeance(int seanceId);
    Result<QList<Participation>> getGradesByStudent(int eleveId);
    Result<bool> saveGrade(int participationId, double note);
    Result<bool> saveGrades(const QList<QPair<int, double>>& grades);
    Result<double> calculateAverage(int seanceId);
    Result<double> calculateStudentAverage(int eleveId);

    // Bulletin: grouped grades per matière for a student in a class/year (used by preview)
    Result<QVariantMap> buildBulletinData(int eleveId, int classeId, int anneeId);

    // Bulletin data for DOCX export: groups S1+S2 by subject name, includes rank & semester avg
    // semestre = 1 → S1 bulletin (S1 subjects only), semestre = 2 → S2/annual bulletin
    Result<QVariantMap> buildBulletinDocxData(int eleveId, int classeId, int anneeId, int semestre);

private:
    IParticipationRepository* m_participationRepo;
    ISeanceRepository*        m_seanceRepo;
    IMatiereRepository*       m_matiereRepo;
};
