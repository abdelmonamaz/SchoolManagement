#pragma once

#include <QDate>
#include <QDateTime>
#include <QString>

struct PaiementMensualite {
    int id = 0;
    int eleveId = 0;
    double montantPaye = 0.0;
    QDate datePaiement;
    int moisConcerne = 0;
    int anneeConcernee = 0;
    int anneeScolaireId = 0; // FK → annees_scolaires.id
    QString justificatifPath;
};

struct PaiementMensuelPersonnel {
    int id = 0;
    int personnelId = 0;           // FK → professeur (table personnel/staff)
    int mois = 0;                  // 1-12
    int annee = 0;                 // >= 2000
    double sommeDue = 0.0;         // Montant dû (calculé ou modifié)
    double sommePaye = 0.0;        // Montant réellement payé
    QDateTime dateModification;    // Dernière modification
    QString datePaiement;          // Date du paiement effectif
    QString justificatifPath;      // Justificatif optionnel
};
