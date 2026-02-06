#pragma once

#include <QString>

#include "repositories/iseance_repository.h"

class SqliteSeanceRepository : public ISeanceRepository {
public:
    explicit SqliteSeanceRepository(const QString& connectionName);

    Result<QList<Seance>> getAll() override;
    Result<std::optional<Seance>> getById(int id) override;
    Result<int> create(const Seance& entity) override;
    Result<bool> update(const Seance& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<Seance>> getByDateRange(const QDateTime& from, const QDateTime& to) override;
    Result<QList<Seance>> getByClasseId(int classeId) override;

private:
    QString m_connectionName;
};

class SqliteParticipationRepository : public IParticipationRepository {
public:
    explicit SqliteParticipationRepository(const QString& connectionName);

    Result<QList<Participation>> getAll() override;
    Result<std::optional<Participation>> getById(int id) override;
    Result<int> create(const Participation& entity) override;
    Result<bool> update(const Participation& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<Participation>> getBySeanceId(int seanceId) override;
    Result<QList<Participation>> getByEleveId(int eleveId) override;

private:
    QString m_connectionName;
};
