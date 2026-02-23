#pragma once

#include <QList>

#include "repositories/irepository.h"
#include "models/professeur.h"

class IPersonnelRepository : public IRepository<Personnel> {
public:
    ~IPersonnelRepository() override = default;
};
