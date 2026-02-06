#pragma once

#include <QString>

#include "repositories/ieleve_repository.h"

class SqliteEleveRepository : public IEleveRepository {
public:
    explicit SqliteEleveRepository(const QString& connectionName);

    Result<QList<Eleve>> getAll() override;
    Result<std::optional<Eleve>> getById(int id) override;
    Result<int> create(const Eleve& entity) override;
    Result<bool> update(const Eleve& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<Eleve>> getByClasseId(int classeId) override;
    Result<int> countAll() override;

private:
    QString m_connectionName;
};
