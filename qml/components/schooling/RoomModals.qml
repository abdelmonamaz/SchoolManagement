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
    required property var editingRoom
    required property int deletingRoomId
    required property var availableEquipments
    property var selectedEquipments: []

    signal createRequested(var data)
    signal editRequested(int id, var data)
    signal deleteRequested(int id)
    signal closeRequested()
    signal manageEquipmentsRequested()

    // ─── Room Modal (Create) ───
    ModalOverlay {
        show: root.showCreate
        modalWidth: 480
        onClose: root.closeRequested()

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Nouvelle Salle"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Item { width: 1; height: 24 }

            Column {
                width: parent.width - 64
                spacing: 18

                FormField { id: roomNameField; width: parent.width; label: "NOM DE LA SALLE"; placeholder: "ex: Salle B1" }
                FormField { id: capacityField; width: parent.width; label: "CAPACITÉ"; text: "20" }

                Column {
                    width: parent.width
                    spacing: 8

                    RowLayout {
                        width: parent.width
                        SectionLabel { text: "ÉQUIPEMENTS"; Layout.fillWidth: true }
                        IconButton {
                            iconName: "settings"
                            iconSize: 14
                            onClicked: root.manageEquipmentsRequested()
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: root.availableEquipments

                            Rectangle {
                                property bool selected: false
                                property string equipName: modelData.nom || modelData
                                Layout.fillWidth: true
                                height: 40; radius: 12
                                color: selected ? Style.primary : Style.bgPage
                                border.color: Style.borderLight

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.equipName; font.pixelSize: 11; font.bold: true
                                    color: parent.selected ? "#FFFFFF" : Style.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        parent.selected = !parent.selected
                                        if (parent.selected)
                                            root.selectedEquipments.push(parent.equipName)
                                        else
                                            root.selectedEquipments = root.selectedEquipments.filter(function(e) { return e !== parent.equipName })
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
                onCancel: root.closeRequested()
                onConfirm: {
                    if (roomNameField.text.trim() !== "") {
                        root.createRequested({
                            nom: roomNameField.text.trim(),
                            capaciteChaises: parseInt(capacityField.text),
                            equipement: root.selectedEquipments.join(", ")
                        })
                        roomNameField.text = ""
                        capacityField.text = "20"
                        root.selectedEquipments = []
                    }
                }
            }
        }
    }

    // ─── Modal Éditer Salle ───
    ModalOverlay {
        show: root.showEdit
        modalWidth: 480
        onClose: root.closeRequested()

        onShowChanged: {
            if (show) {
                editRoomNameField.text = root.editingRoom.nom
                editCapacityField.text = root.editingRoom.capaciteChaises.toString()
                // Pré-sélectionner les équipements existants
                var existingEquip = root.editingRoom.equipement ? root.editingRoom.equipement.split(", ") : []
                root.selectedEquipments = existingEquip.slice()
            }
        }

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Modifier la Salle"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Item { width: 1; height: 24 }

            Column {
                width: parent.width - 64
                spacing: 18

                FormField { id: editRoomNameField; width: parent.width; label: "NOM DE LA SALLE"; placeholder: "ex: Salle B1" }
                FormField { id: editCapacityField; width: parent.width; label: "CAPACITÉ"; text: "20" }

                Column {
                    width: parent.width
                    spacing: 8

                    RowLayout {
                        width: parent.width
                        SectionLabel { text: "ÉQUIPEMENTS"; Layout.fillWidth: true }
                        IconButton {
                            iconName: "settings"
                            iconSize: 14
                            onClicked: root.manageEquipmentsRequested()
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            id: editEquipRepeater
                            model: root.availableEquipments

                            Rectangle {
                                property string equipName: modelData.nom || modelData
                                property bool selected: root.selectedEquipments.indexOf(equipName) >= 0
                                Layout.fillWidth: true
                                height: 40; radius: 12
                                color: selected ? Style.primary : Style.bgPage
                                border.color: Style.borderLight

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.equipName; font.pixelSize: 11; font.bold: true
                                    color: parent.selected ? "#FFFFFF" : Style.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.selected) {
                                            root.selectedEquipments = root.selectedEquipments.filter(function(e) { return e !== parent.equipName })
                                        } else {
                                            var temp = root.selectedEquipments.slice()
                                            temp.push(parent.equipName)
                                            root.selectedEquipments = temp
                                        }
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
                confirmText: "MODIFIER"
                onCancel: root.closeRequested()
                onConfirm: {
                    if (editRoomNameField.text.trim() !== "" && root.editingRoom.id > 0) {
                        root.editRequested(root.editingRoom.id, {
                            nom: editRoomNameField.text.trim(),
                            capaciteChaises: parseInt(editCapacityField.text),
                            equipement: root.selectedEquipments.join(", ")
                        })
                        root.selectedEquipments = []
                    }
                }
            }
        }
    }

    // ─── Confirmation Suppression Salle ───
    Popup {
        id: deleteRoomConfirmPopup
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
                text: "Supprimer la salle ?"
                font.pixelSize: 18
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Text {
                width: parent.width - 56
                text: "Cette salle sera définitivement supprimée."
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
                            if (root.deletingRoomId > 0) {
                                root.deleteRequested(root.deletingRoomId)
                            }
                        }
                    }
                }
            }
        }
    }
}
