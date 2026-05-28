import QtQuick
import QtQuick.Layouts

Rectangle {
    id: control

    property string text: ""
    property string iconName: ""
    property bool active: false

    signal clicked()

    implicitHeight: 48
    radius: 12
    color: active ? Style.primary : (mouseArea.containsMouse ? Style.bgPage : "transparent")

    layer.enabled: active
    layer.effect: null

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        IconLabel {
            iconName: control.iconName
            iconSize: 20
            iconColor: control.active ? Style.primaryForeground : Style.textSecondary
        }

        Text {
            Layout.fillWidth: true
            text: qsTr(control.text)
            font.pixelSize: 14
            font.weight: Font.Medium
            color: control.active ? Style.primaryForeground : Style.textSecondary
            elide: Text.ElideRight
            // Use implicit alignment to respect RTL
            horizontalAlignment: Text.AlignLeft
        }

        Text {
            visible: control.active
            // Using a generic arrow. In RTL it might need a left arrow or let the font mirror it.
            // A safer RTL approach for chevron is to use an IconLabel with rotation, but sticking to text for now.
            text: Qt.application.layoutDirection === Qt.RightToLeft ? "‹" : "›"
            font.pixelSize: 18
            font.bold: true
            color: Style.primaryForeground
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

