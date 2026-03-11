import QtQuick

Rectangle {
    id: control
    property string iconName: ""
    property int iconSize: 18
    property color hoverColor: Style.textPrimary

    width: 36; height: 36
    radius: 10
    color: mouseArea.pressed ? Qt.rgba(0.85, 0.85, 0.85, 1) : Style.bgPage
    border.color: Style.borderLight

    Behavior on color { ColorAnimation { duration: 150 } }

    signal clicked()

    HoverHandler {
        id: hover
    }

    IconLabel {
        anchors.centerIn: parent
        iconName: control.iconName
        iconSize: control.iconSize
        iconColor: hover.hovered ? control.hoverColor : Style.textTertiary
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }
}
