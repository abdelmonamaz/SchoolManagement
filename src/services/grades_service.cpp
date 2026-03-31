#include "services/grades_service.h"

#include <algorithm>
#include <numeric>

#include <QMap>
#include <QVariantList>
#include "repositories/iseance_repository.h"
#include "repositories/iniveau_repository.h"

GradesService::GradesService(IParticipationRepository* participationRepo,
                             ISeanceRepository* seanceRepo,
                             IMatiereRepository* matiereRepo)
    : m_participationRepo(participationRepo)
    , m_seanceRepo(seanceRepo)
    , m_matiereRepo(matiereRepo)
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

Result<QVariantMap> GradesService::buildBulletinData(int eleveId, int classeId, int anneeId)
{
    // 1. All séances for the class in the specified year (bypasses active-year filter)
    auto seancesResult = m_seanceRepo->getByClasseIdAndYear(classeId, anneeId);
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

    // 4. Load matière metadata (coefficient + semestreNumero) for weighting
    QMap<int, double> coefMap;      // matiereId → coefficient
    QMap<int, int>    semestreMap;  // matiereId → semestreNumero (0=all-year, 1=S1, 2=S2)
    if (m_matiereRepo) {
        auto matResult = m_matiereRepo->getAll();
        if (matResult.isOk()) {
            for (const auto& m : matResult.value()) {
                coefMap[m.id]     = m.coefficient > 0 ? m.coefficient : 1.0;
                semestreMap[m.id] = m.semestreNumero;
            }
        }
    }

    // 5. Group séances by matiereId (preserving first-occurrence order)
    QList<int> matiereOrder;
    QMap<int, QList<Seance>> seancesByMatiere;
    for (const auto& s : examSeances) {
        if (!seancesByMatiere.contains(s.matiereId))
            matiereOrder.append(s.matiereId);
        seancesByMatiere[s.matiereId].append(s);
    }

    // 6. Build per-matière result + accumulate weighted sums per semester bucket
    QVariantList matieresList;
    int presenceTotale = 0;
    int seancesTotales = 0;

    // Semester accumulators: index 0=all-year, 1=S1, 2=S2
    double weightedSum[3]  = {0.0, 0.0, 0.0};
    double weightedCoef[3] = {0.0, 0.0, 0.0};
    int    doneCount[3]    = {0, 0, 0};
    int    totalInSem[3]   = {0, 0, 0};

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

            if (statutMap.contains(s.id) && statutMap[s.id] != GS::TypePresence::Absent)
                ++presenceCount;
        }

        // Moyenne only if ALL exam séances for this matière have a note
        bool allDone = (notesCount == seances.size()) && !seances.isEmpty();
        double moyenne = allDone ? matiereSum / notesCount : -1.0;

        double coef     = coefMap.value(matiereId, 1.0);
        int    semestre = semestreMap.value(matiereId, 0);
        int    bucket   = (semestre >= 0 && semestre <= 2) ? semestre : 0;

        totalInSem[bucket]++;
        if (moyenne >= 0.0) {
            weightedSum[bucket]  += moyenne * coef;
            weightedCoef[bucket] += coef;
            doneCount[bucket]++;
        }

        seancesTotales += seances.size();
        presenceTotale += presenceCount;

        QVariantMap mat;
        mat["matiereId"]     = matiereId;
        mat["epreuves"]      = epreuvesList;
        mat["moyenne"]       = moyenne >= 0.0 ? QVariant(moyenne) : QVariant();
        mat["coefficient"]   = coef;
        mat["semestreNumero"]= semestre;
        mat["presenceCount"] = presenceCount;
        mat["totalSeances"]  = (int)seances.size();
        matieresList.append(mat);
    }

    // 7. Compute weighted averages
    // moyenneGenerale: weighted avg of ALL matières (all buckets combined)
    double allSum = weightedSum[0] + weightedSum[1] + weightedSum[2];
    double allCoef= weightedCoef[0]+ weightedCoef[1]+ weightedCoef[2];
    int    allDone= doneCount[0]   + doneCount[1]   + doneCount[2];
    int    allTot = totalInSem[0]  + totalInSem[1]  + totalInSem[2];
    bool allComplete = (allDone == allTot) && allTot > 0;

    // moyenneSemestre1: weighted avg of S1 matières (bucket 1)
    // + "toute l'année" (bucket 0) matières contribute to both semesters
    // S1 = weighted(bucket1) if complete, S2 = weighted(bucket2) if complete
    bool s1HasMatieres = (totalInSem[1] > 0);
    bool s2HasMatieres = (totalInSem[2] > 0);
    bool s1Complete    = s1HasMatieres && (doneCount[1] == totalInSem[1]);
    bool s2Complete    = s2HasMatieres && (doneCount[2] == totalInSem[2]);

    // Include all-year (bucket 0) into both semester averages
    double s1Sum  = weightedSum[1]  + weightedSum[0];
    double s1Coef = weightedCoef[1] + weightedCoef[0];
    double s2Sum  = weightedSum[2]  + weightedSum[0];
    double s2Coef = weightedCoef[2] + weightedCoef[0];
    bool s1FullComplete = s1Complete && (doneCount[0] == totalInSem[0]);
    bool s2FullComplete = s2Complete && (doneCount[0] == totalInSem[0]);

    double moyS1 = (s1FullComplete && s1Coef > 0) ? s1Sum / s1Coef : -1.0;
    double moyS2 = (s2FullComplete && s2Coef > 0) ? s2Sum / s2Coef : -1.0;
    double moyGen = (allComplete && allCoef > 0) ? allSum / allCoef : -1.0;
    double moyAnn = (moyS1 >= 0 && moyS2 >= 0) ? (moyS1 + moyS2) / 2.0 : -1.0;

    QVariantMap result;
    result["matieres"]         = matieresList;
    result["moyenneGenerale"]  = moyGen >= 0 ? QVariant(moyGen)  : QVariant();
    result["moyenneSemestre1"] = moyS1  >= 0 ? QVariant(moyS1)   : QVariant();
    result["moyenneSemestre2"] = moyS2  >= 0 ? QVariant(moyS2)   : QVariant();
    result["moyenneAnnuelle"]  = moyAnn >= 0 ? QVariant(moyAnn)  : QVariant();
    result["hasSemestres"]     = s1HasMatieres || s2HasMatieres;
    result["presenceTotale"]   = presenceTotale;
    result["seancesTotales"]   = seancesTotales;
    return Result<QVariantMap>::success(result);
}
