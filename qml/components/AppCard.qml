import QtQuick
import QtQuick.Layouts

Rectangle {
    id: control

    property string title: ""
    property string subtitle: ""
    property alias headerAction: headerActionLoader.sourceComponent
    property alias content: contentArea.data
    default property alias _content: contentArea.data

    implicitHeight: mainCol.implicitHeight
    radius: Style.radiusRound
    color: Style.bgWhite
    border.color: Style.borderLight
    border.width: 1

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Header
        Item {
            visible: control.title !== "" || headerActionLoader.item
            Layout.fillWidth: true
            Layout.preferredHeight: headerRow.implicitHeight + 32

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                anchors.topMargin: 16
                anchors.bottomMargin: 16

                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        visible: control.title
                        text: control.title
                        font.pixelSize: 16
                        font.bold: true
                        color: Style.textPrimary
                    }
                    Text {
                        visible: control.subtitle
                        text: control.subtitle
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Style.textTertiary
                    }
                }

                Loader {
                    id: headerActionLoader
                }
            }

            // Divider
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Style.borderLight
                visible: control.title !== ""
            }
        }

        // Content
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height + 48
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 24
            Layout.bottomMargin: 24
        }
    }
}
