#pragma once

#include <QDateTime>

#include "common/enums.h"

struct Seance {
    int id = 0;
    int matiereId = 0;
    int profId = 0;
    int salleId = 0;
    int classeId = 0;
    QDateTime dateHeureDebut;
    int dureeMinutes = 60;
    GS::CategorieSeance typeSeance = GS::CategorieSeance::Cours;
    QString titre;       // used for Examen (titre de l'épreuve) and Événement (nom)
    QString descriptif;  // used for Événement only
    bool presenceValide = false; // true once attendance has been confirmed for this seance
};

struct Participation {
    int id = 0;
    int seanceId = 0;
    int eleveId = 0;
    GS::TypePresence statut = GS::TypePresence::Present;
    double note = -1.0; // -1 = pas de note
    bool estInvite = false;
};
