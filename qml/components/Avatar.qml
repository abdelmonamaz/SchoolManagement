import QtQuick

// Avatar avec initiale, réutilisable partout.
// Usage:
//   Avatar { initials: "A"; size: 40 }
Rectangle {
    id: root

    property string initials: ""
    property int size: 40
    property color bgColor: Style.primaryBg
    property color textColor: Style.primary
    property int textSize: Math.round(size * 0.35)

    width: size
    height: size
    radius: Math.round(size * 0.3)
    color: bgColor

    Text {
        anchors.centerIn: parent
        text: root.initials
        font.pixelSize: root.textSize
        font.bold: true
        color: root.textColor
    }
}
