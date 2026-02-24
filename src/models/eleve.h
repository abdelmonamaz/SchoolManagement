#pragma once

#include <QString>

#include "common/enums.h"

struct Eleve {
    int id = 0;
    QString nom;
    QString prenom;
    QString sexe = "M";
    QString telephone;
    QString adresse;
    QString dateNaissance;  // format ISO : YYYY-MM-DD
    QString nomParent;
    QString telParent;
    QString commentaire;
    GS::TypePublic categorie = GS::TypePublic::Jeune;
    int classeId = 0;
};
