import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: dashPage
    implicitHeight: mainLayout.implicitHeight

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
                            NumberAnimation {
                                from: 1.0
                                to: 0.3
                                duration: 800
                            }
                            NumberAnimation {
                                from: 0.3
                                to: 1.0
                                duration: 800
                            }
                        }
                    }

                    Text {
                        text: "4 SESSIONS EN DIRECT"
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

            ListView {
                id: liveSessionsView
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 16
                clip: true

                model: ListModel {
                    ListElement {
                        room: "Salle A1"
                        subject: "Arabe"
                        className: "3A"
                        prof: "Sheikh Omar"
                        timeSlot: "08:00 - 10:00"
                        progress: 75
                    }
                    ListElement {
                        room: "Salle B4"
                        subject: "Coran"
                        className: "2B"
                        prof: "Mme. Fatma"
                        timeSlot: "09:00 - 11:00"
                        progress: 40
                    }
                    ListElement {
                        room: "Grande Salle"
                        subject: "Fiqh"
                        className: "5C"
                        prof: "Sheikh Ahmed"
                        timeSlot: "09:30 - 11:30"
                        progress: 20
                    }
                    ListElement {
                        room: "Labo"
                        subject: "Sciences"
                        className: "4A"
                        prof: "M. Youssef"
                        timeSlot: "08:30 - 10:30"
                        progress: 90
                    }
                }

                delegate: Rectangle {
                    width: 280
                    height: 180
                    radius: 20
                    color: Style.bgWhite
                    border.color: sessionCardMa.containsMouse ? Style.borderMedium : Style.borderLight

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }

                    // Live indicator
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 16
                        width: 8
                        height: 8
                        radius: 4
                        color: Style.successColor

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 1.0
                                to: 0.3
                                duration: 1000
                            }
                            NumberAnimation {
                                from: 0.3
                                to: 1.0
                                duration: 1000
                            }
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        // Class + Subject
                        RowLayout {
                            width: parent.width
                            spacing: 12

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 12
                                color: Style.bgSecondary

                                Text {
                                    anchors.centerIn: parent
                                    text: model.className
                                    font.pixelSize: 13
                                    font.weight: Font.Black
                                    color: Style.textSecondary
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: model.subject
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Style.textPrimary
                                }

                                Text {
                                    text: model.room
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Style.textTertiary
                                    font.letterSpacing: 0.5
                                }
                            }
                        }

                        // Time + Prof
                        Column {
                            width: parent.width
                            spacing: 10

                            RowLayout {
                                width: parent.width

                                Row {
                                    spacing: 6

                                    IconLabel {
                                        iconName: "clock"
                                        iconSize: 12
                                        iconColor: Style.textSecondary
                                    }

                                    Text {
                                        text: model.timeSlot
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: Style.textSecondary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: model.prof
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Style.primary
                                }
                            }

                            // Progress bar
                            Column {
                                width: parent.width
                                spacing: 6

                                RowLayout {
                                    width: parent.width

                                    SectionLabel {
                                        text: "PROGRESSION"
                                        Layout.fillWidth: true
                                    }

                                    SectionLabel {
                                        text: model.progress + "%"
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: Style.bgSecondary
                                    border.color: Style.borderLight

                                    Rectangle {
                                        width: parent.width * (model.progress / 100)
                                        height: parent.height
                                        radius: parent.radius
                                        color: Style.primary

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 1000
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: sessionCardMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
                label: "Total Étudiants"; value: "225"
                iconName: "users"; trend: "+12%"; trendUp: true
                accentColor: Style.chartBlue; accentBg: Style.chartBlueLight
            }
            StatCard {
                Layout.fillWidth: true
                label: "Cours Actifs"; value: "18"
                iconName: "book"; trend: "+2"; trendUp: true
                accentColor: Style.successColor; accentBg: Style.successBg
            }
            StatCard {
                Layout.fillWidth: true
                label: "Présence Moy."; value: "94%"
                iconName: "calendar"; trend: "-1.5%"; trendUp: false
                accentColor: Style.warningColor; accentBg: Style.warningBg
            }
            StatCard {
                Layout.fillWidth: true
                label: "Moyenne École"; value: "14.5"
                iconName: "trending"; trend: "+0.4"; trendUp: true
                accentColor: Style.chartPurple; accentBg: Style.chartPurpleLight
            }
        }

        // ─── Charts Row ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            // Performance par Niveau
            AppCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                title: "Performance par Niveau"

                SimpleBarChart {
                    width: parent.width
                    height: 320
                    data: [
                        { label: "Niveau 1", values: [45, 38] },
                        { label: "Niveau 2", values: [52, 44] },
                        { label: "Niveau 3", values: [38, 32] },
                        { label: "Niveau 4", values: [48, 41] },
                        { label: "Niveau 5", values: [42, 35] }
                    ]
                }
            }

            // Suivi des Absences
            AppCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                title: "Suivi des Absences"
                subtitle: "Cette semaine"

                Column {
                    width: parent.width
                    spacing: 20

                    SimpleAreaChart {
                        width: parent.width
                        height: 200
                        data: [
                            { label: "Lun", value: 4 },
                            { label: "Mar", value: 2 },
                            { label: "Mer", value: 7 },
                            { label: "Jeu", value: 3 },
                            { label: "Ven", value: 5 },
                            { label: "Sam", value: 1 }
                        ]
                    }

                    // Total absences
                    RowLayout {
                        width: parent.width
                        Text { text: "Total absences"; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary; Layout.fillWidth: true }
                        Text { text: "22"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                    }

                    ProgressBar_ {
                        width: parent.width
                        value: 0.15
                    }

                    Text {
                        text: "Moins de 5% du total des étudiants."
                        font.pixelSize: 11
                        color: Style.textTertiary
                    }
                }
            }
        }

        // ─── Recent Activity Row ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            // Dernières Notes
            AppCard {
                Layout.fillWidth: true
                title: "Dernières Notes Saisies"

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: ListModel {
                            ListElement { student: "Amine Ben Salem"; subject: "Coran"; level: "Niveau 3"; score: "18.5/20"; time: "Il y a 10 min" }
                            ListElement { student: "Fatima Zahra"; subject: "Arabe"; level: "Niveau 1"; score: "16.0/20"; time: "Il y a 25 min" }
                            ListElement { student: "Omar El Farouk"; subject: "Fiqh"; level: "Niveau 5"; score: "14.5/20"; time: "Il y a 1 heure" }
                            ListElement { student: "Sarah Mansouri"; subject: "Sunnah"; level: "Niveau 2"; score: "19.0/20"; time: "Il y a 2 heures" }
                        }

                        delegate: Rectangle {
                            width: parent.width
                            height: 56
                            radius: 16
                            color: noteMouseArea.containsMouse ? Style.bgPage : "transparent"
                            border.color: noteMouseArea.containsMouse ? Style.borderLight : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Avatar {
                                    initials: model.student.charAt(0)
                                    size: 40
                                    bgColor: Style.primaryBg
                                    textColor: Style.primary
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: model.student; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text { text: model.subject + " • " + model.level; font.pixelSize: 11; color: Style.textSecondary }
                                }

                                Column {
                                    spacing: 2
                                    Text { text: model.score; font.pixelSize: 13; font.bold: true; color: Style.successColor; anchors.right: parent.right }
                                    Text { text: model.time; font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary; anchors.right: parent.right }
                                }
                            }

                            MouseArea {
                                id: noteMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }

            // Examens à Venir
            AppCard {
                Layout.fillWidth: true
                title: "Examens à Venir"

                Column {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: ListModel {
                            ListElement { title_: "Examen Arabe"; level: "Niveau 2"; day: "7"; time_: "09:00"; room: "Salle A1" }
                            ListElement { title_: "Final Coran"; level: "Niveau 5"; day: "8"; time_: "14:30"; room: "Grande Salle" }
                            ListElement { title_: "Test Fiqh"; level: "Niveau 3"; day: "9"; time_: "10:15"; room: "Salle B4" }
                        }

                        delegate: Rectangle {
                            width: parent.width
                            height: 72
                            radius: 16
                            color: Style.bgPage
                            border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 14

                                // Date box
                                Rectangle {
                                    width: 56; height: 56
                                    radius: 12
                                    color: Style.bgWhite
                                    border.color: Style.borderLight

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text { text: "FEV"; font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary; anchors.horizontalCenter: parent.horizontalCenter }
                                        Text { text: model.day; font.pixelSize: 22; font.weight: Font.Black; color: Style.primary; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: model.title_; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text { text: model.level + " • " + model.room; font.pixelSize: 11; color: Style.textSecondary }
                                }

                                Rectangle {
                                    implicitWidth: timeLabel.implicitWidth + 16
                                    implicitHeight: timeLabel.implicitHeight + 10
                                    radius: 8
                                    color: Style.primaryBg

                                    Text {
                                        id: timeLabel
                                        anchors.centerIn: parent
                                        text: model.time_
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        color: Style.primary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom spacer
        Item { Layout.preferredHeight: 32 }
    }
}
