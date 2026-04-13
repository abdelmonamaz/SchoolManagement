import QtQuick
import QtQuick.Layouts
import UI.Components

Rectangle {
    id: root

    property string docIcon:   "download"
    property string colorKey:  "primary"
    property string docTitle:  ""
    property string docDesc:   ""
    property bool   isLoading: false

    signal generate()

    readonly property color _bg:     colorKey==="success" ? Style.successBg
                                   : colorKey==="error"   ? Style.errorBg
                                   : colorKey==="warning" ? Style.warningBg
                                   : colorKey==="neutral" ? Style.bgPage
                                   : Style.primaryBg
    readonly property color _border: colorKey==="success" ? Style.successBorder
                                   : colorKey==="error"   ? Style.errorBorder
                                   : colorKey==="warning" ? Style.warningBorder
                                   : colorKey==="neutral" ? Style.borderLight
                                   : "#BBDACE"
    readonly property color _icon:   colorKey==="success" ? Style.successColor
                                   : colorKey==="error"   ? Style.errorColor
                                   : colorKey==="warning" ? Style.warningColor
                                   : colorKey==="neutral" ? Style.textSecondary
                                   : Style.primary

    // Fixed height — no dynamic content-based sizing
    height: 200
    radius: 14
    color: cardHover.containsMouse ? Qt.lighter(_bg, 0.97) : _bg
    border.color: _border
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea { id: cardHover; anchors.fill: parent; hoverEnabled: true; z: -1 }

    // Icon
    Rectangle {
        x: 16; y: 20; width: 44; height: 44; radius: 14
        color: Qt.rgba(root._icon.r, root._icon.g, root._icon.b, 0.15)
        IconLabel { anchors.centerIn: parent; iconName: root.docIcon; iconSize: 20; iconColor: root._icon }
    }

    // Title
    Text {
        x: 16; y: 74; width: parent.width - 32
        text: root.docTitle
        font.pixelSize: 12; font.weight: Font.Black; color: Style.textPrimary
        wrapMode: Text.WordWrap
    }

    // Description
    Text {
        x: 16; y: 96; width: parent.width - 32; height: 52
        text: root.docDesc
        font.pixelSize: 10; color: Style.textTertiary
        wrapMode: Text.WordWrap; lineHeight: 1.4
        clip: true
    }

    // Generate button
    Rectangle {
        x: 16; y: 156; width: parent.width - 32; height: 32; radius: 8
        color: root.isLoading ? Style.bgTertiary
             : btnMa.containsMouse ? root._icon : Qt.rgba(root._icon.r, root._icon.g, root._icon.b, 0.12)
        Behavior on color { ColorAnimation { duration: 100 } }

        Row {
            anchors.centerIn: parent; spacing: 6

            Rectangle {
                visible: root.isLoading
                width: 12; height: 12; radius: 6; color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                border.color: Style.textTertiary; border.width: 2
                RotationAnimator on rotation {
                    running: root.isLoading; loops: Animation.Infinite
                    from: 0; to: 360; duration: 900
                }
            }

            IconLabel {
                visible: !root.isLoading
                anchors.verticalCenter: parent.verticalCenter
                iconName: "download"; iconSize: 12
                iconColor: btnMa.containsMouse ? "white" : root._icon
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.isLoading ? qsTr("Export en cours…") : qsTr("Générer CSV")
                font.pixelSize: 10; font.weight: Font.Black
                color: root.isLoading ? Style.textTertiary
                     : btnMa.containsMouse ? "white" : root._icon
            }
        }

        MouseArea {
            id: btnMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: root.isLoading ? Qt.BusyCursor : Qt.PointingHandCursor
            enabled: !root.isLoading
            onClicked: root.generate()
        }
    }
}
