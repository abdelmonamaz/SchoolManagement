import QtQuick 2.15

Rectangle {
    id: control

    property string text: ""
    property string variant: "neutral" // success, warning, error, info, neutral

    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 8
    radius: height / 2

    color: {
        switch (variant) {
            case "success": return Style.successBg;
            case "warning": return Style.warningBg;
            case "error":   return Style.errorBg;
            case "info":    return Style.infoBg;
            default:        return Style.bgSecondary;
        }
    }

    border.color: {
        switch (variant) {
            case "success": return Style.successBorder;
            case "warning": return Style.warningBorder;
            case "error":   return Style.errorBorder;
            case "info":    return Style.infoBorder;
            default:        return Style.borderMedium;
        }
    }
    border.width: 1

    Text {
        id: label
        anchors.centerIn: parent
        text: control.text
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: {
            switch (control.variant) {
                case "success": return Style.successColor;
                case "warning": return Style.warningColor;
                case "error":   return Style.errorColor;
                case "info":    return Style.infoColor;
                default:        return Style.textSecondary;
            }
        }
    }
}
