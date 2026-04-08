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
    QString cinEleve;
    QString cinParent;
    QString niveauScolaireEducatif; // Niveau dans le système éducatif national (ex: 6ème, CE2, Bac)
    // Populated by repository when loading lists (LEFT JOIN on active school year inscription)
    bool inscritAnneeActive   = false;
    bool fraisPayeAnneeActive = false;
    int  classeId             = 0;
    int  niveauId             = 0;
    int  hallClasseId         = 0;
};
