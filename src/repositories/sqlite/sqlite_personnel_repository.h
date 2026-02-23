#pragma once

#include <QString>

#include "repositories/ipersonnel_repository.h"

class SqlitePersonnelRepository : public IPersonnelRepository {
public:
    explicit SqlitePersonnelRepository(const QString& connectionName);

    Result<QList<Personnel>> getAll() override;
    Result<std::optional<Personnel>> getById(int id) override;
    Result<int> create(const Personnel& entity) override;
    Result<bool> update(const Personnel& entity) override;
    Result<bool> remove(int id) override;

private:
    QString m_connectionName;
};
