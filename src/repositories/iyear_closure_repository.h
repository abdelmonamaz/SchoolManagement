#pragma once

#include <QVariantList>
#include <QVariantMap>

#include "common/result.h"

// Aggregated queries for the year-closure workflow.
// All methods execute complex multi-table SQL.
class IYearClosureRepository {
public:
    virtual ~IYearClosureRepository() = default;

    // Returns {stats:{anneeActiveId, anneeActiveLibelle, studentsInscrits,
    //           tauxReussite, diplomes, redoublants, enCours},
    //          sessions:[{id,titre,type,date},...]}
    // or {empty:true} if no active year.
    virtual QVariantMap loadStats() = 0;

    // Returns list of {inscriptionId, eleveId, nom, prenom, categorie,
    //   niveauActuelId, niveauActuelNom, resultat, niveauxSuivants, moyenneAnnuelle}
    virtual QVariantList loadStudentProgressions() = 0;

    // Returns archivage stats {coursTotal, coursValides, examensTotal,
    //   examensAvecNotes, tauxPresenceGlobal, matieres:[...]}
    virtual QVariantMap loadArchivageStats() = 0;

    // Executes the full year closure in a single DB transaction.
    // progressions: list of {inscriptionId, eleveId, niveauActuelId,
    //                        categorie, resultat, niveauSuivantId}
    virtual Result<bool> executeYearClosure(const QString& newLabel,
                                            const QString& dateDebut,
                                            const QString& dateFin,
                                            const QVariantList& progressions) = 0;
};
