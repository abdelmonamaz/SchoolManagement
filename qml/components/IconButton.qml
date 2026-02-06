import QtQuick 2.15

Rectangle {
    id: control
    property string iconName: ""
    property int iconSize: 18
    property color hoverColor: Style.textPrimary

    width: 36; height: 36
    radius: 10
    color: mouseArea.containsMouse ? Style.bgPage : "transparent"
    border.color: mouseArea.containsMouse ? Style.borderLight : "transparent"

    Behavior on color { ColorAnimation { duration: 150 } }

    signal clicked()

    IconLabel {
        anchors.centerIn: parent
        iconName: control.iconName
        iconSize: control.iconSize
        iconColor: mouseArea.containsMouse ? control.hoverColor : Style.textTertiary
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }
}
