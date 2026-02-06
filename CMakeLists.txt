cmake_minimum_required(VERSION 3.16)
project(GestionScolaire VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Sql)

# Politiques Qt 6 recommandées
qt_policy(SET QTP0001 NEW) # Préfixe /qt/qml/
qt_policy(SET QTP0004 NEW) # Gestion propre des dossiers

qt_add_executable(GestionScolaire
    src/main.cpp

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
    src/repositories/iprof_repository.h
    src/repositories/ieleve_repository.h
    src/repositories/iseance_repository.h
    src/repositories/ipaiement_repository.h
    src/repositories/ifinance_repository.h

    # SQLite implementations
    src/repositories/sqlite/sqlite_salle_repository.h
    src/repositories/sqlite/sqlite_salle_repository.cpp
    src/repositories/sqlite/sqlite_niveau_repository.h
    src/repositories/sqlite/sqlite_niveau_repository.cpp
    src/repositories/sqlite/sqlite_prof_repository.h
    src/repositories/sqlite/sqlite_prof_repository.cpp
    src/repositories/sqlite/sqlite_eleve_repository.h
    src/repositories/sqlite/sqlite_eleve_repository.cpp
    src/repositories/sqlite/sqlite_seance_repository.h
    src/repositories/sqlite/sqlite_seance_repository.cpp
    src/repositories/sqlite/sqlite_paiement_repository.h
    src/repositories/sqlite/sqlite_paiement_repository.cpp
    src/repositories/sqlite/sqlite_finance_repository.h
    src/repositories/sqlite/sqlite_finance_repository.cpp

    # Database
    src/database/database_manager.h
    src/database/database_manager.cpp
    src/database/database_worker.h
    src/database/database_worker.cpp

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

    # App bootstrap
    src/app/app_controller.h
    src/app/app_controller.cpp
)

# Include directories for relative includes
target_include_directories(GestionScolaire PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Module principal
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

# Inclusion des modules secondaires
add_subdirectory(qml/components)
add_subdirectory(qml/pages)

target_link_libraries(GestionScolaire PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Sql
    GestionScolaire_Components
    GestionScolaire_Pages
)
