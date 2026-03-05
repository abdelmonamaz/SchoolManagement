#include "repositories/sqlite/sqlite_personnel_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

SqlitePersonnelRepository::SqlitePersonnelRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Personnel>> SqlitePersonnelRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT id, nom, prenom, telephone, adresse, COALESCE(sexe, 'M') FROM personnel WHERE valide = 1"))) {
        return Result<QList<Personnel>>::error(query.lastError().text());
    }

    QList<Personnel> list;
    while (query.next()) {
        Personnel p;
        p.id = query.value(0).toInt();
        p.nom = query.value(1).toString();
        p.prenom = query.value(2).toString();
        p.telephone = query.value(3).toString();
        p.adresse = query.value(4).toString();
        p.sexe = query.value(5).toString();
        list.append(p);
    }
    return Result<QList<Personnel>>::success(list);
}

Result<std::optional<Personnel>> SqlitePersonnelRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, prenom, telephone, adresse, COALESCE(sexe, 'M') FROM personnel WHERE id = ? AND valide = 1"));
    query.addBindValue(id);
    if (!query.exec()) {
        return Result<std::optional<Personnel>>::error(query.lastError().text());
    }

    if (query.next()) {
        Personnel p;
        p.id = query.value(0).toInt();
        p.nom = query.value(1).toString();
        p.prenom = query.value(2).toString();
        p.telephone = query.value(3).toString();
        p.adresse = query.value(4).toString();
        p.sexe = query.value(5).toString();
        return Result<std::optional<Personnel>>::success(p);
    }
    return Result<std::optional<Personnel>>::success(std::nullopt);
}

Result<int> SqlitePersonnelRepository::create(const Personnel& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    // prix_heure_actuel is NOT NULL in legacy schema, provide default 0
    query.prepare(QStringLiteral(
        "INSERT INTO personnel (nom, prenom, telephone, adresse, sexe, prix_heure_actuel) "
        "VALUES (?, ?, ?, ?, ?, 0)"));

    query.addBindValue(entity.nom);
    query.addBindValue(entity.prenom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.sexe);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqlitePersonnelRepository::update(const Personnel& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE personnel SET nom=?, prenom=?, telephone=?, adresse=?, sexe=? , date_modification = datetime('now') WHERE id=?"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.prenom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.sexe);
    query.addBindValue(entity.id);
    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqlitePersonnelRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE personnel SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}
