import QtQuick
import QtQuick.Layouts
import UI.Components

Item {
    id: dashPage
    implicitHeight: mainLayout.implicitHeight

    Component.onCompleted: dashboardController.loadDashboard()

    Connections {
        target: gradesController
        function onOperationSucceeded(msg) { dashboardController.loadDashboard() }
    }

    Connections {
        target: attendanceController
        function onOperationSucceeded(msg) { dashboardController.loadDashboard() }
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 32

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true

            PageHeader {
                Layout.fillWidth: true
                title: "Bonjour, Admin !"
                subtitle: "Voici l'état actuel de l'école Ez-Zaytouna pour aujourd'hui."
            }

            Rectangle {
                implicitWidth: liveBadgeRow.implicitWidth + 24
                height: 40
                radius: 12
                color: Style.successBg
                border.color: Style.successBorder

                RowLayout {
                    id: liveBadgeRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "●"
                        font.pixelSize: 10
                        color: Style.successColor

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                        }
                    }

                    Text {
                        text: dashboardController.liveSessions.length + " SESSIONS EN DIRECT"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.successColor
                        font.letterSpacing: 1
                    }
                }
            }
        }

        // ─── Live Sessions Horizontal Scroll ───
        Item {
            Layout.fillWidth: true
            implicitHeight: 180
            visible: dashboardController.liveSessions.length > 0

            ListView {
                id: liveSessionsView
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 16
                clip: true
                model: dashboardController.liveSessions

                delegate: Rectangle {
                    width: 280
                    height: 180
                    radius: 20
                    color: Style.bgWhite
                    border.color: sessionCardMa.containsMouse ? Style.borderMedium : Style.borderLight

                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 16
                        width: 8; height: 8; radius: 4; color: Style.successColor

                        SequentialAnimation on opacity {
                            running: true; loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 1000 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 1000 }
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        RowLayout {
                            width: parent.width
                            spacing: 12

                            Rectangle {
                                width: 40; height: 40; radius: 12; color: Style.bgSecondary
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.className
                                    font.pixelSize: 13; font.weight: Font.Black; color: Style.textSecondary
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                Text { text: modelData.subject; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                Text { text: modelData.room; font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary; font.letterSpacing: 0.5 }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 10

                            RowLayout {
                                width: parent.width
                                Row {
                                    spacing: 6
                                    IconLabel { iconName: "clock"; iconSize: 12; iconColor: Style.textSecondary }
                                    Text {
                                        text: modelData.timeSlot
                                        font.pixelSize: 11; font.weight: Font.Medium; color: Style.textSecondary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Text { text: modelData.prof; font.pixelSize: 11; font.bold: true; color: Style.primary }
                            }

                            Column {
                                width: parent.width
                                spacing: 6

                                RowLayout {
                                    width: parent.width
                                    SectionLabel { text: "PROGRESSION"; Layout.fillWidth: true }
                                    SectionLabel { text: modelData.progress + "%" }
                                }

                                Rectangle {
                                    width: parent.width; height: 6; radius: 3
                                    color: Style.bgSecondary; border.color: Style.borderLight

                                    Rectangle {
                                        width: parent.width * (modelData.progress / 100)
                                        height: parent.height; radius: parent.radius; color: Style.primary
                                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: sessionCardMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        // ─── Stats Grid (4 cards) ───
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 20
            rowSpacing: 20

            StatCard {
                Layout.fillWidth: true
                label: "Total Étudiants"; value: dashboardController.totalStudents.toString()
                iconName: "users"; trend: ""; trendUp: true
                accentColor: Style.chartBlue; accentBg: Style.chartBlueLight
            }
            StatCard {
                Layout.fillWidth: true
                label: "Cours Actifs"; value: dashboardController.activeCourses.toString()
                iconName: "book"; trend: ""; trendUp: true
                accentColor: Style.successColor; accentBg: Style.successBg
            }
            StatCard {
                Layout.fillWidth: true
                label: "Présence Moy."; value: dashboardController.averageAttendance.toFixed(0) + "%"
                iconName: "calendar"; trend: ""; trendUp: false
                accentColor: Style.warningColor; accentBg: Style.warningBg
            }
            StatCard {
                Layout.fillWidth: true
                label: "Moyenne École"; value: dashboardController.schoolAverage.toFixed(1)
                iconName: "trending"; trend: ""; trendUp: true
                accentColor: Style.chartPurple; accentBg: Style.chartPurpleLight
            }
        }

        // ─── Charts Row ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            AppCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                title: "Performance par Niveau"

                SimpleBarChart {
                    width: parent.width
                    height: 320
                    data: dashboardController.levelPerformanceData
                }
            }

            AppCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                title: "Suivi des Absences"
                subtitle: "6 derniers mois"

                Column {
                    width: parent.width
                    spacing: 20

                    SimpleAreaChart {
                        width: parent.width
                        height: 200
                        data: dashboardController.absencesByMonth
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "Total absences (6 mois)"; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary; Layout.fillWidth: true }
                        Text {
                            text: {
                                var total = 0
                                var abs = dashboardController.absencesByMonth
                                for (var i = 0; i < abs.length; i++) total += abs[i].value
                                return total.toString()
                            }
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                        }
                    }
                }
            }
        }

        // ─── Recent Activity Row ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            AppCard {
                Layout.fillWidth: true
                title: "Dernières Notes Saisies"

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: dashboardController.recentGrades

                        delegate: Rectangle {
                            width: parent.width
                            height: 56; radius: 16
                            color: noteMouseArea.containsMouse ? Style.bgPage : "transparent"
                            border.color: noteMouseArea.containsMouse ? Style.borderLight : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 12

                                Avatar {
                                    initials: modelData.student ? modelData.student.charAt(0) : "?"
                                    size: 40; bgColor: Style.primaryBg; textColor: Style.primary
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: modelData.student || "—"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                }

                                Text { text: modelData.score || "—"; font.pixelSize: 13; font.bold: true; color: Style.successColor }
                            }

                            MouseArea {
                                id: noteMouseArea
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }

            AppCard {
                Layout.fillWidth: true
                title: "Examens à Venir"

                Column {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: dashboardController.upcomingExams

                        delegate: Rectangle {
                            width: parent.width
                            height: 72; radius: 16
                            color: Style.bgPage; border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 14

                                Rectangle {
                                    width: 56; height: 56; radius: 12
                                    color: Style.bgWhite; border.color: Style.borderLight

                                    Column {
                                        anchors.centerIn: parent; spacing: 2
                                        Text { text: modelData.month || ""; font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary; anchors.horizontalCenter: parent.horizontalCenter }
                                        Text { text: modelData.day || ""; font.pixelSize: 22; font.weight: Font.Black; color: Style.primary; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.title || "Examen"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text { text: (modelData.className || "") + " • " + (modelData.room || ""); font.pixelSize: 11; color: Style.textSecondary }
                                }

                                Rectangle {
                                    implicitWidth: examTimeLabel.implicitWidth + 16
                                    implicitHeight: examTimeLabel.implicitHeight + 10
                                    radius: 8; color: Style.primaryBg

                                    Text {
                                        id: examTimeLabel
                                        anchors.centerIn: parent
                                        text: modelData.time || ""
                                        font.pixelSize: 10; font.weight: Font.Black; color: Style.primary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }
}
