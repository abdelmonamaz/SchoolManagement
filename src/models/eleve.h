#pragma once

#include <QString>

#include "common/enums.h"

struct Eleve {
    int id = 0;
    QString nom;
    QString prenom;
    QString telephone;
    QString adresse;
    QString dateNaissance;  // format ISO : YYYY-MM-DD
    GS::TypePublic categorie = GS::TypePublic::Jeune;
    int classeId = 0;
};
