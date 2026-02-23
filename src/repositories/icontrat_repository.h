#pragma once

#include <QDate>
#include <QList>
#include <optional>

#include "common/result.h"
#include "models/professeur.h"

class IContratRepository {
public:
    virtual ~IContratRepository() = default;

    virtual Result<QList<Contrat>> getByPersonnelId(int personnelId) = 0;
    virtual Result<std::optional<Contrat>> getActiveContrat(int personnelId, const QDate& date) = 0;
    virtual Result<QList<Contrat>> getActiveContrats(const QDate& date) = 0;
    virtual Result<QList<Contrat>> getContratsForPeriod(const QDate& from, const QDate& to) = 0;
    virtual Result<int> create(const Contrat& contrat) = 0;
    virtual Result<bool> update(const Contrat& contrat) = 0;
    virtual Result<bool> closeContrat(int contratId, const QDate& dateFin) = 0;
    virtual Result<bool> remove(int contratId) = 0;
    virtual Result<int> countByPersonnelId(int personnelId) = 0;
    virtual Result<bool> hasOverlap(int personnelId, const QDate& dateDebut, const QDate& dateFin, int excludeContratId = 0) = 0;
};
