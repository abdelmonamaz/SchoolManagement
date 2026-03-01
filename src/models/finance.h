#pragma once

#include <QDate>
#include <QString>

#include "common/enums.h"

struct TarifMensualite {
    int     id            = 0;
    QString categorie;       // "Jeune", "Adulte", …
    QString anneeScolaire;   // "2025-2026"
    double  montant       = 0.0;
};

struct Projet {
    int id = 0;
    QString nom;
    QString description;
    double objectifFinancier = 0.0;
    GS::StatutProjet statut = GS::StatutProjet::EnCours;
};

struct Donateur {
    int     id = 0;
    QString nom;                        // Physique: nom complet ; Morale: raison sociale (copie)
    QString telephone;
    QString adresse;
    // Décret-loi 2011-88 — champs étendus
    QString typePersonne   = "Physique"; // "Physique" | "Morale"
    QString cin;                         // Physique seulement
    QString raisonSociale;               // Morale seulement
    QString matriculeFiscal;             // Morale seulement
    QString representantLegal;           // Morale seulement
};

struct Depense {
    int     id = 0;
    QString libelle;
    double  montant       = 0.0;
    QDate   date;
    QString categorie     = "Autre";  // "Salaires"|"Fournitures"|"Loyer"|"Services"|"Autre"
    QString justificatifPath;
    QString notes;
};

struct Don {
    int     id         = 0;
    int     donateurId = 0;
    int     projetId   = 0;
    double  montant    = 0.0;        // Numéraire
    QDate   dateDon;
    // Nature du don
    QString natureDon           = "Numéraire"; // "Numéraire" | "Nature"
    QString modePaiement        = "Espèces";   // "Espèces" | "Virement" | "Chèque"
    QString descriptionMateriel;               // Nature seulement
    double  valeurEstimee       = 0.0;         // Nature seulement
    QString etatMateriel        = "Neuf";      // "Neuf" | "Occasion"
    QString justificatifPath;                  // chemin fichier local
};
