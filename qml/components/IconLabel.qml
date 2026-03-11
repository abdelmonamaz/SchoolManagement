import QtQuick

Item {
    id: control
    property string iconName: ""
    property int iconSize: 20
    property color iconColor: Style.textSecondary

    implicitWidth: iconSize
    implicitHeight: iconSize

    Text {
        anchors.centerIn: parent
        font.pixelSize: control.iconSize
        font.family: "Segoe UI Symbol"
        color: control.iconColor
        text: {
            // Map icon names to Unicode symbols
            switch (control.iconName) {
                case "dashboard":  return "▣";
                case "book":       return "📖";
                case "users":      return "👥";
                case "calendar":   return "📅";
                case "wallet":     return "💰";
                case "settings":   return "⚙";
                case "search":     return "🔍";
                case "bell":       return "🔔";
                case "logout":     return "⏻";
                case "plus":       return "+";
                case "filter":     return "⏞";
                case "eye":        return "👁";
                case "edit":       return "✎";
                case "trash":      return "🗑";
                case "mail":       return "✉";
                case "phone":      return "📞";
                case "check":      return "✓";
                case "alert":      return "⚠";
                case "close":      return "✕";
                case "left":       return "‹";
                case "right":      return "›";
                case "down":       return "▾";
                case "up-right":   return "↗";
                case "down-right": return "↘";
                case "save":       return "💾";
                case "download":   return "⬇";
                case "file":       return "📄";
                case "clock":      return "🕐";
                case "pin":        return "📍";
                case "grid":       return "▦";
                case "list":       return "☰";
                case "heart":      return "♥";
                case "history":    return "↻";
                case "receipt":    return "🧾";
                case "printer":    return "🖨";
                case "cloud":      return "☁";
                case "shield":     return "🛡";
                case "school":     return "🏫";
                case "database":   return "🗄";
                case "user":       return "👤";
                case "more":       return "⋯";
                case "more-v":     return "⋮";
                case "calculator": return "🔢";
                case "trending":   return "📈";
                case "upload":     return "⬆";
                default:           return "●";
            }
        }
    }
}
