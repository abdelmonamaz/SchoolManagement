#include "repositories/sqlite/sqlite_equipement_repository.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>

SqliteEquipementRepository::SqliteEquipementRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<Equipement>> SqliteEquipementRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    if (!query.exec("SELECT id, nom FROM equipements")) {
        return Result<QList<Equipement>>::error(query.lastError().text());
    }

    QList<Equipement> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString()
        });
    }
    return Result<QList<Equipement>>::success(std::move(list));
}

Result<std::optional<Equipement>> SqliteEquipementRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom FROM equipements WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<std::optional<Equipement>>::error(query.lastError().text());
    }
    if (!query.next()) {
        return Result<std::optional<Equipement>>::success(std::nullopt);
    }
    return Result<std::optional<Equipement>>::success(Equipement{
        .id = query.value(0).toInt(),
        .nom = query.value(1).toString()
    });
}

Result<int> SqliteEquipementRepository::create(const Equipement& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO equipements (nom) VALUES (?)");
    query.addBindValue(entity.nom);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteEquipementRepository::update(const Equipement& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE equipements SET nom = ? WHERE id = ?");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteEquipementRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("DELETE FROM equipements WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}
