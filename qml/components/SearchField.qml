import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: control
    property string placeholder: "Rechercher..."
    property alias text: input.text

    implicitHeight: 48
    radius: 16
    color: Style.bgPage
    border.color: input.activeFocus ? Style.primary : Style.borderLight
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 150 } }

    HoverHandler {
        cursorShape: Qt.IBeamCursor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 10

        IconLabel {
            iconName: "search"
            iconSize: 16
            iconColor: Style.textTertiary
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            font.pixelSize: 14
            color: Style.textPrimary
            clip: true
            selectByMouse: true

            Text {
                visible: !parent.text && !parent.activeFocus
                text: control.placeholder
                color: Style.textTertiary
                font: parent.font
            }
        }
    }
}
