#pragma once

#include <QDate>

struct PaiementMensualite {
    int id = 0;
    int eleveId = 0;
    double montantPaye = 0.0;
    QDate datePaiement;
    int moisConcerne = 0;
    int anneeConcernee = 0;
};
