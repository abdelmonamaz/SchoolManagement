import QtQuick 2.15
import QtQuick.Layouts 1.15

// Champ de formulaire réutilisable : label + champ texte stylisé.
// Usage:
//   FormField {
//       width: parent.width
//       label: "NOM COMPLET"
//       placeholder: "ex: Ahmed Ben Moussa"
//   }
Column {
    id: root

    property string label: ""
    property string placeholder: ""
    property alias text: input.text
    property alias inputItem: input
    property int fieldHeight: 44

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

        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 12
            font.pixelSize: 13
            font.bold: true
            color: Style.textPrimary
            clip: true

            Text {
                visible: !input.text
                text: root.placeholder
                font: input.font
                color: Style.textTertiary
            }
        }
    }
}
