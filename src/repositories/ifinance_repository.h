#pragma once

#include <QList>
#include <QVariantMap>

#include "repositories/irepository.h"
#include "models/finance.h"

class IProjetRepository : public IRepository<Projet> {
public:
    ~IProjetRepository() override = default;
};

class IDonateurRepository : public IRepository<Donateur> {
public:
    ~IDonateurRepository() override = default;
};

class IDonRepository : public IRepository<Don> {
public:
    ~IDonRepository() override = default;

    virtual Result<QList<Don>> getByProjetId(int projetId) = 0;
    virtual Result<double> getTotalByProjet(int projetId) = 0;
};

class IDepenseRepository : public IRepository<Depense> {
public:
    ~IDepenseRepository() override = default;
    virtual Result<QList<Depense>> getByMonth(int month, int year) = 0;
};

class ITarifMensualiteRepository {
public:
    virtual ~ITarifMensualiteRepository() = default;

    virtual Result<QList<TarifMensualite>> getAll() = 0;
    virtual Result<QList<TarifMensualite>> getByYear(const QString& anneeScolaireLibelle) = 0;
    virtual Result<QList<TarifMensualite>> getByYearId(int anneeScolaireId) = 0;
};

// Agrégats financiers multi-tables : bilan, exercice comptable
class IFinanceBalanceRepository {
public:
    virtual ~IFinanceBalanceRepository() = default;

    // Bilan filtré par année (yearFilter = "YYYY", ou vide = toutes années)
    virtual QVariantMap computeBalance(const QString& yearFilter) = 0;

    // Bilan sur une plage de dates ISO (YYYY-MM-DD)
    virtual QVariantMap computeBalanceForRange(const QString& dateFrom, const QString& dateTo) = 0;

    // Lit {exerciceDebut, exerciceFin} depuis association_config
    virtual QVariantMap getExerciceConfig() = 0;
};
