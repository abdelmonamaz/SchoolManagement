import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

ColumnLayout {
    id: root
    spacing: 28

    required property var students
    required property var niveaux
    required property var classes
    property string filterLevel: "all"
    property int selectedFilterNiveauId: 0
    property var filteredClassesModel: []

    signal studentSelected(int index)
    signal studentViewClicked(int index)
    signal studentEditClicked(int index)
    signal studentDeleteClicked(int studentId)
    signal registrationRequested()
    signal searchRequested(string text)
    signal filterByClass(int classeId)
    signal loadAllRequested()
    signal niveauFilterChanged(int niveauId)

    // Update filtered classes when niveau or classes change
    onSelectedFilterNiveauIdChanged: updateFilteredClasses()
    onClassesChanged: updateFilteredClasses()

    Component.onCompleted: updateFilteredClasses()

    function updateFilteredClasses() {
        var result = []
        if (selectedFilterNiveauId === 0) {
            for (var i = 0; i < classes.length; i++) {
                result.push(classes[i])
            }
        } else {
            for (var j = 0; j < classes.length; j++) {
                if (classes[j].niveauId === selectedFilterNiveauId) {
                    result.push(classes[j])
                }
            }
        }
        filteredClassesModel = result
    }

    RowLayout {
        Layout.fillWidth: true
        PageHeader {
            Layout.fillWidth: true
            title: "Annuaire des Étudiants"
            subtitle: "Gestion des dossiers individuels et du suivi."
        }
        PrimaryButton {
            text: "Inscrire un Élève"
            iconName: "plus"
            onClicked: root.registrationRequested()
        }
    }

    AppCard {
        Layout.fillWidth: true

        Column {
            width: parent.width
            spacing: 20

            // Search & Filters
            RowLayout {
                width: parent.width
                spacing: 12

                SearchField {
                    Layout.fillWidth: true
                    placeholder: "Rechercher par nom, matricule..."
                    onTextChanged: {
                        if (text.length > 0)
                            root.searchRequested(text)
                        else
                            root.loadAllRequested()
                    }
                }

                // Niveau Selector
                Rectangle {
                    width: 160
                    height: 44
                    radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "📚"
                            font.pixelSize: 14
                        }

                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (root.selectedFilterNiveauId === 0) return "Tous niveaux"
                                for (var i = 0; i < root.niveaux.length; i++) {
                                    if (root.niveaux[i].id === root.selectedFilterNiveauId)
                                        return root.niveaux[i].nom
                                }
                                return "Tous niveaux"
                            }
                            font.pixelSize: 11
                            font.bold: true
                            color: Style.textPrimary
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "▼"
                            font.pixelSize: 8
                            color: Style.textTertiary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: niveauMenu.open()
                    }

                    Menu {
                        id: niveauMenu
                        y: parent.height

                        MenuItem {
                            text: "Tous niveaux"
                            onTriggered: {
                                root.selectedFilterNiveauId = 0
                                root.filterLevel = "all"
                                root.niveauFilterChanged(0)
                                root.loadAllRequested()
                            }
                        }

                        Repeater {
                            model: root.niveaux

                            MenuItem {
                                text: modelData.nom
                                onTriggered: {
                                    root.selectedFilterNiveauId = modelData.id
                                    root.filterLevel = "all"
                                    root.niveauFilterChanged(modelData.id)
                                    root.loadAllRequested()
                                }
                            }
                        }
                    }
                }

                // Class Filter Buttons
                Rectangle {
                    Layout.preferredWidth: Math.max(implicitWidth, 200)
                    implicitWidth: levelFilterRow.implicitWidth + 8
                    height: 44
                    radius: 16
                    color: Style.bgSecondary
                    visible: classRepeater.count > 0 || root.filterLevel === "all"

                    Row {
                        id: levelFilterRow
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 4
                        spacing: 4

                        // "Tous" button
                        Rectangle {
                            width: allFilterText.implicitWidth + 24
                            height: 36
                            radius: 12
                            color: root.filterLevel === "all" ? Style.primary : "transparent"

                            Text {
                                id: allFilterText
                                anchors.centerIn: parent
                                text: "Tous"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: root.filterLevel === "all" ? "#FFFFFF" : Style.textTertiary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.filterLevel = "all"
                                    root.loadAllRequested()
                                }
                            }
                        }

                        // Dynamic class buttons (filtered by niveau)
                        Repeater {
                            id: classRepeater
                            model: filteredClassesModel

                            delegate: Rectangle {
                                width: classFilterText.implicitWidth + 24
                                height: 36
                                radius: 12
                                color: root.filterLevel === modelData.nom ? Style.primary : "transparent"

                                Text {
                                    id: classFilterText
                                    anchors.centerIn: parent
                                    text: modelData.nom
                                    font.pixelSize: 10
                                    font.weight: Font.Black
                                    color: root.filterLevel === modelData.nom ? "#FFFFFF" : Style.textTertiary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.filterLevel = modelData.nom
                                        root.filterByClass(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }

                // Hint text when niveau selected but no classes
                Text {
                    visible: root.selectedFilterNiveauId > 0 && classRepeater.count === 0
                    text: "Aucune classe dans ce niveau"
                    font.pixelSize: 11
                    font.italic: true
                    color: Style.textTertiary
                }
            }

            // Table Header
            Separator { width: parent.width }

            RowLayout {
                width: parent.width
                spacing: 0
                Text { Layout.preferredWidth: 200; text: "ÉLÈVE"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                Text { Layout.preferredWidth: 100; text: "MATRICULE"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                Text { Layout.preferredWidth: 100; text: "CATÉGORIE"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                Text { Layout.fillWidth: true; text: "CONTACT"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                Text { Layout.preferredWidth: 110; text: "ACTION"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; horizontalAlignment: Text.AlignRight }
            }

            // Table Rows
            Column {
                width: parent.width
                spacing: 0

                Repeater {
                    model: root.students

                    delegate: Rectangle {
                        width: parent.width
                        height: 64
                        color: rowHover.hovered ? "#FAFBFC" : "transparent"
                        border.color: Style.borderLight
                        border.width: 0

                        HoverHandler { id: rowHover }

                        Separator {
                            anchors.bottom: parent.bottom
                            width: parent.width
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onDoubleClicked: root.studentViewClicked(index)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.topMargin: 1
                            spacing: 0

                            // Name
                            RowLayout {
                                Layout.preferredWidth: 200
                                spacing: 10
                                Avatar {
                                    initials: modelData.nom.charAt(0)
                                    size: 38
                                }
                                Text { text: modelData.nom + " " + modelData.prenom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                            }

                            // Matricule
                            Text { Layout.preferredWidth: 100; text: modelData.id.toString(); font.pixelSize: 12; font.weight: Font.Medium; color: Style.textSecondary }

                            // Categorie
                            Item {
                                Layout.preferredWidth: 100
                                implicitHeight: lvlBadge.height
                                Badge { id: lvlBadge; text: modelData.categorie; variant: "info" }
                            }

                            // Contact
                            Column {
                                Layout.fillWidth: true
                                spacing: 1
                                Text { text: modelData.telephone; font.pixelSize: 12; font.weight: Font.Medium; color: Style.textPrimary }
                                Text { text: modelData.adresse; font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary }
                            }

                            // Actions
                            Row {
                                Layout.preferredWidth: 80
                                Layout.alignment: Qt.AlignRight
                                spacing: 4
                                IconButton {
                                    iconName: "eye"; iconSize: 16
                                    onClicked: root.studentViewClicked(index)
                                }
                                IconButton {
                                    iconName: "delete"; iconSize: 16; hoverColor: Style.errorColor
                                    onClicked: root.studentDeleteClicked(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
