#pragma once

#include <QDateTime>
#include <QString>

#include "common/enums.h"

struct Personnel {
    int id = 0;
    QString nom;
    QString prenom;
    QString telephone;
    QString adresse;
    QString poste = "Enseignant";             // Enseignant, Administration, Sécurité, Entretien
    QString specialite;                        // Pour les enseignants
    QString modePaie = "Heure";               // Heure ou Fixe
    double valeurBase = 25.0;                 // Prix/heure ou Salaire Mensuel
    bool payePendantVacances = true;          // Payé pendant les vacances
    int heuresTravailes = 0;                  // Heures travaillées ce mois
    GS::StatutProf statut = GS::StatutProf::Actif;
    double prixHeureActuel = 0.0;             // Gardé pour compatibilité
};

struct TarifPersonnelHistorique {
    int id = 0;
    int profId = 0;
    double nouveauPrix = 0.0;
    QDateTime dateChangement;
};
