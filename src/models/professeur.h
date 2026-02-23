#pragma once

#include <QDate>
#include <QDateTime>
#include <QString>

struct Personnel {
    int id = 0;
    QString nom;
    QString prenom;
    QString telephone;
    QString adresse;
    QString sexe = "M";  // "M" ou "F"
};

struct Contrat {
    int id = 0;
    int personnelId = 0;
    QString poste = "Enseignant";       // Enseignant, Administration, Sécurité, Entretien
    QString specialite;                  // Pour les enseignants
    QString modePaie = "Heure";         // "Heure" ou "Fixe"
    double valeurBase = 25.0;           // DT/h ou DT/mois
    QDate dateDebut;                    // Début de validité
    QDate dateFin;                      // Fin de validité (null/invalid = en cours)
};
