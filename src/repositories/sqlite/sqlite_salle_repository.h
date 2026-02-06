#pragma once

#include <QString>

#include "repositories/isalle_repository.h"

class SqliteSalleRepository : public ISalleRepository {
public:
    explicit SqliteSalleRepository(QString connectionName);

    Result<QList<Salle>> getAll() override;
    Result<std::optional<Salle>> getById(int id) override;
    Result<int> create(const Salle& entity) override;
    Result<bool> update(const Salle& entity) override;
    Result<bool> remove(int id) override;

private:
    QString m_connectionName;
};
