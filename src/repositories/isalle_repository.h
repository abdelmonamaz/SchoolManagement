#pragma once

#include "repositories/irepository.h"
#include "models/salle.h"

class ISalleRepository : public IRepository<Salle> {
public:
    ~ISalleRepository() override = default;
};
