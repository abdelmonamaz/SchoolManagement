import QtQuick
import QtQuick.Layouts

Rectangle {
    id: control
    property string text: ""
    property string iconName: ""
    property color textColor: Style.textSecondary
    property color baseColor: Style.bgWhite
    property color hoverColor: Style.bgPage

    signal clicked()

    implicitWidth: row.implicitWidth + 36
    implicitHeight: 48
    radius: 16
    color: mouseArea.containsMouse ? control.hoverColor : control.baseColor
    border.color: Style.borderLight
    border.width: 1

    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        IconLabel {
            visible: control.iconName !== ""
            iconName: control.iconName
            iconSize: 18
            iconColor: control.textColor
        }

        Text {
            text: control.text
            font.pixelSize: 14
            font.bold: true
            color: control.textColor
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }
}
