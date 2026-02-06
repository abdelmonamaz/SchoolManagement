import QtQuick 2.15
import QtQuick.Layouts 1.15
Rectangle {
    id: control

    property string label: ""
    property string value: ""
    property string trend: ""
    property bool trendUp: true
    property string iconName: ""
    property color accentColor: Style.chartBlue
    property color accentBg: Style.chartBlueLight

    implicitHeight: 160
    radius: Style.radiusRound
    color: Style.bgWhite
    border.color: mouseArea.containsMouse ? Style.borderMedium : Style.borderLight
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 200 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            // Icon circle
            Rectangle {
                width: 48; height: 48
                radius: 16
                color: control.accentBg

                IconLabel {
                    anchors.centerIn: parent
                    iconName: control.iconName
                    iconSize: 22
                    iconColor: control.accentColor
                }
            }

            Item { Layout.fillWidth: true }

            // Trend badge
            Rectangle {
                visible: control.trend !== ""
                implicitWidth: trendRow.implicitWidth + 12
                implicitHeight: trendRow.implicitHeight + 6
                radius: 8
                color: control.trendUp ? Style.successBg : Style.errorBg

                Row {
                    id: trendRow
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        text: control.trendUp ? "↗" : "↘"
                        font.pixelSize: 11
                        font.bold: true
                        color: control.trendUp ? Style.successColor : Style.errorColor
                    }
                    Text {
                        text: control.trend
                        font.pixelSize: 11
                        font.bold: true
                        color: control.trendUp ? Style.successColor : Style.errorColor
                    }
                }
            }
        }

        Text {
            text: control.label
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Style.textTertiary
        }

        Text {
            text: control.value
            font.pixelSize: 26
            font.weight: Font.Black
            color: Style.textPrimary
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
