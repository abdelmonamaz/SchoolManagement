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

    required property var student
    required property var niveaux
    required property var allClasses  // Toutes les classes pour filtrage côté client

    property int selectedEditNiveauId: 0
    property int selectedEditClasseId: 0

    signal updateRequested(int studentId, var data)
    signal closeRequested()

    onClosed: root.closeRequested()

    onOpened: {
        editNameField.text = root.student.nom || ""
        editPrenomField.text = root.student.prenom || ""
        editPhoneField.text = root.student.telephone || ""
        editAddressField.text = root.student.adresse || ""
        editDateField.setDate(root.student.dateNaissance || "")

        // Find niveau from classeId
        var cid = root.student.classeId || 0
        root.selectedEditClasseId = cid

        for (var i = 0; i < root.allClasses.length; i++) {
            if (root.allClasses[i].id === cid) {
                root.selectedEditNiveauId = root.allClasses[i].niveauId
                break
            }
        }

        editNameField.inputItem.forceActiveFocus()
    }

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
                        text: "Modifier " + (root.student.prenom || "") + " " + (root.student.nom || "")
                        font.pixelSize: 20
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "METTEZ À JOUR LES INFORMATIONS DE L'ÉLÈVE"
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
                            id: editNameField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "NOM"
                            placeholder: "ex: Ben Moussa"
                        }

                        FormField {
                            id: editPrenomField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "PRÉNOM"
                            placeholder: "ex: Ahmed"
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

                    DateField {
                        id: editDateField
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
                                                if (root.niveaux[i].id === root.selectedEditNiveauId) return root.niveaux[i].nom
                                            }
                                            return "Changer..."
                                        }
                                        font.pixelSize: 13; font.bold: true
                                        color: root.selectedEditNiveauId !== 0 ? Style.textPrimary : Style.textTertiary
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
                                                    color: root.selectedEditNiveauId === modelData.id ? Style.primary : Style.textPrimary
                                                }

                                                MouseArea {
                                                    id: nvHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.selectedEditNiveauId = modelData.id
                                                        root.selectedEditClasseId = 0
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
                            opacity: root.selectedEditNiveauId !== 0 ? 1.0 : 0.4

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
                                            for (var i = 0; i < root.allClasses.length; i++) {
                                                if (root.allClasses[i].id === root.selectedEditClasseId) return root.allClasses[i].nom
                                            }
                                            if (root.selectedEditClasseId !== 0) return "Classe #" + root.selectedEditClasseId
                                            return "Sélectionner..."
                                        }
                                        font.pixelSize: 13; font.bold: true
                                        color: root.selectedEditClasseId !== 0 ? Style.textPrimary : Style.textTertiary
                                        elide: Text.ElideRight
                                    }
                                    Text { text: "▾"; font.pixelSize: 11; color: Style.textTertiary }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: root.selectedEditNiveauId !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: { if (root.selectedEditNiveauId !== 0) classePopup.open() }
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
                                                for (var i = 0; i < root.allClasses.length; i++) {
                                                    if (root.allClasses[i].niveauId === root.selectedEditNiveauId)
                                                        result.push(root.allClasses[i])
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
                                                    color: root.selectedEditClasseId === modelData.id ? Style.primary : Style.textPrimary
                                                }

                                                MouseArea {
                                                    id: clHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.selectedEditClasseId = modelData.id
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
                            id: editPhoneField
                            Layout.fillWidth: true
                            label: "TÉLÉPHONE DE CONTACT"
                            placeholder: "06 12 34 56 78"
                            validator: RegularExpressionValidator {
                                regularExpression: /^\+?[0-9]*$/
                            }
                        }

                        FormField {
                            id: editAddressField
                            Layout.fillWidth: true
                            label: "ADRESSE DE RÉSIDENCE"
                            placeholder: "ex: Rue de la Paix, Tunis"
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
                anchors.margins: 24
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    height: 48; radius: 16
                    color: Style.bgSecondary

                    Text {
                        anchors.centerIn: parent
                        text: "ANNULER"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.textTertiary; font.letterSpacing: 1
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

                    readonly property bool canConfirmEdit:
                        editNameField.text.trim().length > 0 &&
                        editPrenomField.text.trim().length > 0 &&
                        editAddressField.text.trim().length > 0 &&
                        root.selectedEditClasseId !== 0 &&
                        editDateField.isValid

                    color: canConfirmEdit ? Style.primary : Style.bgSecondary

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "METTRE À JOUR"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: parent.canConfirmEdit ? "#FFFFFF" : Style.textTertiary
                        font.letterSpacing: 1

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.canConfirmEdit
                        cursorShape: parent.canConfirmEdit ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root.updateRequested(root.student.id, {
                                nom: editNameField.text,
                                prenom: editPrenomField.text,
                                telephone: editPhoneField.text,
                                adresse: editAddressField.text,
                                dateNaissance: editDateField.dateString,
                                categorie: editDateField.categorie,
                                classeId: root.selectedEditClasseId
                            })
                        }
                    }
                }
            }
        }
    }
}
