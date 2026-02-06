import QtQuick 2.15

Rectangle {
    id: control
    property real value: 0  // 0.0 to 1.0
    property color barColor: Style.primary
    property color completeColor: Style.successColor

    implicitHeight: 8
    radius: 4
    color: Style.bgSecondary

    Rectangle {
        width: parent.width * Math.min(1, Math.max(0, control.value))
        height: parent.height
        radius: parent.radius
        color: control.value >= 1.0 ? control.completeColor : control.barColor

        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }
}
