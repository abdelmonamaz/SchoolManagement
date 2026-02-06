#pragma once

#include <QList>

#include "repositories/irepository.h"
#include "models/niveau.h"

class INiveauRepository : public IRepository<Niveau> {
public:
    ~INiveauRepository() override = default;
};

class IClasseRepository : public IRepository<Classe> {
public:
    ~IClasseRepository() override = default;

    virtual Result<QList<Classe>> getByNiveauId(int niveauId) = 0;
};

class IMatiereRepository : public IRepository<Matiere> {
public:
    ~IMatiereRepository() override = default;

    virtual Result<QList<Matiere>> getByNiveauId(int niveauId) = 0;
};
