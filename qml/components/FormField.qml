import QtQuick
import QtQuick.Layouts

// Champ de formulaire réutilisable : label + champ texte stylisé.
// Usage:
//   FormField {
//       width: parent.width
//       label: qsTr("NOM COMPLET")
//       placeholder: qsTr("ex: Ahmed Ben Moussa")
//       nextTabItem: autreChamp.inputItem
//   }
Column {
    id: root

    property string label: ""
    property string placeholder: ""
    property alias text: input.text
    property alias inputItem: input
    property alias validator: input.validator
    property int fieldHeight: 44
    property var nextTabItem: null
    property var prevTabItem: null

    spacing: 6

    Text {
        visible: label !== ""
        text: root.label
        font.pixelSize: 9
        font.weight: Font.Black
        color: Style.textTertiary
        font.letterSpacing: 1
    }

    Rectangle {
        width: parent.width
        height: fieldHeight
        radius: 12
        color: Style.bgPage
        border.color: Style.borderLight

        HoverHandler {
            cursorShape: Qt.IBeamCursor
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 12
            font.pixelSize: 13
            font.bold: true
            color: Style.textPrimary
            clip: true
            selectByMouse: true

            Keys.onTabPressed: function(event) {
                event.accepted = true
                if (root.nextTabItem) root.nextTabItem.forceActiveFocus()
            }

            Keys.onBacktabPressed: function(event) {
                event.accepted = true
                if (root.prevTabItem) root.prevTabItem.forceActiveFocus()
            }

            Text {
                visible: !input.text
                text: root.placeholder
                font: input.font
                color: Style.textTertiary
            }
        }
    }
}
