import QtQuick
import QtQuick.Controls
import UI.Components

// Combo box with an optional "reset / none" item at the top of the popup.
// Used for optional fields (prof on exam, salle on event).
Rectangle {
    id: root

    property var    model:       []
    property string textRole:    "nom"
    property string valueRole:   "id"
    property bool   showReset:   false        // show the "Sélectionner…" reset item
    property string placeholder: "Sélectionner..."
    property alias  currentIndex: combo.currentIndex
    property alias  enabled:      combo.enabled

    signal valueSelected(var value)
    signal valueCleared()

    function reset() { combo.currentIndex = -1 }

    height: 44; radius: 12
    color: Style.bgPage
    border.color: Style.borderLight
    opacity: combo.enabled ? 1.0 : 0.6

    ComboBox {
        id: combo
        anchors.fill: parent; anchors.margins: 4
        model: root.model
        textRole: root.textRole; valueRole: root.valueRole
        currentIndex: -1
        background: Rectangle { color: "transparent" }

        contentItem: Text {
            leftPadding: 8; verticalAlignment: Text.AlignVCenter
            text: combo.currentIndex >= 0 ? combo.currentText : root.placeholder
            font.pixelSize: 13; font.weight: Font.Bold
            color: combo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
        }

        onCurrentValueChanged: {
            if (combo.currentIndex >= 0)
                root.valueSelected(currentValue)
        }

        popup: Popup {
            y: combo.height - 1
            width: combo.width
            implicitHeight: Math.min(popupCol.implicitHeight + 2, 220)
            padding: 1

            contentItem: Flickable {
                clip: true
                contentHeight: popupCol.implicitHeight
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: popupCol
                    width: parent.width

                    // Optional reset row
                    Rectangle {
                        width: parent.width; height: 36
                        visible: root.showReset
                        color: resetMa.containsMouse ? Style.bgSecondary : "transparent"
                        Text {
                            anchors.fill: parent; leftPadding: 12
                            text: "Sélectionner..."
                            font.pixelSize: 13; font.italic: true; font.weight: Font.Bold
                            color: Style.textTertiary; verticalAlignment: Text.AlignVCenter
                        }
                        MouseArea {
                            id: resetMa
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                combo.currentIndex = -1
                                root.valueCleared()
                                combo.popup.close()
                            }
                        }
                    }

                    Repeater {
                        model: root.model
                        Rectangle {
                            width: popupCol.width; height: 36
                            color: itemMa.containsMouse ? Style.bgSecondary
                                 : (combo.currentIndex === index ? Style.bgPage : "transparent")
                            Text {
                                anchors.fill: parent; leftPadding: 12
                                text: modelData[root.textRole] || ""
                                font.pixelSize: 13; font.weight: Font.Bold
                                color: Style.textPrimary; verticalAlignment: Text.AlignVCenter
                            }
                            MouseArea {
                                id: itemMa
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { combo.currentIndex = index; combo.popup.close() }
                            }
                        }
                    }
                }
            }
            background: Rectangle { radius: 8; border.color: Style.borderLight; color: "#FFFFFF" }
        }
    }
}
