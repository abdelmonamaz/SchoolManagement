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
    virtual Result<bool> update(const Matiere& entity) = 0;
};

class IMatiereExamenRepository : public IRepository<MatiereExamen> {
public:
    ~IMatiereExamenRepository() override = default;

    virtual Result<QList<MatiereExamen>> getByMatiereId(int matiereId) = 0;
};

class ITypeExamenRepository : public IRepository<TypeExamen> {
public:
    ~ITypeExamenRepository() override = default;
};

class IEquipementRepository : public IRepository<Equipement> {
public:
    ~IEquipementRepository() override = default;
};
