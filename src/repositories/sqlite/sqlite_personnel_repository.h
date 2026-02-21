#pragma once

#include <QString>

#include "repositories/ipersonnel_repository.h"

class SqlitePersonnelRepository : public IPersonnelRepository {
public:
    explicit SqlitePersonnelRepository(const QString& connectionName);

    Result<QList<Professeur>> getAll() override;
    Result<std::optional<Professeur>> getById(int id) override;
    Result<int> create(const Professeur& entity) override;
    Result<bool> update(const Professeur& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<TarifProfHistorique>> getTarifHistorique(int profId) override;
    Result<int> addTarifHistorique(const TarifProfHistorique& tarif) override;

private:
    QString m_connectionName;
};
