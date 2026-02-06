import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: schoolPage
    implicitHeight: mainLayout.implicitHeight

    property string activeTab: "levels"
    property int selectedLevel: 0
    property bool showRoomModal: false
    property bool showClassModal: false

    readonly property var levelsData: [
        {
            name: "Niveau 1",
            subjects: ["Arabe", "Coran", "Mathématiques"],
            classes: [
                { name: "A", students: 15 },
                { name: "B", students: 18 },
                { name: "C", students: 12 }
            ]
        },
        {
            name: "Niveau 2",
            subjects: ["Arabe", "Coran", "Mathématiques", "Histoires"],
            classes: [
                { name: "A", students: 20 },
                { name: "B", students: 16 },
                { name: "C", students: 16 }
            ]
        },
        {
            name: "Niveau 3",
            subjects: ["Arabe", "Coran", "Mathématiques", "Fiqh"],
            classes: [
                { name: "A", students: 12 },
                { name: "B", students: 14 },
                { name: "C", students: 12 }
            ]
        },
        {
            name: "Niveau 4",
            subjects: ["Arabe", "Coran", "Tajwid", "Fiqh"],
            classes: [
                { name: "A", students: 16 },
                { name: "B", students: 16 },
                { name: "C", students: 16 }
            ]
        },
        {
            name: "Niveau 5",
            subjects: ["Arabe", "Coran", "Tajwid", "Fiqh", "Hadith"],
            classes: [
                { name: "A", students: 14 },
                { name: "B", students: 14 },
                { name: "C", students: 14 }
            ]
        }
    ]

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true

            PageHeader {
                Layout.fillWidth: true
                title: "Architecture Académique"
                subtitle: "Configuration des niveaux, des matières et de la logistique."
            }

            Rectangle {
                implicitWidth: tabRow.implicitWidth + 16
                height: 42
                radius: 16
                color: Style.bgSecondary
                border.color: Style.borderLight

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        width: levelsTabLabel.implicitWidth + 32
                        height: 34
                        radius: 12
                        color: activeTab === "levels" ? Style.primary : "transparent"

                        Text {
                            id: levelsTabLabel
                            anchors.centerIn: parent
                            text: "NIVEAUX & MATIÈRES"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: activeTab === "levels" ? "#FFFFFF" : Style.textTertiary
                            font.letterSpacing: 0.5
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = "levels"
                        }
                    }

                    Rectangle {
                        width: roomsTabLabel.implicitWidth + 32
                        height: 34
                        radius: 12
                        color: activeTab === "rooms" ? Style.primary : "transparent"

                        Text {
                            id: roomsTabLabel
                            anchors.centerIn: parent
                            text: "GESTION DES SALLES"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: activeTab === "rooms" ? "#FFFFFF" : Style.textTertiary
                            font.letterSpacing: 0.5
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = "rooms"
                        }
                    }
                }
            }
        }

        // ─── Levels Tab Content ───
        Loader {
            Layout.fillWidth: true
            active: activeTab === "levels"
            visible: active

            sourceComponent: Component {
                RowLayout {
                    spacing: 24

                    Column {
                        Layout.preferredWidth: 220
                        spacing: 12

                        SectionLabel {
                            text: "SÉLECTIONNER UN NIVEAU"
                            leftPadding: 4
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: levelsData.length

                                Rectangle {
                                    width: 220
                                    height: 52
                                    radius: 16
                                    color: selectedLevel === index ? Style.primary : Style.bgWhite
                                    border.color: selectedLevel === index ? Style.primary : Style.borderLight

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 12

                                        Text {
                                            Layout.fillWidth: true
                                            text: levelsData[index].name
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: selectedLevel === index ? "#FFFFFF" : Style.textPrimary
                                        }

                                        Text {
                                            text: "›"
                                            font.pixelSize: 16
                                            color: selectedLevel === index ? "#FFFFFF60" : Style.textTertiary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: selectedLevel = index
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 24

                        AppCard {
                            Layout.fillWidth: true
                            title: "Matières enseignées : " + levelsData[selectedLevel].name
                            subtitle: "Ajoutez ou supprimez des cours pour ce niveau"

                            Column {
                                width: parent.width
                                spacing: 18

                                Flow {
                                    width: parent.width
                                    spacing: 12

                                    Repeater {
                                        model: levelsData[selectedLevel].subjects

                                        Rectangle {
                                            implicitWidth: subjectRow.implicitWidth + 24
                                            height: 40
                                            radius: 12
                                            color: Style.bgPage
                                            border.color: subjectCardMa.containsMouse ? Style.primary : Style.borderLight

                                            Behavior on border.color { ColorAnimation { duration: 150 } }

                                            RowLayout {
                                                id: subjectRow
                                                anchors.centerIn: parent
                                                spacing: 8

                                                Text {
                                                    text: modelData
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    color: Style.textPrimary
                                                }

                                                IconButton {
                                                    iconName: "close"
                                                    iconSize: 12
                                                    hoverColor: Style.errorColor
                                                }
                                            }

                                            MouseArea {
                                                id: subjectCardMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                            }
                                        }
                                    }
                                }

                                Separator { width: parent.width }

                                RowLayout {
                                    width: parent.width
                                    spacing: 12

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 44
                                        radius: 12
                                        color: Style.bgPage
                                        border.color: Style.borderLight

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14

                                            IconLabel {
                                                iconName: "book"
                                                iconSize: 16
                                                iconColor: Style.textTertiary
                                            }

                                            TextInput {
                                                Layout.fillWidth: true
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: Style.textPrimary

                                                Text {
                                                    visible: !parent.text
                                                    text: "Nom de la nouvelle matière..."
                                                    font: parent.font
                                                    color: Style.textTertiary
                                                }
                                            }
                                        }
                                    }

                                    PrimaryButton {
                                        text: "AJOUTER"
                                        iconName: "plus"
                                    }
                                }
                            }
                        }

                        AppCard {
                            Layout.fillWidth: true
                            title: "Groupes & Classes"
                            subtitle: "Structure actuelle du " + levelsData[selectedLevel].name

                            GridLayout {
                                width: parent.width
                                columns: 3
                                columnSpacing: 18
                                rowSpacing: 18

                                Repeater {
                                    model: levelsData[selectedLevel].classes

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 140
                                        radius: 24
                                        color: Style.bgPage
                                        border.color: classCardMa.containsMouse ? Style.primary : Style.borderLight

                                        Behavior on border.color { ColorAnimation { duration: 200 } }

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 20
                                            spacing: 12

                                            RowLayout {
                                                width: parent.width

                                                Rectangle {
                                                    width: 48; height: 48; radius: 16
                                                    color: classCardMa.containsMouse ? Style.primary : Style.bgWhite
                                                    Behavior on color { ColorAnimation { duration: 200 } }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.name
                                                        font.pixelSize: 18
                                                        font.weight: Font.Black
                                                        color: classCardMa.containsMouse ? "#FFFFFF" : Style.primary
                                                    }
                                                }

                                                Item { Layout.fillWidth: true }

                                                Badge {
                                                    text: modelData.students + " Élèves"
                                                    variant: "neutral"
                                                }
                                            }

                                            Column {
                                                width: parent.width
                                                spacing: 2

                                                Text {
                                                    text: "Classe " + (selectedLevel + 1) + modelData.name
                                                    font.pixelSize: 14
                                                    font.weight: Font.Black
                                                    color: Style.textPrimary
                                                }

                                                SectionLabel { text: "CAPACITÉ OPTIMALE" }
                                            }
                                        }

                                        MouseArea {
                                            id: classCardMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 140
                                    radius: 24
                                    color: "transparent"
                                    border.color: addClassMa.containsMouse ? Style.primary : Style.borderMedium
                                    border.width: 2

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 10

                                        IconLabel {
                                            iconName: "plus"
                                            iconSize: 24
                                            iconColor: addClassMa.containsMouse ? Style.primary : Style.textTertiary
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }

                                        SectionLabel {
                                            text: "NOUVEAU GROUPE"
                                            font.pixelSize: 10
                                            color: addClassMa.containsMouse ? Style.primary : Style.textTertiary
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: addClassMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: showClassModal = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── Rooms Tab Content ───
        Loader {
            Layout.fillWidth: true
            active: activeTab === "rooms"
            visible: active

            sourceComponent: Component {
                Column {
                    width: parent.width
                    spacing: 24

                    RowLayout {
                        width: parent.width
                        Item { Layout.fillWidth: true }
                        PrimaryButton {
                            text: "Ajouter une Salle"
                            iconName: "plus"
                            onClicked: showRoomModal = true
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 4
                        columnSpacing: 20
                        rowSpacing: 20

                        Repeater {
                            model: ListModel {
                                ListElement { roomName: "Salle A1"; capacity: 30; equipment: "Projecteur, Tableau Blanc" }
                                ListElement { roomName: "Salle B4"; capacity: 25; equipment: "Tableau Blanc" }
                                ListElement { roomName: "Grande Salle"; capacity: 60; equipment: "Projecteur, Système Audio, Tableau Blanc" }
                                ListElement { roomName: "Labo 1"; capacity: 20; equipment: "Tableaux Digitaux, WiFi" }
                            }

                            delegate: Rectangle {
                                property string roomEquipment: model.equipment

                                Layout.fillWidth: true
                                implicitHeight: roomCardCol.implicitHeight + 48
                                radius: 24
                                color: Style.bgWhite
                                border.color: roomCardMa.containsMouse ? Style.borderMedium : Style.borderLight
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                Column {
                                    id: roomCardCol
                                    anchors.fill: parent
                                    anchors.margins: 24
                                    spacing: 18

                                    RowLayout {
                                        width: parent.width

                                        Rectangle {
                                            width: 48; height: 48; radius: 16; color: Style.bgPage
                                            Text { anchors.centerIn: parent; text: "🏫"; font.pixelSize: 20 }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Row {
                                            spacing: 4
                                            IconButton { iconName: "edit"; iconSize: 14; onClicked: showRoomModal = true }
                                            IconButton { iconName: "delete"; iconSize: 14; hoverColor: Style.errorColor }
                                        }
                                    }

                                    Column {
                                        width: parent.width
                                        spacing: 8
                                        Text { text: model.roomName; font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                                        Badge { text: model.capacity + " Places"; variant: "info" }
                                    }

                                    Separator { width: parent.width }

                                    Column {
                                        width: parent.width
                                        spacing: 8

                                        SectionLabel { text: "ÉQUIPEMENTS" }

                                        Flow {
                                            width: parent.width
                                            spacing: 6

                                            Repeater {
                                                model: roomEquipment ? roomEquipment.split(", ") : []

                                                Rectangle {
                                                    implicitWidth: equipRow.implicitWidth + 12
                                                    height: 24; radius: 8
                                                    color: Style.bgPage; border.color: Style.borderLight

                                                    RowLayout {
                                                        id: equipRow
                                                        anchors.centerIn: parent
                                                        spacing: 4
                                                        Text { text: "✓"; font.pixelSize: 10; color: Style.successColor }
                                                        Text { text: modelData; font.pixelSize: 10; font.bold: true; color: Style.textSecondary }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: roomCardMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }

    // ─── Class Modal ───
    ModalOverlay {
        show: showClassModal
        modalWidth: 420
        onClose: showClassModal = false

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Nouveau Groupe (" + levelsData[selectedLevel].name + ")"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
                bottomPadding: 24
            }

            FormField {
                width: parent.width - 64
                label: "NOM DU GROUPE"
                placeholder: "ex: A, B, Matin, etc."
            }

            Item { width: 1; height: 24 }

            ModalButtons {
                width: parent.width - 64
                confirmText: "CRÉER"
                onCancel: showClassModal = false
                onConfirm: showClassModal = false
            }
        }
    }

    // ─── Room Modal ───
    ModalOverlay {
        show: showRoomModal
        modalWidth: 480
        onClose: showRoomModal = false

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Nouvelle Salle"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
                bottomPadding: 24
            }

            Column {
                width: parent.width - 64
                spacing: 18

                FormField { width: parent.width; label: "NOM DE LA SALLE"; placeholder: "ex: Salle B1" }
                FormField { width: parent.width; label: "CAPACITÉ"; text: "20" }

                Column {
                    width: parent.width
                    spacing: 8

                    SectionLabel { text: "ÉQUIPEMENTS" }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: ["Projecteur", "Tableau Blanc", "Tableau Digital", "WiFi", "Système Audio"]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40; radius: 12
                                color: Style.bgPage; border.color: Style.borderLight

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData; font.pixelSize: 11; font.bold: true; color: Style.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        parent.color = parent.color === Style.primary ? Style.bgPage : Style.primary
                                        parent.children[0].color = parent.color === Style.primary ? "#FFFFFF" : Style.textSecondary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 24 }

            ModalButtons {
                width: parent.width - 64
                confirmText: "ENREGISTRER"
                onCancel: showRoomModal = false
                onConfirm: showRoomModal = false
            }
        }
    }
}
