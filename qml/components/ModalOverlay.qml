import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

// Composant modal réutilisable avec overlay, animation et conteneur centré.
// Usage:
//   ModalOverlay {
//       show: showMyModal
//       modalWidth: 480
//       onClose: showMyModal = false
//       Column { ... contenu du modal ... }
//   }
Popup {
    id: modalOverlay

    property bool show: false
    property int modalWidth: 420
    property int modalRadius: 32
    property color modalColor: Style.bgWhite

    signal close()

    default property alias content: contentContainer.data

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: modalWidth
    implicitHeight: contentContainer.implicitHeight
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    onShowChanged: {
        if (show) open()
        else      visible = false
    }

    // Quand le Popup se ferme (clic extérieur / Echap), notifier le parent
    onClosed: {
        if (show) close()
    }

    background: Rectangle {
        radius: modalRadius
        color: modalColor
        border.color: Style.borderLight

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    Column {
        id: contentContainer
        width: parent.width
        spacing: 0
    }

    Overlay.modal: Rectangle {
        color: "#0F172A99"
    }
}
