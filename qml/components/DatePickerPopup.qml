import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

Popup {
    id: root

    property date selectedDate: new Date()

    signal confirmed(string isoDate)

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 360
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

    // Internal state
    property int viewMonth: new Date().getMonth()      // 0-based
    property int viewYear: new Date().getFullYear()

    readonly property var monthNames: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                                       "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
    readonly property var dayHeaders: ["LUN", "MAR", "MER", "JEU", "VEN", "SAM", "DIM"]

    function daysInMonth(m, y) { return new Date(y, m + 1, 0).getDate() }
    function firstDayOffset(m, y) {
        var dow = new Date(y, m, 1).getDay()
        return dow === 0 ? 6 : dow - 1  // Monday = 0
    }

    function isSameDay(d1, d2) {
        return d1.getFullYear() === d2.getFullYear()
            && d1.getMonth() === d2.getMonth()
            && d1.getDate() === d2.getDate()
    }

    function formatSelected() {
        var d = selectedDate
        var dd = d.getDate().toString()
        if (dd.length < 2) dd = "0" + dd
        var mm = (d.getMonth() + 1).toString()
        if (mm.length < 2) mm = "0" + mm
        return dd + "/" + mm + "/" + d.getFullYear()
    }

    onAboutToShow: {
        viewMonth = selectedDate.getMonth()
        viewYear = selectedDate.getFullYear()
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
                    width: 36; height: 36; radius: 12
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
                    text: "Choisir la Date"
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

        // Month/Year navigation
        Item {
            width: parent.width
            height: 54

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    ComboBox {
                        id: monthCombo
                        anchors.fill: parent
                        anchors.margins: 2
                        model: root.monthNames
                        currentIndex: root.viewMonth
                        
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: monthCombo.displayText
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }

                        onActivated: root.viewMonth = currentIndex
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 120
                    height: 38
                    radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    ComboBox {
                        id: yearCombo
                        anchors.fill: parent
                        anchors.margins: 2
                        model: {
                            var years = []
                            var currentYear = new Date().getFullYear()
                            for (var i = currentYear - 80; i <= currentYear + 5; i++) {
                                years.push(i)
                            }
                            return years
                        }
                        currentIndex: root.viewYear - (new Date().getFullYear() - 80)
                        
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: yearCombo.displayText
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }

                        onActivated: root.viewYear = new Date().getFullYear() - 80 + currentIndex
                    }
                }
            }
        }

        // Day headers
        Item {
            width: parent.width
            height: 32

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Repeater {
                    model: root.dayHeaders

                    Item {
                        width: 42; height: 32

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 9
                            font.weight: Font.Black
                            color: Style.textTertiary
                            font.letterSpacing: 0.5
                        }
                    }
                }
            }
        }

        // Day grid - fixed 6 rows height
        Item {
            width: parent.width
            // Fixed height: 6 rows * 38px + 5 gaps * 2px + 16px padding = 254
            implicitHeight: 254

            GridLayout {
                id: dayGrid
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 4
                columns: 7
                columnSpacing: 0
                rowSpacing: 2

                property int offset: root.firstDayOffset(root.viewMonth, root.viewYear)
                property int days: root.daysInMonth(root.viewMonth, root.viewYear)
                // Always render 42 cells (6 rows * 7 columns) for fixed height
                property int totalCells: 42

                Repeater {
                    model: dayGrid.totalCells

                    Item {
                        width: 42; height: 38

                        property bool isDay: index >= dayGrid.offset && index < dayGrid.offset + dayGrid.days
                        property int dayNum: isDay ? index - dayGrid.offset + 1 : 1
                        property date cellDate: new Date(root.viewYear, root.viewMonth, dayNum)
                        property bool isSelected: isDay && root.isSameDay(cellDate, root.selectedDate)
                        property bool isToday: isDay && root.isSameDay(cellDate, new Date())

                        Rectangle {
                            anchors.centerIn: parent
                            width: 36; height: 36
                            radius: 12
                            visible: parent.isDay
                            color: parent.isSelected ? Style.primary
                                 : dayCellMa.containsMouse ? Style.bgSecondary
                                 : "transparent"

        
                            Text {
                                anchors.centerIn: parent
                                text: parent.parent.dayNum.toString()
                                font.pixelSize: 13
                                font.weight: parent.parent.isSelected || parent.parent.isToday ? Font.Black : Font.Medium
                                color: parent.parent.isSelected ? "#FFFFFF"
                                     : parent.parent.isToday ? Style.primary
                                     : Style.textPrimary
                            }

                            // Today indicator dot
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                width: 4; height: 4; radius: 2
                                color: parent.parent.isSelected ? "#FFFFFF" : Style.primary
                                visible: parent.parent.isToday
                            }
                        }

                        MouseArea {
                            id: dayCellMa
                            anchors.fill: parent
                            hoverEnabled: parent.isDay
                            cursorShape: parent.isDay ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (parent.isDay)
                                    root.selectedDate = parent.cellDate
                            }
                        }
                    }
                }
            }
        }

        Separator { width: parent.width }

        // Selected date indicator
        Item {
            width: parent.width
            height: 44

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 48
                height: 32
                radius: 10
                color: Style.primaryBg

                Text {
                    anchors.centerIn: parent
                    text: root.formatSelected()
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Style.primary
                }
            }
        }

        Separator { width: parent.width }

        // Footer
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
                    height: 42; radius: 12
                    color: cancelDpMa.containsMouse ? Style.bgSecondary : Style.bgPage

                    Text {
                        anchors.centerIn: parent
                        text: "ANNULER"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.textSecondary; font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: cancelDpMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 42; radius: 12
                    color: confirmDpMa.containsMouse ? Style.primaryDark : Style.primary

                    Text {
                        anchors.centerIn: parent
                        text: "CONFIRMER"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: "#FFFFFF"; font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: confirmDpMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var d = root.selectedDate
                            var dd = d.getDate().toString()
                            if (dd.length < 2) dd = "0" + dd
                            var mm = (d.getMonth() + 1).toString()
                            if (mm.length < 2) mm = "0" + mm
                            root.confirmed(dd + "/" + mm + "/" + d.getFullYear())
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
