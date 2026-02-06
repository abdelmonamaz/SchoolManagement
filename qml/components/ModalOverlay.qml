import QtQuick 2.15
import QtQuick.Layouts 1.15

// Composant modal réutilisable avec overlay, animation et conteneur centré.
// Usage:
//   ModalOverlay {
//       show: showMyModal
//       modalWidth: 480
//       onClose: showMyModal = false
//       Column { ... contenu du modal ... }
//   }
Rectangle {
    id: modalOverlay

    property bool show: false
    property int modalWidth: 420
    property int modalRadius: 32
    property color modalColor: Style.bgWhite

    signal close()

    default property alias content: contentContainer.data

    anchors.fill: parent
    color: "#0F172A99"
    visible: show
    opacity: show ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: modalOverlay.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: modalWidth
        implicitHeight: contentContainer.implicitHeight
        radius: modalRadius
        color: modalColor
        scale: show ? 1.0 : 0.95

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: contentContainer
            width: parent.width
            spacing: 0
        }
    }
}
