#pragma once

#include <QList>

#include "repositories/irepository.h"
#include "models/professeur.h"

class IProfesseurRepository : public IRepository<Professeur> {
public:
    ~IProfesseurRepository() override = default;

    virtual Result<QList<TarifProfHistorique>> getTarifHistorique(int profId) = 0;
    virtual Result<int> addTarifHistorique(const TarifProfHistorique& tarif) = 0;
};
