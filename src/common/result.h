#pragma once

#include <QString>
#include <variant>

template<typename T>
class Result {
public:
    static Result success(T value) {
        Result r;
        r.m_data = std::move(value);
        return r;
    }

    static Result error(const QString& message) {
        Result r;
        r.m_data = message;
        return r;
    }

    [[nodiscard]] bool isOk() const {
        return std::holds_alternative<T>(m_data);
    }

    [[nodiscard]] const T& value() const {
        return std::get<T>(m_data);
    }

    [[nodiscard]] T&& take() {
        return std::get<T>(std::move(m_data));
    }

    [[nodiscard]] const QString& errorMessage() const {
        return std::get<QString>(m_data);
    }

private:
    std::variant<T, QString> m_data;
};
