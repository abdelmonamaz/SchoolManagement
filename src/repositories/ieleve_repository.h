#pragma once

#include <QList>

#include "repositories/irepository.h"
#include "models/eleve.h"

class IEleveRepository : public IRepository<Eleve> {
public:
    ~IEleveRepository() override = default;

    virtual Result<QList<Eleve>> getByClasseId(int classeId) = 0;
    virtual Result<int> countAll() = 0;
    virtual Result<bool> unassignClasse(int classeId) = 0;
    virtual Result<bool> removeFromClasse(int studentId) = 0;
};
