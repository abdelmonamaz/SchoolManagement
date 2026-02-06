#pragma once

#include <QList>

#include "repositories/irepository.h"
#include "models/paiement.h"

class IPaiementRepository : public IRepository<PaiementMensualite> {
public:
    ~IPaiementRepository() override = default;

    virtual Result<QList<PaiementMensualite>> getByMonth(int month, int year) = 0;
    virtual Result<QList<PaiementMensualite>> getByEleveId(int eleveId) = 0;
};
