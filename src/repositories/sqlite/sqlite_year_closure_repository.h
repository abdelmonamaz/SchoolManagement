#pragma once

#include <QString>

#include "repositories/iyear_closure_repository.h"

class SqliteYearClosureRepository : public IYearClosureRepository {
public:
    explicit SqliteYearClosureRepository(const QString& connectionName);

    QVariantMap  loadStats() override;
    QVariantList loadStudentProgressions() override;
    QVariantMap  loadArchivageStats() override;
    Result<bool> executeYearClosure(const QString& newLabel,
                                    const QString& dateDebut,
                                    const QString& dateFin,
                                    const QVariantList& progressions) override;

private:
    QString m_connectionName;
};
