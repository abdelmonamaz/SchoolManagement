#pragma once

#include <QString>
#include <QDate>

struct Inscription {
    int id = 0;
    int eleveId = 0;
    QString anneeScolaire;
    int niveauId = 0;
    QString resultat = "En cours";
    bool fraisInscriptionPaye = false;
    double montantInscription = 50.0;
    QString dateInscription;
};
