#pragma once

#include <QVariantList>
#include <QVariantMap>

#include "common/result.h"

// ── Association & global config ───────────────────────────────────────────────
// Wraps association_config table + eleves.categorie recalculation.
class IAssociationRepository {
public:
    virtual ~IAssociationRepository() = default;

    // Returns {initialized:bool, associationData:{nomAssociation, adresse,
    //          exerciceDebut, exerciceFin, agePassageAdulte}}
    virtual QVariantMap getConfig() = 0;

    // UPDATE association_config fields; data keys: nomAssociation, adresse,
    // exerciceDebut, exerciceFin, agePassageAdulte
    virtual Result<bool> saveAssociation(const QVariantMap& data) = 0;

    // SET app_initialized = 1
    virtual Result<bool> markInitialized() = 0;

    // UPDATE eleves.categorie based on age threshold; returns affected row count
    virtual Result<int> recalculeCategories(int agePassage) = 0;
};

// ── School-year setup operations ─────────────────────────────────────────────
// Wraps annees_scolaires + tarifs_mensualites + semestres
// operations specific to the setup/settings flow.
class ISetupSchoolYearRepository {
public:
    virtual ~ISetupSchoolYearRepository() = default;

    // Returns active year tarifs {id, libelle, tarifJeune, tarifAdulte,
    //   fraisInscriptionJeune, fraisInscriptionAdulte, dateDebut, dateFin}
    // or empty map if no active year.
    virtual QVariantMap getActiveYearTarifs() = 0;

    // INSERT OR REPLACE annees_scolaires from data:
    //   {libelle, dateDebut, dateFin, tarifJeune, tarifAdulte,
    //    fraisInscriptionJeune, fraisInscriptionAdulte}
    // Returns id of the created/updated row.
    virtual Result<int> upsertAnneeScolaire(const QVariantMap& data) = 0;

    // Creates a provisional Active year with default Sep–Jun dates if none exists.
    // Returns the id of the existing or newly created row.
    // Called when the user advances from step 1 → step 2 of the setup wizard so
    // that niveaux created in step 2 auto-link via niveaux.annee_scolaire_id.
    virtual Result<int> initDraftYear() = 0;

    // UPDATE the current Active year with final details from step 3.
    // Falls back to INSERT if no active year exists.
    // data keys: libelle, dateDebut, dateFin, tarifJeune, tarifAdulte,
    //            fraisInscriptionJeune, fraisInscriptionAdulte
    virtual Result<int> finalizeActiveYear(const QVariantMap& data) = 0;

    // INSERT OR IGNORE all valid niveaux into niveaux_actifs_par_annee for anneeId.
    virtual Result<bool> linkAllNiveauxToAnnee(int anneeId) = 0;

    // INSERT OR REPLACE tarifs_mensualites (Jeune, Adulte) for anneeId.
    virtual Result<bool> syncTarifs(int anneeId, double tarifJeune, double tarifAdulte) = 0;

    // UPDATE active annees_scolaires tarifs + sync tarifs_mensualites.
    // data keys: tarifJeune, tarifAdulte, fraisInscriptionJeune, fraisInscriptionAdulte
    virtual Result<bool> updateActiveTarifs(const QVariantMap& data) = 0;

    // INSERT OR IGNORE two semestre rows for anneeId.
    // S1: dateDebut → s1DateFin (default: Jan 14 of following year if empty).
    // S2: s2DateDebut (default: Jan 15 of following year if empty) → dateFin.
    // Idempotent via UNIQUE(annee_scolaire_id, numero).
    virtual Result<bool> createDefaultSemestres(int anneeId,
                                                const QString& dateDebut,
                                                const QString& dateFin,
                                                const QString& s1DateFin,
                                                const QString& s2DateDebut) = 0;

    // Returns list of {id, numero, nom, dateDebut, dateFin} for the active year's semestres.
    virtual QVariantList getActiveSemestres() = 0;
};
