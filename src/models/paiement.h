#pragma once

#include <QDate>
#include <QDateTime>

struct PaiementMensualite {
    int id = 0;
    int eleveId = 0;
    double montantPaye = 0.0;
    QDate datePaiement;
    int moisConcerne = 0;
    int anneeConcernee = 0;
};

struct PaiementMensuelPersonnel {
    int id = 0;
    int personnelId = 0;           // FK → professeur (table personnel/staff)
    int mois = 0;                  // 1-12
    int annee = 0;                 // >= 2000
    double sommeDue = 0.0;         // Montant dû (calculé ou modifié)
    double sommePaye = 0.0;        // Montant réellement payé
    QDateTime dateModification;    // Dernière modification
};
