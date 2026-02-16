import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

AppCard {
    id: root
    title: "Groupes & Classes"
    subtitle: "Structure actuelle du " + selectedNiveauNom

    required property var classes
    required property var students
    required property string selectedNiveauNom

    signal classCardClicked(int classeId, string classeNom)
    signal classEditRequested(int id, string nom)
    signal classDeleteRequested(int id)
    signal classAddRequested()

    GridLayout {
        width: parent.width
        columns: 3
        columnSpacing: 18
        rowSpacing: 18

        Repeater {
            model: root.classes

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 140
                radius: 24
                color: Style.bgPage
                border.color: classCardHover.hovered ? Style.primary : Style.borderLight

                Behavior on border.color { ColorAnimation { duration: 200 } }

                HoverHandler {
                    id: classCardHover
                    cursorShape: Qt.PointingHandCursor
                }

                // Clic sur le fond de la carte → popup étudiants
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.classCardClicked(modelData.id, modelData.nom)
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        width: parent.width

                        Rectangle {
                            width: 48; height: 48; radius: 16
                            color: classCardHover.hovered ? Style.primary : Style.bgWhite
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.nom
                                font.pixelSize: 18
                                font.weight: Font.Black
                                color: classCardHover.hovered ? "#FFFFFF" : Style.primary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Row {
                            spacing: 2

                            IconButton {
                                iconName: "edit"
                                iconSize: 14
                                onClicked: root.classEditRequested(modelData.id, modelData.nom)
                            }

                            IconButton {
                                iconName: "delete"
                                iconSize: 14
                                hoverColor: Style.errorColor
                                onClicked: root.classDeleteRequested(modelData.id)
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: "Classe " + modelData.nom
                            font.pixelSize: 14
                            font.weight: Font.Black
                            color: Style.textPrimary
                        }

                        Text {
                            property int cnt: {
                                var c = 0
                                for (var i = 0; i < root.students.length; i++) {
                                    if (root.students[i].classeId === modelData.id) c++
                                }
                                return c
                            }
                            text: cnt + " élève" + (cnt > 1 ? "s" : "")
                            font.pixelSize: 12
                            color: Style.textTertiary
                        }
                    }
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
                onClicked: root.classAddRequested()
            }
        }
    }
}
