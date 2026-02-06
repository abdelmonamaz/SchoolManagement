#include "services/grades_service.h"

#include <algorithm>
#include <numeric>

#include "repositories/iseance_repository.h"

GradesService::GradesService(IParticipationRepository* participationRepo,
                             ISeanceRepository* seanceRepo)
    : m_participationRepo(participationRepo)
    , m_seanceRepo(seanceRepo)
{
}

Result<QList<Participation>> GradesService::getGradesBySeance(int seanceId)
{
    return m_participationRepo->getBySeanceId(seanceId);
}

Result<QList<Participation>> GradesService::getGradesByStudent(int eleveId)
{
    return m_participationRepo->getByEleveId(eleveId);
}

Result<bool> GradesService::saveGrade(int participationId, double note)
{
    if (note < 0.0) {
        return Result<bool>::error("La note ne peut pas etre negative.");
    }

    auto result = m_participationRepo->getById(participationId);
    if (!result.isOk()) {
        return Result<bool>::error(result.errorMessage());
    }

    const auto& optParticipation = result.value();
    if (!optParticipation.has_value()) {
        return Result<bool>::error("Participation introuvable.");
    }

    Participation updated = optParticipation.value();
    updated.note = note;
    return m_participationRepo->update(updated);
}

Result<bool> GradesService::saveGrades(const QList<QPair<int, double>>& grades)
{
    for (const auto& [participationId, note] : grades) {
        auto result = saveGrade(participationId, note);
        if (!result.isOk()) {
            return result;
        }
    }

    return Result<bool>::success(true);
}

Result<double> GradesService::calculateAverage(int seanceId)
{
    auto result = m_participationRepo->getBySeanceId(seanceId);
    if (!result.isOk()) {
        return Result<double>::error(result.errorMessage());
    }

    const auto& participations = result.value();

    // Filter participations that have a valid grade (note >= 0)
    QList<double> notes;
    for (const auto& p : participations) {
        if (p.note >= 0.0) {
            notes.append(p.note);
        }
    }

    if (notes.isEmpty()) {
        return Result<double>::success(0.0);
    }

    double sum = std::accumulate(notes.begin(), notes.end(), 0.0);
    return Result<double>::success(sum / notes.size());
}

Result<double> GradesService::calculateStudentAverage(int eleveId)
{
    auto result = m_participationRepo->getByEleveId(eleveId);
    if (!result.isOk()) {
        return Result<double>::error(result.errorMessage());
    }

    const auto& participations = result.value();

    QList<double> notes;
    for (const auto& p : participations) {
        if (p.note >= 0.0) {
            notes.append(p.note);
        }
    }

    if (notes.isEmpty()) {
        return Result<double>::success(0.0);
    }

    double sum = std::accumulate(notes.begin(), notes.end(), 0.0);
    return Result<double>::success(sum / notes.size());
}
