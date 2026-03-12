import QtQuick
import QtQuick.Effects

Item {
    id: control
    property string iconName: ""
    property int iconSize: 20
    property color iconColor: Style.textSecondary

    implicitWidth: iconSize
    implicitHeight: iconSize

    Image {
        id: img
        anchors.centerIn: parent
        source: control.iconName !== "" ? "qrc:/qt/qml/GestionScolaire/qml/icons/" + control.iconName + ".svg" : ""
        sourceSize.width: control.iconSize
        sourceSize.height: control.iconSize
        width: control.iconSize
        height: control.iconSize
        visible: false // Hidden because MultiEffect handles rendering
        fillMode: Image.PreserveAspectFit
    }

    MultiEffect {
        source: img
        anchors.fill: img
        colorization: 1.0
        colorizationColor: control.iconColor
        visible: control.iconName !== ""
    }
}
