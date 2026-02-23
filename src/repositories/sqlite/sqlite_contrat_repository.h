#pragma once

#include <QString>

#include "repositories/icontrat_repository.h"

class SqliteContratRepository : public IContratRepository {
public:
    explicit SqliteContratRepository(const QString& connectionName);

    Result<QList<Contrat>> getByPersonnelId(int personnelId) override;
    Result<std::optional<Contrat>> getActiveContrat(int personnelId, const QDate& date) override;
    Result<QList<Contrat>> getActiveContrats(const QDate& date) override;
    Result<QList<Contrat>> getContratsForPeriod(const QDate& from, const QDate& to) override;
    Result<int> create(const Contrat& contrat) override;
    Result<bool> update(const Contrat& contrat) override;
    Result<bool> closeContrat(int contratId, const QDate& dateFin) override;
    Result<bool> remove(int contratId) override;
    Result<int> countByPersonnelId(int personnelId) override;
    Result<bool> hasOverlap(int personnelId, const QDate& dateDebut, const QDate& dateFin, int excludeContratId = 0) override;

private:
    QString m_connectionName;
};
