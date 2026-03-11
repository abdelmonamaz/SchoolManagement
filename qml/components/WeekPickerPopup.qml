import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

Popup {
    id: root

    property int selectedWeek: currentWeekNumber()
    property int selectedYear: new Date().getFullYear()

    signal confirmed(int week, int year)

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 340
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    background: Rectangle {
        radius: 24
        color: Style.bgWhite
        border.color: Style.borderLight
        border.width: 1
    }

    Overlay.modal: Rectangle {
        color: "#0F172A99"
    }

    // Helpers
    function currentWeekNumber() {
        var now = new Date()
        var year = now.getFullYear()
        var onejan = new Date(year, 0, 1)
        var dayOfWeek = onejan.getDay()
        var isoDay = dayOfWeek === 0 ? 7 : dayOfWeek
        // Monday of week 1
        var mondayW1 = new Date(year, 0, 1 + (1 - isoDay))
        // Days since Monday of week 1
        var diff = Math.floor((now - mondayW1) / 86400000)
        return Math.floor(diff / 7) + 1
    }

    function maxWeeksInYear(year) {
        // ISO 8601: a year has 53 weeks if Jan 1 is Thursday,
        // or Dec 31 is Thursday (accounts for leap years)
        var jan1 = new Date(year, 0, 1).getDay()
        var dec31 = new Date(year, 11, 31).getDay()
        // JS: 0=Sun, 4=Thu
        if (jan1 === 4 || dec31 === 4) return 53
        return 52
    }

    function weekStartEnd(week, year) {
        var onejan = new Date(year, 0, 1)
        var dayOfWeek = onejan.getDay()
        // ISO: Monday = 1, Sunday = 7. JS: Sunday = 0
        var isoDay = dayOfWeek === 0 ? 7 : dayOfWeek
        // Monday of week 1
        var mondayW1 = new Date(year, 0, 1 + (1 - isoDay))
        var start = new Date(mondayW1)
        start.setDate(mondayW1.getDate() + (week - 1) * 7)
        var end = new Date(start)
        end.setDate(start.getDate() + 6)
        return { start: start, end: end }
    }

    function formatDate(d) {
        var months = ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc"]
        return d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear()
    }

    function weekRangeText() {
        var w = parseInt(weekInput.text)
        if (isNaN(w) || w < 1 || w > maxWeeksInYear(selectedYear)) return ""
        var range = weekStartEnd(w, selectedYear)
        return formatDate(range.start) + "  →  " + formatDate(range.end)
    }

    onAboutToShow: {
        selectedWeek = currentWeekNumber()
        selectedYear = new Date().getFullYear()
        weekInput.text = selectedWeek.toString()
    }

    Column {
        width: parent.width
        spacing: 0

        // Header
        Item {
            width: parent.width
            height: 64

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: 12
                    color: Style.primaryBg

                    IconLabel {
                        anchors.centerIn: parent
                        iconName: "calendar"
                        iconSize: 16
                        iconColor: Style.primary
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Choisir la Semaine"
                    font.pixelSize: 16
                    font.weight: Font.Black
                    color: Style.textPrimary
                }

                IconButton {
                    iconName: "close"
                    iconSize: 16
                    onClicked: root.close()
                }
            }
        }

        Separator { width: parent.width }

        // Body
        Item {
            width: parent.width
            implicitHeight: bodyCol.implicitHeight + 48

            Column {
                id: bodyCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 20

                // Week number
                Column {
                    width: parent.width
                    spacing: 6

                    SectionLabel { text: "NUMÉRO DE SEMAINE" }

                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 12
                        color: Style.bgPage
                        border.color: weekInput.activeFocus ? Style.primary : Style.borderLight


                        HoverHandler { cursorShape: Qt.IBeamCursor }

                        TextInput {
                            id: weekInput
                            anchors.fill: parent
                            anchors.margins: 12
                            font.pixelSize: 13
                            font.bold: true
                            color: {
                                var v = parseInt(text)
                                if (text.length > 0 && (isNaN(v) || v < 1 || v > root.maxWeeksInYear(root.selectedYear)))
                                    return Style.errorColor
                                return Style.textPrimary
                            }
                            clip: true
                            selectByMouse: true
                            maximumLength: 2
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: RegularExpressionValidator { regularExpression: /[0-9]{0,2}/ }
                            text: root.selectedWeek.toString()

                            Text {
                                visible: !weekInput.text
                                text: "1 - " + root.maxWeeksInYear(root.selectedYear)
                                font: weekInput.font
                                color: Style.textTertiary
                            }

                            onTextChanged: {
                                var v = parseInt(text)
                                if (!isNaN(v) && v >= 1 && v <= root.maxWeeksInYear(root.selectedYear)) {
                                    root.selectedWeek = v
                                }
                            }
                        }
                    }

                    Text {
                        text: "Entre 1 et " + root.maxWeeksInYear(root.selectedYear) + " pour l'année " + root.selectedYear
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Style.textTertiary
                    }
                }

                // Year
                Column {
                    width: parent.width
                    spacing: 6

                    SectionLabel { text: "ANNÉE" }

                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 12
                        color: Style.bgPage
                        border.color: Style.borderLight

                        ComboBox {
                            id: yearCombo
                            anchors.fill: parent
                            anchors.margins: 4
                            model: {
                                var years = []
                                var cur = new Date().getFullYear()
                                for (var i = cur - 2; i <= cur + 3; i++) years.push(i)
                                return years
                            }
                            currentIndex: {
                                var cur = new Date().getFullYear()
                                return root.selectedYear - cur + 2
                            }

                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                text: yearCombo.displayText
                                font.pixelSize: 13
                                font.bold: true
                                color: Style.textPrimary
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }

                            onCurrentIndexChanged: {
                                if (currentIndex >= 0) {
                                    var cur = new Date().getFullYear()
                                    root.selectedYear = cur - 2 + currentIndex
                                    // Clamp week if needed
                                    var maxW = root.maxWeeksInYear(root.selectedYear)
                                    if (root.selectedWeek > maxW) {
                                        root.selectedWeek = maxW
                                        weekInput.text = maxW.toString()
                                    }
                                }
                            }
                        }
                    }
                }

                // Week range indicator
                Rectangle {
                    width: parent.width
                    height: rangeCol.implicitHeight + 20
                    radius: 14
                    color: Style.primaryBg
                    border.color: Qt.rgba(0.24, 0.35, 0.27, 0.15)
                    visible: weekRangeText() !== ""

                    Column {
                        id: rangeCol
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "PÉRIODE SÉLECTIONNÉE"
                            font.pixelSize: 9
                            font.weight: Font.Black
                            color: Style.primary
                            font.letterSpacing: 1
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: weekRangeText()
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Style.textPrimary
                        }
                    }
                }
            }
        }

        Separator { width: parent.width }

        // Footer buttons
        Item {
            width: parent.width
            height: 68

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    radius: 12
                    color: cancelMa.containsMouse ? Style.bgSecondary : Style.bgPage


                    Text {
                        anchors.centerIn: parent
                        text: "ANNULER"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.textSecondary
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    radius: 12

                    property bool isValid: {
                        var v = parseInt(weekInput.text)
                        return !isNaN(v) && v >= 1 && v <= root.maxWeeksInYear(root.selectedYear)
                    }

                    color: !isValid ? Style.bgTertiary : confirmMa.containsMouse ? Style.primaryDark : Style.primary
                    opacity: isValid ? 1.0 : 0.6


                    Text {
                        anchors.centerIn: parent
                        text: "CONFIRMER"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: parent.isValid ? "#FFFFFF" : Style.textTertiary
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: confirmMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: parent.isValid ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: {
                            if (!parent.isValid) return
                            var w = parseInt(weekInput.text)
                            root.confirmed(w, root.selectedYear)
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
