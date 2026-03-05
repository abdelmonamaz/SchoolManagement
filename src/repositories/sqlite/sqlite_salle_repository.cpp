#include "repositories/sqlite/sqlite_salle_repository.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>

SqliteSalleRepository::SqliteSalleRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<Salle>> SqliteSalleRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    if (!query.exec("SELECT id, nom, capacite_chaises, equipement FROM salles WHERE valide = 1")) {
        return Result<QList<Salle>>::error(query.lastError().text());
    }

    QList<Salle> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .capaciteChaises = query.value(2).toInt(),
            .equipement = query.value(3).toString()
        });
    }
    return Result<QList<Salle>>::success(std::move(list));
}

Result<std::optional<Salle>> SqliteSalleRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom, capacite_chaises, equipement FROM salles WHERE id = ? AND valide = 1");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<std::optional<Salle>>::error(query.lastError().text());
    }

    if (!query.next()) {
        return Result<std::optional<Salle>>::success(std::nullopt);
    }

    return Result<std::optional<Salle>>::success(Salle{
        .id = query.value(0).toInt(),
        .nom = query.value(1).toString(),
        .capaciteChaises = query.value(2).toInt(),
        .equipement = query.value(3).toString()
    });
}

Result<int> SqliteSalleRepository::create(const Salle& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO salles (nom, capacite_chaises, equipement) VALUES (?, ?, ?)");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.capaciteChaises);
    query.addBindValue(entity.equipement);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteSalleRepository::update(const Salle& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE salles SET nom = ?, capacite_chaises = ?, equipement = ? , date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.capaciteChaises);
    query.addBindValue(entity.equipement);
    query.addBindValue(entity.id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteSalleRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE salles SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}
