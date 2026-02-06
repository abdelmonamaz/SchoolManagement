#pragma once

#include <QDate>
#include <QString>

#include "common/enums.h"

struct Projet {
    int id = 0;
    QString nom;
    QString description;
    double objectifFinancier = 0.0;
    GS::StatutProjet statut = GS::StatutProjet::EnCours;
};

struct Donateur {
    int id = 0;
    QString nom;
    QString telephone;
    QString adresse;
};

struct Don {
    int id = 0;
    int donateurId = 0;
    int projetId = 0;
    double montant = 0.0;
    QDate dateDon;
};
