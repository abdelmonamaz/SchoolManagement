import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import UI.Components

RowLayout {
    id: root
    spacing: 20

    required property int selectedMonth
    required property int selectedYear
    required property int filterNiveauId
    required property int filterSalleId
    required property int filterProfId
    required property int selectedDay

    signal monthChanged(int month)
    signal yearChanged(int year)
    signal daySelected(int day)
    signal sessionClicked(var item)
    signal filterNiveauChanged(int id)
    signal filterSalleChanged(int id)
    signal filterProfChanged(int id)

    function getFilteredExams() {
        var all = examsController.exams
        var result = []
        for (var i = 0; i < all.length; i++) {
            var s = all[i]
            if (root.filterNiveauId >= 0) {
                var match = false
                var cls = schoolingController.allClasses
                for (var c = 0; c < cls.length; c++) {
                    if (cls[c].id === s.classeId && cls[c].niveauId === root.filterNiveauId) {
                        match = true; break
                    }
                }
                if (!match) continue
            }
            if (root.filterSalleId >= 0 && s.salleId !== root.filterSalleId) continue
            if (root.filterProfId >= 0 && s.profId !== root.filterProfId) continue
            result.push(s)
        }
        return result
    }

    function getSessionsForDay(dayNum) {
        var filtered = getFilteredExams()
        var result = []
        for (var i = 0; i < filtered.length; i++) {
            if (filtered[i].dayOfMonth === dayNum)
                result.push(filtered[i])
        }
        result.sort(function(a, b) {
            var ta = a.time || "00:00"
            var tb = b.time || "00:00"
            return ta < tb ? -1 : ta > tb ? 1 : 0
        })
        return result
    }

    function countByType(sessions, type) {
        var n = 0
        for (var i = 0; i < sessions.length; i++)
            if (sessions[i].typeSeance === type) n++
        return n
    }

    function getHeatmapOpacity(count) {
        if (count === 0) return 0.0
        if (count <= 2) return 0.12
        if (count <= 5) return 0.25
        if (count <= 8) return 0.4
        return 0.6
    }

    function sessionTypeColor(type) {
        if (type === "Examen") return Style.errorColor
        if (type === "Événement") return Style.warningColor
        return "#374151"
    }

    function navigateMonth(delta) {
        var m = root.selectedMonth + delta
        var y = root.selectedYear
        if (m < 0)  { y -= 1; m = 11 }
        if (m > 11) { y += 1; m = 0  }
        if (y !== root.selectedYear) root.yearChanged(y)
        root.monthChanged(m)
    }

    function formatEndTime(startTime, durationMin) {
        var parts = startTime.split(":")
        if (parts.length < 2) return ""
        var h = parseInt(parts[0])
        var m = parseInt(parts[1]) + durationMin
        h += Math.floor(m / 60)
        m = m % 60
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
    }

    // ═══ LEFT: Heatmap Calendar (2/3) ═══
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredWidth: 2
        Layout.alignment: Qt.AlignTop
        implicitHeight: leftCol.implicitHeight + 48
        radius: Style.radiusRound
        color: Style.bgWhite
        border.color: Style.borderLight
        border.width: 1

        Column {
            id: leftCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 16

            // Row 1: Title + Month/Year + Legend
            RowLayout {
                width: parent.width
                spacing: 12

                Text {
                    text: "Calendrier Mensuel"
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: Style.textPrimary
                }

                // ◀ Mois précédent
                Rectangle {
                    width: 28; implicitHeight: 32; radius: 8
                    color: calPrevMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 16; font.bold: true; color: Style.textSecondary }
                    MouseArea {
                        id: calPrevMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: navigateMonth(-1)
                    }
                }

                ComboBox {
                    implicitWidth: 140; implicitHeight: 32
                    currentIndex: root.selectedMonth
                    model: ["Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"]
                    onCurrentIndexChanged: root.monthChanged(currentIndex)
                    background: Rectangle { radius: 10; color: Style.bgWhite; border.color: Style.borderLight; border.width: 1 }
                    contentItem: Text {
                        leftPadding: 12; rightPadding: 12; text: parent.displayText
                        font.pixelSize: 9; font.weight: Font.Black; color: Style.textPrimary
                        font.letterSpacing: 0.5; verticalAlignment: Text.AlignVCenter
                    }
                }

                ComboBox {
                    implicitWidth: 90; implicitHeight: 32
                    currentIndex: root.selectedYear - 2024
                    model: ["2024","2025","2026","2027","2028"]
                    onCurrentIndexChanged: root.yearChanged(2024 + currentIndex)
                    background: Rectangle { radius: 10; color: Style.bgWhite; border.color: Style.borderLight; border.width: 1 }
                    contentItem: Text {
                        leftPadding: 12; rightPadding: 12; text: parent.displayText
                        font.pixelSize: 9; font.weight: Font.Black; color: Style.textPrimary
                        font.letterSpacing: 0.5; verticalAlignment: Text.AlignVCenter
                    }
                }

                // ▶ Mois suivant
                Rectangle {
                    width: 28; implicitHeight: 32; radius: 8
                    color: calNextMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 16; font.bold: true; color: Style.textSecondary }
                    MouseArea {
                        id: calNextMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: navigateMonth(1)
                    }
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 16
                    Repeater {
                        model: [
                            { label: "COURS", clr: "#374151" },
                            { label: "EXAMEN", clr: Style.errorColor },
                            { label: "ÉVÈNEMENT", clr: Style.warningColor }
                        ]
                        Row {
                            spacing: 6
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                color: modelData.clr
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.label
                                font.pixelSize: 9; font.weight: Font.Black
                                color: Style.textSecondary; font.letterSpacing: 0.5
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // Row 2: Filters
            RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 10
                    color: Style.bgPage; border.color: Style.borderLight

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 6

                        IconLabel { iconName: "book"; iconSize: 12; iconColor: Style.textTertiary }

                        ComboBox {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: {
                                var items = [{"nom": "Tous les Niveaux", "id": -1}]
                                var n = schoolingController.niveaux
                                for (var i = 0; i < n.length; i++) items.push(n[i])
                                return items
                            }
                            textRole: "nom"; valueRole: "id"
                            currentIndex: 0
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 4; text: parent.displayText
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: Style.textPrimary; verticalAlignment: Text.AlignVCenter
                            }
                            onCurrentValueChanged: root.filterNiveauChanged(currentValue)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 10
                    color: Style.bgPage; border.color: Style.borderLight

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 6

                        IconLabel { iconName: "location"; iconSize: 12; iconColor: Style.textTertiary }

                        ComboBox {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: {
                                var items = [{"nom": "Toutes les Salles", "id": -1}]
                                var s = schoolingController.salles
                                for (var i = 0; i < s.length; i++) items.push(s[i])
                                return items
                            }
                            textRole: "nom"; valueRole: "id"
                            currentIndex: 0
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 4; text: parent.displayText
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: Style.textPrimary; verticalAlignment: Text.AlignVCenter
                            }
                            onCurrentValueChanged: root.filterSalleChanged(currentValue)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 10
                    color: Style.bgPage; border.color: Style.borderLight

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 6

                        IconLabel { iconName: "user"; iconSize: 12; iconColor: Style.textTertiary }

                        ComboBox {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: {
                                var items = [{"nom": "Tous les Professeurs", "id": -1}]
                                var p = staffController.enseignants
                                for (var i = 0; i < p.length; i++) items.push(p[i])
                                return items
                            }
                            textRole: "nom"; valueRole: "id"
                            currentIndex: 0
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 4; text: parent.displayText
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: Style.textPrimary; verticalAlignment: Text.AlignVCenter
                            }
                            onCurrentValueChanged: root.filterProfChanged(currentValue)
                        }
                    }
                }
            }

            // Day-of-week headers
            GridLayout {
                width: parent.width
                columns: 7
                columnSpacing: 8

                Repeater {
                    model: ["LUN","MAR","MER","JEU","VEN","SAM","DIM"]
                    SectionLabel {
                        Layout.fillWidth: true
                        text: modelData
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Heatmap Grid
            GridLayout {
                id: calGrid
                width: parent.width
                columns: 7
                columnSpacing: 8
                rowSpacing: 8

                property int daysInMonth: new Date(root.selectedYear, root.selectedMonth + 1, 0).getDate()
                property int firstDayOffset: {
                    var dow = new Date(root.selectedYear, root.selectedMonth, 1).getDay()
                    return dow === 0 ? 6 : dow - 1
                }

                Repeater {
                    model: calGrid.firstDayOffset + calGrid.daysInMonth

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 80
                        radius: Style.radiusMedium
                        opacity: isDay ? 1.0 : 0.0

                        property bool isDay: index >= calGrid.firstDayOffset
                        property int dayNum: isDay ? index - calGrid.firstDayOffset + 1 : 0

                        property var daySessions: {
                            var _f1 = root.filterNiveauId; var _f2 = root.filterSalleId; var _f3 = root.filterProfId
                            var _d = examsController.exams
                            return isDay ? getSessionsForDay(dayNum) : []
                        }
                        property int totalCount: daySessions.length
                        property int coursCount: countByType(daySessions, "Cours")
                        property int examCount: countByType(daySessions, "Examen")
                        property int eventCount: countByType(daySessions, "Événement")

                        property bool isToday: isDay && dayNum === new Date().getDate()
                            && root.selectedMonth === new Date().getMonth()
                            && root.selectedYear === new Date().getFullYear()
                        property bool isSelected: isDay && dayNum === root.selectedDay

                        color: {
                            if (!isDay) return "transparent"
                            if (isSelected) return Qt.rgba(0.24, 0.35, 0.27, 0.12)
                            if (totalCount > 0) return Qt.rgba(0.24, 0.35, 0.27, getHeatmapOpacity(totalCount))
                            return Style.bgWhite
                        }

                        border.color: {
                            if (!isDay) return "transparent"
                            if (isSelected) return Style.primary
                            if (isToday) return Qt.rgba(0.24, 0.35, 0.27, 0.3)
                            return Style.borderLight
                        }
                        border.width: isSelected ? 2 : 1


                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            Text {
                                text: dayNum.toString()
                                font.pixelSize: 13
                                font.weight: Font.Black
                                color: isToday ? Style.primary
                                     : isSelected ? Style.primaryDark
                                     : Style.textTertiary
                            }

                            Item { width: 1; height: 2 }

                            Row {
                                spacing: 8
                                visible: totalCount > 0

                                Row {
                                    spacing: 3; visible: coursCount > 0
                                    Rectangle { width: 8; height: 8; radius: 4; color: "#374151"; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: coursCount.toString(); font.pixelSize: 9; font.weight: Font.Bold; color: "#374151"; anchors.verticalCenter: parent.verticalCenter }
                                }
                                Row {
                                    spacing: 3; visible: examCount > 0
                                    Rectangle { width: 8; height: 8; radius: 4; color: Style.errorColor; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: examCount.toString(); font.pixelSize: 9; font.weight: Font.Bold; color: Style.errorColor; anchors.verticalCenter: parent.verticalCenter }
                                }
                                Row {
                                    spacing: 3; visible: eventCount > 0
                                    Rectangle { width: 8; height: 8; radius: 4; color: Style.warningColor; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: eventCount.toString(); font.pixelSize: 9; font.weight: Font.Bold; color: Style.warningColor; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }

                            Text {
                                visible: totalCount > 0
                                text: totalCount + " session" + (totalCount > 1 ? "s" : "")
                                font.pixelSize: 9; font.weight: Font.DemiBold
                                color: Style.textTertiary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: isDay ? Qt.PointingHandCursor : Qt.ArrowCursor
                            hoverEnabled: isDay
                            enabled: isDay
                            onClicked: root.daySelected(dayNum)
                        }
                    }
                }
            }
        }
    }

    // ═══ RIGHT: Day Details Panel (1/3) ═══
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        implicitHeight: rightCol.implicitHeight + 48
        radius: Style.radiusRound
        color: Style.bgWhite
        border.color: Style.borderLight
        border.width: 1

        Column {
            id: rightCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 16

            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Détails du Jour"
                    font.pixelSize: 16; font.weight: Font.Black
                    color: Style.textPrimary
                }

                Text {
                    text: {
                        if (root.selectedDay < 0) return "Cliquez sur un jour"
                        var months = ["Janvier","Février","Mars","Avril","Mai","Juin",
                                      "Juillet","Août","Septembre","Octobre","Novembre","Décembre"]
                        return root.selectedDay + " " + months[root.selectedMonth] + " " + root.selectedYear
                    }
                    font.pixelSize: 13; font.weight: Font.Medium
                    color: Style.textTertiary
                }
            }

            Separator { width: parent.width }

            // Empty state - no day selected
            Column {
                width: parent.width
                spacing: 8
                visible: root.selectedDay < 0

                Item { width: 1; height: 40 }

                Rectangle {
                    width: 56; height: 56; radius: 20
                    color: Style.primaryBg
                    anchors.horizontalCenter: parent.horizontalCenter
                    IconLabel { anchors.centerIn: parent; iconName: "calendar"; iconSize: 24; iconColor: Style.primary }
                }

                Text {
                    width: parent.width
                    text: "Sélectionnez un jour dans\nle calendrier pour voir les détails"
                    font.pixelSize: 13; font.weight: Font.Medium
                    color: Style.textTertiary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }

                Item { width: 1; height: 40 }
            }

            // Summary badges
            RowLayout {
                width: parent.width
                spacing: 8
                visible: root.selectedDay >= 0

                property var ds: {
                    var _f1 = root.filterNiveauId; var _f2 = root.filterSalleId; var _f3 = root.filterProfId
                    var _d = examsController.exams
                    return root.selectedDay >= 0 ? getSessionsForDay(root.selectedDay) : []
                }

                Badge { text: countByType(parent.ds, "Cours") + " Cours"; variant: "neutral" }
                Badge { text: countByType(parent.ds, "Examen") + " Examen"; variant: "error" }
                Badge { text: countByType(parent.ds, "Événement") + " Évt."; variant: "warning" }
                Item { Layout.fillWidth: true }
            }

            // No sessions for this day
            Column {
                width: parent.width
                visible: root.selectedDay >= 0 && dayDetailsRepeater.count === 0
                spacing: 8

                Item { width: 1; height: 20 }
                Text {
                    width: parent.width
                    text: "Aucune session ce jour"
                    font.pixelSize: 13; font.weight: Font.Medium
                    color: Style.textTertiary
                    horizontalAlignment: Text.AlignHCenter
                }
                Item { width: 1; height: 20 }
            }

            // Scrollable session cards
            Flickable {
                width: parent.width
                height: Math.min(contentHeight, 520)
                contentHeight: detailsCol.implicitHeight
                clip: true
                visible: root.selectedDay >= 0
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: detailsCol
                    width: parent.width
                    spacing: 10

                    Repeater {
                        id: dayDetailsRepeater
                        model: {
                            var _f1 = root.filterNiveauId; var _f2 = root.filterSalleId; var _f3 = root.filterProfId
                            var _d = examsController.exams
                            return root.selectedDay >= 0 ? getSessionsForDay(root.selectedDay) : []
                        }

                        delegate: Rectangle {
                            width: detailsCol.width
                            implicitHeight: cardCol.implicitHeight + 24
                            radius: Style.radiusMedium
                            color: cardMa.containsMouse ? Style.bgSecondary : Style.bgPage
                            border.color: cardMa.containsMouse ? Style.borderMedium : Style.borderLight
                            border.width: 1

    
                            Rectangle {
                                width: 4
                                height: parent.height - 16
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 2
                                color: sessionTypeColor(modelData.typeSeance)
                            }

                            Column {
                                id: cardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: 20
                                anchors.rightMargin: 12
                                anchors.topMargin: 12
                                spacing: 5

                                property bool isEvent: modelData.typeSeance === "Événement"

                                Text {
                                    text: (modelData.time || "08:00") + " — "
                                        + formatEndTime(modelData.time || "08:00", modelData.dureeMinutes || 60)
                                    font.pixelSize: 11; font.weight: Font.Bold
                                    color: sessionTypeColor(modelData.typeSeance)
                                }

                                // Titre principal
                                Text {
                                    text: {
                                        if (cardCol.isEvent)
                                            return modelData.titre || "Événement"
                                        // Pour un examen : "Matière — Épreuve" si épreuve définie
                                        if (modelData.typeSeance === "Examen" && modelData.titre)
                                            return (modelData.subject || "") + " — " + modelData.titre
                                        return modelData.subject || ""
                                    }
                                    font.pixelSize: 14; font.weight: Font.Black
                                    color: Style.textPrimary
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                // Descriptif (événements uniquement, tronqué)
                                Text {
                                    visible: cardCol.isEvent && modelData.descriptif
                                    text: {
                                        var d = modelData.descriptif || ""
                                        return d.length > 60 ? d.substring(0, 60) + "…" : d
                                    }
                                    font.pixelSize: 11; color: Style.textTertiary
                                    elide: Text.ElideRight; width: parent.width
                                }

                                // Professeur (cours & examens)
                                RowLayout {
                                    spacing: 5
                                    visible: !cardCol.isEvent
                                    IconLabel { iconName: "user"; iconSize: 11; iconColor: Style.textTertiary }
                                    Text {
                                        text: modelData.professor || ""
                                        font.pixelSize: 11; font.weight: Font.Bold
                                        color: Style.textSecondary
                                    }
                                }

                                // Salle + Classe (cours & examens) ou Salle seule (événements)
                                RowLayout {
                                    spacing: 10
                                    visible: !cardCol.isEvent || (modelData.room && modelData.room !== "—")
                                    RowLayout {
                                        spacing: 4
                                        IconLabel { iconName: "location"; iconSize: 11; iconColor: Style.textTertiary }
                                        Text {
                                            text: modelData.room || ""
                                            font.pixelSize: 11; font.weight: Font.Bold
                                            color: Style.textSecondary
                                        }
                                    }
                                    Badge {
                                        text: modelData.className || ""
                                        variant: "neutral"
                                        visible: !cardCol.isEvent
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sessionClicked(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
