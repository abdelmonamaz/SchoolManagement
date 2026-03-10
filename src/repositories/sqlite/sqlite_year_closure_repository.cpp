#include "repositories/sqlite/sqlite_year_closure_repository.h"
#include "common/result.h"

#include <QDateTime>
#include <QDebug>
#include <QMap>
#include <QSet>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

SqliteYearClosureRepository::SqliteYearClosureRepository(const QString& connectionName)
    : m_connectionName(connectionName)
{
}

// ── loadStats ─────────────────────────────────────────────────────────────────

QVariantMap SqliteYearClosureRepository::loadStats()
{
    auto db = QSqlDatabase::database(m_connectionName);

    QSqlQuery qYear(db);
    qYear.exec(QStringLiteral(
        "SELECT id, libelle FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (!qYear.next())
        return {{"empty", true}};

    const int     activeId       = qYear.value(0).toInt();
    const QString activeLibelle  = qYear.value(1).toString();

    QSqlQuery qResultats(db);
    qResultats.prepare(QStringLiteral(
        "SELECT resultat, COUNT(*) FROM inscriptions_eleves "
        "WHERE annee_scolaire_id = :id AND valide = 1 GROUP BY resultat"));
    qResultats.bindValue(":id", activeId);
    qResultats.exec();

    int totalInscrits = 0, nbReussi = 0, nbRedoublant = 0, nbEnCours = 0;
    while (qResultats.next()) {
        const QString res = qResultats.value(0).toString();
        const int cnt     = qResultats.value(1).toInt();
        totalInscrits += cnt;
        if      (res == QStringLiteral("Réussi"))     nbReussi     += cnt;
        else if (res == QStringLiteral("Redoublant")) nbRedoublant += cnt;
        else                                           nbEnCours    += cnt;
    }

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
        ? (static_cast<double>(nbReussi) / totalInscrits * 100.0) : 0.0;

    QVariantMap stats = {
        {"anneeActiveId",      activeId},
        {"anneeActiveLibelle", activeLibelle},
        {"studentsInscrits",   totalInscrits},
        {"tauxReussite",       qRound(tauxReussite * 10.0) / 10.0},
        {"diplomes",           nbDiplomes},
        {"redoublants",        nbRedoublant},
        {"enCours",            nbEnCours}
    };

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

    return {{"stats", stats}, {"sessions", sessions}};
}

// ── loadStudentProgressions ───────────────────────────────────────────────────

QVariantList SqliteYearClosureRepository::loadStudentProgressions()
{
    auto db = QSqlDatabase::database(m_connectionName);

    QSqlQuery qYear(db);
    qYear.exec(QStringLiteral(
        "SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (!qYear.next())
        return {};
    const int activeId = qYear.value(0).toInt();

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

    QSqlQuery qChildren(db);
    qChildren.prepare(QStringLiteral(
        "SELECT n.id, n.nom FROM niveaux n "
        "WHERE n.parent_level_id = :niveauId AND n.valide = 1 "
        "  AND n.annee_scolaire_id = :activeId "
        "ORDER BY n.id"));

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
        const int     inscriptionId   = q.value(0).toInt();
        const int     eleveId         = q.value(1).toInt();
        const QString nom             = q.value(2).toString();
        const QString prenom          = q.value(3).toString();
        const QString categorie       = q.value(4).toString();
        const int     niveauActuelId  = q.value(5).toInt();
        const QString niveauActuelNom = q.value(6).toString();
        const QString resultat        = q.value(7).toString();

        qChildren.bindValue(":niveauId", niveauActuelId);
        qChildren.bindValue(":activeId", activeId);
        qChildren.exec();
        QVariantList niveauxSuivants;
        while (qChildren.next()) {
            niveauxSuivants.append(QVariantMap{
                {"id",  qChildren.value(0).toInt()},
                {"nom", qChildren.value(1).toString()}
            });
        }

        qMoyenne.bindValue(":eleveId", eleveId);
        qMoyenne.bindValue(":anneeId", activeId);
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

    return progressions;
}

// ── loadArchivageStats ────────────────────────────────────────────────────────

QVariantMap SqliteYearClosureRepository::loadArchivageStats()
{
    auto db = QSqlDatabase::database(m_connectionName);

    QSqlQuery qYear(db);
    qYear.exec(QStringLiteral(
        "SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (!qYear.next())
        return {};
    const int activeId = qYear.value(0).toInt();

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
        const int    matId      = qMat.value(0).toInt();
        const QString matNom    = qMat.value(1).toString();
        const QString niveauNom = qMat.value(2).toString();
        const int    cTotal     = qMat.value("cours_total").toInt();
        const int    cValides   = qMat.value("cours_valides").toInt();
        const int    eTotal     = qMat.value("examens_total").toInt();

        qMatPres.bindValue(":anneeId", activeId);
        qMatPres.bindValue(":matId",   matId);
        qMatPres.exec();
        double presRate = 0.0;
        if (qMatPres.next() && qMatPres.value(0).toInt() > 0)
            presRate = qRound(qMatPres.value(1).toDouble() / qMatPres.value(0).toDouble() * 1000.0) / 10.0;

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
                {"seanceId",     qExamNotes.value(0).toInt()},
                {"titre",        qExamNotes.value(1).toString()},
                {"date",         qExamNotes.value(2).toString()},
                {"notesSaisies", notesSaisies},
                {"totalPart",    totalPart},
                {"notesEntrees", notesEntrees}
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

    int examensAvecNotesTotal = 0;
    for (const auto& m : std::as_const(matieres))
        examensAvecNotesTotal += m.toMap().value("examensAvecNotes").toInt();

    return {
        {"coursTotal",         coursTotal},
        {"coursValides",       coursValides},
        {"examensTotal",       examensTotal},
        {"examensAvecNotes",   examensAvecNotesTotal},
        {"tauxPresenceGlobal", tauxPresenceGlobal},
        {"matieres",           matieres}
    };
}

// ── executeYearClosure — helpers ──────────────────────────────────────────────
// File-local helpers (anonymous namespace) — not exposed in the header.

namespace {

// 1. Persist the final resultat on each inscription
static Result<bool> updateProgressionResults(QSqlDatabase& db,
    const QVariantList& progressions, const QString& now)
{
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves SET resultat=:res, date_modification=:now WHERE id=:id"));
    for (const QVariant& v : progressions) {
        const auto m = v.toMap();
        q.bindValue(":res", m.value(QStringLiteral("resultat")).toString());
        q.bindValue(":now", now);
        q.bindValue(":id",  m.value(QStringLiteral("inscriptionId")).toInt());
        if (!q.exec())
            return Result<bool>::error(
                QStringLiteral("Erreur mise à jour résultats : %1").arg(q.lastError().text()));
    }
    return Result<bool>::success(true);
}

// 2. Insert the new school year row — returns its new id
static Result<int> createNewYear(QSqlDatabase& db,
    const QString& newLabel, const QString& dateDebut, const QString& dateFin,
    double tarifJeune, double tarifAdulte, double fraisJeune, double fraisAdulte,
    const QString& now)
{
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO annees_scolaires "
        "  (libelle, date_debut, date_fin, tarif_jeune, tarif_adulte, "
        "   frais_inscription_jeune, frais_inscription_adulte, statut, valide, date_modification) "
        "VALUES (:lib, :debut, :fin, :tj, :ta, :fj, :fa, 'Active', 1, :now)"));
    q.bindValue(":lib",   newLabel);
    q.bindValue(":debut", dateDebut);
    q.bindValue(":fin",   dateFin);
    q.bindValue(":tj",    tarifJeune);
    q.bindValue(":ta",    tarifAdulte);
    q.bindValue(":fj",    fraisJeune);
    q.bindValue(":fa",    fraisAdulte);
    q.bindValue(":now",   now);
    if (!q.exec())
        return Result<int>::error(
            QStringLiteral("Erreur création nouvelle année : %1").arg(q.lastError().text()));
    return Result<int>::success(q.lastInsertId().toInt());
}

// 3. Duplicate niveaux (rows + parent hierarchy + NAPA links)
//    Returns oldNiveauId → newNiveauId mapping.
static Result<QMap<int,int>> duplicateNiveaux(QSqlDatabase& db,
    int currentId, int newYearId, const QString& now)
{
    struct NvInfo { int id; QString nom; int parentId; };
    QList<NvInfo> current;

    // 3a. Fetch all niveaux active for the current year
    {
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "SELECT DISTINCT n.id, n.nom, COALESCE(n.parent_level_id, 0) "
            "FROM niveaux n "
            "WHERE n.valide = 1 "
            "  AND (n.annee_scolaire_id = :y1 "
            "       OR EXISTS (SELECT 1 FROM inscriptions_eleves ie "
            "                  WHERE ie.niveau_id = n.id AND ie.annee_scolaire_id = :y2 AND ie.valide = 1)) "
            "ORDER BY n.id"));
        q.bindValue(":y1", currentId);
        q.bindValue(":y2", currentId);
        if (!q.exec())
            return Result<QMap<int,int>>::error(
                QStringLiteral("Erreur lecture niveaux : %1").arg(q.lastError().text()));
        while (q.next())
            current.append({q.value(0).toInt(), q.value(1).toString(), q.value(2).toInt()});
    }

    // 3b. Insert copies → build niveauMapping
    QMap<int,int> mapping;
    {
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "INSERT INTO niveaux (nom, valide, annee_scolaire_id, date_modification) "
            "VALUES (:nom, 1, :anneeId, :now)"));
        for (const auto& n : std::as_const(current)) {
            q.bindValue(":nom",     n.nom);
            q.bindValue(":anneeId", newYearId);
            q.bindValue(":now",     now);
            if (!q.exec())
                return Result<QMap<int,int>>::error(
                    QStringLiteral("Erreur copie niveau '%1' : %2").arg(n.nom, q.lastError().text()));
            mapping[n.id] = q.lastInsertId().toInt();
        }
    }

    // 3c. Fix parent_level_id on new copies
    {
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "UPDATE niveaux SET parent_level_id = :newParent WHERE id = :newId"));
        for (const auto& n : std::as_const(current)) {
            if (n.parentId > 0 && mapping.contains(n.parentId)) {
                q.bindValue(":newParent", mapping[n.parentId]);
                q.bindValue(":newId",     mapping[n.id]);
                if (!q.exec())
                    return Result<QMap<int,int>>::error(
                        QStringLiteral("Erreur hiérarchie niveaux : %1").arg(q.lastError().text()));
            }
        }
    }

    return Result<QMap<int,int>>::success(mapping);
}

// 4. Duplicate classes: copy each class to the new niveau copy
//    classes(id, nom, niveau_id) — no soft-delete columns
static Result<bool> duplicateClasses(QSqlDatabase& db, const QMap<int,int>& niveauMapping)
{
    QSqlQuery qGet(db);
    qGet.prepare(QStringLiteral("SELECT nom FROM classes WHERE niveau_id = :oldId"));
    QSqlQuery qIns(db);
    qIns.prepare(QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES (:nom, :newId)"));

    for (auto it = niveauMapping.cbegin(); it != niveauMapping.cend(); ++it) {
        qGet.bindValue(":oldId", it.key());
        if (!qGet.exec()) continue; // no classes for this niveau — skip silently
        while (qGet.next()) {
            qIns.bindValue(":nom",   qGet.value(0).toString());
            qIns.bindValue(":newId", it.value());
            if (!qIns.exec())
                return Result<bool>::error(
                    QStringLiteral("Erreur copie classe : %1").arg(qIns.lastError().text()));
        }
    }
    return Result<bool>::success(true);
}

// 5. Duplicate matieres — returns oldMatiereId → newMatiereId mapping
static Result<QMap<int,int>> duplicateMatieres(QSqlDatabase& db,
    const QMap<int,int>& niveauMapping, int /*newYearId*/)
{
    QMap<int,int> mapping;
    QSqlQuery qGet(db);
    qGet.prepare(QStringLiteral(
        "SELECT id, nom, nombre_seances, duree_seance_minutes "
        "FROM matieres WHERE niveau_id = :niveauId AND valide = 1"));
    QSqlQuery qIns(db);
    qIns.prepare(QStringLiteral(
        "INSERT INTO matieres (nom, niveau_id, nombre_seances, duree_seance_minutes) "
        "VALUES (:nom, :niveauId, :nbS, :dur)"));

    for (auto it = niveauMapping.cbegin(); it != niveauMapping.cend(); ++it) {
        qGet.bindValue(":niveauId", it.key());
        if (!qGet.exec()) continue;
        while (qGet.next()) {
            qIns.bindValue(":nom",     qGet.value(1).toString());
            qIns.bindValue(":niveauId", it.value());
            qIns.bindValue(":nbS",     qGet.value(2).toInt());
            qIns.bindValue(":dur",     qGet.value(3).toInt());
            if (!qIns.exec())
                return Result<QMap<int,int>>::error(
                    QStringLiteral("Erreur copie matière : %1").arg(qIns.lastError().text()));
            mapping[qGet.value(0).toInt()] = qIns.lastInsertId().toInt();
        }
    }
    return Result<QMap<int,int>>::success(mapping);
}

// 6. Duplicate matiere_examens (non-fatal — best effort)
static void duplicateMatiereExamens(QSqlDatabase& db, const QMap<int,int>& matiereMapping)
{
    QSqlQuery qGet(db);
    qGet.prepare(QStringLiteral(
        "SELECT type_examen_id FROM matiere_examens WHERE matiere_id = :mId AND valide = 1"));
    QSqlQuery qIns(db);
    qIns.prepare(QStringLiteral(
        "INSERT INTO matiere_examens (matiere_id, type_examen_id) VALUES (:mId, :teId)"));
    for (auto it = matiereMapping.cbegin(); it != matiereMapping.cend(); ++it) {
        qGet.bindValue(":mId", it.key());
        if (!qGet.exec()) continue;
        while (qGet.next()) {
            qIns.bindValue(":mId",  it.value());
            qIns.bindValue(":teId", qGet.value(0).toInt());
            qIns.exec();
        }
    }
}

// 7. Copy tarifs_mensualites for the new year
static Result<bool> copyTarifs(QSqlDatabase& db,
    int newYearId, double tarifJeune, double tarifAdulte)
{
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT OR IGNORE INTO tarifs_mensualites (categorie, annee_scolaire_id, montant) "
        "VALUES (:cat, :yearId, :montant)"));
    for (const auto& [cat, montant] : { std::pair<const char*, double>{"Jeune",  tarifJeune},
                                         std::pair<const char*, double>{"Adulte", tarifAdulte} }) {
        q.bindValue(":cat",     QLatin1String(cat));
        q.bindValue(":yearId",  newYearId);
        q.bindValue(":montant", montant);
        if (!q.exec())
            return Result<bool>::error(
                QStringLiteral("Erreur copie tarifs : %1").arg(q.lastError().text()));
    }
    return Result<bool>::success(true);
}

// 8. Create new inscriptions for the new year based on progressions
//    - "Réussi"    → inscribed at the new copy of niveauSuivantId
//    - "Redoublant"→ inscribed at the new copy of niveauActuelId
//    - niveauSuivantId == 0 (Réussi, terminal) → diplômé, no inscription
static Result<bool> createNewInscriptions(QSqlDatabase& db,
    const QVariantList& progressions, const QMap<int,int>& niveauMapping,
    int newYearId, const QString& now, double fraisJeune, double fraisAdulte)
{
    // Build the set of non-terminal niveau IDs (those that appear as parent of another niveau)
    QSet<int> nonTerminalIds;
    {
        QSqlQuery q(db);
        q.exec(QStringLiteral(
            "SELECT DISTINCT parent_level_id FROM niveaux "
            "WHERE parent_level_id IS NOT NULL AND valide = 1"));
        while (q.next())
            nonTerminalIds.insert(q.value(0).toInt());
    }

    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO inscriptions_eleves "
        "  (eleve_id, annee_scolaire_id, niveau_id, resultat, "
        "   frais_inscription_paye, montant_inscription, date_inscription, valide, date_modification) "
        "VALUES (:eleveId, :yearId, :niveauId, 'En cours', 0, :montant, DATE('now'), 1, :now)"));

    for (const QVariant& v : progressions) {
        const auto    m              = v.toMap();
        // NOTE: use QStringLiteral (not QLatin1String) for non-ASCII keys/values
        //       to avoid UTF-8 / Latin-1 mismatch on some platforms.
        const QString resultat       = m.value(QStringLiteral("resultat")).toString();
        const int     niveauSuivantId = m.value(QStringLiteral("niveauSuivantId")).toInt();
        const int     eleveId         = m.value(QStringLiteral("eleveId")).toInt();
        const int     niveauActuelId  = m.value(QStringLiteral("niveauActuelId")).toInt();
        const QString categorie       = m.value(QStringLiteral("categorie")).toString();
        const double  montant         = (categorie == QStringLiteral("Adulte")) ? fraisAdulte : fraisJeune;

        int newNiveauId = 0;

        if (resultat == QStringLiteral("Réussi")) {
            if (niveauSuivantId <= 0) {
                qDebug() << "[YearClosure] Élève" << eleveId << "→ Diplômé (pas de niveau suivant)";
                continue;
            }
            // Map OLD niveauSuivantId → its NEW copy
            newNiveauId = niveauMapping.value(niveauSuivantId, 0);
            if (newNiveauId <= 0) {
                qWarning() << "[YearClosure] Réussi: niveauSuivant" << niveauSuivantId
                           << "pour élève" << eleveId << "non trouvé dans le mapping → ignoré";
                continue;
            }
            qDebug() << "[YearClosure] Élève" << eleveId
                     << "→ Réussi, old niveauSuivant" << niveauSuivantId
                     << "→ new niveau" << newNiveauId;
        } else {
            // Redoublant (or any other value)
            if (!nonTerminalIds.contains(niveauActuelId)) {
                // Terminal niveau with no successors — treated as diplômé
                qDebug() << "[YearClosure] Élève" << eleveId
                         << "→ Redoublant au niveau terminal" << niveauActuelId << "→ Diplômé";
                continue;
            }
            // Map OLD niveauActuelId → its NEW copy
            newNiveauId = niveauMapping.value(niveauActuelId, 0);
            if (newNiveauId <= 0) {
                qWarning() << "[YearClosure] Redoublant: niveau" << niveauActuelId
                           << "pour élève" << eleveId << "non trouvé dans le mapping → ignoré";
                continue;
            }
            qDebug() << "[YearClosure] Élève" << eleveId
                     << "→ Redoublant, old niveau" << niveauActuelId
                     << "→ new niveau" << newNiveauId;
        }

        q.bindValue(":eleveId",  eleveId);
        q.bindValue(":yearId",   newYearId);
        q.bindValue(":niveauId", newNiveauId);
        q.bindValue(":montant",  montant);
        q.bindValue(":now",      now);
        if (!q.exec())
            return Result<bool>::error(
                QStringLiteral("Erreur inscription élève %1 : %2")
                    .arg(eleveId).arg(q.lastError().text()));
    }
    return Result<bool>::success(true);
}

// 9. Soft-delete future sessions of the closing year (non-fatal)
static void softDeleteFutureSessions(QSqlDatabase& db, int currentId, const QString& now)
{
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE seances "
        "SET valide=0, date_invalidation=datetime('now'), date_modification=:now "
        "WHERE annee_scolaire_id=:id "
        "  AND presence_valide=0 "
        "  AND date_heure_debut > datetime('now') "
        "  AND type_seance IN ('Cours','Examen')"));
    q.bindValue(":now", now);
    q.bindValue(":id",  currentId);
    if (!q.exec())
        qWarning() << "[YearClosure] Soft-delete sessions failed:" << q.lastError().text();
    else
        qDebug()   << "[YearClosure] Future sessions soft-deleted:" << q.numRowsAffected();
}

// 10. Mark the closing year as 'Fermée'
static Result<bool> closeCurrentYear(QSqlDatabase& db, int currentId, const QString& now)
{
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE annees_scolaires SET statut='Fermée', date_modification=:now WHERE id=:id"));
    q.bindValue(":now", now);
    q.bindValue(":id",  currentId);
    if (!q.exec())
        return Result<bool>::error(
            QStringLiteral("Erreur fermeture de l'année : %1").arg(q.lastError().text()));
    return Result<bool>::success(true);
}

} // anonymous namespace

// ── executeYearClosure ────────────────────────────────────────────────────────

Result<bool> SqliteYearClosureRepository::executeYearClosure(
    const QString& newLabel, const QString& dateDebut,
    const QString& dateFin, const QVariantList& progressions)
{
    auto db = QSqlDatabase::database(m_connectionName);

    // Fetch active year metadata
    QSqlQuery qYear(db);
    qYear.exec(QStringLiteral(
        "SELECT id, tarif_jeune, tarif_adulte, "
        "       frais_inscription_jeune, frais_inscription_adulte "
        "FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (!qYear.next())
        return Result<bool>::error(QStringLiteral("Aucune année scolaire active trouvée."));

    const int    currentId   = qYear.value(0).toInt();
    const double tarifJeune  = qYear.value(1).toDouble();
    const double tarifAdulte = qYear.value(2).toDouble();
    const double fraisJeune  = qYear.value(3).toDouble();
    const double fraisAdulte = qYear.value(4).toDouble();
    const QString now        = QDateTime::currentDateTime().toString(Qt::ISODate);

    if (!db.transaction())
        return Result<bool>::error(QStringLiteral("Impossible de démarrer la transaction."));

    qDebug() << "[YearClosure] Start. currentYearId:" << currentId << "→ newLabel:" << newLabel;

// Helper macro: rollback and return the error if a step fails
#define YC_CHECK(expr)                              \
    if (auto _r = (expr); !_r.isOk()) {             \
        db.rollback();                              \
        return Result<bool>::error(_r.errorMessage()); \
    }

    // 1. Persist resultat on current inscriptions
    YC_CHECK(updateProgressionResults(db, progressions, now))

    // 2. Create the new school year row
    auto newYearRes = createNewYear(db, newLabel, dateDebut, dateFin,
                                    tarifJeune, tarifAdulte, fraisJeune, fraisAdulte, now);
    if (!newYearRes.isOk()) { db.rollback(); return Result<bool>::error(newYearRes.errorMessage()); }
    const int newYearId = newYearRes.value();
    qDebug() << "[YearClosure] New year id:" << newYearId;

    // 3. Duplicate niveaux (rows + hierarchy + NAPA)
    auto niveauxRes = duplicateNiveaux(db, currentId, newYearId, now);
    if (!niveauxRes.isOk()) { db.rollback(); return Result<bool>::error(niveauxRes.errorMessage()); }
    const QMap<int,int> niveauMapping = niveauxRes.take();
    qDebug() << "[YearClosure] Niveaux dupliqués:" << niveauMapping.size();

    // 4. Duplicate classes (new niveau IDs)
    YC_CHECK(duplicateClasses(db, niveauMapping))

    // 5. Duplicate matieres
    auto matieresRes = duplicateMatieres(db, niveauMapping, newYearId);
    if (!matieresRes.isOk()) { db.rollback(); return Result<bool>::error(matieresRes.errorMessage()); }

    // 6. Duplicate matiere_examens (best effort)
    duplicateMatiereExamens(db, matieresRes.value());

    // 7. Copy tarifs mensualites
    YC_CHECK(copyTarifs(db, newYearId, tarifJeune, tarifAdulte))

    // 8. Create new inscriptions based on progressions
    YC_CHECK(createNewInscriptions(db, progressions, niveauMapping,
                                   newYearId, now, fraisJeune, fraisAdulte))

    // 9. Soft-delete future sessions of the closing year
    softDeleteFutureSessions(db, currentId, now);

    // 10. Mark closing year as 'Fermée'
    YC_CHECK(closeCurrentYear(db, currentId, now))

#undef YC_CHECK

    if (!db.commit()) {
        db.rollback();
        return Result<bool>::error(
            QStringLiteral("Erreur commit transaction : %1").arg(db.lastError().text()));
    }

    qInfo() << "[YearClosureRepository] Clôture réussie:" << newLabel;
    return Result<bool>::success(true);
}
