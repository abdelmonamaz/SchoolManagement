import QtQuick 2.15

Rectangle {
    id: control

    property string text: ""
    property string variant: "neutral" // success, warning, error, info, neutral
    property var customTextColor: undefined
    property var customBgColor: undefined
    property var customBorderColor: undefined

    property color defaultTextColor: {
        switch (variant) {
            case "success": return Style.successColor;
            case "warning": return Style.warningColor;
            case "error":   return Style.errorColor;
            case "info":    return Style.infoColor;
            default:        return Style.textSecondary;
        }
    }
    property color defaultBgColor: {
        switch (variant) {
            case "success": return Style.successBg;
            case "warning": return Style.warningBg;
            case "error":   return Style.errorBg;
            case "info":    return Style.infoBg;
            default:        return Style.bgSecondary;
        }
    }
    property color defaultBorderColor: {
        switch (variant) {
            case "success": return Style.successBorder;
            case "warning": return Style.warningBorder;
            case "error":   return Style.errorBorder;
            case "info":    return Style.infoBorder;
            default:        return Style.borderMedium;
        }
    }

    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 8
    radius: height / 2

    color: customBgColor !== undefined ? customBgColor : defaultBgColor

    border.color: customBorderColor !== undefined ? customBorderColor : defaultBorderColor
    border.width: 1

    Text {
        id: label
        anchors.centerIn: parent
        text: control.text
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: control.customTextColor !== undefined ? control.customTextColor : control.defaultTextColor
    }
}
