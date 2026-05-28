import QtQuick
import QtQuick.Layouts
import UI.Components

Column {
    id: root
    width: parent.width
    spacing: 24

    required property var salles

    signal roomAddRequested()
    signal roomEditRequested(int id, string nom, int capaciteChaises, string equipement)
    signal roomDeleteRequested(int id)

    RowLayout {
        width: parent.width
        Item { Layout.fillWidth: true }
        PrimaryButton {
            text: qsTr("Ajouter une Salle")
            iconName: "plus"
            onClicked: root.roomAddRequested()
        }
    }

    GridLayout {
        width: parent.width
        columns: 4
        columnSpacing: 20
        rowSpacing: 20

        Repeater {
            model: root.salles

            delegate: Rectangle {
                property string roomEquipment: modelData.equipement || ""

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
                            Text { anchors.centerIn: parent; text: qsTr("🏫"); font.pixelSize: 20 }
                        }

                        Item { Layout.fillWidth: true }

                        Row {
                            spacing: 4
                            IconButton {
                                iconName: "edit"
                                iconSize: 14
                                onClicked: root.roomEditRequested(
                                    modelData.id,
                                    modelData.nom,
                                    modelData.capaciteChaises,
                                    modelData.equipement || ""
                                )
                            }
                            IconButton {
                                iconName: "delete"
                                iconSize: 14
                                hoverColor: Style.errorColor
                                onClicked: root.roomDeleteRequested(modelData.id)
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 8
                        Text { text: modelData.nom; font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                        Badge { text: modelData.capaciteChaises + " Places"; variant: "info" }
                    }

                    Separator { width: parent.width }

                    Column {
                        width: parent.width
                        spacing: 8

                        SectionLabel { text: qsTr("ÉQUIPEMENTS") }

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
                                        Text { text: qsTr("✓"); font.pixelSize: 10; color: Style.successColor }
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
                    z: -1
                    hoverEnabled: true
                }
            }
        }
    }
}
