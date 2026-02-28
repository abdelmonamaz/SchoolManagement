#include "services/grades_service.h"

#include <algorithm>
#include <numeric>

#include <QMap>
#include <QVariantList>
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

Result<QVariantMap> GradesService::buildBulletinData(int eleveId, int classeId)
{
    // 1. All séances for the class
    auto seancesResult = m_seanceRepo->getByClasseId(classeId);
    if (!seancesResult.isOk())
        return Result<QVariantMap>::error(seancesResult.errorMessage());

    // 2. Filter exam séances only
    QList<Seance> examSeances;
    for (const auto& s : seancesResult.value())
        if (s.typeSeance == GS::CategorieSeance::Examen)
            examSeances.append(s);

    // 3. All participations for this student → maps seanceId → note / statut
    auto partResult = m_participationRepo->getByEleveId(eleveId);
    if (!partResult.isOk())
        return Result<QVariantMap>::error(partResult.errorMessage());

    QMap<int, double> notesMap;
    QMap<int, GS::TypePresence> statutMap;
    for (const auto& p : partResult.value()) {
        if (p.note >= 0.0)
            notesMap[p.seanceId] = p.note;
        statutMap[p.seanceId] = p.statut;
    }

    // 4. Group séances by matiereId (preserving first-occurrence order)
    QList<int> matiereOrder;
    QMap<int, QList<Seance>> seancesByMatiere;
    for (const auto& s : examSeances) {
        if (!seancesByMatiere.contains(s.matiereId))
            matiereOrder.append(s.matiereId);
        seancesByMatiere[s.matiereId].append(s);
    }

    // 5. Build result structure
    QVariantList matieresList;
    double totalSum = 0.0;
    int totalCount = 0;
    int presenceTotale = 0;
    int seancesTotales = 0;

    for (int matiereId : matiereOrder) {
        const auto& seances = seancesByMatiere[matiereId];
        QVariantList epreuvesList;
        double matiereSum = 0.0;
        int notesCount = 0;
        int presenceCount = 0;

        for (const auto& s : seances) {
            QVariantMap ep;
            ep["titre"]   = s.titre.isEmpty() ? QStringLiteral("Épreuve") : s.titre;
            bool hasNote  = notesMap.contains(s.id);
            ep["note"]    = hasNote ? QVariant(notesMap[s.id]) : QVariant();
            ep["hasNote"] = hasNote;
            epreuvesList.append(ep);
            if (hasNote) { matiereSum += notesMap[s.id]; ++notesCount; }

            // Present if a participation record exists with statut != Absent
            if (statutMap.contains(s.id) && statutMap[s.id] != GS::TypePresence::Absent)
                ++presenceCount;
        }

        // Moyenne only if ALL exam séances for this matière have a note
        bool allDone = (notesCount == seances.size()) && !seances.isEmpty();
        double moyenne = allDone ? matiereSum / notesCount : -1.0;
        if (moyenne >= 0.0) { totalSum += moyenne; ++totalCount; }

        seancesTotales += seances.size();
        presenceTotale += presenceCount;

        QVariantMap mat;
        mat["matiereId"]     = matiereId;
        mat["epreuves"]      = epreuvesList;
        mat["moyenne"]       = moyenne >= 0.0 ? QVariant(moyenne) : QVariant();
        mat["presenceCount"] = presenceCount;
        mat["totalSeances"]  = (int)seances.size();
        matieresList.append(mat);
    }

    // Total average only if every matière has its average
    bool allMatieresDone = (totalCount == matiereOrder.size()) && !matiereOrder.isEmpty();

    QVariantMap result;
    result["matieres"]        = matieresList;
    result["moyenneGenerale"] = allMatieresDone ? QVariant(totalSum / totalCount) : QVariant();
    result["presenceTotale"]  = presenceTotale;
    result["seancesTotales"]  = seancesTotales;
    return Result<QVariantMap>::success(result);
}
