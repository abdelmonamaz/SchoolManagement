#include "controllers/year_closure_controller.h"
#include "database/database_manager.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDateTime>
#include <QDebug>
#include <QMap>
#include <QList>

static const QString kClosureConn = QStringLiteral("gs_closure_main");

YearClosureController::YearClosureController(const QString& dbPath, QObject* parent)
    : QObject(parent)
    , m_connectionName(kClosureConn)
{
    if (!QSqlDatabase::contains(kClosureConn)) {
        DatabaseManager::initialize(dbPath, kClosureConn);
    }
}

void YearClosureController::setIsLoading(bool v) {
    if (m_isLoading == v) return;
    m_isLoading = v;
    emit isLoadingChanged();
}

// ── loadStats ─────────────────────────────────────────────────────────────────

void YearClosureController::loadStats()
{
    setIsLoading(true);
    auto db = QSqlDatabase::database(m_connectionName);

    // Active year
    QSqlQuery qYear(db);
    qYear.exec(QStringLiteral(
        "SELECT id, libelle FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));

    if (!qYear.next()) {
        m_closureStats = {};
        emit closureStatsChanged();
        m_incompleteSessions = {};
        emit incompleteSessionsChanged();
        setIsLoading(false);
        return;
    }

    const int    activeId      = qYear.value(0).toInt();
    const QString activeLibelle = qYear.value(1).toString();

    // Enrollments by resultat
    QSqlQuery qResultats(db);
    qResultats.prepare(QStringLiteral(
        "SELECT resultat, COUNT(*) FROM inscriptions_eleves "
        "WHERE annee_scolaire_id = :id AND valide = 1 "
        "GROUP BY resultat"));
    qResultats.bindValue(":id", activeId);
    qResultats.exec();

    int totalInscrits = 0, nbReussi = 0, nbRedoublant = 0, nbEnCours = 0;
    while (qResultats.next()) {
        const QString res = qResultats.value(0).toString();
        const int cnt     = qResultats.value(1).toInt();
        totalInscrits += cnt;
        if (res == QLatin1String("Réussi"))    nbReussi    += cnt;
        else if (res == QLatin1String("Redoublant")) nbRedoublant += cnt;
        else nbEnCours += cnt;
    }

    // Diplômés = Réussi students at a terminal niveau (no children)
    QSqlQuery qDiplomes(db);
    qDiplomes.prepare(QStringLiteral(
        "SELECT COUNT(DISTINCT ie.eleve_id) "
        "FROM inscriptions_eleves ie "
        "WHERE ie.annee_scolaire_id = :id AND ie.valide = 1 AND ie.resultat = 'Réussi' "
        "  AND NOT EXISTS ("
        "      SELECT 1 FROM niveaux n "
        "      WHERE n.parent_level_id = ie.niveau_id AND n.valide = 1)"));
    qDiplomes.bindValue(":id", activeId);
    qDiplomes.exec();
    const int nbDiplomes = qDiplomes.next() ? qDiplomes.value(0).toInt() : 0;

    const double tauxReussite = (totalInscrits > 0)
        ? (static_cast<double>(nbReussi) / totalInscrits * 100.0)
        : 0.0;

    m_closureStats = {
        {"anneeActiveId",      activeId},
        {"anneeActiveLibelle", activeLibelle},
        {"studentsInscrits",   totalInscrits},
        {"tauxReussite",       qRound(tauxReussite * 10.0) / 10.0},
        {"diplomes",           nbDiplomes},
        {"redoublants",        nbRedoublant},
        {"enCours",            nbEnCours}
    };
    emit closureStatsChanged();

    // Incomplete sessions (past but presence not validated)
    QSqlQuery qSessions(db);
    qSessions.prepare(QStringLiteral(
        "SELECT s.id, COALESCE(NULLIF(s.titre,''), s.type_seance), s.type_seance, "
        "       DATE(s.date_heure_debut) "
        "FROM seances s "
        "WHERE s.annee_scolaire_id = :id AND s.valide = 1 "
        "  AND s.presence_valide = 0 "
        "  AND s.date_heure_debut < DATETIME('now') "
        "  AND s.type_seance IN ('Cours','Examen') "
        "ORDER BY s.date_heure_debut DESC"));
    qSessions.bindValue(":id", activeId);
    qSessions.exec();

    QVariantList sessions;
    while (qSessions.next()) {
        sessions.append(QVariantMap{
            {"id",    qSessions.value(0).toInt()},
            {"titre", qSessions.value(1).toString()},
            {"type",  qSessions.value(2).toString()},
            {"date",  qSessions.value(3).toString()}
        });
    }
    m_incompleteSessions = sessions;
    emit incompleteSessionsChanged();

    setIsLoading(false);
}

// ── loadStudentProgressions ───────────────────────────────────────────────────

void YearClosureController::loadStudentProgressions()
{
    setIsLoading(true);
    auto db = QSqlDatabase::database(m_connectionName);

    // Active year id
    QSqlQuery qYear(db);
    qYear.exec(QStringLiteral(
        "SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (!qYear.next()) {
        m_studentProgressions = {};
        emit studentProgressionsChanged();
        setIsLoading(false);
        return;
    }
    const int activeId = qYear.value(0).toInt();

    // All active enrollments with student and level info.
    // - e.valide = 1 : exclude soft-deleted students
    // - dedup subquery : keep only the latest inscription per student per year
    //   (guards against a student being enrolled twice in the same year)
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "SELECT ie.id, e.id, e.nom, e.prenom, e.categorie, "
        "       ie.niveau_id, COALESCE(n.nom,'?'), ie.resultat "
        "FROM inscriptions_eleves ie "
        "JOIN eleves e ON e.id = ie.eleve_id AND e.valide = 1 "
        "LEFT JOIN niveaux n ON n.id = ie.niveau_id "
        "WHERE ie.annee_scolaire_id = :id AND ie.valide = 1 "
        "  AND NOT EXISTS ("
        "    SELECT 1 FROM inscriptions_eleves ie2 "
        "    WHERE ie2.eleve_id = ie.eleve_id "
        "      AND ie2.annee_scolaire_id = ie.annee_scolaire_id "
        "      AND ie2.valide = 1 AND ie2.id > ie.id"
        "  ) "
        "ORDER BY n.id, e.nom, e.prenom"));
    q.bindValue(":id", activeId);
    q.exec();

    // For each inscription, fetch possible next niveaux (active year only)
    QSqlQuery qChildren(db);
    qChildren.prepare(QStringLiteral(
        "SELECT n.id, n.nom FROM niveaux n "
        "JOIN niveaux_actifs_par_annee napa ON napa.niveau_id = n.id "
        "WHERE napa.annee_scolaire_id = :activeId AND n.parent_level_id = :niveauId AND n.valide = 1 "
        "ORDER BY n.id"));

    // Average grade per student for the active year (-1.0 = no data at all)
    // Rules:
    //   - Explicit note (>= 0)              → use as-is
    //   - Absent at exam + not guest + no note → counted as 0
    //   - Present at exam but no note         → excluded (not yet graded)
    QSqlQuery qMoyenne(db);
    qMoyenne.prepare(QStringLiteral(
        "SELECT AVG(note_effective) FROM ("
        "  SELECT CASE"
        "    WHEN p.note IS NOT NULL AND p.note >= 0 THEN p.note"
        "    WHEN p.statut = 'Absent' AND p.est_invite = 0"
        "         AND (p.note IS NULL OR p.note < 0) THEN 0.0"
        "    ELSE NULL"
        "  END AS note_effective"
        "  FROM participations p"
        "  JOIN seances s ON s.id = p.seance_id"
        "  WHERE p.eleve_id = :eleveId"
        "    AND s.annee_scolaire_id = :anneeId"
        "    AND s.type_seance = 'Examen'"
        ") WHERE note_effective IS NOT NULL"));

    QVariantList progressions;
    while (q.next()) {
        const int    inscriptionId = q.value(0).toInt();
        const int    eleveId       = q.value(1).toInt();
        const QString nom          = q.value(2).toString();
        const QString prenom       = q.value(3).toString();
        const QString categorie    = q.value(4).toString();
        const int    niveauActuelId  = q.value(5).toInt();
        const QString niveauActuelNom = q.value(6).toString();
        const QString resultat     = q.value(7).toString();

        // Children niveaux (filtered to active year)
        qChildren.bindValue(":activeId",  activeId);
        qChildren.bindValue(":niveauId",  niveauActuelId);
        qChildren.exec();
        QVariantList niveauxSuivants;
        while (qChildren.next()) {
            niveauxSuivants.append(QVariantMap{
                {"id",  qChildren.value(0).toInt()},
                {"nom", qChildren.value(1).toString()}
            });
        }

        // Average grade
        qMoyenne.bindValue(":eleveId",  eleveId);
        qMoyenne.bindValue(":anneeId",  activeId);
        qMoyenne.exec();
        double moyenneAnnuelle = -1.0;
        if (qMoyenne.next() && !qMoyenne.value(0).isNull())
            moyenneAnnuelle = qMoyenne.value(0).toDouble();

        progressions.append(QVariantMap{
            {"inscriptionId",   inscriptionId},
            {"eleveId",         eleveId},
            {"nom",             nom},
            {"prenom",          prenom},
            {"categorie",       categorie},
            {"niveauActuelId",  niveauActuelId},
            {"niveauActuelNom", niveauActuelNom},
            {"resultat",        resultat},
            {"niveauxSuivants", niveauxSuivants},
            {"moyenneAnnuelle", moyenneAnnuelle}
        });
    }

    m_studentProgressions = progressions;
    emit studentProgressionsChanged();
    setIsLoading(false);
}

// ── loadArchivageStats ────────────────────────────────────────────────────────

void YearClosureController::loadArchivageStats()
{
    auto db = QSqlDatabase::database(m_connectionName);

    QSqlQuery qYear(db);
    qYear.exec(QStringLiteral(
        "SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (!qYear.next()) {
        m_archivageStats = {};
        emit archivageStatsChanged();
        return;
    }
    const int activeId = qYear.value(0).toInt();

    // ── Global: sessions planned vs done ──────────────────────────────────────
    QSqlQuery qGlobal(db);
    qGlobal.prepare(QStringLiteral(
        "SELECT "
        "  SUM(CASE WHEN type_seance IN ('Cours','Examen') THEN 1 ELSE 0 END) AS total, "
        "  SUM(CASE WHEN type_seance='Cours' THEN 1 ELSE 0 END) AS cours_total, "
        "  SUM(CASE WHEN type_seance='Cours' AND presence_valide=1 THEN 1 ELSE 0 END) AS cours_valides, "
        "  SUM(CASE WHEN type_seance='Examen' THEN 1 ELSE 0 END) AS examens_total "
        "FROM seances WHERE annee_scolaire_id=:id AND valide=1"));
    qGlobal.bindValue(":id", activeId);
    qGlobal.exec();
    int coursTotal = 0, coursValides = 0, examensTotal = 0;
    if (qGlobal.next()) {
        coursTotal   = qGlobal.value("cours_total").toInt();
        coursValides = qGlobal.value("cours_valides").toInt();
        examensTotal = qGlobal.value("examens_total").toInt();
    }

    // ── Global presence rate ───────────────────────────────────────────────────
    QSqlQuery qPresGlobal(db);
    qPresGlobal.prepare(QStringLiteral(
        "SELECT COUNT(*), "
        "  SUM(CASE WHEN p.statut='Présent' THEN 1 ELSE 0 END) "
        "FROM participations p "
        "JOIN seances s ON s.id=p.seance_id "
        "WHERE s.annee_scolaire_id=:id AND s.valide=1 AND s.presence_valide=1"));
    qPresGlobal.bindValue(":id", activeId);
    qPresGlobal.exec();
    double tauxPresenceGlobal = 0.0;
    if (qPresGlobal.next() && qPresGlobal.value(0).toInt() > 0) {
        tauxPresenceGlobal = qPresGlobal.value(1).toDouble() / qPresGlobal.value(0).toDouble() * 100.0;
        tauxPresenceGlobal = qRound(tauxPresenceGlobal * 10.0) / 10.0;
    }

    // ── Per-matière summary ────────────────────────────────────────────────────
    QSqlQuery qMat(db);
    qMat.prepare(QStringLiteral(
        "SELECT m.id, m.nom, COALESCE(niv.nom,'?') AS niveau_nom, "
        "  SUM(CASE WHEN s.type_seance='Cours' THEN 1 ELSE 0 END) AS cours_total, "
        "  SUM(CASE WHEN s.type_seance='Cours' AND s.presence_valide=1 THEN 1 ELSE 0 END) AS cours_valides, "
        "  SUM(CASE WHEN s.type_seance='Examen' THEN 1 ELSE 0 END) AS examens_total "
        "FROM seances s "
        "LEFT JOIN cours  c ON c.seance_id=s.id "
        "LEFT JOIN examens e ON e.seance_id=s.id "
        "LEFT JOIN matieres m ON m.id=COALESCE(c.matiere_id, e.matiere_id) "
        "LEFT JOIN niveaux niv ON niv.id=m.niveau_id "
        "WHERE s.annee_scolaire_id=:id AND s.valide=1 "
        "  AND COALESCE(c.matiere_id, e.matiere_id) IS NOT NULL "
        "GROUP BY m.id, m.nom, niveau_nom "
        "ORDER BY niv.id, m.nom"));
    qMat.bindValue(":id", activeId);
    qMat.exec();

    // Per-matière presence rate
    QSqlQuery qMatPres(db);
    qMatPres.prepare(QStringLiteral(
        "SELECT COUNT(*), "
        "  SUM(CASE WHEN p.statut='Présent' THEN 1 ELSE 0 END) "
        "FROM participations p "
        "JOIN seances s ON s.id=p.seance_id "
        "LEFT JOIN cours  c ON c.seance_id=s.id "
        "LEFT JOIN examens e ON e.seance_id=s.id "
        "WHERE s.annee_scolaire_id=:anneeId AND s.valide=1 AND s.presence_valide=1 "
        "  AND COALESCE(c.matiere_id, e.matiere_id)=:matId"));

    // Per-exam notes status
    QSqlQuery qExamNotes(db);
    qExamNotes.prepare(QStringLiteral(
        "SELECT s.id, COALESCE(NULLIF(e.titre,''), 'Examen'), DATE(s.date_heure_debut), "
        "  (SELECT COUNT(*) FROM participations p2 WHERE p2.seance_id=s.id AND p2.note>=0) AS notes_saisies, "
        "  (SELECT COUNT(*) FROM participations p3 WHERE p3.seance_id=s.id) AS total_part "
        "FROM seances s "
        "JOIN examens e ON e.seance_id=s.id "
        "WHERE s.annee_scolaire_id=:anneeId AND s.valide=1 AND e.matiere_id=:matId "
        "ORDER BY s.date_heure_debut"));

    QVariantList matieres;
    while (qMat.next()) {
        const int    matId       = qMat.value(0).toInt();
        const QString matNom     = qMat.value(1).toString();
        const QString niveauNom  = qMat.value(2).toString();
        const int    cTotal      = qMat.value("cours_total").toInt();
        const int    cValides    = qMat.value("cours_valides").toInt();
        const int    eTotal      = qMat.value("examens_total").toInt();

        // Presence rate for this matière
        qMatPres.bindValue(":anneeId", activeId);
        qMatPres.bindValue(":matId",   matId);
        qMatPres.exec();
        double presRate = 0.0;
        if (qMatPres.next() && qMatPres.value(0).toInt() > 0)
            presRate = qRound(qMatPres.value(1).toDouble() / qMatPres.value(0).toDouble() * 1000.0) / 10.0;

        // Exams for this matière
        qExamNotes.bindValue(":anneeId", activeId);
        qExamNotes.bindValue(":matId",   matId);
        qExamNotes.exec();
        QVariantList examens;
        int examensAvecNotes = 0;
        while (qExamNotes.next()) {
            const int notesSaisies  = qExamNotes.value(3).toInt();
            const int totalPart     = qExamNotes.value(4).toInt();
            const bool notesEntrees = (notesSaisies > 0 && notesSaisies >= totalPart);
            if (notesEntrees) examensAvecNotes++;
            examens.append(QVariantMap{
                {"seanceId",      qExamNotes.value(0).toInt()},
                {"titre",         qExamNotes.value(1).toString()},
                {"date",          qExamNotes.value(2).toString()},
                {"notesSaisies",  notesSaisies},
                {"totalPart",     totalPart},
                {"notesEntrees",  notesEntrees}
            });
        }

        matieres.append(QVariantMap{
            {"matiereId",        matId},
            {"nom",              matNom},
            {"niveauNom",        niveauNom},
            {"coursTotal",       cTotal},
            {"coursValides",     cValides},
            {"examensTotal",     eTotal},
            {"examensAvecNotes", examensAvecNotes},
            {"presenceRate",     presRate},
            {"examens",          examens}
        });
    }

    // Count examens with all notes entered globally
    int examensAvecNotesTotal = 0;
    for (const auto& m : std::as_const(matieres)) {
        examensAvecNotesTotal += m.toMap().value("examensAvecNotes").toInt();
    }

    m_archivageStats = {
        {"coursTotal",          coursTotal},
        {"coursValides",        coursValides},
        {"examensTotal",        examensTotal},
        {"examensAvecNotes",    examensAvecNotesTotal},
        {"tauxPresenceGlobal",  tauxPresenceGlobal},
        {"matieres",            matieres}
    };
    emit archivageStatsChanged();
}

// ── executeYearClosure ────────────────────────────────────────────────────────

bool YearClosureController::executeYearClosure(const QString& newLabel,
                                               const QString& dateDebut,
                                               const QString& dateFin,
                                               const QVariantList& progressions)
{
    // Validate: no 'En cours' remaining
    for (const QVariant& v : progressions) {
        const QVariantMap m = v.toMap();
        if (m.value("resultat").toString() == QLatin1String("En cours")) {
            emit closureError(tr("Tous les élèves doivent avoir un résultat avant de clôturer."));
            return false;
        }
    }

    auto db = QSqlDatabase::database(m_connectionName);

    // Active year id + tarifs
    QSqlQuery qYear(db);
    qYear.exec(QStringLiteral(
        "SELECT id, tarif_jeune, tarif_adulte, "
        "       frais_inscription_jeune, frais_inscription_adulte "
        "FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (!qYear.next()) {
        emit closureError(tr("Aucune année scolaire active trouvée."));
        return false;
    }
    const int    currentId         = qYear.value(0).toInt();
    const double tarifJeune        = qYear.value(1).toDouble();
    const double tarifAdulte       = qYear.value(2).toDouble();
    const double fraisJeune        = qYear.value(3).toDouble();
    const double fraisAdulte       = qYear.value(4).toDouble();

    const QString now = QDateTime::currentDateTime().toString(Qt::ISODate);

    if (!db.transaction()) {
        emit closureError(tr("Impossible de démarrer la transaction."));
        return false;
    }

    qDebug() << "[YearClosure] Transaction started. CurrentYearId:" << currentId << "NewLabel:" << newLabel;

    // 1. Update existing inscriptions' resultat in DB
    QSqlQuery qUpdRes(db);
    qUpdRes.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves "
        "SET resultat=:res, date_modification=:now "
        "WHERE id=:id"));
    for (const QVariant& v : progressions) {
        const QVariantMap m = v.toMap();
        qUpdRes.bindValue(":res", m.value("resultat").toString());
        qUpdRes.bindValue(":now", now);
        qUpdRes.bindValue(":id",  m.value("inscriptionId").toInt());
        if (!qUpdRes.exec()) {
            db.rollback();
            emit closureError(tr("Erreur mise à jour résultats : %1").arg(qUpdRes.lastError().text()));
            return false;
        }
    }

    // 2. Create new annee_scolaire (copy tarifs, statut='Active')
    QSqlQuery qInsYear(db);
    qInsYear.prepare(QStringLiteral(
        "INSERT INTO annees_scolaires "
        "  (libelle, date_debut, date_fin, tarif_jeune, tarif_adulte, "
        "   frais_inscription_jeune, frais_inscription_adulte, statut, valide, date_modification) "
        "VALUES (:lib, :debut, :fin, :tj, :ta, :fj, :fa, 'Active', 1, :now)"));
    qInsYear.bindValue(":lib",   newLabel);
    qInsYear.bindValue(":debut", dateDebut);
    qInsYear.bindValue(":fin",   dateFin);
    qInsYear.bindValue(":tj",    tarifJeune);
    qInsYear.bindValue(":ta",    tarifAdulte);
    qInsYear.bindValue(":fj",    fraisJeune);
    qInsYear.bindValue(":fa",    fraisAdulte);
    qInsYear.bindValue(":now",   now);
    if (!qInsYear.exec()) {
        db.rollback();
        emit closureError(tr("Erreur création nouvelle année : %1").arg(qInsYear.lastError().text()));
        return false;
    }
    const int newYearId = qInsYear.lastInsertId().toInt();
    qDebug() << "[YearClosure] New year created with id:" << newYearId;

    // 3. Duplicate niveaux for new year (per-year copies)
    // 3a: Fetch niveaux for current year.
    //     Include BOTH niveaux from the junction table AND any niveau directly
    //     referenced by active inscriptions (guards against niveaux that exist
    //     in inscriptions but were not linked to niveaux_actifs_par_annee).
    struct NiveauInfo { int id; QString nom; int parentId; };
    QList<NiveauInfo> currentNiveaux;
    {
        QSqlQuery qGetNiveaux(db);
        qGetNiveaux.prepare(QStringLiteral(
            "SELECT DISTINCT n.id, n.nom, COALESCE(n.parent_level_id, 0) "
            "FROM niveaux n "
            "WHERE ("
            "  EXISTS (SELECT 1 FROM niveaux_actifs_par_annee napa "
            "           WHERE napa.niveau_id = n.id AND napa.annee_scolaire_id = :yearId) "
            "  OR EXISTS (SELECT 1 FROM inscriptions_eleves ie "
            "              WHERE ie.niveau_id = n.id AND ie.annee_scolaire_id = :yearId2 AND ie.valide = 1) "
            ") "
            "ORDER BY n.id"));
        qGetNiveaux.bindValue(":yearId",  currentId);
        qGetNiveaux.bindValue(":yearId2", currentId);
        if (!qGetNiveaux.exec()) {
            db.rollback();
            emit closureError(tr("Erreur lecture niveaux : %1").arg(qGetNiveaux.lastError().text()));
            return false;
        }
        while (qGetNiveaux.next())
            currentNiveaux.append({qGetNiveaux.value(0).toInt(),
                                    qGetNiveaux.value(1).toString(),
                                    qGetNiveaux.value(2).toInt()});
    }

    // 3b: Insert new niveau rows (no parent yet)
    QMap<int, int> niveauMapping; // oldId -> newId
    {
        QSqlQuery qIns(db);
        qIns.prepare(QStringLiteral(
            "INSERT INTO niveaux (nom, valide, annee_scolaire_id, date_modification) "
            "VALUES (:nom, 1, :anneeId, :now)"));
        for (const auto& n : std::as_const(currentNiveaux)) {
            qIns.bindValue(":nom",     n.nom);
            qIns.bindValue(":anneeId", newYearId);
            qIns.bindValue(":now",     now);
            if (!qIns.exec()) {
                db.rollback();
                emit closureError(tr("Erreur duplication niveau : %1").arg(qIns.lastError().text()));
                return false;
            }
            niveauMapping[n.id] = qIns.lastInsertId().toInt();
        }
    }

    // 3c: Fix parent_level_id using mapping
    {
        QSqlQuery qUpd(db);
        qUpd.prepare(QStringLiteral(
            "UPDATE niveaux SET parent_level_id = :newParent WHERE id = :newId"));
        for (const auto& n : std::as_const(currentNiveaux)) {
            if (n.parentId > 0 && niveauMapping.contains(n.parentId)) {
                qUpd.bindValue(":newParent", niveauMapping[n.parentId]);
                qUpd.bindValue(":newId",     niveauMapping[n.id]);
                if (!qUpd.exec()) {
                    db.rollback();
                    emit closureError(tr("Erreur hiérarchie niveaux : %1").arg(qUpd.lastError().text()));
                    return false;
                }
            }
        }
    }

    // 3d: Link new niveaux to new year via niveaux_actifs_par_annee
    {
        QSqlQuery qNapa(db);
        qNapa.prepare(QStringLiteral(
            "INSERT INTO niveaux_actifs_par_annee (annee_scolaire_id, niveau_id) VALUES (:yearId, :niveauId)"));
        for (auto it = niveauMapping.cbegin(); it != niveauMapping.cend(); ++it) {
            qNapa.bindValue(":yearId",   newYearId);
            qNapa.bindValue(":niveauId", it.value());
            if (!qNapa.exec()) {
                db.rollback();
                emit closureError(tr("Erreur liaison niveau-année : %1").arg(qNapa.lastError().text()));
                return false;
            }
        }
    }

    // Pre-compute terminal niveaux (OLD ids): a niveau is terminal if no other
    // niveau has it as parentId. Redoublant students at terminal niveaux must
    // NOT receive a new inscription (they are treated as diplômés).
    QList<int> parentNiveauIds; // old ids that are parents of at least one niveau
    for (const auto& n : std::as_const(currentNiveaux)) {
        if (n.parentId > 0 && !parentNiveauIds.contains(n.parentId))
            parentNiveauIds.append(n.parentId);
    }

    // 3e: Duplicate matieres (linked to new niveau IDs)
    QMap<int, int> matiereMapping; // oldId -> newId
    {
        QSqlQuery qGetM(db);
        qGetM.prepare(QStringLiteral(
            "SELECT id, nom, nombre_seances, duree_seance_minutes "
            "FROM matieres WHERE niveau_id = :niveauId AND valide = 1"));
        QSqlQuery qInsM(db);
        qInsM.prepare(QStringLiteral(
            "INSERT INTO matieres (nom, niveau_id, nombre_seances, duree_seance_minutes) "
            "VALUES (:nom, :niveauId, :nbS, :dur)"));
        for (const auto& n : std::as_const(currentNiveaux)) {
            qGetM.bindValue(":niveauId", n.id);
            if (!qGetM.exec()) continue;
            while (qGetM.next()) {
                const int oldId = qGetM.value(0).toInt();
                qInsM.bindValue(":nom",     qGetM.value(1).toString());
                qInsM.bindValue(":niveauId", niveauMapping[n.id]);
                qInsM.bindValue(":nbS",     qGetM.value(2).toInt());
                qInsM.bindValue(":dur",     qGetM.value(3).toInt());
                if (!qInsM.exec()) {
                    db.rollback();
                    emit closureError(tr("Erreur duplication matière : %1").arg(qInsM.lastError().text()));
                    return false;
                }
                matiereMapping[oldId] = qInsM.lastInsertId().toInt();
            }
        }
    }

    // 3f: Duplicate matiere_examens (linked to new matiere IDs)
    {
        QSqlQuery qGetME(db);
        qGetME.prepare(QStringLiteral(
            "SELECT type_examen_id FROM matiere_examens WHERE matiere_id = :mId AND valide = 1"));
        QSqlQuery qInsME(db);
        qInsME.prepare(QStringLiteral(
            "INSERT INTO matiere_examens (matiere_id, type_examen_id) VALUES (:mId, :teId)"));
        for (auto it = matiereMapping.cbegin(); it != matiereMapping.cend(); ++it) {
            qGetME.bindValue(":mId", it.key());
            if (!qGetME.exec()) continue;
            while (qGetME.next()) {
                qInsME.bindValue(":mId",  it.value());
                qInsME.bindValue(":teId", qGetME.value(0).toInt());
                if (!qInsME.exec()) {
                    db.rollback();
                    emit closureError(tr("Erreur duplication examens matière : %1").arg(qInsME.lastError().text()));
                    return false;
                }
            }
        }
    }

    // 4. Copy tarifs_mensualites
    QSqlQuery qTarifs(db);
    qTarifs.prepare(QStringLiteral(
        "INSERT OR IGNORE INTO tarifs_mensualites (categorie, annee_scolaire_id, montant) "
        "VALUES (:cat, :yearId, :montant)"));
    for (const auto& [cat, montant] : { std::pair<const char*, double>{"Jeune", tarifJeune},
                                         std::pair<const char*, double>{"Adulte", tarifAdulte} }) {
        qTarifs.bindValue(":cat",    QLatin1String(cat));
        qTarifs.bindValue(":yearId", newYearId);
        qTarifs.bindValue(":montant", montant);
        if (!qTarifs.exec()) {
            db.rollback();
            emit closureError(tr("Erreur copie tarifs : %1").arg(qTarifs.lastError().text()));
            return false;
        }
    }

    // 5. Create new inscriptions (classe_id left NULL — will be assigned later)
    QSqlQuery qInsInscription(db);
    qInsInscription.prepare(QStringLiteral(
        "INSERT INTO inscriptions_eleves "
        "  (eleve_id, annee_scolaire_id, niveau_id, resultat, "
        "   frais_inscription_paye, montant_inscription, date_inscription, valide, date_modification) "
        "VALUES (:eleveId, :yearId, :niveauId, 'En cours', "
        "        0, :montant, DATE('now'), 1, :now)"));

    qDebug() << "[YearClosure] Creating inscriptions for" << progressions.size() << "students into year" << newYearId;

    for (const QVariant& v : progressions) {
        const QVariantMap m      = v.toMap();
        const QString resultat   = m.value("resultat").toString();
        const int niveauSuivantId = m.value("niveauSuivantId").toInt();
        const int eleveId        = m.value("eleveId").toInt();
        const int niveauActuelId = m.value("niveauActuelId").toInt();
        const QString categorie  = m.value("categorie").toString();
        const double montant     = (categorie == QLatin1String("Adulte")) ? fraisAdulte : fraisJeune;

        if (resultat == QLatin1String("Réussi")) {
            if (niveauSuivantId <= 0) {
                qDebug() << "[YearClosure] Élève" << eleveId << "→ Diplômé, pas de nouvelle inscription";
                continue;  // diplômé — no new inscription
            }
            const int newNiveauId = niveauMapping.value(niveauSuivantId, 0);
            if (newNiveauId <= 0) {
                qDebug() << "[YearClosure] Élève" << eleveId << "→ Réussi mais niveauSuivant" << niveauSuivantId << "non mappé";
                continue;
            }
            qDebug() << "[YearClosure] Élève" << eleveId << "→ Réussi, nouveau niveau" << newNiveauId;
            qInsInscription.bindValue(":eleveId",  eleveId);
            qInsInscription.bindValue(":yearId",   newYearId);
            qInsInscription.bindValue(":niveauId", newNiveauId);
            qInsInscription.bindValue(":montant",  montant);
            qInsInscription.bindValue(":now",      now);
        } else {
            // Redoublant → same niveau (new copy)
            // If the niveau is terminal (no children), treat as diplômé: no new inscription
            if (!parentNiveauIds.contains(niveauActuelId)) {
                qDebug() << "[YearClosure] Élève" << eleveId
                         << "→ Redoublant au niveau terminal" << niveauActuelId << "→ skipped (diplômé)";
                continue;
            }
            const int newNiveauId = niveauMapping.value(niveauActuelId, 0);
            if (newNiveauId <= 0) {
                // Should not happen after the UNION query above, but skip gracefully
                qWarning() << "[YearClosure] Redoublant élève" << eleveId
                           << "niveau" << niveauActuelId << "non mappé → skipped";
                continue;
            }
            qDebug() << "[YearClosure] Élève" << eleveId << "→ Redoublant, nouveau niveau" << newNiveauId;
            qInsInscription.bindValue(":eleveId",  eleveId);
            qInsInscription.bindValue(":yearId",   newYearId);
            qInsInscription.bindValue(":niveauId", newNiveauId);
            qInsInscription.bindValue(":montant",  montant);
            qInsInscription.bindValue(":now",      now);
        }

        if (!qInsInscription.exec()) {
            db.rollback();
            qDebug() << "[YearClosure] ERREUR inscription élève" << eleveId
                     << "- SQL:" << qInsInscription.lastQuery()
                     << "- Erreur:" << qInsInscription.lastError().databaseText()
                     << qInsInscription.lastError().driverText();
            emit closureError(tr("Erreur création inscription élève %1 : %2")
                              .arg(eleveId)
                              .arg(qInsInscription.lastError().text()));
            return false;
        }
    }

    // 6. Soft-delete future Cours/Examen sessions of the old year that were never held
    //    (Events are kept — they are not year-scoped)
    QSqlQuery qDelSeances(db);
    qDelSeances.prepare(QStringLiteral(
        "UPDATE seances "
        "SET valide=0, date_invalidation=datetime('now'), date_modification=:now "
        "WHERE annee_scolaire_id=:id "
        "  AND presence_valide=0 "
        "  AND date_heure_debut > datetime('now') "
        "  AND type_seance IN ('Cours','Examen')"));
    qDelSeances.bindValue(":now", now);
    qDelSeances.bindValue(":id",  currentId);
    if (!qDelSeances.exec()) {
        qWarning() << "[YearClosure] Warning: could not soft-delete future sessions:"
                   << qDelSeances.lastError().text();
        // Non-fatal: continue
    } else {
        qDebug() << "[YearClosure] Future sessions soft-deleted:" << qDelSeances.numRowsAffected();
    }

    // 7. Close current year
    QSqlQuery qClose(db);
    qClose.prepare(QStringLiteral(
        "UPDATE annees_scolaires SET statut='Fermée', date_modification=:now WHERE id=:id"));
    qClose.bindValue(":now", now);
    qClose.bindValue(":id",  currentId);
    if (!qClose.exec()) {
        db.rollback();
        emit closureError(tr("Erreur fermeture de l'année : %1").arg(qClose.lastError().text()));
        return false;
    }

    if (!db.commit()) {
        db.rollback();
        emit closureError(tr("Erreur commit transaction : %1").arg(db.lastError().text()));
        return false;
    }

    qInfo() << "[YearClosureController] Clôture réussie:" << newLabel;
    emit closureSuccess(newLabel);
    return true;
}
