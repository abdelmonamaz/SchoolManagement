#pragma once

#include <QList>

#include "repositories/irepository.h"
#include "models/professeur.h"

class IPersonnelRepository : public IRepository<Professeur> {
public:
    ~IPersonnelRepository() override = default;

    virtual Result<QList<TarifProfHistorique>> getTarifHistorique(int profId) = 0;
    virtual Result<int> addTarifHistorique(const TarifProfHistorique& tarif) = 0;
};
