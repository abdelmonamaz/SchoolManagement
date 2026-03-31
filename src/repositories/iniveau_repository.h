#pragma once

#include <QList>

#include "repositories/irepository.h"
#include "models/niveau.h"

class INiveauRepository : public IRepository<Niveau> {
public:
    ~INiveauRepository() override = default;

    // Returns all valid niveaux regardless of active year (used during setup wizard).
    virtual Result<QList<Niveau>> getAllGlobal() = 0;

    // Soft-delete a niveau and detach any children pointing to it.
    virtual Result<bool> removeAndDetachChildren(int id) = 0;
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

    // Set semester assignment for a matière.
    // semestreNumero: 0 = toute l'année, 1 = S1, 2 = S2.
    // Looks up the semestreId from the active year's semestres table.
    virtual Result<bool> setMatiereSemestre(int matiereId, int semestreNumero) = 0;
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
