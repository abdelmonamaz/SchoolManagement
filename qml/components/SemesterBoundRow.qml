import QtQuick
import UI.Components

// A date-range row showing two columns separated by an arrow.
// Each side can be either a static display box or an editable DateField.
//
// SetupStep3 S1 usage: leftDate=yearStart (fixed), rightEditable=true
// SetupStep3 S2 usage: leftEditable=true, rightDate=yearEnd (fixed)
// SessionFormModal usage: both static (leftDate=semStart, rightDate=semEnd)
Item {
    id: root

    implicitHeight: _leftCol.implicitHeight

    // ── Properties ─────────────────────────────────────────────────────────
    property string leftLabel:     ""
    property string leftDate:      ""    // static date value (ISO) — used when !leftEditable
    property string rightLabel:    ""
    property string rightDate:     ""    // static date value (ISO) — used when !rightEditable
    property bool   leftEditable:  false // if true, left side shows a DateField instead of a static box
    property bool   rightEditable: false // if true, right side shows a DateField instead of a static box
    property color  fieldColor:    Style.bgWhite

    // Exposed DateFields (only meaningful when the corresponding side is editable)
    property alias leftField:  _leftField
    property alias rightField: _rightField

    // ── Left column ─────────────────────────────────────────────────────────
    Column {
        id: _leftCol
        anchors.left: parent.left
        anchors.top:  parent.top
        width: (parent.width - 30) / 2
        spacing: 6

        Text {
            text: root.leftLabel
            font.pixelSize: 9; font.weight: Font.Black
            color: Style.textTertiary; font.letterSpacing: 1
        }

        Rectangle {
            width: parent.width; height: 44; radius: 12
            visible: !root.leftEditable
            color: root.fieldColor; border.color: Style.borderLight
            Text {
                anchors.centerIn: parent
                text: root.leftDate || "—"
                font.pixelSize: 13; font.bold: true; color: Style.textSecondary
            }
        }

        DateField {
            id: _leftField
            width: parent.width
            visible: root.leftEditable
            label: ""
            fieldColor: root.fieldColor
        }
    }

    // ── Arrow ───────────────────────────────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        text: "→"; font.pixelSize: 16; color: Style.textTertiary
    }

    // ── Right column ────────────────────────────────────────────────────────
    Column {
        id: _rightCol
        anchors.right: parent.right
        anchors.top:   parent.top
        width: (parent.width - 30) / 2
        spacing: 6

        Text {
            text: root.rightLabel
            font.pixelSize: 9; font.weight: Font.Black
            color: Style.textTertiary; font.letterSpacing: 1
        }

        Rectangle {
            width: parent.width; height: 44; radius: 12
            visible: !root.rightEditable
            color: root.fieldColor; border.color: Style.borderLight
            Text {
                anchors.centerIn: parent
                text: root.rightDate || "—"
                font.pixelSize: 13; font.bold: true; color: Style.textSecondary
            }
        }

        DateField {
            id: _rightField
            width: parent.width
            visible: root.rightEditable
            label: ""
            fieldColor: root.fieldColor
        }
    }
}
