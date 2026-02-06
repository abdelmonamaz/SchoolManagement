#pragma once

#include <QDateTime>
#include <QString>

#include "common/enums.h"

struct Professeur {
    int id = 0;
    QString nom;
    QString prenom;
    QString telephone;
    QString adresse;
    GS::StatutProf statut = GS::StatutProf::Actif;
    double prixHeureActuel = 0.0;
};

struct TarifProfHistorique {
    int id = 0;
    int profId = 0;
    double nouveauPrix = 0.0;
    QDateTime dateChangement;
};
