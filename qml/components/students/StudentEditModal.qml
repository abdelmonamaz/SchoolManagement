import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

Popup {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 650
    modal: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    required property var student
    required property var niveaux
    required property var allClasses

    property string selectedEditSexe: "M"
    property int selectedEditNiveauId: 0
    property int selectedEditClasseId: 0

    signal updateRequested(int studentId, var data)
    signal closeRequested()

    onClosed: root.closeRequested()

    onOpened: {
        editNameField.text = root.student.nom || ""
        editPrenomField.text = root.student.prenom || ""
        root.selectedEditSexe = root.student.sexe || "M"
        editPhoneField.text = root.student.telephone || ""
        editAddressField.text = root.student.adresse || ""
        editParentNameField.text = root.student.nomParent || ""
        editParentPhoneField.text = root.student.telParent || ""
        editCinEleveField.text = root.student.cinEleve || ""
        editCinParentField.text = root.student.cinParent || ""
        editCommentField.text = root.student.commentaire || ""
        editDateField.setDate(root.student.dateNaissance || "")

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

    background: Rectangle { radius: 32; color: Style.bgWhite }
    Overlay.modal: Rectangle { color: "#0F172A99" }

    contentItem: Column {
        width: root.width; spacing: 0

        // Header
        Rectangle {
            width: parent.width; height: 80; color: Style.sandBg; radius: 32
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 40; color: Style.sandBg }
            Separator { anchors.bottom: parent.bottom; width: parent.width }
            RowLayout {
                anchors.fill: parent; anchors.margins: 24
                Column {
                    Layout.fillWidth: true; spacing: 4
                    Text { text: "Modifier le Profil"; font.pixelSize: 20; font.weight: Font.Black; color: Style.primary }
                    Text { text: "IDENTITÉ ET INFORMATIONS PERMANENTES"; font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary; font.letterSpacing: 1 }
                }
                IconButton { iconName: "close"; iconSize: 18; onClicked: root.closeRequested() }
            }
        }

        // Body
        Flickable {
            id: flickableBody
            width: parent.width; height: 500; contentHeight: bodyCol.implicitHeight + 64; clip: true

            ColumnLayout {
                id: bodyCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 24
                y: 32 // Add top margin without anchors to prevent binding loops
                height: Math.max(implicitHeight, flickableBody.height - 64)
                spacing: 24
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    FormField { id: editNameField; Layout.fillWidth: true; Layout.preferredWidth: 1; label: "NOM"; nextTabItem: editPrenomField.inputItem }
                    FormField { id: editPrenomField; Layout.fillWidth: true; Layout.preferredWidth: 1; label: "PRÉNOM"; nextTabItem: editDateField.inputItem; prevTabItem: editNameField.inputItem }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    Column {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 8; SectionLabel { text: "SEXE" }
                        Row {
                            spacing: 16
                            Row {
                                spacing: 8
                                Rectangle {
                                    width: 20; height: 20; radius: 10
                                    border.color: root.selectedEditSexe === "M" ? Style.primary : Style.borderMedium
                                    border.width: root.selectedEditSexe === "M" ? 6 : 2
                                    MouseArea { anchors.fill: parent; onClicked: root.selectedEditSexe = "M" }
                                }
                                Text { text: "Masculin"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                            }
                            Row {
                                spacing: 8
                                Rectangle {
                                    width: 20; height: 20; radius: 10
                                    border.color: root.selectedEditSexe === "F" ? Style.primary : Style.borderMedium
                                    border.width: root.selectedEditSexe === "F" ? 6 : 2
                                    MouseArea { anchors.fill: parent; onClicked: root.selectedEditSexe = "F" }
                                }
                                Text { text: "Féminin"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: editDateField.implicitHeight
                        DateField {
                            id: editDateField
                            width: 240
                            label: "DATE DE NAISSANCE"
                            nextTabItem: editPhoneField.inputItem
                            prevTabItem: editPrenomField.inputItem
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    FormField { id: editPhoneField; Layout.fillWidth: true; Layout.preferredWidth: 1; label: "TÉLÉPHONE"; nextTabItem: editAddressField.inputItem; prevTabItem: editDateField.inputItem }
                    FormField { id: editAddressField; Layout.fillWidth: true; Layout.preferredWidth: 1; label: "ADRESSE"; nextTabItem: editParentNameField.inputItem; prevTabItem: editPhoneField.inputItem }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    FormField { id: editParentNameField; Layout.fillWidth: true; Layout.preferredWidth: 1; label: "NOM DU PARENT"; nextTabItem: editParentPhoneField.inputItem; prevTabItem: editAddressField.inputItem }
                    FormField { id: editParentPhoneField; Layout.fillWidth: true; Layout.preferredWidth: 1; label: "TÉLÉPHONE PARENT"; nextTabItem: editCinEleveField.inputItem; prevTabItem: editParentNameField.inputItem }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    FormField { id: editCinEleveField; Layout.fillWidth: true; Layout.preferredWidth: 1; label: "CIN ÉLÈVE (optionnel)"; placeholder: "ex: 12345678"; nextTabItem: editCinParentField.inputItem; prevTabItem: editParentPhoneField.inputItem }
                    FormField { id: editCinParentField; Layout.fillWidth: true; Layout.preferredWidth: 1; label: "CIN PARENT (optionnel)"; placeholder: "ex: 12345678"; prevTabItem: editCinEleveField.inputItem }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    SectionLabel { text: "COMMENTAIRE / NOTES" }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 80
                        radius: 12
                        color: Style.bgPage; border.color: Style.borderLight
                        TextArea {
                            id: editCommentField; anchors.fill: parent; anchors.margins: 12
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary; wrapMode: TextEdit.Wrap; background: null
                        }
                    }
                }
            }
        }

        // Footer
        Rectangle {
            width: parent.width; height: 80; color: Style.bgPage
            Separator { anchors.top: parent.top; width: parent.width }
            RowLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 12
                OutlineButton { Layout.fillWidth: true; text: "ANNULER"; onClicked: root.closeRequested() }
                PrimaryButton {
                    Layout.fillWidth: true; text: "MODIFIER LES INFORMATIONS"
                    onClicked: root.updateRequested(root.student.id, {
                        nom: editNameField.text,
                        prenom: editPrenomField.text,
                        sexe: root.selectedEditSexe,
                        telephone: editPhoneField.text,
                        adresse: editAddressField.text,
                        dateNaissance: editDateField.dateString,
                        nomParent: editParentNameField.text,
                        telParent: editParentPhoneField.text,
                        commentaire: editCommentField.text,
                        categorie: editDateField.categorie,
                        classeId: root.selectedEditClasseId,
                        cinEleve: editCinEleveField.text,
                        cinParent: editCinParentField.text
                    })
                }
            }
        }
    }
}
