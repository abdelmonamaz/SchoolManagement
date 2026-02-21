#pragma once

#include <QList>

#include "repositories/irepository.h"
#include "models/professeur.h"

class IPersonnelRepository : public IRepository<Personnel> {
public:
    ~IPersonnelRepository() override = default;

    virtual Result<QList<TarifPersonnelHistorique>> getTarifHistorique(int profId) = 0;
    virtual Result<int> addTarifHistorique(const TarifPersonnelHistorique& tarif) = 0;
};
