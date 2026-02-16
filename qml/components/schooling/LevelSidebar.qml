import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

Column {
    id: root
    width: 220
    spacing: 12

    required property var niveaux
    required property int selectedNiveauId

    signal niveauSelected(int niveauId)
    signal niveauEditRequested(int id, string nom)
    signal niveauDeleteRequested(int id)
    signal niveauAddRequested()

    SectionLabel {
        text: "SÉLECTIONNER UN NIVEAU"
        leftPadding: 4
    }

    Column {
        width: parent.width
        spacing: 8

        Repeater {
            model: root.niveaux

            Rectangle {
                width: 220
                height: 52
                radius: 16
                color: root.selectedNiveauId === modelData.id ? Style.primary : Style.bgWhite
                border.color: root.selectedNiveauId === modelData.id ? Style.primary : Style.borderLight

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 4
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: modelData.nom
                        font.pixelSize: 13
                        font.bold: true
                        color: root.selectedNiveauId === modelData.id ? "#FFFFFF" : Style.textPrimary
                    }

                    Row {
                        spacing: 2
                        visible: root.selectedNiveauId === modelData.id
                        IconButton {
                            iconName: "edit"
                            iconSize: 12
                            hoverColor: "#FFFFFF"
                            onClicked: root.niveauEditRequested(modelData.id, modelData.nom)
                        }
                        IconButton {
                            iconName: "delete"
                            iconSize: 12
                            hoverColor: Style.errorColor
                            onClicked: root.niveauDeleteRequested(modelData.id)
                        }
                    }

                    Text {
                        visible: root.selectedNiveauId !== modelData.id
                        text: "›"
                        font.pixelSize: 16
                        color: Style.textTertiary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.niveauSelected(modelData.id)
                }
            }
        }

        // Bouton Ajouter Niveau
        Rectangle {
            width: 220
            height: 52
            radius: 16
            color: "transparent"
            border.color: addNiveauMa.containsMouse ? Style.primary : Style.borderMedium
            border.width: 2

            Row {
                anchors.centerIn: parent
                spacing: 8

                IconLabel {
                    iconName: "plus"
                    iconSize: 16
                    iconColor: addNiveauMa.containsMouse ? Style.primary : Style.textTertiary
                }

                Text {
                    text: "NOUVEAU NIVEAU"
                    font.pixelSize: 10
                    font.weight: Font.Black
                    color: addNiveauMa.containsMouse ? Style.primary : Style.textTertiary
                    font.letterSpacing: 0.5
                }
            }

            MouseArea {
                id: addNiveauMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.niveauAddRequested()
            }
        }
    }
}
