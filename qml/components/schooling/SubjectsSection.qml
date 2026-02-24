import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

AppCard {
    id: root
    title: "Matières enseignées : " + selectedNiveauNom
    subtitle: "Ajoutez ou supprimez des cours pour ce niveau"

    required property var matieres
    required property string selectedNiveauNom
    required property int selectedNiveauId

    signal matiereCreateRequested(string nom)
    signal matiereDeleteRequested(int id)
    signal matiereEditRequested(int id)

    Column {
        width: parent.width
        spacing: 18

        Flow {
            width: parent.width
            spacing: 12

            Repeater {
                model: root.matieres

                Rectangle {
                    implicitWidth: subjectRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: Style.bgPage
                    border.color: subjectCardHover.hovered ? Style.primary : Style.borderLight

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    HoverHandler { id: subjectCardHover }

                    RowLayout {
                        id: subjectRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData.nom
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }

                        IconButton {
                            iconName: "edit"
                            iconSize: 12
                            hoverColor: Style.primary
                            onClicked: root.matiereEditRequested(modelData.id)
                        }

                        IconButton {
                            iconName: "close"
                            iconSize: 12
                            hoverColor: Style.errorColor
                            onClicked: root.matiereDeleteRequested(modelData.id)
                        }
                    }
                }
            }
        }

        Separator { width: parent.width }

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
                        iconName: "book"
                        iconSize: 16
                        iconColor: Style.textTertiary
                    }

                    TextInput {
                        id: newSubjectInput
                        Layout.fillWidth: true
                        font.pixelSize: 13
                        font.bold: true
                        color: Style.textPrimary
                        cursorVisible: true

                        Text {
                            visible: !parent.text
                            text: "Nom de la nouvelle matière..."
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
                    if (newSubjectInput.text.trim() !== "" && root.selectedNiveauId > 0) {
                        root.matiereCreateRequested(newSubjectInput.text.trim())
                        newSubjectInput.text = ""
                    }
                }
            }
        }
    }
}
