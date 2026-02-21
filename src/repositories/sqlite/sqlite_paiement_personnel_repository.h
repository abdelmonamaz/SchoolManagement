#pragma once

#include <QString>
#include "repositories/ipaiement_personnel_repository.h"

class SqlitePaiementPersonnelRepository : public IPaiementPersonnelRepository {
public:
    explicit SqlitePaiementPersonnelRepository(const QString& connectionName);

    Result<QList<PaiementMensuelPersonnel>> getAll() override;
    Result<std::optional<PaiementMensuelPersonnel>> getById(int id) override;
    Result<int> create(const PaiementMensuelPersonnel& entity) override;
    Result<bool> update(const PaiementMensuelPersonnel& entity) override;
    Result<bool> remove(int id) override;

    Result<std::optional<PaiementMensuelPersonnel>>
        getByPersonnelAndMonth(int personnelId, int mois, int annee) override;
    Result<QList<PaiementMensuelPersonnel>>
        getByMonth(int mois, int annee) override;
    Result<bool> upsert(const PaiementMensuelPersonnel& paiement) override;

private:
    QString m_connectionName;
};
