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
        FinanceSchoolingTab.qml
        FinanceDonationsTab.qml
        FinanceJournalTab.qml
        FinancePaymentModal.qml
        FinanceEditModals.qml
        FinanceDonationModal.qml
        FinanceExpenseModal.qml
        FinanceExpensesTab.qml
        FinanceDonateursTab.qml
        SettingsPage.qml
        GradesPage.qml
        AttendancePage.qml
        AttendanceModals.qml
        StaffPage.qml
)