import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

Item {
    id: root
    anchors.fill: parent

    required property bool showCreate
    required property bool showEdit
    required property bool showDelete
    required property var editingClass
    required property int deletingClasseId
    required property string selectedNiveauNom
    required property int selectedNiveauId

    signal createRequested(string nom, int niveauId)
    signal editRequested(int id, string nom, int niveauId)
    signal deleteRequested(int id)
    signal closeRequested()

    // ─── Class Modal (Create) ───
    ModalOverlay {
        show: root.showCreate
        modalWidth: 420
        onClose: root.closeRequested()

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Nouveau Groupe (" + root.selectedNiveauNom + ")"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Item { width: 1; height: 24 }

            FormField {
                id: classNameField
                width: parent.width - 64
                label: "NOM DU GROUPE"
                placeholder: "ex: A, B, Matin, etc."
            }

            Item { width: 1; height: 24 }

            ModalButtons {
                width: parent.width - 64
                confirmText: "CRÉER"
                onCancel: root.closeRequested()
                onConfirm: {
                    if (classNameField.text.trim() !== "" && root.selectedNiveauId > 0) {
                        root.createRequested(classNameField.text.trim(), root.selectedNiveauId)
                        classNameField.text = ""
                    }
                }
            }
        }
    }

    // ─── Edit Class Modal ───
    ModalOverlay {
        show: root.showEdit
        modalWidth: 420
        onClose: root.closeRequested()

        onShowChanged: {
            if (show)
                editClassNameField.text = root.editingClass.nom
        }

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Modifier le Groupe"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Item { width: 1; height: 24 }

            FormField {
                id: editClassNameField
                width: parent.width - 64
                label: "NOM DU GROUPE"
                placeholder: "ex: A, B, Matin, etc."
            }

            Item { width: 1; height: 24 }

            ModalButtons {
                width: parent.width - 64
                confirmText: "MODIFIER"
                onCancel: root.closeRequested()
                onConfirm: {
                    if (editClassNameField.text.trim() !== "" && root.editingClass.id > 0) {
                        root.editRequested(root.editingClass.id, editClassNameField.text.trim(), root.selectedNiveauId)
                        editClassNameField.text = ""
                    }
                }
            }
        }
    }

    // ─── Confirmation Suppression Classe ───
    Popup {
        id: deleteClassConfirmPopup
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 420
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: root.showDelete

        onVisibleChanged: {
            if (!visible) root.closeRequested()
        }

        background: Rectangle {
            radius: 20
            color: Style.bgWhite
            border.color: Style.borderLight
        }

        Column {
            width: parent.width
            spacing: 20
            padding: 28

            Text {
                text: "Supprimer la classe ?"
                font.pixelSize: 18
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Text {
                width: parent.width - 56
                text: "Les élèves de cette classe seront retirés de la classe mais resteront dans la base de données."
                font.pixelSize: 13
                color: Style.textSecondary
                wrapMode: Text.WordWrap
            }

            RowLayout {
                width: parent.width - 56
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    Text {
                        anchors.centerIn: parent
                        text: "ANNULER"
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: Style.textSecondary
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: Style.errorColor

                    Text {
                        anchors.centerIn: parent
                        text: "SUPPRIMER"
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: "#FFFFFF"
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.deletingClasseId > 0) {
                                root.deleteRequested(root.deletingClasseId)
                            }
                        }
                    }
                }
            }
        }
    }
}
