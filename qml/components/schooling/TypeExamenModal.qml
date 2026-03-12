import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

ModalOverlay {
    id: root
    modalWidth: 500
    modalColor: Style.background

    onShowChanged: {
        if (show) schoolingController.loadTypeExamens()
    }
    onClose: show = false

    Item {
        width: parent.width; height: 72
        Separator { anchors.bottom: parent.bottom; width: parent.width }
        RowLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 12
            Column { Layout.fillWidth: true; spacing: 2
                Text { text: "Types d'évaluations"; font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                Text { text: "Gérer les types d'examens disponibles"; font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
            }
            IconButton { iconName: "close"; onClicked: root.show = false }
        }
    }

    Item {
        width: parent.width; implicitHeight: col.implicitHeight + 40
        Column { id: col; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 } spacing: 16
            
            ListView {
                id: lv
                width: parent.width; height: Math.min(contentHeight, 300)
                clip: true; spacing: 6
                model: schoolingController.typeExamens
                delegate: Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.secondary; border.color: Style.textSecondary; border.width: 1
                    property bool editing: false
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8; spacing: 8
                        TextInput {
                            id: txtInput
                            Layout.fillWidth: true; text: modelData.titre
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                            readOnly: !parent.parent.editing; selectByMouse: true
                            HoverHandler { cursorShape: parent.parent.editing ? Qt.IBeamCursor : Qt.ArrowCursor }
                        }
                        Rectangle {
                            width: 30; height: 30; radius: 9
                            color: eMa.containsMouse ? (parent.parent.editing ? Style.successColor : Style.primaryBg) : "transparent"
                            Text { anchors.centerIn: parent; text: parent.parent.editing ? "✓" : "✎"; font.pixelSize: parent.parent.editing ? 14 : 13; color: eMa.containsMouse ? (parent.parent.editing ? Style.background : Style.primary) : Style.textTertiary }
                            MouseArea { id: eMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (parent.parent.parent.editing) {
                                        var newTitle = txtInput.text.trim()
                                        if (newTitle && newTitle !== modelData.titre) schoolingController.updateTypeExamen(modelData.id, newTitle)
                                        parent.parent.parent.editing = false
                                    } else { parent.parent.parent.editing = true; txtInput.forceActiveFocus() }
                                }
                            }
                        }
                        Rectangle {
                            width: 30; height: 30; radius: 9
                            color: dMa.containsMouse ? Style.errorBorder : "transparent"
                            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; font.bold: true; color: dMa.containsMouse ? Style.errorColor : Style.textTertiary }
                            MouseArea { id: dMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: schoolingController.deleteTypeExamen(modelData.id)
                            }
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width; spacing: 12
                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: Style.secondary
                    border.color: newExInput.activeFocus ? Style.primary : Style.textSecondary; border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    HoverHandler { cursorShape: Qt.IBeamCursor }
                    TextInput { id: newExInput; anchors.fill: parent; anchors.margins: 12; font.pixelSize: 13; color: Style.textPrimary; Text { visible: !parent.text; text: "Nouveau type d'examen..."; font: parent.font; color: Style.textTertiary } Keys.onReturnPressed: addBtn.doAdd() }
                }
                Rectangle {
                    id: addBtn; width: 44; height: 44; radius: 12; color: aMa.containsMouse ? Style.primary : Style.primaryBg
                    Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 20; font.bold: true; color: aMa.containsMouse ? Style.background : Style.primary }
                    function doAdd() { var t = newExInput.text.trim(); if(t) { schoolingController.createTypeExamen(t); newExInput.text = "" } }
                    MouseArea { id: aMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: addBtn.doAdd() }
                }
            }
        }
    }

    // ─── Footer ───
    Item {
        width: parent.width; implicitHeight: 80
        Separator { anchors.top: parent.top; width: parent.width }

        RowLayout {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom
                      leftMargin: 16; rightMargin: 16; topMargin: 16; bottomMargin: 20 }
            spacing: 12

            Rectangle {
                Layout.fillWidth: true; height: 44; radius: 12
                color: cancelFooterMa.containsMouse ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderMedium; border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "ANNULER"; font.pixelSize: 11; font.weight: Font.Black; color: Style.textSecondary; font.letterSpacing: 0.5 }
                MouseArea { id: cancelFooterMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.show = false }
            }

            Rectangle {
                Layout.fillWidth: true; height: 44; radius: 12
                color: confirmFooterMa.containsMouse ? Style.primaryDark : Style.primary
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "CONFIRMER"; font.pixelSize: 11; font.weight: Font.Black; color: Style.background; font.letterSpacing: 0.5 }
                MouseArea { id: confirmFooterMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.show = false }
            }
        }
    }
}