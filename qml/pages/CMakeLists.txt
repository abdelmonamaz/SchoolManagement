qt_add_qml_module(GestionScolaire_Pages
    URI UI.Pages
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/UI/Pages"
    QML_FILES
        DashboardPage.qml
        SchoolingPage.qml
        StudentsPage.qml
        ExamsPage.qml
        FinancePage.qml
        SettingsPage.qml
        GradesPage.qml
        AttendancePage.qml
        StaffPage.qml
)