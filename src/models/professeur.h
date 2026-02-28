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
    QString modePaie = "Heure";         // "Heure" | "Jour" | "Fixe"
    double valeurBase = 25.0;           // DT/h, DT/jour ou DT/mois selon modePaie
    int joursTravail = 31;              // bitmask Lun-Dim : bit0=Lun..bit6=Dim, défaut 31=Lun-Ven
    QDate dateDebut;                    // Début de validité
    QDate dateFin;                      // Fin de validité (null/invalid = en cours)
};
