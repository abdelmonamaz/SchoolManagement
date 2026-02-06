#pragma once

#include <QObject>

namespace GS {

Q_NAMESPACE

enum class TypePublic {
    Jeune,
    Adulte
};
Q_ENUM_NS(TypePublic)

enum class StatutProf {
    Actif,
    EnConge
};
Q_ENUM_NS(StatutProf)

enum class TypePresence {
    Present,
    Absent,
    Retard
};
Q_ENUM_NS(TypePresence)

enum class CategorieSeance {
    Cours,
    Examen,
    Evenement
};
Q_ENUM_NS(CategorieSeance)

enum class StatutProjet {
    EnCours,
    Termine,
    EnPause
};
Q_ENUM_NS(StatutProjet)

} // namespace GS
