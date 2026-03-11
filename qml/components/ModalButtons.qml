import QtQuick
import QtQuick.Layouts

// Paire de boutons pour les modaux (Annuler + Action).
// Usage:
//   ModalButtons {
//       width: parent.width
//       cancelText: "ANNULER"
//       confirmText: "CRÉER"
//       confirmColor: Style.primary
//       onCancel: showMyModal = false
//       onConfirm: { /* logique */ }
//   }
RowLayout {
    id: root

    property string cancelText: "ANNULER"
    property string confirmText: "CONFIRMER"
    property color confirmColor: Style.primary

    signal cancel()
    signal confirm()

    spacing: 12

    Rectangle {
        Layout.fillWidth: true
        height: 48
        radius: 16
        color: Style.bgPage
        visible: root.cancelText !== ""

        Text {
            anchors.centerIn: parent
            text: root.cancelText
            font.pixelSize: 10
            font.weight: Font.Black
            color: Style.textTertiary
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cancel()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 48
        radius: 16
        color: root.confirmColor

        Text {
            anchors.centerIn: parent
            text: root.confirmText
            font.pixelSize: 10
            font.weight: Font.Black
            color: "#FFFFFF"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.confirm()
        }
    }
}
