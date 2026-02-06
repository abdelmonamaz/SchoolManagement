#pragma once

#include <QString>

#include "repositories/ifinance_repository.h"

class SqliteProjetRepository : public IProjetRepository {
public:
    explicit SqliteProjetRepository(const QString& connectionName);

    Result<QList<Projet>> getAll() override;
    Result<std::optional<Projet>> getById(int id) override;
    Result<int> create(const Projet& entity) override;
    Result<bool> update(const Projet& entity) override;
    Result<bool> remove(int id) override;

private:
    QString m_connectionName;
};

class SqliteDonateurRepository : public IDonateurRepository {
public:
    explicit SqliteDonateurRepository(const QString& connectionName);

    Result<QList<Donateur>> getAll() override;
    Result<std::optional<Donateur>> getById(int id) override;
    Result<int> create(const Donateur& entity) override;
    Result<bool> update(const Donateur& entity) override;
    Result<bool> remove(int id) override;

private:
    QString m_connectionName;
};

class SqliteDonRepository : public IDonRepository {
public:
    explicit SqliteDonRepository(const QString& connectionName);

    Result<QList<Don>> getAll() override;
    Result<std::optional<Don>> getById(int id) override;
    Result<int> create(const Don& entity) override;
    Result<bool> update(const Don& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<Don>> getByProjetId(int projetId) override;
    Result<double> getTotalByProjet(int projetId) override;

private:
    QString m_connectionName;
};
