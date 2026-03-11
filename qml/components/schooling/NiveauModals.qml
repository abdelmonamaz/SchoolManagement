import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

Item {
    id: root
    anchors.fill: parent

    required property bool showCreate
    required property bool showEdit
    required property bool showDelete
    required property var editingNiveau
    required property int deletingNiveauId

    signal createRequested(string nom)
    signal editRequested(int id, string nom)
    signal deleteRequested(int id)
    signal closeRequested()

    // ─── Modal Nouveau Niveau ───
    ModalOverlay {
        show: root.showCreate
        modalWidth: 420
        onClose: root.closeRequested()

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Nouveau Niveau"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Item { width: 1; height: 24 }

            FormField {
                id: niveauNameField
                width: parent.width - 64
                label: "NOM DU NIVEAU"
                placeholder: "ex: Niveau 1, Niveau 2, etc."
            }

            Item { width: 1; height: 24 }

            ModalButtons {
                width: parent.width - 64
                confirmText: "CRÉER"
                onCancel: root.closeRequested()
                onConfirm: {
                    if (niveauNameField.text.trim() !== "") {
                        root.createRequested(niveauNameField.text.trim())
                        niveauNameField.text = ""
                    }
                }
            }
        }
    }

    // ─── Modal Éditer Niveau ───
    ModalOverlay {
        show: root.showEdit
        modalWidth: 420
        onClose: root.closeRequested()

        onShowChanged: {
            if (show)
                editNiveauNameField.text = root.editingNiveau.nom
        }

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Modifier le Niveau"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Item { width: 1; height: 24 }

            FormField {
                id: editNiveauNameField
                width: parent.width - 64
                label: "NOM DU NIVEAU"
                placeholder: "ex: Niveau 1, Niveau 2, etc."
            }

            Item { width: 1; height: 24 }

            ModalButtons {
                width: parent.width - 64
                confirmText: "MODIFIER"
                onCancel: root.closeRequested()
                onConfirm: {
                    if (editNiveauNameField.text.trim() !== "" && root.editingNiveau.id > 0) {
                        root.editRequested(root.editingNiveau.id, editNiveauNameField.text.trim())
                        editNiveauNameField.text = ""
                    }
                }
            }
        }
    }

    // ─── Confirmation Suppression Niveau ───
    Popup {
        id: deleteNiveauConfirmPopup
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
                text: "Supprimer le niveau ?"
                font.pixelSize: 18
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Text {
                width: parent.width - 56
                text: "⚠️ Attention : Supprimer ce niveau supprimera également toutes les classes et matières associées."
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
                            if (root.deletingNiveauId > 0) {
                                root.deleteRequested(root.deletingNiveauId)
                            }
                        }
                    }
                }
            }
        }
    }
}
