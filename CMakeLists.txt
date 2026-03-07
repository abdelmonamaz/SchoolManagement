cmake_minimum_required(VERSION 3.16)
project(GestionScolaire VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Sql LabsPlatform)

# Politiques Qt 6 recommandées
qt_policy(SET QTP0001 NEW) # Préfixe /qt/qml/
qt_policy(SET QTP0004 NEW) # Gestion propre des dossiers

# ═══════════════════════════════════════════════════════════════
# GS_Core : common, models, repositories, database
# ═══════════════════════════════════════════════════════════════

add_library(GS_Core STATIC
    # Common
    src/common/enums.h
    src/common/result.h

    # Models
    src/models/salle.h
    src/models/niveau.h
    src/models/professeur.h
    src/models/eleve.h
    src/models/seance.h
    src/models/paiement.h
    src/models/finance.h

    # Repository interfaces
    src/repositories/irepository.h
    src/repositories/isalle_repository.h
    src/repositories/iniveau_repository.h
    src/repositories/ipersonnel_repository.h
    src/repositories/icontrat_repository.h
    src/repositories/ieleve_repository.h
    src/repositories/iseance_repository.h
    src/repositories/ipaiement_repository.h
    src/repositories/ipaiement_personnel_repository.h
    src/repositories/ifinance_repository.h

    # SQLite implementations
    src/repositories/sqlite/sqlite_salle_repository.h
    src/repositories/sqlite/sqlite_salle_repository.cpp
    src/repositories/sqlite/sqlite_niveau_repository.h
    src/repositories/sqlite/sqlite_niveau_repository.cpp
    src/repositories/sqlite/sqlite_equipement_repository.h
    src/repositories/sqlite/sqlite_equipement_repository.cpp
    src/repositories/sqlite/sqlite_personnel_repository.h
    src/repositories/sqlite/sqlite_personnel_repository.cpp
    src/repositories/sqlite/sqlite_contrat_repository.h
    src/repositories/sqlite/sqlite_contrat_repository.cpp
    src/repositories/sqlite/sqlite_eleve_repository.h
    src/repositories/sqlite/sqlite_eleve_repository.cpp
    src/repositories/sqlite/sqlite_seance_repository.h
    src/repositories/sqlite/sqlite_seance_repository.cpp
    src/repositories/sqlite/sqlite_paiement_repository.h
    src/repositories/sqlite/sqlite_paiement_repository.cpp
    src/repositories/sqlite/sqlite_paiement_personnel_repository.h
    src/repositories/sqlite/sqlite_paiement_personnel_repository.cpp
    src/repositories/sqlite/sqlite_finance_repository.h
    src/repositories/sqlite/sqlite_finance_repository.cpp

    # Database
    src/database/database_manager.h
    src/database/database_manager.cpp
    src/database/database_worker.h
    src/database/database_worker.cpp
)

target_include_directories(GS_Core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(GS_Core PUBLIC Qt6::Core Qt6::Sql)

# ═══════════════════════════════════════════════════════════════
# GS_Services : services + controllers
# ═══════════════════════════════════════════════════════════════

add_library(GS_Services STATIC
    # Services
    src/services/schooling_service.h
    src/services/schooling_service.cpp
    src/services/student_service.h
    src/services/student_service.cpp
    src/services/staff_service.h
    src/services/staff_service.cpp
    src/services/attendance_service.h
    src/services/attendance_service.cpp
    src/services/grades_service.h
    src/services/grades_service.cpp
    src/services/finance_service.h
    src/services/finance_service.cpp
    src/services/dashboard_service.h
    src/services/dashboard_service.cpp

    # Controllers
    src/controllers/setup_controller.h
    src/controllers/setup_controller.cpp
    src/controllers/schooling_controller.h
    src/controllers/schooling_controller.cpp
    src/controllers/student_controller.h
    src/controllers/student_controller.cpp
    src/controllers/staff_controller.h
    src/controllers/staff_controller.cpp
    src/controllers/attendance_controller.h
    src/controllers/attendance_controller.cpp
    src/controllers/exams_controller.h
    src/controllers/exams_controller.cpp
    src/controllers/grades_controller.h
    src/controllers/grades_controller.cpp
    src/controllers/finance_controller.h
    src/controllers/finance_controller.cpp
    src/controllers/dashboard_controller.h
    src/controllers/dashboard_controller.cpp
)

target_link_libraries(GS_Services PUBLIC GS_Core Qt6::Core Qt6::Gui Qt6::Sql)

# ═══════════════════════════════════════════════════════════════
# Exécutable principal
# ═══════════════════════════════════════════════════════════════

qt_add_executable(GestionScolaire
    src/main.cpp
    src/app/app_controller.h
    src/app/app_controller.cpp
)

# Module QML principal
qt_add_qml_module(GestionScolaire
    URI GestionScolaire
    VERSION 1.0
    QML_FILES qml/main.qml
    RESOURCES
        fonts/Inter-Regular.ttf
        fonts/Inter-Medium.ttf
        fonts/Inter-Bold.ttf
        fonts/Inter-Black.ttf
)

# Modules QML secondaires
add_subdirectory(qml/components)
add_subdirectory(qml/pages)

target_link_libraries(GestionScolaire PRIVATE
    GS_Core
    GS_Services
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Sql
    Qt6::LabsPlatform
    GestionScolaire_Components
    GestionScolaire_Pages
)
