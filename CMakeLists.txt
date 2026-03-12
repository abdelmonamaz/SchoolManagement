cmake_minimum_required(VERSION 3.16)

# ── Git version detection ──────────────────────────────────────
find_package(Git QUIET)
set(APP_VERSION "0.0.0")
if(Git_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags --match "v*" --abbrev=0
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_TAG
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE GIT_RESULT
    )
    if(GIT_RESULT EQUAL 0 AND GIT_TAG MATCHES "^v([0-9]+)\\.([0-9]+)\\.([0-9]+)$")
        set(APP_VERSION "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}")
    endif()
endif()
message(STATUS "Ez-Zaytouna version: ${APP_VERSION}")

project(GestionScolaire VERSION ${APP_VERSION} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Sql LabsPlatform LinguistTools)

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
    src/repositories/isetup_repository.h
    src/repositories/iyear_closure_repository.h

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
    src/repositories/sqlite/sqlite_setup_repository.h
    src/repositories/sqlite/sqlite_setup_repository.cpp
    src/repositories/sqlite/sqlite_year_closure_repository.h
    src/repositories/sqlite/sqlite_year_closure_repository.cpp

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
    src/controllers/backup_controller.h
    src/controllers/backup_controller.cpp
    src/controllers/year_closure_controller.h
    src/controllers/year_closure_controller.cpp
)

target_link_libraries(GS_Services PUBLIC GS_Core Qt6::Core Qt6::Gui Qt6::Sql Qt6::ZlibPrivate)

# ═══════════════════════════════════════════════════════════════
# Exécutable principal
# ═══════════════════════════════════════════════════════════════

qt_add_executable(GestionScolaire
    src/main.cpp
    src/app/app_controller.h
    src/app/app_controller.cpp
)

# ─── Traductions ───
qt_add_translations(GestionScolaire
    TS_FILES i18n/ar_AE.ts
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
        qml/icons/alert.svg
        qml/icons/bell.svg
        qml/icons/book.svg
        qml/icons/building.svg
        qml/icons/calculator.svg
        qml/icons/calendar.svg
        qml/icons/check.svg
        qml/icons/chevron-down.svg
        qml/icons/chevron-left.svg
        qml/icons/chevron-right.svg
        qml/icons/chevron-up.svg
        qml/icons/clipboard-check.svg
        qml/icons/clipboard.svg
        qml/icons/clock.svg
        qml/icons/close.svg
        qml/icons/cloud.svg
        qml/icons/contact-2.svg
        qml/icons/contact.svg
        qml/icons/dashboard.svg
        qml/icons/database.svg
        qml/icons/delete.svg
        qml/icons/dollar-sign.svg
        qml/icons/down-right.svg
        qml/icons/down.svg
        qml/icons/download.svg
        qml/icons/edit.svg
        qml/icons/eye.svg
        qml/icons/file.svg
        qml/icons/filter.svg
        qml/icons/graduation-cap.svg
        qml/icons/graduation.svg
        qml/icons/grid.svg
        qml/icons/heart.svg
        qml/icons/history.svg
        qml/icons/info.svg
        qml/icons/left.svg
        qml/icons/list.svg
        qml/icons/location.svg
        qml/icons/lock.svg
        qml/icons/log-out.svg
        qml/icons/logout.svg
        qml/icons/mail.svg
        qml/icons/moon.svg
        qml/icons/more-v.svg
        qml/icons/more.svg
        qml/icons/phone.svg
        qml/icons/pin.svg
        qml/icons/plus.svg
        qml/icons/printer.svg
        qml/icons/receipt.svg
        qml/icons/refresh-cw.svg
        qml/icons/refresh.svg
        qml/icons/right.svg
        qml/icons/save.svg
        qml/icons/school.svg
        qml/icons/search.svg
        qml/icons/settings.svg
        qml/icons/shield.svg
        qml/icons/sun.svg
        qml/icons/target.svg
        qml/icons/trash.svg
        qml/icons/trending.svg
        qml/icons/up-right.svg
        qml/icons/upload.svg
        qml/icons/user.svg
        qml/icons/users.svg
        qml/icons/wallet.svg
        qml/icons/warning.svg
)

# Modules QML secondaires
add_subdirectory(qml/components)
add_subdirectory(qml/pages)

target_compile_definitions(GestionScolaire PRIVATE
    APP_VERSION_STR="${APP_VERSION}"
)

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

