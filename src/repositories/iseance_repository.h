#pragma once

#include <QList>
#include <QDate>
#include <QDateTime>
#include <QStringList>

#include "repositories/irepository.h"
#include "models/seance.h"

class ISeanceRepository : public IRepository<Seance> {
public:
    ~ISeanceRepository() override = default;

    virtual Result<QList<Seance>> getByDateRange(const QDateTime& from, const QDateTime& to) = 0;
    virtual Result<QList<Seance>> getByClasseId(int classeId) = 0;
    virtual Result<int> getTotalMinutesByProf(int profId, const QDate& from, const QDate& to) = 0;

    // Conflict detection: returns list of conflict descriptions, empty if no conflicts
    virtual Result<QStringList> checkConflicts(const Seance& seance, int excludeSeanceId = 0) = 0;

    // Mark attendance as validated / unvalidated for a seance
    virtual Result<bool> setPresenceValide(int seanceId, bool valide) = 0;
};

class IParticipationRepository : public IRepository<Participation> {
public:
    ~IParticipationRepository() override = default;

    virtual Result<QList<Participation>> getBySeanceId(int seanceId) = 0;
    virtual Result<QList<Participation>> getByEleveId(int eleveId) = 0;
};
