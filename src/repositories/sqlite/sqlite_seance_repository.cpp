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

static Seance rowToSeance(const QSqlQuery& q) {
    Seance s;
    s.id = q.value(0).toInt();
    s.matiereId = q.value(1).toInt();
    s.profId = q.value(2).toInt();
    s.salleId = q.value(3).toInt();
    s.classeId = q.value(4).toInt();
    s.dateHeureDebut = QDateTime::fromString(q.value(5).toString(), Qt::ISODate);
    s.dureeMinutes = q.value(6).toInt();
    s.typeSeance = stringToCategorieSeance(q.value(7).toString());
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

static const auto kSeanceCols = QStringLiteral(
    "id, matiere_id, prof_id, salle_id, classe_id, date_heure_debut, duree_minutes, type_seance");

SqliteSeanceRepository::SqliteSeanceRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Seance>> SqliteSeanceRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT %1 FROM seances").arg(kSeanceCols))) {
        return Result<QList<Seance>>::error(query.lastError().text());
    }
    QList<Seance> list;
    while (query.next()) list.append(rowToSeance(query));
    return Result<QList<Seance>>::success(list);
}

Result<std::optional<Seance>> SqliteSeanceRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM seances WHERE id = ?").arg(kSeanceCols));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Seance>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Seance>>::success(rowToSeance(query));
    return Result<std::optional<Seance>>::success(std::nullopt);
}

Result<int> SqliteSeanceRepository::create(const Seance& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO seances (matiere_id, prof_id, salle_id, classe_id, date_heure_debut, duree_minutes, type_seance) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.matiereId);
    query.addBindValue(entity.profId);
    query.addBindValue(entity.salleId);
    query.addBindValue(entity.classeId);
    query.addBindValue(entity.dateHeureDebut.toString(Qt::ISODate));
    query.addBindValue(entity.dureeMinutes);
    query.addBindValue(categorieSeanceToString(entity.typeSeance));
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteSeanceRepository::update(const Seance& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE seances SET matiere_id=?, prof_id=?, salle_id=?, classe_id=?, "
        "date_heure_debut=?, duree_minutes=?, type_seance=? WHERE id=?"));
    query.addBindValue(entity.matiereId);
    query.addBindValue(entity.profId);
    query.addBindValue(entity.salleId);
    query.addBindValue(entity.classeId);
    query.addBindValue(entity.dateHeureDebut.toString(Qt::ISODate));
    query.addBindValue(entity.dureeMinutes);
    query.addBindValue(categorieSeanceToString(entity.typeSeance));
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteSeanceRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM seances WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Seance>> SqliteSeanceRepository::getByDateRange(const QDateTime& from, const QDateTime& to) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM seances WHERE date_heure_debut BETWEEN ? AND ?").arg(kSeanceCols));
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
    query.prepare(QStringLiteral("SELECT %1 FROM seances WHERE classe_id = ?").arg(kSeanceCols));
    query.addBindValue(classeId);
    if (!query.exec()) return Result<QList<Seance>>::error(query.lastError().text());
    QList<Seance> list;
    while (query.next()) list.append(rowToSeance(query));
    return Result<QList<Seance>>::success(list);
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
    if (!query.exec(QStringLiteral("SELECT %1 FROM participations").arg(kParticipationCols))) {
        return Result<QList<Participation>>::error(query.lastError().text());
    }
    QList<Participation> list;
    while (query.next()) list.append(rowToParticipation(query));
    return Result<QList<Participation>>::success(list);
}

Result<std::optional<Participation>> SqliteParticipationRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM participations WHERE id = ?").arg(kParticipationCols));
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
        "UPDATE participations SET seance_id=?, eleve_id=?, statut=?, note=?, est_invite=? WHERE id=?"));
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
    query.prepare(QStringLiteral("DELETE FROM participations WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Participation>> SqliteParticipationRepository::getBySeanceId(int seanceId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM participations WHERE seance_id = ?").arg(kParticipationCols));
    query.addBindValue(seanceId);
    if (!query.exec()) return Result<QList<Participation>>::error(query.lastError().text());
    QList<Participation> list;
    while (query.next()) list.append(rowToParticipation(query));
    return Result<QList<Participation>>::success(list);
}

Result<QList<Participation>> SqliteParticipationRepository::getByEleveId(int eleveId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM participations WHERE eleve_id = ?").arg(kParticipationCols));
    query.addBindValue(eleveId);
    if (!query.exec()) return Result<QList<Participation>>::error(query.lastError().text());
    QList<Participation> list;
    while (query.next()) list.append(rowToParticipation(query));
    return Result<QList<Participation>>::success(list);
}
