#pragma once

#include "irepository.h"
#include "models/paiement.h"

class IPaiementPersonnelRepository : public IRepository<PaiementMensuelPersonnel> {
public:
    ~IPaiementPersonnelRepository() override = default;

    virtual Result<std::optional<PaiementMensuelPersonnel>>
        getByPersonnelAndMonth(int personnelId, int mois, int annee) = 0;

    virtual Result<QList<PaiementMensuelPersonnel>>
        getByMonth(int mois, int annee) = 0;

    virtual Result<bool> upsert(const PaiementMensuelPersonnel& paiement) = 0;
};
