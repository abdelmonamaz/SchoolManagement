#include "repositories/sqlite/sqlite_eleve_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

static QString typePublicToString(GS::TypePublic t) {
    switch (t) {
        case GS::TypePublic::Jeune: return QStringLiteral("Jeune");
        case GS::TypePublic::Adulte: return QStringLiteral("Adulte");
    }
    return QStringLiteral("Jeune");
}

static GS::TypePublic stringToTypePublic(const QString& s) {
    if (s == QStringLiteral("Adulte")) return GS::TypePublic::Adulte;
    return GS::TypePublic::Jeune;
}

static Eleve rowToEleve(const QSqlQuery& query) {
    Eleve e;
    e.id            = query.value(0).toInt();
    e.nom           = query.value(1).toString();
    e.prenom        = query.value(2).toString();
    e.telephone     = query.value(3).toString();
    e.adresse       = query.value(4).toString();
    e.dateNaissance = query.value(5).toString();
    e.categorie     = stringToTypePublic(query.value(6).toString());
    e.classeId      = query.value(7).toInt();
    return e;
}

SqliteEleveRepository::SqliteEleveRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Eleve>> SqliteEleveRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT id, nom, prenom, telephone, adresse, date_naissance, categorie, classe_id FROM eleves"))) {
        return Result<QList<Eleve>>::error(query.lastError().text());
    }
    QList<Eleve> list;
    while (query.next()) list.append(rowToEleve(query));
    return Result<QList<Eleve>>::success(list);
}

Result<std::optional<Eleve>> SqliteEleveRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, prenom, telephone, adresse, date_naissance, categorie, classe_id FROM eleves WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Eleve>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Eleve>>::success(rowToEleve(query));
    return Result<std::optional<Eleve>>::success(std::nullopt);
}

Result<int> SqliteEleveRepository::create(const Eleve& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO eleves (nom, prenom, telephone, adresse, date_naissance, categorie, classe_id)"
        " VALUES (?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.prenom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.dateNaissance);
    query.addBindValue(typePublicToString(entity.categorie));
    query.addBindValue(entity.classeId);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteEleveRepository::update(const Eleve& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE eleves SET nom=?, prenom=?, telephone=?, adresse=?, date_naissance=?, categorie=?, classe_id=? WHERE id=?"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.prenom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.dateNaissance);
    query.addBindValue(typePublicToString(entity.categorie));
    query.addBindValue(entity.classeId);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteEleveRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM eleves WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Eleve>> SqliteEleveRepository::getByClasseId(int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, prenom, telephone, adresse, date_naissance, categorie, classe_id FROM eleves WHERE classe_id = ?"));
    query.addBindValue(classeId);
    if (!query.exec()) return Result<QList<Eleve>>::error(query.lastError().text());
    QList<Eleve> list;
    while (query.next()) list.append(rowToEleve(query));
    return Result<QList<Eleve>>::success(list);
}

Result<int> SqliteEleveRepository::countAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT COUNT(*) FROM eleves"))) {
        return Result<int>::error(query.lastError().text());
    }
    query.next();
    return Result<int>::success(query.value(0).toInt());
}

Result<bool> SqliteEleveRepository::unassignClasse(int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE eleves SET classe_id = NULL WHERE classe_id = ?"));
    query.addBindValue(classeId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteEleveRepository::removeFromClasse(int studentId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE eleves SET classe_id = NULL WHERE id = ?"));
    query.addBindValue(studentId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}
