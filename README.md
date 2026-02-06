# Ez-Zaytouna — Gestion Scolaire (QML)

Application de gestion scolaire complète en **Qt/QML**, convertie depuis le design Figma / React original.

## 📁 Structure du Projet

```
qml_project/
├── CMakeLists.txt              # Configuration CMake (Qt6)
├── resources.qrc               # Fichier de ressources Qt
├── src/
│   └── main.cpp                # Point d'entrée C++
└── qml/
    ├── main.qml                # Fenêtre principale + Sidebar + Header + Navigation
    ├── components/             # Composants réutilisables
    │   ├── qmldir              # Déclaration du module
    │   ├── Style.qml           # Singleton : couleurs, rayons, constantes
    │   ├── SidebarButton.qml   # Bouton de navigation latérale
    │   ├── IconLabel.qml       # Icônes Unicode (remplacement Lucide)
    │   ├── IconButton.qml      # Bouton icône avec hover
    │   ├── AppCard.qml         # Carte avec titre, sous-titre, actions
    │   ├── Badge.qml           # Badge coloré (success/warning/error/info)
    │   ├── StatCard.qml        # Carte statistique avec icône et tendance
    │   ├── PageHeader.qml      # En-tête de page (titre + sous-titre)
    │   ├── PrimaryButton.qml   # Bouton principal vert
    │   ├── OutlineButton.qml   # Bouton avec bordure
    │   ├── TabBar_.qml         # Barre d'onglets personnalisée
    │   ├── SearchField.qml     # Champ de recherche
    │   ├── ProgressBar_.qml    # Barre de progression animée
    │   ├── SimpleBarChart.qml  # Graphique en barres (Canvas)
    │   └── SimpleAreaChart.qml # Graphique en aires (Canvas)
    └── pages/                  # Pages de l'application
        ├── qmldir
        ├── DashboardPage.qml   # Tableau de bord (stats, graphiques, activité)
        ├── SchoolingPage.qml   # Scolarité & Niveaux (matières, enseignants)
        ├── StudentsPage.qml    # Annuaire étudiants (liste + fiche détaillée)
        ├── ExamsPage.qml       # Examens & Planning (calendrier, salles)
        ├── FinancePage.qml     # Finance (paiements, dons, dépenses, journal)
        ├── GradesPage.qml      # Saisie des Notes (grille, progression)
        └── SettingsPage.qml    # Paramètres du système
```

## 🎨 Design System

| Élément          | Couleur     | Usage                          |
|------------------|-------------|--------------------------------|
| Primary          | `#3D5A45`   | Boutons, accents, sidebar      |
| Primary Dark     | `#2D4233`   | Hover sur boutons              |
| Primary Light    | `#86A38E`   | Barres secondaires (charts)    |
| Background       | `#F9FAFB`   | Fond de page                   |
| Text Primary     | `#1E293B`   | Texte principal                |
| Text Secondary   | `#6B7280`   | Texte secondaire               |
| Success          | `#059669`   | Statut validé, payé            |
| Warning          | `#D97706`   | Alertes, en attente            |
| Error            | `#EF4444`   | Erreurs, impayés               |

## 🔧 Prérequis

- **Qt 6.5+** (ou Qt 5.15+ avec adaptations mineures)
- **CMake 3.16+**
- Compilateur C++17

## 🚀 Compilation & Exécution

```bash
# Avec CMake
mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x
cmake --build .
./GestionScolaire

# OU développement rapide avec qml
cd qml_project
qml qml/main.qml
```

## 📋 Correspondance React → QML

| React (TSX)                | QML Équivalent                    |
|----------------------------|-----------------------------------|
| `<Dashboard />`           | `DashboardPage.qml`              |
| `<Schooling />`           | `SchoolingPage.qml`              |
| `<Students />`            | `StudentsPage.qml`               |
| `<Exams />`               | `ExamsPage.qml`                  |
| `<Finance />`             | `FinancePage.qml`                |
| `<Grades />`              | `GradesPage.qml`                 |
| `<SettingsScreen />`      | `SettingsPage.qml`               |
| `<Card />`                | `AppCard.qml`                    |
| `<Badge />`               | `Badge.qml`                      |
| Lucide React icons        | `IconLabel.qml` (Unicode)        |
| Recharts BarChart          | `SimpleBarChart.qml` (Canvas)    |
| Recharts AreaChart         | `SimpleAreaChart.qml` (Canvas)   |
| Tailwind classes           | `Style.qml` singleton            |
| Framer Motion animations   | QML `Behavior` + `NumberAnimation`|
| React `useState`           | QML `property`                   |
| React Router / tabs        | `Loader` + `source` switching    |

## 📝 Notes

- Les **icônes** utilisent des symboles Unicode au lieu de Lucide React. Pour une meilleure
  qualité, remplacez par des icônes SVG ou Font Awesome dans `IconLabel.qml`.
- Les **graphiques** sont rendus avec `Canvas` QML pur — pas de dépendance externe.
- La **navigation** utilise un `Loader` avec transition en opacité pour simuler les animations
  de Framer Motion.
- Le projet est prêt pour l'intégration d'un backend C++ (modèles, base de données SQLite, etc).
