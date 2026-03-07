#pragma once

#include <QString>
#include <QDate>

struct Inscription {
    int id = 0;
    int eleveId = 0;
    QString anneeScolaire;
    int annee_scolaire_id = 0;
    int niveauId = 0;
    int classeId = 0;
    QString resultat = "En cours";
    bool fraisInscriptionPaye = false;
    double montantInscription = 50.0;
    QString dateInscription;
    QString justificatifPath;
};
