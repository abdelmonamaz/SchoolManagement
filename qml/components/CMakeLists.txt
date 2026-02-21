set_source_files_properties(Style.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(GestionScolaire_Components
    URI UI.Components
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/UI/Components"
    QML_FILES
        Style.qml
        Badge.qml
        PrimaryButton.qml
        SidebarButton.qml
        IconLabel.qml
        IconButton.qml
        AppCard.qml
        StatCard.qml
        PageHeader.qml
        OutlineButton.qml
        TabBar_.qml
        SearchField.qml
        ProgressBar_.qml
        SimpleBarChart.qml
        SimpleAreaChart.qml
        DataTable.qml
        ModalOverlay.qml
        FormField.qml
        DateField.qml
        Separator.qml
        Avatar.qml
        SectionLabel.qml
        ModalButtons.qml
        MonthYearSelector.qml
        PaymentPopup.qml
        StaffCard.qml
        StaffFormModal.qml
        schooling/LevelSidebar.qml
        schooling/SubjectsSection.qml
        schooling/ClassesSection.qml
        schooling/RoomsSection.qml
        schooling/NiveauModals.qml
        schooling/MatiereDeleteModal.qml
        schooling/ClassModals.qml
        schooling/ClassStudentsPopup.qml
        schooling/RoomModals.qml
        schooling/ManageEquipmentsModal.qml
        students/StudentListView.qml
        students/StudentDetailView.qml
        students/StudentRegistrationModal.qml
        students/StudentEditModal.qml
        students/StudentDeleteModal.qml
)