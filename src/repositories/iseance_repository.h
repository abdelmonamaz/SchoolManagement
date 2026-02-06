#pragma once

#include <QList>
#include <QDateTime>

#include "repositories/irepository.h"
#include "models/seance.h"

class ISeanceRepository : public IRepository<Seance> {
public:
    ~ISeanceRepository() override = default;

    virtual Result<QList<Seance>> getByDateRange(const QDateTime& from, const QDateTime& to) = 0;
    virtual Result<QList<Seance>> getByClasseId(int classeId) = 0;
};

class IParticipationRepository : public IRepository<Participation> {
public:
    ~IParticipationRepository() override = default;

    virtual Result<QList<Participation>> getBySeanceId(int seanceId) = 0;
    virtual Result<QList<Participation>> getByEleveId(int eleveId) = 0;
};
