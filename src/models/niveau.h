#pragma once

#include <QString>

struct Niveau {
    int id = 0;
    QString nom;
    int parentLevelId = 0;   // 0 = niveau terminal (diplômé) ou racine
    int anneeScolaireId = 0; // FK → annees_scolaires.id (0 = global, non rattaché à une année)
};

struct Classe {
    int id = 0;
    QString nom;
    int niveauId = 0;
};

struct Matiere {
    int id = 0;
    QString nom;
    int niveauId = 0;
    int nombreSeances = 0;
    int dureeSeanceMinutes = 60;
};

struct MatiereExamen {
    int id = 0;
    int matiereId = 0;
    int typeExamenId = 0;
    QString titre; // Fetched from TypeExamen via JOIN
};

struct TypeExamen {
    int id = 0;
    QString titre;
};

struct Equipement {
    int id = 0;
    QString nom;
};
