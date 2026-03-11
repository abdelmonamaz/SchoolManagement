import QtQuick
import QtQuick.Layouts

Rectangle {
    id: control
    property string text: ""
    property string iconName: ""

    signal clicked()

    implicitWidth: row.implicitWidth + 40
    implicitHeight: 48
    radius: 16
    opacity: control.enabled ? 1.0 : 0.4
    color: mouseArea.pressed ? Style.primaryDark : (mouseArea.containsMouse ? Style.primaryDark : Style.primary)

    Behavior on color { ColorAnimation { duration: 100 } }
    Behavior on opacity { NumberAnimation { duration: 150 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        IconLabel {
            visible: control.iconName !== ""
            iconName: control.iconName
            iconSize: 18
            iconColor: "#FFFFFF"
        }

        Text {
            text: control.text
            font.pixelSize: 14
            font.bold: true
            color: "#FFFFFF"
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: control.clicked()
    }
}
