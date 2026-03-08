#include "repositories/sqlite/sqlite_seance_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

// ─── Enum helpers ───

static QString categorieSeanceToString(GS::CategorieSeance c) {
    switch (c) {
        case GS::CategorieSeance::Cours: return QStringLiteral("Cours");
        case GS::CategorieSeance::Examen: return QStringLiteral("Examen");
        case GS::CategorieSeance::Evenement: return QStringLiteral("Événement");
    }
    return QStringLiteral("Cours");
}

static GS::CategorieSeance stringToCategorieSeance(const QString& s) {
    if (s == QStringLiteral("Examen")) return GS::CategorieSeance::Examen;
    if (s == QStringLiteral("Événement")) return GS::CategorieSeance::Evenement;
    return GS::CategorieSeance::Cours;
}

static QString typePresenceToString(GS::TypePresence t) {
    switch (t) {
        case GS::TypePresence::Present: return QStringLiteral("Présent");
        case GS::TypePresence::Absent: return QStringLiteral("Absent");
        case GS::TypePresence::Retard: return QStringLiteral("Retard");
    }
    return QStringLiteral("Présent");
}

static GS::TypePresence stringToTypePresence(const QString& s) {
    if (s == QStringLiteral("Absent")) return GS::TypePresence::Absent;
    if (s == QStringLiteral("Retard")) return GS::TypePresence::Retard;
    return GS::TypePresence::Present;
}

// ─── Row mappers ───

// Column order matches kSeanceSelect JOIN query:
// 0: s.id, 1: s.salle_id, 2: s.date_heure_debut, 3: s.duree_minutes, 4: s.type_seance,
// 5: matiere_id (COALESCE), 6: prof_id (COALESCE), 7: classe_id (COALESCE),
// 8: titre (COALESCE), 9: descriptif (COALESCE), 10: s.presence_valide, 11: s.annee_scolaire_id
static Seance rowToSeance(const QSqlQuery& q) {
    Seance s;
    s.id = q.value(0).toInt();
    s.salleId = q.value(1).toInt();
    s.dateHeureDebut = QDateTime::fromString(q.value(2).toString(), Qt::ISODate);
    s.dureeMinutes = q.value(3).toInt();
    s.typeSeance = stringToCategorieSeance(q.value(4).toString());
    s.matiereId = q.value(5).toInt();
    s.profId = q.value(6).toInt();
    s.classeId = q.value(7).toInt();
    s.titre = q.value(8).toString();
    s.descriptif = q.value(9).toString();
    s.presenceValide = q.value(10).toBool();
    s.anneeScolaireId = q.value(11).toInt();
    return s;
}

static Participation rowToParticipation(const QSqlQuery& q) {
    Participation p;
    p.id = q.value(0).toInt();
    p.seanceId = q.value(1).toInt();
    p.eleveId = q.value(2).toInt();
    p.statut = stringToTypePresence(q.value(3).toString());
    p.note = q.value(4).isNull() ? -1.0 : q.value(4).toDouble();
    p.estInvite = q.value(5).toBool();
    return p;
}

// ═══════════════════════════════════════════════════════════════
// SqliteSeanceRepository
// ═══════════════════════════════════════════════════════════════

// JOIN-based SELECT: reads from seances + cours/examens/events sub-tables
static const auto kSeanceSelect = QStringLiteral(
    "SELECT s.id, s.salle_id, s.date_heure_debut, s.duree_minutes, s.type_seance, "
    "COALESCE(c.matiere_id, e.matiere_id, 0), "
    "COALESCE(c.prof_id, e.prof_id, 0), "
    "COALESCE(c.classe_id, e.classe_id, 0), "
    "COALESCE(e.titre, ev.titre, ''), "
    "COALESCE(ev.descriptif, ''), "
    "s.presence_valide, "
    "COALESCE(s.annee_scolaire_id, 0) "
    "FROM seances s "
    "LEFT JOIN cours c ON c.seance_id = s.id "
    "LEFT JOIN examens e ON e.seance_id = s.id "
    "LEFT JOIN events ev ON ev.seance_id = s.id "
    "WHERE s.valide = 1");

SqliteSeanceRepository::SqliteSeanceRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Seance>> SqliteSeanceRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(kSeanceSelect)) {
        return Result<QList<Seance>>::error(query.lastError().text());
    }
    QList<Seance> list;
    while (query.next()) list.append(rowToSeance(query));
    return Result<QList<Seance>>::success(list);
}

Result<std::optional<Seance>> SqliteSeanceRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(kSeanceSelect + QStringLiteral(" AND s.id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Seance>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Seance>>::success(rowToSeance(query));
    return Result<std::optional<Seance>>::success(std::nullopt);
}

Result<int> SqliteSeanceRepository::create(const Seance& entity) {
    auto db = QSqlDatabase::database(m_connectionName);

    if (!db.transaction())
        return Result<int>::error(QStringLiteral("Failed to begin transaction"));

    // 1. Insert base seance
    // annee_scolaire_id est NULL pour les événements (indépendants de l'année scolaire)
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO seances (salle_id, date_heure_debut, duree_minutes, type_seance, annee_scolaire_id) "
        "VALUES (?, ?, ?, ?, ?)"));
    q.addBindValue(entity.salleId > 0 ? entity.salleId : QVariant());
    q.addBindValue(entity.dateHeureDebut.toString(Qt::ISODate));
    q.addBindValue(entity.dureeMinutes);
    q.addBindValue(categorieSeanceToString(entity.typeSeance));
    bool isEvent = (entity.typeSeance == GS::CategorieSeance::Evenement);
    q.addBindValue(!isEvent && entity.anneeScolaireId > 0 ? QVariant(entity.anneeScolaireId) : QVariant());
    if (!q.exec()) {
        db.rollback();
        return Result<int>::error(q.lastError().text());
    }
    int seanceId = q.lastInsertId().toInt();

    // 2. Insert into sub-table based on type
    QSqlQuery sub(db);
    switch (entity.typeSeance) {
        case GS::CategorieSeance::Cours:
            sub.prepare(QStringLiteral(
                "INSERT INTO cours (seance_id, matiere_id, prof_id, classe_id) VALUES (?, ?, ?, ?)"));
            sub.addBindValue(seanceId);
            sub.addBindValue(entity.matiereId);
            sub.addBindValue(entity.profId);
            sub.addBindValue(entity.classeId);
            break;
        case GS::CategorieSeance::Examen:
            sub.prepare(QStringLiteral(
                "INSERT INTO examens (seance_id, matiere_id, classe_id, titre, prof_id) VALUES (?, ?, ?, ?, ?)"));
            sub.addBindValue(seanceId);
            sub.addBindValue(entity.matiereId);
            sub.addBindValue(entity.classeId);
            sub.addBindValue(entity.titre);
            sub.addBindValue(entity.profId > 0 ? entity.profId : QVariant());
            break;
        case GS::CategorieSeance::Evenement:
            sub.prepare(QStringLiteral(
                "INSERT INTO events (seance_id, titre, salle_id, descriptif) VALUES (?, ?, ?, ?)"));
            sub.addBindValue(seanceId);
            sub.addBindValue(entity.titre);
            sub.addBindValue(entity.salleId > 0 ? entity.salleId : QVariant());
            sub.addBindValue(entity.descriptif.isEmpty() ? QVariant() : entity.descriptif);
            break;
    }
    if (!sub.exec()) {
        db.rollback();
        return Result<int>::error(sub.lastError().text());
    }

    if (!db.commit()) {
        db.rollback();
        return Result<int>::error(QStringLiteral("Failed to commit transaction"));
    }
    return Result<int>::success(seanceId);
}

Result<bool> SqliteSeanceRepository::update(const Seance& entity) {
    auto db = QSqlDatabase::database(m_connectionName);

    if (!db.transaction())
        return Result<bool>::error(QStringLiteral("Failed to begin transaction"));

    // 1. Update base seance
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE seances SET salle_id=?, date_heure_debut=?, duree_minutes=?, type_seance=?, annee_scolaire_id=?"
        ", date_modification = datetime('now') WHERE id=?"));
    q.addBindValue(entity.salleId > 0 ? entity.salleId : QVariant());
    q.addBindValue(entity.dateHeureDebut.toString(Qt::ISODate));
    q.addBindValue(entity.dureeMinutes);
    q.addBindValue(categorieSeanceToString(entity.typeSeance));
    {
        bool isEvent = (entity.typeSeance == GS::CategorieSeance::Evenement);
        q.addBindValue(!isEvent && entity.anneeScolaireId > 0 ? QVariant(entity.anneeScolaireId) : QVariant());
    }
    q.addBindValue(entity.id);
    if (!q.exec()) {
        db.rollback();
        return Result<bool>::error(q.lastError().text());
    }

    // 2. Update sub-table
    QSqlQuery sub(db);
    switch (entity.typeSeance) {
        case GS::CategorieSeance::Cours:
            sub.prepare(QStringLiteral(
                "UPDATE cours SET matiere_id=?, prof_id=?, classe_id=? , date_modification = datetime('now') WHERE seance_id=?"));
            sub.addBindValue(entity.matiereId);
            sub.addBindValue(entity.profId);
            sub.addBindValue(entity.classeId);
            sub.addBindValue(entity.id);
            break;
        case GS::CategorieSeance::Examen:
            sub.prepare(QStringLiteral(
                "UPDATE examens SET matiere_id=?, classe_id=?, titre=?, prof_id=? , date_modification = datetime('now') WHERE seance_id=?"));
            sub.addBindValue(entity.matiereId);
            sub.addBindValue(entity.classeId);
            sub.addBindValue(entity.titre);
            sub.addBindValue(entity.profId > 0 ? entity.profId : QVariant());
            sub.addBindValue(entity.id);
            break;
        case GS::CategorieSeance::Evenement:
            sub.prepare(QStringLiteral(
                "UPDATE events SET titre=?, salle_id=?, descriptif=? , date_modification = datetime('now') WHERE seance_id=?"));
            sub.addBindValue(entity.titre);
            sub.addBindValue(entity.salleId > 0 ? entity.salleId : QVariant());
            sub.addBindValue(entity.descriptif.isEmpty() ? QVariant() : entity.descriptif);
            sub.addBindValue(entity.id);
            break;
    }
    if (!sub.exec()) {
        db.rollback();
        return Result<bool>::error(sub.lastError().text());
    }

    if (!db.commit()) {
        db.rollback();
        return Result<bool>::error(QStringLiteral("Failed to commit transaction"));
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteSeanceRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    // CASCADE deletes the sub-table row automatically
    query.prepare(QStringLiteral("UPDATE seances SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteSeanceRepository::setPresenceValide(int seanceId, bool valide) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE seances SET presence_valide = ? , date_modification = datetime('now') WHERE id = ?"));
    query.addBindValue(valide ? 1 : 0);
    query.addBindValue(seanceId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Seance>> SqliteSeanceRepository::getByDateRange(const QDateTime& from, const QDateTime& to) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(kSeanceSelect + QStringLiteral(" AND s.date_heure_debut BETWEEN ? AND ? ORDER BY s.date_heure_debut ASC"));
    query.addBindValue(from.toString(Qt::ISODate));
    query.addBindValue(to.toString(Qt::ISODate));
    if (!query.exec()) return Result<QList<Seance>>::error(query.lastError().text());
    QList<Seance> list;
    while (query.next()) list.append(rowToSeance(query));
    return Result<QList<Seance>>::success(list);
}

Result<QList<Seance>> SqliteSeanceRepository::getByClasseId(int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(kSeanceSelect + QStringLiteral(" AND (c.classe_id = ? OR e.classe_id = ?)"));
    query.addBindValue(classeId);
    query.addBindValue(classeId);
    if (!query.exec()) return Result<QList<Seance>>::error(query.lastError().text());
    QList<Seance> list;
    while (query.next()) list.append(rowToSeance(query));
    return Result<QList<Seance>>::success(list);
}

Result<int> SqliteSeanceRepository::getTotalMinutesByProf(int profId, const QDate& from, const QDate& to) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    // Include both cours (teaching) and examens (supervision) hours
    query.prepare(QStringLiteral(
        "SELECT COALESCE(SUM(s.duree_minutes), 0) "
        "FROM seances s "
        "LEFT JOIN cours c ON c.seance_id = s.id "
        "LEFT JOIN examens e ON e.seance_id = s.id "
        "WHERE s.valide = 1 AND (c.prof_id = ? OR e.prof_id = ?) "
        "AND date(s.date_heure_debut) BETWEEN ? AND ?"));
    query.addBindValue(profId);
    query.addBindValue(profId);
    query.addBindValue(from.toString(Qt::ISODate));
    query.addBindValue(to.toString(Qt::ISODate));
    if (!query.exec() || !query.next())
        return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.value(0).toInt());
}

Result<QStringList> SqliteSeanceRepository::checkConflicts(const Seance& seance, int excludeSeanceId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QStringList conflicts;

    // Compute new session time range in SQLite datetime format (space separator, not T)
    QString newStart = seance.dateHeureDebut.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    QString newEnd = seance.dateHeureDebut.addSecs(seance.dureeMinutes * 60).toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));

    // Overlap condition: existing_start < new_end AND existing_end > new_start
    // datetime() normalizes dates to 'YYYY-MM-DD HH:MM:SS' format (space, not T)
    // so we must also use space format for bind values

    // Check professor conflict
    if (seance.profId > 0) {
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "SELECT s.id, s.date_heure_debut, s.duree_minutes, p.nom "
            "FROM seances s "
            "LEFT JOIN cours c ON c.seance_id = s.id "
            "LEFT JOIN examens e ON e.seance_id = s.id "
            "LEFT JOIN personnel p ON p.id = COALESCE(c.prof_id, e.prof_id) "
            "WHERE s.valide = 1 AND COALESCE(c.prof_id, e.prof_id) = ? "
            "AND s.id != ? "
            "AND datetime(s.date_heure_debut) < ? "
            "AND datetime(s.date_heure_debut, '+' || CAST(s.duree_minutes AS TEXT) || ' minutes') > ? "
            "LIMIT 1"));
        q.addBindValue(seance.profId);
        q.addBindValue(excludeSeanceId);
        q.addBindValue(newEnd);
        q.addBindValue(newStart);
        if (!q.exec()) {
            qWarning() << "checkConflicts prof query error:" << q.lastError().text();
            return Result<QStringList>::error(q.lastError().text());
        }
        if (q.next()) {
            QString profName = q.value(3).toString();
            QString existStart = q.value(1).toString();
            conflicts.append(QStringLiteral("Le professeur %1 a déjà une session à cette horaire (%2).")
                .arg(profName.isEmpty() ? QStringLiteral("sélectionné") : profName,
                     QDateTime::fromString(existStart, Qt::ISODate).toString(QStringLiteral("dd/MM/yyyy HH:mm"))));
        }
    }

    // Check room conflict
    if (seance.salleId > 0) {
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "SELECT s.id, s.date_heure_debut, sa.nom "
            "FROM seances s "
            "LEFT JOIN salles sa ON sa.id = s.salle_id "
            "WHERE s.valide = 1 AND s.salle_id = ? "
            "AND s.id != ? "
            "AND datetime(s.date_heure_debut) < ? "
            "AND datetime(s.date_heure_debut, '+' || CAST(s.duree_minutes AS TEXT) || ' minutes') > ? "
            "LIMIT 1"));
        q.addBindValue(seance.salleId);
        q.addBindValue(excludeSeanceId);
        q.addBindValue(newEnd);
        q.addBindValue(newStart);
        if (!q.exec()) {
            qWarning() << "checkConflicts salle query error:" << q.lastError().text();
            return Result<QStringList>::error(q.lastError().text());
        }
        if (q.next()) {
            QString salleName = q.value(2).toString();
            conflicts.append(QStringLiteral("La salle %1 est déjà occupée à cette horaire.")
                .arg(salleName.isEmpty() ? QStringLiteral("sélectionnée") : salleName));
        }
    }

    // Check class conflict
    if (seance.classeId > 0) {
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "SELECT s.id, s.date_heure_debut, cl.nom "
            "FROM seances s "
            "LEFT JOIN cours c ON c.seance_id = s.id "
            "LEFT JOIN examens e ON e.seance_id = s.id "
            "LEFT JOIN classes cl ON cl.id = COALESCE(c.classe_id, e.classe_id) "
            "WHERE s.valide = 1 AND COALESCE(c.classe_id, e.classe_id) = ? "
            "AND s.id != ? "
            "AND datetime(s.date_heure_debut) < ? "
            "AND datetime(s.date_heure_debut, '+' || CAST(s.duree_minutes AS TEXT) || ' minutes') > ? "
            "LIMIT 1"));
        q.addBindValue(seance.classeId);
        q.addBindValue(excludeSeanceId);
        q.addBindValue(newEnd);
        q.addBindValue(newStart);
        if (!q.exec()) {
            qWarning() << "checkConflicts classe query error:" << q.lastError().text();
            return Result<QStringList>::error(q.lastError().text());
        }
        if (q.next()) {
            QString className = q.value(2).toString();
            conflicts.append(QStringLiteral("La classe %1 a déjà une session à cette horaire.")
                .arg(className.isEmpty() ? QStringLiteral("sélectionnée") : className));
        }
    }

    return Result<QStringList>::success(conflicts);
}

// ═══════════════════════════════════════════════════════════════
// SqliteParticipationRepository
// ═══════════════════════════════════════════════════════════════

static const auto kParticipationCols = QStringLiteral(
    "id, seance_id, eleve_id, statut, note, est_invite");

SqliteParticipationRepository::SqliteParticipationRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Participation>> SqliteParticipationRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT %1 FROM participations WHERE valide = 1").arg(kParticipationCols))) {
        return Result<QList<Participation>>::error(query.lastError().text());
    }
    QList<Participation> list;
    while (query.next()) list.append(rowToParticipation(query));
    return Result<QList<Participation>>::success(list);
}

Result<std::optional<Participation>> SqliteParticipationRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM participations WHERE id = ? AND valide = 1").arg(kParticipationCols));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Participation>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Participation>>::success(rowToParticipation(query));
    return Result<std::optional<Participation>>::success(std::nullopt);
}

Result<int> SqliteParticipationRepository::create(const Participation& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO participations (seance_id, eleve_id, statut, note, est_invite) VALUES (?, ?, ?, ?, ?)"));
    query.addBindValue(entity.seanceId);
    query.addBindValue(entity.eleveId);
    query.addBindValue(typePresenceToString(entity.statut));
    if (entity.note < 0) query.addBindValue(QVariant());
    else query.addBindValue(entity.note);
    query.addBindValue(entity.estInvite ? 1 : 0);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteParticipationRepository::update(const Participation& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE participations SET seance_id=?, eleve_id=?, statut=?, note=?, est_invite=? , date_modification = datetime('now') WHERE id=?"));
    query.addBindValue(entity.seanceId);
    query.addBindValue(entity.eleveId);
    query.addBindValue(typePresenceToString(entity.statut));
    if (entity.note < 0) query.addBindValue(QVariant());
    else query.addBindValue(entity.note);
    query.addBindValue(entity.estInvite ? 1 : 0);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteParticipationRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE participations SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Participation>> SqliteParticipationRepository::getBySeanceId(int seanceId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM participations WHERE seance_id = ? AND valide = 1").arg(kParticipationCols));
    query.addBindValue(seanceId);
    if (!query.exec()) return Result<QList<Participation>>::error(query.lastError().text());
    QList<Participation> list;
    while (query.next()) list.append(rowToParticipation(query));
    return Result<QList<Participation>>::success(list);
}

Result<QList<Participation>> SqliteParticipationRepository::getByEleveId(int eleveId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM participations WHERE eleve_id = ? AND valide = 1").arg(kParticipationCols));
    query.addBindValue(eleveId);
    if (!query.exec()) return Result<QList<Participation>>::error(query.lastError().text());
    QList<Participation> list;
    while (query.next()) list.append(rowToParticipation(query));
    return Result<QList<Participation>>::success(list);
}
