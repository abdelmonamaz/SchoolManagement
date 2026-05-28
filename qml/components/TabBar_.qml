import QtQuick
import QtQuick.Layouts

Rectangle {
    id: control
    property var tabs: []  // [{id: "", label: ""}]
    property string currentTab: tabs.length > 0 ? tabs[0].id : ""

    signal tabChanged(string tabId)

    implicitHeight: 46
    implicitWidth: tabRow.implicitWidth + 12
    radius: 16
    color: Style.bgSecondary

    Row {
        id: tabRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: control.tabs

            Rectangle {
                width: tabLabel.implicitWidth + 48
                height: 38
                radius: 12
                color: control.currentTab === modelData.id ? Style.bgWhite : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: tabLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    font.pixelSize: 13
                    font.bold: true
                    color: control.currentTab === modelData.id ? Style.primary : Style.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        control.currentTab = modelData.id
                        control.tabChanged(modelData.id)
                    }
                }
            }
        }
    }
}
