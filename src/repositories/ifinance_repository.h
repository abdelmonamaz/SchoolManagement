#pragma once

#include <QList>

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
