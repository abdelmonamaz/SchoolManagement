#pragma once

#include <QString>

#include "repositories/iniveau_repository.h"

class SqliteNiveauRepository : public INiveauRepository {
public:
    explicit SqliteNiveauRepository(QString connectionName);

    Result<QList<Niveau>> getAll() override;
    Result<std::optional<Niveau>> getById(int id) override;
    Result<int> create(const Niveau& entity) override;
    Result<bool> update(const Niveau& entity) override;
    Result<bool> remove(int id) override;

private:
    QString m_connectionName;
};

class SqliteClasseRepository : public IClasseRepository {
public:
    explicit SqliteClasseRepository(QString connectionName);

    Result<QList<Classe>> getAll() override;
    Result<std::optional<Classe>> getById(int id) override;
    Result<int> create(const Classe& entity) override;
    Result<bool> update(const Classe& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<Classe>> getByNiveauId(int niveauId) override;

private:
    QString m_connectionName;
};

class SqliteMatiereRepository : public IMatiereRepository {
public:
    explicit SqliteMatiereRepository(QString connectionName);

    Result<QList<Matiere>> getAll() override;
    Result<std::optional<Matiere>> getById(int id) override;
    Result<int> create(const Matiere& entity) override;
    Result<bool> update(const Matiere& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<Matiere>> getByNiveauId(int niveauId) override;

private:
    QString m_connectionName;
};

class SqliteMatiereExamenRepository : public IMatiereExamenRepository {
public:
    explicit SqliteMatiereExamenRepository(QString connectionName);

    Result<QList<MatiereExamen>> getAll() override;
    Result<std::optional<MatiereExamen>> getById(int id) override;
    Result<int> create(const MatiereExamen& entity) override;
    Result<bool> update(const MatiereExamen& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<MatiereExamen>> getByMatiereId(int matiereId) override;

private:
    QString m_connectionName;
};

class SqliteTypeExamenRepository : public ITypeExamenRepository {
public:
    explicit SqliteTypeExamenRepository(QString connectionName);

    Result<QList<TypeExamen>> getAll() override;
    Result<std::optional<TypeExamen>> getById(int id) override;
    Result<int> create(const TypeExamen& entity) override;
    Result<bool> update(const TypeExamen& entity) override;
    Result<bool> remove(int id) override;

private:
    QString m_connectionName;
};
