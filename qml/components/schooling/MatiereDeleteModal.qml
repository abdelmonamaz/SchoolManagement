import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

Popup {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 420
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    required property bool show
    required property int deletingMatiereId

    signal deleteRequested(int id)
    signal closeRequested()

    visible: show

    onVisibleChanged: {
        if (!visible) closeRequested()
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
            text: qsTr("Supprimer la matière ?")
            font.pixelSize: 18
            font.weight: Font.Black
            color: Style.textPrimary
        }

        Text {
            width: parent.width - 56
            text: qsTr("Cette matière sera définitivement supprimée de ce niveau.")
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
                    text: qsTr("ANNULER")
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
                    text: qsTr("SUPPRIMER")
                    font.pixelSize: 11
                    font.weight: Font.Black
                    color: Style.background
                    font.letterSpacing: 0.5
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.deletingMatiereId > 0) {
                            root.deleteRequested(root.deletingMatiereId)
                        }
                    }
                }
            }
        }
    }
}
