import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

Popup {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 800
    modal: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    required property var niveaux
    required property var classes

    property int selectedNiveauId: 0
    property int selectedClasseId: 0

    signal createRequested(var data)
    signal closeRequested()
    signal niveauSelected(int niveauId)

    onClosed: root.closeRequested()
    onOpened: nameField.inputItem.forceActiveFocus()

    background: Rectangle {
        radius: 32
        color: Style.bgWhite
    }

    Overlay.modal: Rectangle {
        color: "#0F172A99"
    }

    contentItem: Column {
        width: root.width
        spacing: 0

        // Modal Header
        Rectangle {
            width: parent.width
            height: 80
            color: "#FAFBFC"
            radius: 32

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 40
                color: "#FAFBFC"
            }

            Separator {
                anchors.bottom: parent.bottom
                width: parent.width
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Nouvelle Inscription"
                        font.pixelSize: 20
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "REMPLISSEZ LES INFORMATIONS DE L'ÉLÈVE"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.textTertiary
                        font.letterSpacing: 1
                    }
                }

                IconButton {
                    iconName: "close"
                    iconSize: 18
                    onClicked: root.closeRequested()
                }
            }
        }

        // Modal Body
        Item {
            width: parent.width
            implicitHeight: bodyCol.implicitHeight + 48

            Column {
                id: bodyCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 32

                // Section 1: Identité
                Column {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: Style.primary
                            Text { anchors.centerIn: parent; text: "1"; font.pixelSize: 10; font.weight: Font.Black; color: "#FFFFFF" }
                        }

                        Text {
                            text: "IDENTITÉ DE L'ÉLÈVE"
                            font.pixelSize: 10; font.weight: Font.Black; color: Style.textPrimary; font.letterSpacing: 1
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 16

                        FormField {
                            id: nameField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "NOM"
                            placeholder: "ex: Ben Moussa"
                            nextTabItem: prenomField.inputItem
                            prevTabItem: addressField.inputItem
                        }

                        FormField {
                            id: prenomField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "PRÉNOM"
                            placeholder: "ex: Ahmed"
                            nextTabItem: phoneField.inputItem
                            prevTabItem: nameField.inputItem
                        }
                    }
                }

                // Section 2: Scolarité
                Column {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: Style.primary
                            Text { anchors.centerIn: parent; text: "2"; font.pixelSize: 10; font.weight: Font.Black; color: "#FFFFFF" }
                        }

                        Text {
                            text: "INFORMATIONS ACADÉMIQUES"
                            font.pixelSize: 10; font.weight: Font.Black; color: Style.textPrimary; font.letterSpacing: 1
                        }
                    }

                    // Date de naissance : catégorie calculée automatiquement
                    DateField {
                        id: birthDateField
                        width: parent.width
                        label: "DATE DE NAISSANCE"
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 16

                        // ── Sélecteur NIVEAU ──
                        Column {
                            Layout.preferredWidth: 220
                            spacing: 6

                            SectionLabel { text: "NIVEAU" }

                            Rectangle {
                                id: niveauTrigger
                                width: parent.width; height: 44; radius: 12
                                color: Style.bgPage; border.color: Style.borderLight

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 12
                                    spacing: 6
                                    Text {
                                        Layout.fillWidth: true
                                        text: {
                                            for (var i = 0; i < root.niveaux.length; i++) {
                                                if (root.niveaux[i].id === root.selectedNiveauId) return root.niveaux[i].nom
                                            }
                                            return "Sélectionner..."
                                        }
                                        font.pixelSize: 13; font.bold: true
                                        color: root.selectedNiveauId !== 0 ? Style.textPrimary : Style.textTertiary
                                        elide: Text.ElideRight
                                    }
                                    Text { text: "▾"; font.pixelSize: 11; color: Style.textTertiary }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: niveauPopup.open()
                                }

                                Popup {
                                    id: niveauPopup
                                    y: parent.height + 4
                                    width: parent.width
                                    padding: 0
                                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                                    background: Rectangle {
                                        radius: 12
                                        color: "#FFFFFF"
                                        border.color: Style.borderLight
                                        border.width: 1
                                    }

                                    Column {
                                        width: parent.width

                                        Repeater {
                                            model: root.niveaux
                                            delegate: Rectangle {
                                                width: niveauPopup.width
                                                height: 40
                                                color: nvHover.containsMouse ? Style.bgPage : "transparent"
                                                radius: 8

                                                Text {
                                                    anchors.left: parent.left; anchors.leftMargin: 14
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.nom
                                                    font.pixelSize: 13; font.bold: true
                                                    color: root.selectedNiveauId === modelData.id ? Style.primary : Style.textPrimary
                                                }

                                                MouseArea {
                                                    id: nvHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.selectedNiveauId = modelData.id
                                                        root.selectedClasseId = 0
                                                        root.niveauSelected(modelData.id)
                                                        niveauPopup.close()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Sélecteur CLASSE (filtré par niveau) ──
                        Column {
                            Layout.preferredWidth: 220
                            spacing: 6
                            opacity: root.selectedNiveauId !== 0 ? 1.0 : 0.4

                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            SectionLabel { text: "CLASSE" }

                            Rectangle {
                                id: classeTrigger
                                width: parent.width; height: 44; radius: 12
                                color: Style.bgPage; border.color: Style.borderLight

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 12
                                    spacing: 6
                                    Text {
                                        Layout.fillWidth: true
                                        text: {
                                            for (var i = 0; i < root.classes.length; i++) {
                                                if (root.classes[i].id === root.selectedClasseId) return root.classes[i].nom
                                            }
                                            return "Sélectionner..."
                                        }
                                        font.pixelSize: 13; font.bold: true
                                        color: root.selectedClasseId !== 0 ? Style.textPrimary : Style.textTertiary
                                        elide: Text.ElideRight
                                    }
                                    Text { text: "▾"; font.pixelSize: 11; color: Style.textTertiary }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: root.selectedNiveauId !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: { if (root.selectedNiveauId !== 0) classePopup.open() }
                                }

                                Popup {
                                    id: classePopup
                                    y: parent.height + 4
                                    width: parent.width
                                    padding: 0
                                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                                    background: Rectangle {
                                        radius: 12
                                        color: "#FFFFFF"
                                        border.color: Style.borderLight
                                        border.width: 1
                                    }

                                    Column {
                                        width: parent.width

                                        Repeater {
                                            model: {
                                                var result = []
                                                for (var i = 0; i < root.classes.length; i++) {
                                                    if (root.classes[i].niveauId === root.selectedNiveauId)
                                                        result.push(root.classes[i])
                                                }
                                                return result
                                            }
                                            delegate: Rectangle {
                                                width: classePopup.width
                                                height: 40
                                                color: clHover.containsMouse ? Style.bgPage : "transparent"
                                                radius: 8

                                                Text {
                                                    anchors.left: parent.left; anchors.leftMargin: 14
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.nom
                                                    font.pixelSize: 13; font.bold: true
                                                    color: root.selectedClasseId === modelData.id ? Style.primary : Style.textPrimary
                                                }

                                                MouseArea {
                                                    id: clHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.selectedClasseId = modelData.id
                                                        classePopup.close()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                // Section 3: Contacts
                Column {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: Style.primary
                            Text { anchors.centerIn: parent; text: "3"; font.pixelSize: 10; font.weight: Font.Black; color: "#FFFFFF" }
                        }

                        Text {
                            text: "CONTACTS"
                            font.pixelSize: 10; font.weight: Font.Black; color: Style.textPrimary; font.letterSpacing: 1
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 16

                        FormField {
                            id: phoneField
                            Layout.fillWidth: true
                            label: "TÉLÉPHONE DE CONTACT"
                            placeholder: "06 12 34 56 78"
                            nextTabItem: addressField.inputItem
                            prevTabItem: prenomField.inputItem
                            validator: RegularExpressionValidator {
                                regularExpression: /^\+?[0-9]*$/
                            }
                        }

                        FormField {
                            id: addressField
                            Layout.fillWidth: true
                            label: "ADRESSE DE RÉSIDENCE"
                            placeholder: "Adresse complète"
                            nextTabItem: nameField.inputItem
                            prevTabItem: phoneField.inputItem
                        }
                    }
                }
            }
        }

        // Modal Footer
        Rectangle {
            width: parent.width
            height: 80
            color: "#FAFBFC"

            Separator {
                anchors.top: parent.top
                width: parent.width
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    height: 48; radius: 16
                    color: Style.bgPage; border.color: Style.borderLight

                    Text {
                        anchors.centerIn: parent
                        text: "ANNULER"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 48; radius: 16

                    readonly property bool canConfirm:
                        nameField.text.trim().length > 0 &&
                        prenomField.text.trim().length > 0 &&
                        addressField.text.trim().length > 0 &&
                        root.selectedClasseId !== 0 &&
                        birthDateField.isValid

                    color: canConfirm ? Style.primary : Style.bgSecondary

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "CONFIRMER L'INSCRIPTION"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: parent.canConfirm ? "#FFFFFF" : Style.textTertiary
                        font.letterSpacing: 1

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.canConfirm
                        cursorShape: parent.canConfirm ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root.createRequested({
                                nom: nameField.text,
                                prenom: prenomField.text,
                                telephone: phoneField.text,
                                adresse: addressField.text,
                                dateNaissance: birthDateField.dateString,
                                categorie: birthDateField.categorie,
                                classeId: root.selectedClasseId
                            })
                            nameField.text = ""
                            prenomField.text = ""
                            phoneField.text = ""
                            addressField.text = ""
                            birthDateField.clear()
                            root.selectedNiveauId = 0
                            root.selectedClasseId = 0
                        }
                    }
                }
            }
        }
    }
}
