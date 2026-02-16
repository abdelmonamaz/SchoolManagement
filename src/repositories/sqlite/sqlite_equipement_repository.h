#pragma once

#include <QString>

#include "repositories/iniveau_repository.h"

class SqliteEquipementRepository : public IEquipementRepository {
public:
    explicit SqliteEquipementRepository(QString connectionName);

    Result<QList<Equipement>> getAll() override;
    Result<std::optional<Equipement>> getById(int id) override;
    Result<int> create(const Equipement& entity) override;
    Result<bool> update(const Equipement& entity) override;
    Result<bool> remove(int id) override;

private:
    QString m_connectionName;
};
