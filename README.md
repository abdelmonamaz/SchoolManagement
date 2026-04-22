# Ez-Zaytouna — Gestion Scolaire (Qt6/QML)

Application de gestion scolaire complète pour l'association d'éducation culturelle (Ezzaytouna), développée en **Qt6/QML et C++23**.  
Gestion intégrée des élèves, cours, séances, personnel, examens, notes et finances avec base de données SQLite.

## 🎯 Fonctionnalités

- 👥 **Gestion des Élèves** : Annuaire, dossiers, fiche détaillée, inscriptions
- 📚 **Gestion Scolaire** : Niveaux, salles, équipements, matières, scolarité
- 👨‍🏫 **Personnel** : Gestion des professeurs, contrats, affectations, rémunération
- 📝 **Séances** : Planification et suivi des cours, présences
- 📊 **Examens** : Planning, salles d'examen, organisation, types d'épreuves
- 📋 **Grades** : Saisie des notes, génération bulletins (DOCX), moyennes
- 💰 **Finance** : Paiements élèves, rémunération personnel, dons, bilan comptable, journal
- 📈 **Dashboard** : Statistiques et visualisations en temps réel
- 🌍 **Multilingue** : Support de l'arabe (ar_AE) en cours
- 💾 **Sauvegarde** : Backup automatique/manuel de la base de données
- 📅 **Clôture d'Année** : Gestion des fermetures d'année scolaire

## 📁 Arborescence du Projet

```
qml_project/
├── .gitignore                          # Fichiers ignorés par Git
├── .qtcreator/                         # Configuration Qt Creator
├── .claude/                            # Configuration Copilot/Claude
├── CMakeLists.txt                      # Configuration CMake (Qt6)
├── CMakeLists.txt.user                 # Paramètres utilisateur Qt Creator
├── build_installer.ps1                 # Script PowerShell génération installeur
├── installer.iss                       # Configuration Inno Setup
├── logo.ico & logo.png                 # Logo application
├── README.md                           # Documentation (ce fichier)
│
├── src/                                # CODE SOURCE C++ (~150 fichiers)
│   ├── main.cpp                        # Point d'entrée application
│   ├── app/
│   │   ├── app_controller.h/cpp        # Contrôleur principal
│   ├── common/                         # Utilities partagées
│   │   ├── enums.h                     # Énumérations métier
│   │   └── result.h                    # Classe Result<T>
│   ├── models/                         # Modèles données (8 classes)
│   │   ├── eleve.h                     # Élève
│   │   ├── finance.h                   # Transactions financières
│   │   ├── inscription.h               # Inscriptions élèves
│   │   ├── niveau.h                    # Niveaux/Classes
│   │   ├── paiement.h                  # Paiements
│   │   ├── professeur.h                # Professeurs
│   │   ├── salle.h                     # Salles de classe
│   │   └── seance.h                    # Séances de cours
│   │
│   ├── repositories/                   # Interfaces Data Access (12)
│   │   ├── irepository.h               # Interface base
│   │   ├── isalle_repository.h
│   │   ├── ieleve_repository.h
│   │   ├── iniveau_repository.h
│   │   ├── ipersonnel_repository.h
│   │   ├── icontrat_repository.h
│   │   ├── iseance_repository.h
│   │   ├── ipaiement_repository.h
│   │   ├── ipaiement_personnel_repository.h
│   │   ├── ifinance_repository.h
│   │   ├── isetup_repository.h
│   │   └── iyear_closure_repository.h
│   │
│   ├── repositories/sqlite/            # Implémentations SQLite (15 paires h/cpp)
│   │   ├── sqlite_salle_repository.*
│   │   ├── sqlite_eleve_repository.*
│   │   ├── sqlite_niveau_repository.*
│   │   ├── sqlite_personnel_repository.*
│   │   ├── sqlite_contrat_repository.*
│   │   ├── sqlite_equipement_repository.*
│   │   ├── sqlite_seance_repository.*
│   │   ├── sqlite_paiement_repository.*
│   │   ├── sqlite_paiement_personnel_repository.*
│   │   ├── sqlite_finance_repository.*
│   │   ├── sqlite_setup_repository.*
│   │   └── sqlite_year_closure_repository.*
│   │
│   ├── services/                       # Services métier (7)
│   │   ├── schooling_service.h/cpp     # Scolarité
│   │   ├── student_service.h/cpp       # Élèves
│   │   ├── staff_service.h/cpp         # Personnel
│   │   ├── attendance_service.h/cpp    # Séances/Présences
│   │   ├── grades_service.h/cpp        # Notes & Bulletins
│   │   ├── finance_service.h/cpp       # Finances & Paiements
│   │   └── dashboard_service.h/cpp     # Statistiques
│   │
│   ├── controllers/                    # Contrôleurs exposés à QML (10)
│   │   ├── setup_controller.h/cpp      # Assistant configuration initiale
│   │   ├── schooling_controller.h/cpp  # Scolarité
│   │   ├── student_controller.h/cpp    # Élèves
│   │   ├── staff_controller.h/cpp      # Personnel
│   │   ├── attendance_controller.h/cpp # Séances/Présences
│   │   ├── exams_controller.h/cpp      # Examens
│   │   ├── grades_controller.h/cpp     # Notes
│   │   ├── finance_controller.h/cpp    # Finances
│   │   ├── dashboard_controller.h/cpp  # Tableau de bord
│   │   ├── backup_controller.h/cpp     # Sauvegarde BD
│   │   └── year_closure_controller.h/cpp # Clôture d'année
│   │
│   ├── database/                       # Gestion BD
│   │   ├── database_manager.h/cpp      # Initialisation, lifecycle SQLite
│   │   └── database_worker.h/cpp       # Exécution async requêtes (thread worker)
│   │
│   └── generators/                     # Générateurs documents
│       └── docx_generator.h/cpp        # Génération bulletins DOCX via Qt API
│
├── qml/                                # INTERFACE UTILISATEUR (~90 fichiers QML)
│   ├── main.qml                        # Fenêtre principale (app shell)
│   │
│   ├── components/                     # Composants réutilisables (67 QML)
│   │   ├── CMakeLists.txt
│   │   ├── Style.qml                   # Design system (palette, typos, rayons)
│   │   │
│   │   ├── ★ CORE COMPONENTS
│   │   ├── AppCard.qml                 # Carte générique
│   │   ├── Avatar.qml                  # Avatar utilisateur
│   │   ├── Badge.qml                   # Badges (success, warning, error, info)
│   │   ├── StatCard.qml                # Carte statistique avec icône
│   │   ├── PageHeader.qml              # En-tête page (titre + sous-titre)
│   │   │
│   │   ├── ★ FORM & INPUT
│   │   ├── FormField.qml               # Champ formulaire avec validation
│   │   ├── DateField.qml               # Champ date
│   │   ├── SearchField.qml             # Champ recherche avec filtre
│   │   ├── DataTable.qml               # Tableau données (sorting, pagination)
│   │   ├── DatePickerPopup.qml         # Picker date popup
│   │   ├── MonthYearSelector.qml       # Sélecteur mois/année
│   │   ├── WeekPickerPopup.qml         # Picker semaine
│   │   │
│   │   ├── ★ BUTTONS & NAVIGATION
│   │   ├── PrimaryButton.qml           # Bouton principal (vert)
│   │   ├── OutlineButton.qml           # Bouton bordure
│   │   ├── IconButton.qml              # Bouton icône seul
│   │   ├── SidebarButton.qml           # Bouton navigation sidebar
│   │   ├── TabBar_.qml                 # Barre d'onglets
│   │   │
│   │   ├── ★ DISPLAY & CONTENT
│   │   ├── IconLabel.qml               # Icône SVG + texte
│   │   ├── SimpleBarChart.qml          # Graphique barres (Canvas)
│   │   ├── SimpleAreaChart.qml         # Graphique aires (Canvas)
│   │   ├── ProgressBar_.qml            # Barre progression animée
│   │   ├── Separator.qml               # Séparateur visuel
│   │   ├── SectionLabel.qml            # Étiquette section
│   │   ├── SemesterBoundRow.qml        # Marqueur limite semestre
│   │   │
│   │   ├── ★ MODALS & OVERLAYS
│   │   ├── ModalOverlay.qml            # Overlay modal semi-transparent
│   │   ├── ModalButtons.qml            # Boutons modal (OK/Annuler)
│   │   ├── PaymentPopup.qml            # Modal saisie paiement
│   │   ├── ExportDocCard.qml           # Carte export document
│   │   ├── BulletinConfigPopup.qml     # Config génération bulletins
│   │   ├── BulletinPreviewPopup.qml    # Aperçu bulletin généré
│   │   ├── ContratHistoryPopup.qml     # Historique contrats personnel
│   │   ├── SetupWizardModal.qml        # Assistant configuration (wizard)
│   │   ├── YearClosureModal.qml        # Modal clôture année
│   │   ├── StaffCard.qml               # Carte personnel
│   │   ├── StaffFormModal.qml          # Modal formulaire personnel
│   │   │
│   │   ├── closure/                    # Étapes clôture d'année (5 QML)
│   │   │   ├── ClosureStep1Stats.qml         # Stats avant clôture
│   │   │   ├── ClosureStep2Progressions.qml  # Progressions élèves
│   │   │   ├── ClosureStep3Archivage.qml     # Archivage données
│   │   │   ├── ClosureStep4Rapports.qml      # Rapports générés
│   │   │   └── ClosureStep5Confirmation.qml  # Confirmation finale
│   │   │
│   │   ├── exams/                      # Composants examens (7 QML)
│   │   │   ├── CalendarView.qml
│   │   │   ├── PlanningView.qml
│   │   │   ├── EpreuvePickerSection.qml
│   │   │   ├── SessionDetailModal.qml
│   │   │   ├── SessionFormModal.qml
│   │   │   ├── SessionSubmitSection.qml
│   │   │   └── FormComboWithReset.qml
│   │   │
│   │   ├── schooling/                  # Composants scolarité (12 QML)
│   │   │   ├── LevelSidebar.qml              # Sidebar niveaux
│   │   │   ├── ClassesSection.qml           # Section classes
│   │   │   ├── RoomsSection.qml             # Section salles
│   │   │   ├── SubjectsSection.qml          # Section matières
│   │   │   ├── NiveauModals.qml             # Modales niveaux
│   │   │   ├── ClassModals.qml              # Modales classes
│   │   │   ├── RoomModals.qml               # Modales salles
│   │   │   ├── ClassStudentsPopup.qml       # Élèves d'une classe
│   │   │   ├── MatiereEditModal.qml         # Édition matière
│   │   │   ├── MatiereDeleteModal.qml       # Suppression matière
│   │   │   ├── ManageEquipmentsModal.qml    # Gestion équipements
│   │   │   └── TypeExamenModal.qml          # Types d'examen
│   │   │
│   │   ├── setup/                      # Étapes configuration (3 QML)
│   │   │   ├── SetupStep1Association.qml      # Données association
│   │   │   ├── SetupStep2Niveaux.qml         # Configuration niveaux
│   │   │   └── SetupStep3AnneeScolaire.qml   # Année scolaire
│   │   │
│   │   └── students/                   # Composants élèves (8 QML)
│   │       ├── StudentListView.qml
│   │       ├── StudentDetailView.qml
│   │       ├── StudentListFilters.qml
│   │       ├── StudentTableHeader.qml
│   │       ├── StudentRegistrationModal.qml
│   │       ├── StudentEditModal.qml
│   │       ├── StudentDeleteModal.qml
│   │       └── EnrollmentEditModal.qml
│   │
│   └── pages/                          # Pages application (22 QML)
│       ├── CMakeLists.txt
│       ├── DashboardPage.qml           # Tableau de bord principal
│       ├── SchoolingPage.qml           # Gestion scolarité
│       ├── StudentsPage.qml            # Annuaire élèves
│       ├── StaffPage.qml               # Gestion personnel
│       ├── AttendancePage.qml          # Séances & Présences
│       ├── AttendanceModals.qml        # Modales présences
│       ├── ExamsPage.qml               # Examens & Planning
│       ├── GradesPage.qml              # Notes & Bulletins
│       ├── SettingsPage.qml            # Configuration système
│       ├── FinancePage.qml             # Page finance (hub)
│       ├── FinanceSchoolingTab.qml     # Paiements élèves
│       ├── FinancePaymentModal.qml     # Modal paiement élève
│       ├── FinanceDonateursTab.qml     # Gestion donateurs
│       ├── FinanceDonationModal.qml    # Modal donation
│       ├── FinanceDonationsTab.qml     # Historique dons
│       ├── FinanceExpensesTab.qml      # Dépenses
│       ├── FinanceExpenseModal.qml     # Modal dépense
│       ├── FinanceJournalTab.qml       # Journal transactions
│       ├── FinanceEditModals.qml       # Modales édition finances
│       ├── FinanceProjectModal.qml     # Projets/budgets
│       └── FinanceExportsTab.qml       # Exports rapports
│
├── qml/icons/                          # Icônes SVG (69 fichiers)
│   ├── alert.svg, bell.svg, book.svg, building.svg, calculator.svg
│   ├── calendar.svg, check.svg, chevron-down/left/right/up.svg
│   ├── clipboard.svg, clipboard-check.svg, clock.svg, close.svg
│   ├── cloud.svg, contact.svg, contact-2.svg, dashboard.svg, database.svg
│   ├── delete.svg, dollar-sign.svg, down.svg, down-right.svg, download.svg
│   ├── edit.svg, eye.svg, file.svg, filter.svg, graduation.svg
│   ├── graduation-cap.svg, grid.svg, heart.svg, history.svg, info.svg
│   ├── left.svg, list.svg, location.svg, lock.svg, log-out.svg
│   ├── logout.svg, mail.svg, moon.svg, more.svg, more-v.svg, phone.svg
│   ├── pin.svg, plus.svg, printer.svg, receipt.svg, refresh.svg, refresh-cw.svg
│   ├── right.svg, save.svg, school.svg, search.svg, settings.svg, shield.svg
│   ├── sun.svg, target.svg, trash.svg, trending.svg, up-right.svg
│   ├── upload.svg, user.svg, users.svg, wallet.svg, warning.svg
│   └── ... (icônes SVG modernes style Feather)
│
├── resources/                          # Ressources
│   └── templates/                      # Templates bulletins
│       ├── template_bulletin.docx      # Bulletin S1
│       └── template_bulletin_s2.docx   # Bulletin S2
│
├── fonts/                              # Polices d'application (5 .ttf)
│   ├── Inter-Regular.ttf
│   ├── Inter-Medium.ttf
│   ├── Inter-Bold.ttf
│   ├── Inter-Black.ttf
│   └── Inter-Thin.ttf
│
├── i18n/                               # Traductions
│   ├── ar_AE.ts                        # Arabe (complète)
│   └── ar_AE_backup.ts                 # Backup
│
├── deploy/                             # Artefacts déploiement (80+ DLLs + ressources)
│   ├── GestionScolaire.exe             # Exécutable principal
│   ├── GestionScolaire_Components.dll  # Module QML Components
│   ├── GestionScolaire_Pages.dll       # Module QML Pages
│   ├── [Qt Libraries - 35+ DLLs]
│   ├── [Qt Plugins - 20+ DLLs]
│   ├── [QML Modules - qml/]
│   ├── [UI Components & Pages déployés]
│   └── [Ressources - fonts, icons, etc]
│
├── build/                              # Répertoires compilation
│   ├── Desktop_Qt_6_11_0_MinGW_64_bit-Debug/
│   ├── Desktop_Qt_6_11_0_MSVC2022_64bit-Debug/
│   └── Desktop_Qt_6_11_0_MSVC2022_64bit-Release/
│
├── build_release/                      # Build Release optimisée
├── build_i18n/                         # Build traductions
└── Output/
    └── GestionScolaire_Installer.exe   # Installeur Inno Setup généré
```

## 🏗️ Architecture Technique

### Statistiques Globales

| Catégorie | Nombre |
|-----------|--------|
| Fichiers C++ (.cpp) | 29 |
| Headers C++ (.h) | 48 |
| Composants QML | 67 |
| Pages QML | 22 |
| Modèles de données | 8 |
| Interfaces Repositories | 12 |
| Implémentations SQLite | 15 |
| Services métier | 7 |
| Contrôleurs exposés | 10 |
| Icônes SVG | 69 |
| Polices TTF | 5 |
| Templates DOCX | 2 |
| **Total fichiers source** | **~150+** |
| **Total projet (incl. dépendances)** | **~400+** |

### Architecture en couches

```
┌──────────────────────────────────────────────────┐
│         QML UI (Pages & Components)              │ Interface
│  • 1 App shell + 22 Pages + 67 Composants        │ Utilisateur
├──────────────────────────────────────────────────┤
│       Controllers (10 exposés à QML)             │ Logique
│  • Setup, Schooling, Student, Staff, Attendance │ Métier
│  • Exams, Grades, Finance, Dashboard, Backup    │ Exposée
├──────────────────────────────────────────────────┤
│    Services (7 services métier + Generators)     │ Couche
│  • Schooling, Student, Staff, Attendance, etc   │ Métier
│  • DocxGenerator pour bulletins                  │ (Traitements)
├──────────────────────────────────────────────────┤
│   Repositories (12 interfaces + 15 impls)        │ Abstraction
│  • SQLite Pattern DAO                            │ Données
├──────────────────────────────────────────────────┤
│      Database Manager & Worker (SQLite)          │ Couche BD
│  • Lifecycle, transactions, async queries        │
└──────────────────────────────────────────────────┘
```

### Composants Clés

| Composant | Type | Rôle |
|-----------|------|------|
| **GS_Core** | Lib statique | Modèles, repositories, gestion BD |
| **GS_Services** | Lib statique | Services, contrôleurs, générateurs |
| **GestionScolaire** | Exécutable | Fenêtre principale + app shell |
| **GestionScolaire_Components** | QML Module DLL | 67 composants UI |
| **GestionScolaire_Pages** | QML Module DLL | 22 pages application |
| **DatabaseManager** | Service C++ | Initialisation & lifecycle SQLite |
| **DatabaseWorker** | Worker thread | Exécution asynchrone requêtes |
| **DocxGenerator** | Utilitaire C++ | Génération bulletins DOCX |

### Patterns de Conception

- **Repository Pattern** : 12 interfaces + 15 impl. SQLite
- **Service Layer** : 7 services métier
- **MVC** : Controllers → QML
- **Observer** : QML property bindings
- **Factory** : Création repositories
- **Async/Worker** : DatabaseWorker pour ops non-bloquantes
- **Singleton** : Style.qml (design system)

## 🎨 Design System

| Élément | Couleur | Usage |
|---------|---------|-------|
| **Primary** | `#3D5A45` | Boutons, accents, sidebar |
| **Primary Dark** | `#2D4233` | Hover boutons |
| **Primary Light** | `#86A38E` | Charts secondaires |
| **Background** | `#F9FAFB` | Fond pages |
| **Text Primary** | `#1E293B` | Texte principal |
| **Text Secondary** | `#6B7280` | Texte secondaire |
| **Success** | `#059669` | Validé, payé |
| **Warning** | `#D97706` | Alertes, en attente |
| **Error** | `#EF4444` | Erreurs, impayés |

**Typos** : Inter (Regular, Medium, Bold, Black, Thin)  
**Rayons** : 8px (small), 12px (medium), 16px (large)

## 🔧 Prérequis

- **Qt 6.11+** (MinGW 64-bit OU MSVC 2022 64-bit)
- **CMake 3.16+**
- **C++23**
- **SQLite 3**

## 🚀 Compilation & Exécution

### Générer Installeur

```powershell
.\build_installer.ps1
# → Output/GestionScolaire_Installer.exe
```

## 📊 Modèles de Données

**Élève** • **Niveau** • **Salle** • **Personnel** • **Contrat** • **Séance** • **Examen** • **Paiement** • **Finance** • **Équipement** • **Inscription**

## 🗄️ Base de Données

- **Type** : SQLite
- **Localisation** : Configurable au runtime
- **Migration** : Schéma auto-créé au démarrage
- **Transactions** : Complètes + atomicité
- **Backup** : Intégré (BackupController)

## 🌍 Multilingue

- 🇦🇪 **Arabe** (ar_AE) - En cours
- 🇬🇧 **Anglais/Français** - Défaut

Ajouter une langue :
1. Créer `i18n/xx_XX.ts` (Qt Linguist)
2. Ajouter `TS_FILES i18n/xx_XX.ts` à CMakeLists.txt
3. Rebuild

## 📋 Fonctionnalités Avancées

✅ **Génération Bulletins** DOCX (templates S1/S2)  
✅ **Dashboard** stats + graphiques temps réel  
✅ **Finance** complète (paiements, dons, bilan, journal)  
✅ **Clôture d'Année** (5 étapes supervisées)  
✅ **Backup/Restauration** BD  
✅ **Multi-utilisateurs** (préparé pour futur)

---

**Version** : 0.0.0+ (détection Git)  
**Licence** : FULL FREE
**Support** : azaiez.abdelmonam@gmail.com
