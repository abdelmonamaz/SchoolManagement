#pragma once

#include <QString>

#include "repositories/isetup_repository.h"

class SqliteAssociationRepository : public IAssociationRepository {
public:
    explicit SqliteAssociationRepository(const QString& connectionName);

    QVariantMap  getConfig() override;
    Result<bool> saveAssociation(const QVariantMap& data) override;
    Result<bool> markInitialized() override;
    Result<int>  recalculeCategories(int agePassage) override;

private:
    QString m_connectionName;
};

class SqliteSetupSchoolYearRepository : public ISetupSchoolYearRepository {
public:
    explicit SqliteSetupSchoolYearRepository(const QString& connectionName);

    QVariantMap  getActiveYearTarifs() override;
    Result<int>  upsertAnneeScolaire(const QVariantMap& data) override;
    Result<int>  initDraftYear() override;
    Result<int>  finalizeActiveYear(const QVariantMap& data) override;
    Result<bool> linkAllNiveauxToAnnee(int anneeId) override;
    Result<bool> syncTarifs(int anneeId, double tarifJeune, double tarifAdulte) override;
    Result<bool> updateActiveTarifs(const QVariantMap& data) override;
    Result<bool> createDefaultSemestres(int anneeId,
                                        const QString& dateDebut,
                                        const QString& dateFin,
                                        const QString& s1DateFin,
                                        const QString& s2DateDebut) override;
    QVariantList getActiveSemestres() override;

private:
    QString m_connectionName;
};
