#pragma once

#include <QString>

struct Niveau {
    int id = 0;
    QString nom;
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
};

struct Equipement {
    int id = 0;
    QString nom;
};
