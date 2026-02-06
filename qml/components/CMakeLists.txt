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
        Separator.qml
        Avatar.qml
        SectionLabel.qml
        ModalButtons.qml
)