import QtQuick
import QtQuick.Layouts
import UI.Components

ModalOverlay {
    id: root

    required property var availableEquipments

    signal equipmentAdded(string name)
    signal equipmentDeleted(int index)
    signal closeRequested()

    modalWidth: 450
    onClose: root.closeRequested()

    Column {
        width: parent.width
        spacing: 0
        padding: 32

        Text {
            text: "Gérer les Équipements"
            font.pixelSize: 22
            font.weight: Font.Black
            color: Style.textPrimary
        }

        Item { width: 1; height: 24 }

        Column {
            width: parent.width - 64
            spacing: 12

            SectionLabel { text: "ÉQUIPEMENTS DISPONIBLES" }

            Column {
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.availableEquipments

                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 12
                        color: Style.bgPage
                        border.color: Style.borderLight

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                text: modelData.nom || modelData
                                font.pixelSize: 13
                                font.bold: true
                                color: Style.textPrimary
                            }

                            IconButton {
                                iconName: "delete"
                                iconSize: 12
                                hoverColor: Style.errorColor
                                onClicked: root.equipmentDeleted(index)
                            }
                        }
                    }
                }
            }

            Separator { width: parent.width }

            // Ajouter un nouvel équipement
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
                            iconName: "plus"
                            iconSize: 16
                            iconColor: Style.textTertiary
                        }

                        TextInput {
                            id: newEquipmentInput
                            Layout.fillWidth: true
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                            cursorVisible: true

                            Text {
                                visible: !parent.text
                                text: "Nouvel équipement..."
                                font: parent.font
                                color: Style.textTertiary
                            }

                            HoverHandler {
                                cursorShape: Qt.IBeamCursor
                            }
                        }
                    }
                }

                PrimaryButton {
                    text: "AJOUTER"
                    iconName: "plus"
                    onClicked: {
                        if (newEquipmentInput.text.trim() !== "") {
                            root.equipmentAdded(newEquipmentInput.text.trim())
                            newEquipmentInput.text = ""
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 24 }

        Rectangle {
            width: parent.width - 64
            height: 48
            radius: 16
            color: Style.primary

            Text {
                anchors.centerIn: parent
                text: "FERMER"
                font.pixelSize: 10
                font.weight: Font.Black
                color: "#FFFFFF"
                font.letterSpacing: 0.5
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }
}
