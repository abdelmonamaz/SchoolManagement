import QtQuick 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    property string title: ""
    property string subtitle: ""

    spacing: 4

    Text {
        text: parent.title
        font.pixelSize: 28
        font.weight: Font.Black
        color: Style.textPrimary
        Layout.fillWidth: true
    }
    Text {
        text: parent.subtitle
        font.pixelSize: 14
        font.weight: Font.Medium
        color: Style.textSecondary
        Layout.fillWidth: true
    }
}
