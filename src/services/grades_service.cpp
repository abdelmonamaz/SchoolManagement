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

// ── buildBulletinDocxData ─────────────────────────────────────────────────────
// Returns data optimized for DocxGenerator: subjects grouped by name (S1+S2 paired),
// weighted semester averages, rank in class, and appreciation.
// semestre=1 → S1 bulletin (S1/all-year subjects); semestre=2 → S2+annual bulletin.
//
// Average formula:
//   - subject avg = simple mean of its exam notes (all must be entered)
//   - semester avg = Σ(subjectAvg × coef) / Σ(coef)  [weighted]
//   - annual avg = (S1 avg + S2 avg) / 2
//
// Rank optimisation: instead of N queries (one per student), we call getBySeanceId
// once per exam séance (M séances << N students), building all students' notes in one pass.
Result<QVariantMap> GradesService::buildBulletinDocxData(
    int eleveId, int classeId, int anneeId, int semestre)
{
    // 1. All exam séances for class + year
    auto seancesResult = m_seanceRepo->getByClasseIdAndYear(classeId, anneeId);
    if (!seancesResult.isOk())
        return Result<QVariantMap>::error(seancesResult.errorMessage());

    QList<Seance> examSeances;
    for (const auto& s : seancesResult.value())
        if (s.typeSeance == GS::CategorieSeance::Examen)
            examSeances.append(s);

    // 2. Matière metadata — only for matieres referenced by those séances
    QMap<int, QString> matNomMap;
    QMap<int, double>  coefMap;
    QMap<int, int>     semMap;  // matiereId → semestreNumero (0=all-year, 1=S1, 2=S2)
    {
        QSet<int> neededIds;
        for (const auto& s : examSeances) neededIds.insert(s.matiereId);

        if (m_matiereRepo) {
            auto r = m_matiereRepo->getAll();
            if (r.isOk()) {
                for (const auto& m : r.value()) {
                    if (!neededIds.contains(m.id)) continue;
                    matNomMap[m.id] = m.nom;
                    coefMap[m.id]   = m.coefficient > 0 ? m.coefficient : 1.0;
                    semMap[m.id]    = m.semestreNumero;
                }
            }
        }
    }

    // 3. Group exam séances by matiereId (preserving first-seen order)
    QList<int> matiereOrder;
    QMap<int, QList<Seance>> seancesByMatiere;
    for (const auto& s : examSeances) {
        if (!seancesByMatiere.contains(s.matiereId))
            matiereOrder.append(s.matiereId);
        seancesByMatiere[s.matiereId].append(s);
    }

    // 4. Load all students' notes in one pass via getBySeanceId (M queries instead of N).
    //    allStudentNotes[eleveId][seanceId] = note
    QMap<int, QMap<int, double>> allStudentNotes;
    for (const auto& s : examSeances) {
        auto pr = m_participationRepo->getBySeanceId(s.id);
        if (!pr.isOk()) continue;
        for (const auto& p : pr.value())
            if (p.note >= 0.0)
                allStudentNotes[p.eleveId][p.seanceId] = p.note;
    }
    const QMap<int, double>& notesMap = allStudentNotes[eleveId];

    // 5. Collect matiereIds per semester bucket
    QList<int> s1Ids, s2Ids, allIds;
    for (int mId : matiereOrder) {
        int s = semMap.value(mId, 0);
        if (s == 1) s1Ids << mId;
        else if (s == 2) s2Ids << mId;
        else allIds << mId;
    }
    QList<int> s1AllIds = s1Ids + allIds;
    QList<int> s2AllIds = s2Ids + allIds;

    // 6. Weighted semester average for a list of matiereIds
    //    Returns -1 if any subject has incomplete (missing) notes.
    auto semAvg = [&](const QList<int>& ids, const QMap<int, double>& notes) -> double {
        if (ids.isEmpty()) return -1.0;
        double wSum = 0, wCoef = 0;
        for (int mId : ids) {
            const auto& ss = seancesByMatiere.value(mId);
            if (ss.isEmpty()) continue;
            double sum = 0; int cnt = 0; bool allDone = true;
            for (const auto& s : ss) {
                if (notes.contains(s.id)) { sum += notes[s.id]; cnt++; }
                else allDone = false;
            }
            if (!allDone || cnt == 0) return -1.0;
            wSum  += (sum / cnt) * coefMap.value(mId, 1.0);
            wCoef += coefMap.value(mId, 1.0);
        }
        return (wCoef > 0) ? wSum / wCoef : -1.0;
    };

    double moyS1  = semAvg(s1AllIds, notesMap);
    double moyS2  = (semestre == 2) ? semAvg(s2AllIds, notesMap) : -1.0;
    double moyTot = (moyS1 >= 0 && moyS2 >= 0) ? (moyS1 + moyS2) / 2.0 : -1.0;

    // 7. Group matiereIds by nom to pair S1 and S2 entries for the template
    struct NomGroup { int s1 = -1, s2 = -1, all = -1; };
    QMap<QString, NomGroup> groups;
    QStringList nomOrder;
    for (int mId : matiereOrder) {
        QString nom = matNomMap.value(mId, QStringLiteral("Matière #%1").arg(mId));
        int s = semMap.value(mId, 0);
        if (!groups.contains(nom)) nomOrder << nom;
        auto& g = groups[nom];
        if      (s == 1 && g.s1  < 0) g.s1  = mId;
        else if (s == 2 && g.s2  < 0) g.s2  = mId;
        else if (s == 0 && g.all < 0) g.all = mId;
    }

    // Per-matière helper: exam titles, individual notes, subject average
    auto examData = [&](int mId, const QMap<int, double>& notes) -> QVariantMap {
        QVariantMap m;
        if (mId < 0) return m;
        const auto& ss = seancesByMatiere.value(mId);
        if (ss.isEmpty()) return m;
        QStringList titles; QList<double> nlist; bool allDone = true;
        for (const auto& s : ss) {
            titles << (s.titre.isEmpty() ? QStringLiteral("Épreuve") : s.titre);
            if (notes.contains(s.id)) nlist << notes[s.id];
            else { nlist << -1.0; allDone = false; }
        }
        double avg = (allDone && !nlist.isEmpty())
            ? std::accumulate(nlist.begin(), nlist.end(), 0.0) / nlist.size() : -1.0;
        m["isDual"] = (ss.size() >= 2);
        m["titles"] = titles;
        QVariantList vl;
        for (double n : nlist) vl << QVariant(n);
        m["notes"] = vl;
        m["avg"]   = avg;
        return m;
    };

    auto fmt = [](double n) -> QString {
        return n >= 0 ? QString::number(n, 'f', 2) : QStringLiteral("—");
    };

    // 8. Build DOCX matières list
    QVariantList docxMats;
    for (const QString& nom : nomOrder) {
        const auto& g = groups[nom];

        // S1 bulletin: skip subjects with no S1 or all-year data
        if (semestre == 1 && g.s1 < 0 && g.all < 0) continue;

        int s1SrcId   = (g.s1  >= 0) ? g.s1  : g.all;
        int s2SrcId   = (g.s2  >= 0) ? g.s2  : -1;
        int primaryId = (semestre == 1) ? s1SrcId : (s2SrcId >= 0 ? s2SrcId : s1SrcId);
        if (primaryId < 0) continue;

        auto s1d = examData(s1SrcId, notesMap);
        auto s2d = examData(s2SrcId, notesMap);
        bool isDual = !s1d.isEmpty() ? s1d["isDual"].toBool()
                                     : (!s2d.isEmpty() ? s2d["isDual"].toBool() : false);

        QVariantMap dm;
        dm["nom"]         = nom;
        dm["coefficient"] = coefMap.value(primaryId, 1.0);
        dm["isDual"]      = isDual;

        if (!s1d.isEmpty()) {
            QStringList titles = s1d["titles"].toStringList();
            QList<double> nlist;
            for (const auto& v : s1d["notes"].toList()) nlist << v.toDouble();
            if (isDual) {
                dm["exam1"]   = titles.value(0);
                dm["exam2"]   = titles.value(1);
                dm["note1"]   = fmt(nlist.value(0, -1.0));
                dm["note2"]   = fmt(nlist.value(1, -1.0));
                dm["noteMoy"] = fmt(s1d["avg"].toDouble());
            } else {
                dm["note"] = fmt(nlist.value(0, -1.0));
            }
        }

        if (semestre == 2 && !s2d.isEmpty()) {
            QList<double> nlist2;
            for (const auto& v : s2d["notes"].toList()) nlist2 << v.toDouble();
            if (isDual) {
                dm["note1S2"]   = fmt(nlist2.value(0, -1.0));
                dm["note2S2"]   = fmt(nlist2.value(1, -1.0));
                dm["noteMoyS2"] = fmt(s2d["avg"].toDouble());
            } else {
                dm["noteS2"] = fmt(nlist2.value(0, -1.0));
            }
        }

        docxMats.append(dm);
    }

    // 9. Rank: use the already-loaded allStudentNotes — no extra DB queries needed.
    //    Compare target student against every other student present in the séances.
    int rang = 0;
    double rankAvg = (semestre == 2 && moyTot >= 0) ? moyTot : moyS1;

    if (rankAvg >= 0) {
        int betterCount = 0;
        for (auto it = allStudentNotes.constBegin(); it != allStudentNotes.constEnd(); ++it) {
            if (it.key() == eleveId) continue;
            const QMap<int, double>& stNotes = it.value();
            double stS1  = semAvg(s1AllIds, stNotes);
            double stAvg = stS1;
            if (semestre == 2) {
                double stS2 = semAvg(s2AllIds, stNotes);
                stAvg = (stS1 >= 0 && stS2 >= 0) ? (stS1 + stS2) / 2.0 : -1.0;
            }
            if (stAvg > rankAvg) betterCount++;
        }
        rang = betterCount + 1;
    }

    // 10. Appreciation
    double avgForNotif = (semestre == 2 && moyTot >= 0) ? moyTot : moyS1;
    QString notif;
    if      (avgForNotif >= 18) notif = QStringLiteral("Excellent");
    else if (avgForNotif >= 15) notif = QStringLiteral("Très Bien");
    else if (avgForNotif >= 12) notif = QStringLiteral("Bien");
    else if (avgForNotif >= 10) notif = QStringLiteral("Assez Bien");
    else if (avgForNotif >=  7) notif = QStringLiteral("Passable");
    else if (avgForNotif >=  0) notif = QStringLiteral("Insuffisant");

    QVariantMap out;
    out["matieres"] = docxMats;
    out["moyS1"]    = moyS1  >= 0 ? QVariant(moyS1)  : QVariant();
    out["moyS2"]    = moyS2  >= 0 ? QVariant(moyS2)  : QVariant();
    out["moyTot"]   = moyTot >= 0 ? QVariant(moyTot) : QVariant();
    out["rang"]     = rang   >  0 ? QVariant(rang)   : QVariant();
    out["notif"]    = "";
    return Result<QVariantMap>::success(out);
}
