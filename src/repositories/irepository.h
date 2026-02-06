#pragma once

#include <QList>
#include <optional>

#include "common/result.h"

template<typename T>
class IRepository {
public:
    virtual ~IRepository() = default;

    virtual Result<QList<T>> getAll() = 0;
    virtual Result<std::optional<T>> getById(int id) = 0;
    virtual Result<int> create(const T& entity) = 0;
    virtual Result<bool> update(const T& entity) = 0;
    virtual Result<bool> remove(int id) = 0;
};
