#include "repositories/sqlite/sqlite_niveau_repository.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>

// --- SqliteNiveauRepository ---

SqliteNiveauRepository::SqliteNiveauRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<Niveau>> SqliteNiveauRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    if (!query.exec("SELECT id, nom FROM niveaux")) {
        return Result<QList<Niveau>>::error(query.lastError().text());
    }

    QList<Niveau> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString()
        });
    }
    return Result<QList<Niveau>>::success(std::move(list));
}

Result<std::optional<Niveau>> SqliteNiveauRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom FROM niveaux WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<std::optional<Niveau>>::error(query.lastError().text());
    }
    if (!query.next()) {
        return Result<std::optional<Niveau>>::success(std::nullopt);
    }
    return Result<std::optional<Niveau>>::success(Niveau{
        .id = query.value(0).toInt(),
        .nom = query.value(1).toString()
    });
}

Result<int> SqliteNiveauRepository::create(const Niveau& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO niveaux (nom) VALUES (?)");
    query.addBindValue(entity.nom);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteNiveauRepository::update(const Niveau& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE niveaux SET nom = ? WHERE id = ?");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteNiveauRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("DELETE FROM niveaux WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

// --- SqliteClasseRepository ---

SqliteClasseRepository::SqliteClasseRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<Classe>> SqliteClasseRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    if (!query.exec("SELECT id, nom, niveau_id FROM classes")) {
        return Result<QList<Classe>>::error(query.lastError().text());
    }

    QList<Classe> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .niveauId = query.value(2).toInt()
        });
    }
    return Result<QList<Classe>>::success(std::move(list));
}

Result<std::optional<Classe>> SqliteClasseRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom, niveau_id FROM classes WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<std::optional<Classe>>::error(query.lastError().text());
    }
    if (!query.next()) {
        return Result<std::optional<Classe>>::success(std::nullopt);
    }
    return Result<std::optional<Classe>>::success(Classe{
        .id = query.value(0).toInt(),
        .nom = query.value(1).toString(),
        .niveauId = query.value(2).toInt()
    });
}

Result<int> SqliteClasseRepository::create(const Classe& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO classes (nom, niveau_id) VALUES (?, ?)");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.niveauId);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteClasseRepository::update(const Classe& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE classes SET nom = ?, niveau_id = ? WHERE id = ?");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteClasseRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("DELETE FROM classes WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<QList<Classe>> SqliteClasseRepository::getByNiveauId(int niveauId)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom, niveau_id FROM classes WHERE niveau_id = ?");
    query.addBindValue(niveauId);

    if (!query.exec()) {
        return Result<QList<Classe>>::error(query.lastError().text());
    }

    QList<Classe> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .niveauId = query.value(2).toInt()
        });
    }
    return Result<QList<Classe>>::success(std::move(list));
}

// --- SqliteMatiereRepository ---

SqliteMatiereRepository::SqliteMatiereRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<Matiere>> SqliteMatiereRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    if (!query.exec("SELECT id, nom, niveau_id, nombre_seances, duree_seance_minutes FROM matieres")) {
        return Result<QList<Matiere>>::error(query.lastError().text());
    }

    QList<Matiere> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .niveauId = query.value(2).toInt(),
            .nombreSeances = query.value(3).toInt(),
            .dureeSeanceMinutes = query.value(4).toInt()
        });
    }
    return Result<QList<Matiere>>::success(std::move(list));
}

Result<std::optional<Matiere>> SqliteMatiereRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom, niveau_id, nombre_seances, duree_seance_minutes FROM matieres WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<std::optional<Matiere>>::error(query.lastError().text());
    }
    if (!query.next()) {
        return Result<std::optional<Matiere>>::success(std::nullopt);
    }
    return Result<std::optional<Matiere>>::success(Matiere{
        .id = query.value(0).toInt(),
        .nom = query.value(1).toString(),
        .niveauId = query.value(2).toInt(),
        .nombreSeances = query.value(3).toInt(),
        .dureeSeanceMinutes = query.value(4).toInt()
    });
}

Result<int> SqliteMatiereRepository::create(const Matiere& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO matieres (nom, niveau_id, nombre_seances, duree_seance_minutes) VALUES (?, ?, ?, ?)");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.nombreSeances);
    query.addBindValue(entity.dureeSeanceMinutes);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteMatiereRepository::update(const Matiere& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE matieres SET nom = ?, niveau_id = ?, nombre_seances = ?, duree_seance_minutes = ? WHERE id = ?");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.nombreSeances);
    query.addBindValue(entity.dureeSeanceMinutes);
    query.addBindValue(entity.id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteMatiereRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("DELETE FROM matieres WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<QList<Matiere>> SqliteMatiereRepository::getByNiveauId(int niveauId)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom, niveau_id, nombre_seances, duree_seance_minutes FROM matieres WHERE niveau_id = ?");
    query.addBindValue(niveauId);

    if (!query.exec()) {
        return Result<QList<Matiere>>::error(query.lastError().text());
    }

    QList<Matiere> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .niveauId = query.value(2).toInt(),
            .nombreSeances = query.value(3).toInt(),
            .dureeSeanceMinutes = query.value(4).toInt()
        });
    }
    return Result<QList<Matiere>>::success(std::move(list));
}

// --- SqliteMatiereExamenRepository ---

SqliteMatiereExamenRepository::SqliteMatiereExamenRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<MatiereExamen>> SqliteMatiereExamenRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec("SELECT id, matiere_id, titre FROM matiere_examens ORDER BY id"))
        return Result<QList<MatiereExamen>>::error(query.lastError().text());
    QList<MatiereExamen> list;
    while (query.next())
        list.append({ .id = query.value(0).toInt(), .matiereId = query.value(1).toInt(), .titre = query.value(2).toString() });
    return Result<QList<MatiereExamen>>::success(std::move(list));
}

Result<std::optional<MatiereExamen>> SqliteMatiereExamenRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, matiere_id, titre FROM matiere_examens WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<MatiereExamen>>::error(query.lastError().text());
    if (!query.next()) return Result<std::optional<MatiereExamen>>::success(std::nullopt);
    return Result<std::optional<MatiereExamen>>::success(MatiereExamen{
        .id = query.value(0).toInt(), .matiereId = query.value(1).toInt(), .titre = query.value(2).toString()
    });
}

Result<int> SqliteMatiereExamenRepository::create(const MatiereExamen& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO matiere_examens (matiere_id, titre) VALUES (?, ?)");
    query.addBindValue(entity.matiereId);
    query.addBindValue(entity.titre);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteMatiereExamenRepository::update(const MatiereExamen& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE matiere_examens SET titre = ? WHERE id = ?");
    query.addBindValue(entity.titre);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteMatiereExamenRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("DELETE FROM matiere_examens WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<MatiereExamen>> SqliteMatiereExamenRepository::getByMatiereId(int matiereId)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, matiere_id, titre FROM matiere_examens WHERE matiere_id = ? ORDER BY id");
    query.addBindValue(matiereId);
    if (!query.exec()) return Result<QList<MatiereExamen>>::error(query.lastError().text());
    QList<MatiereExamen> list;
    while (query.next())
        list.append({ .id = query.value(0).toInt(), .matiereId = query.value(1).toInt(), .titre = query.value(2).toString() });
    return Result<QList<MatiereExamen>>::success(std::move(list));
}
