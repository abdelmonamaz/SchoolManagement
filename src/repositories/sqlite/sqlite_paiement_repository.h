#pragma once

#include <QString>

#include "repositories/ipaiement_repository.h"

class SqlitePaiementRepository : public IPaiementRepository {
public:
    explicit SqlitePaiementRepository(const QString& connectionName);

    Result<QList<PaiementMensualite>> getAll() override;
    Result<std::optional<PaiementMensualite>> getById(int id) override;
    Result<int> create(const PaiementMensualite& entity) override;
    Result<bool> update(const PaiementMensualite& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<PaiementMensualite>> getByMonth(int month, int year) override;
    Result<QList<PaiementMensualite>> getByEleveId(int eleveId) override;

private:
    QString m_connectionName;
};
