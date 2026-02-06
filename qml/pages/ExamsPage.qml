import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: examsPage
    implicitHeight: mainLayout.implicitHeight

    property string activeView: "planning"
    property string modalType: ""
    property bool showAssignModal: false
    property bool showDetailModal: false
    property var selectedItem: null
    property int selectedMonth: 1
    property int selectedYear: 2026

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true

            PageHeader {
                Layout.fillWidth: true
                title: "Planning & Organisation"
                subtitle: "Gestion centralisée des cours, examens et évènements scolaires."
            }

            Row {
                spacing: 12

                // View Toggle
                Rectangle {
                    implicitWidth: viewToggleRow.implicitWidth + 8
                    height: 42
                    radius: 16
                    color: Style.bgSecondary

                    Row {
                        id: viewToggleRow
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: planningLabel.implicitWidth + 28
                            height: 34
                            radius: 12
                            color: activeView === "planning" ? Style.bgWhite : "transparent"

                            Text {
                                id: planningLabel
                                anchors.centerIn: parent
                                text: "PLANNING"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: activeView === "planning" ? Style.primary : Style.textTertiary
                                font.letterSpacing: 0.5
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: activeView = "planning"
                            }
                        }

                        Rectangle {
                            width: calendarLabel.implicitWidth + 28
                            height: 34
                            radius: 12
                            color: activeView === "calendar" ? Style.bgWhite : "transparent"

                            Text {
                                id: calendarLabel
                                anchors.centerIn: parent
                                text: "CALENDRIER"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: activeView === "calendar" ? Style.primary : Style.textTertiary
                                font.letterSpacing: 0.5
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: activeView = "calendar"
                            }
                        }
                    }
                }

                // Action Buttons
                Rectangle {
                    implicitWidth: courseRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: Style.bgWhite
                    border.color: courseMa.containsMouse ? Style.primary : Style.borderLight

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        id: courseRow
                        anchors.centerIn: parent
                        spacing: 6

                        IconLabel {
                            iconName: "book"
                            iconSize: 14
                            iconColor: Style.primary
                        }

                        Text {
                            text: "COURS"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: Style.textPrimary
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: courseMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modalType = "course"
                            showAssignModal = true
                        }
                    }
                }

                Rectangle {
                    implicitWidth: examRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: examMa.containsMouse ? Style.primaryDark : Style.primary

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        id: examRow
                        anchors.centerIn: parent
                        spacing: 6

                        IconLabel {
                            iconName: "check"
                            iconSize: 14
                            iconColor: "#FFFFFF"
                        }

                        Text {
                            text: "EXAMEN"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: "#FFFFFF"
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: examMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modalType = "exam"
                            showAssignModal = true
                        }
                    }
                }

                Rectangle {
                    implicitWidth: eventRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: eventMa.containsMouse ? "#D97706" : Style.warningColor

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        id: eventRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "✨"
                            font.pixelSize: 14
                        }

                        Text {
                            text: "ÉVÈNEMENT"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: "#FFFFFF"
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: eventMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modalType = "event"
                            showAssignModal = true
                        }
                    }
                }
            }
        }

        // ─── Planning View ───
        Loader {
            Layout.fillWidth: true
            active: activeView === "planning"
            visible: active

            sourceComponent: Component {
                RowLayout {
                    spacing: 24

                    // Planning Table
                    AppCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 3
                        title: "Planning Hebdomadaire"
                        subtitle: "Visualisation des assignations actives"

                        Column {
                            width: parent.width
                            spacing: 0

                            // Table header
                            RowLayout {
                                width: parent.width
                                height: 50

                                SectionLabel {
                                    Layout.preferredWidth: 120
                                    text: "JOUR / HEURE"
                                }

                                SectionLabel {
                                    Layout.preferredWidth: 150
                                    text: "MATIÈRE"
                                }

                                SectionLabel {
                                    Layout.fillWidth: true
                                    text: "PROFESSEUR"
                                }

                                SectionLabel {
                                    Layout.preferredWidth: 100
                                    text: "CLASSE"
                                }

                                SectionLabel {
                                    Layout.preferredWidth: 120
                                    text: "SALLE"
                                }

                                SectionLabel {
                                    Layout.preferredWidth: 60
                                    text: "ACTION"
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            Separator {
                                width: parent.width
                            }

                            // Table rows
                            Repeater {
                                model: ListModel {
                                    ListElement {
                                        day: "Lundi"
                                        time: "08:00"
                                        subject: "Langue Arabe"
                                        professor: "Sheikh Omar"
                                        className: "3A"
                                        room: "Salle A1"
                                    }
                                    ListElement {
                                        day: "Mardi"
                                        time: "10:00"
                                        subject: "Coran (Hifz)"
                                        professor: "Mme. Fatma"
                                        className: "2B"
                                        room: "Salle B4"
                                    }
                                    ListElement {
                                        day: "Mercredi"
                                        time: "14:00"
                                        subject: "Fiqh"
                                        professor: "Sheikh Ahmed"
                                        className: "4C"
                                        room: "Grande Salle"
                                    }
                                    ListElement {
                                        day: "Jeudi"
                                        time: "08:00"
                                        subject: "Mathématiques"
                                        professor: "M. Youssef"
                                        className: "1A"
                                        room: "Labo 1"
                                    }
                                }

                                delegate: Column {
                                    width: parent.width

                                    Rectangle {
                                        width: parent.width
                                        height: 64
                                        color: rowMa.containsMouse ? Style.bgPage : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 0

                                            Column {
                                                Layout.preferredWidth: 120
                                                spacing: 2

                                                Text {
                                                    text: model.day
                                                    font.pixelSize: 13
                                                    font.weight: Font.Black
                                                    color: Style.textPrimary
                                                }

                                                Text {
                                                    text: model.time
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: Style.textTertiary
                                                }
                                            }

                                            Text {
                                                Layout.preferredWidth: 150
                                                text: model.subject
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: Style.primary
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Rectangle {
                                                    width: 28
                                                    height: 28
                                                    radius: 8
                                                    color: Style.bgSecondary

                                                    IconLabel {
                                                        anchors.centerIn: parent
                                                        iconName: "user"
                                                        iconSize: 12
                                                        iconColor: Style.textTertiary
                                                    }
                                                }

                                                Text {
                                                    text: model.professor
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    color: Style.textSecondary
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 100

                                                Badge {
                                                    text: "CLASSE " + model.className
                                                    variant: "neutral"
                                                }
                                            }

                                            RowLayout {
                                                Layout.preferredWidth: 120
                                                spacing: 6

                                                IconLabel {
                                                    iconName: "location"
                                                    iconSize: 12
                                                    iconColor: Style.textSecondary
                                                }

                                                Text {
                                                    text: model.room
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: Style.textSecondary
                                                }
                                            }

                                            Row {
                                                Layout.preferredWidth: 60
                                                Layout.alignment: Qt.AlignRight

                                                IconButton {
                                                    iconName: "close"
                                                    iconSize: 16
                                                    hoverColor: Style.errorColor
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: rowMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }
                                    }

                                    Separator {
                                        width: parent.width
                                    }
                                }
                            }
                        }
                    }

                    // Sidebar
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 20

                        AppCard {
                            Layout.fillWidth: true
                            title: "Guide d'Organisation"

                            Column {
                                width: parent.width
                                spacing: 20

                                Repeater {
                                    model: [
                                        { num: "1", title: "CHOISIR LA MATIÈRE", desc: "Définissez le contenu pédagogique de la session." },
                                        { num: "2", title: "ASSIGNER LE PROFESSEUR", desc: "Sélectionnez l'expert qualifié pour cette matière." },
                                        { num: "3", title: "CIBLER LA CLASSE", desc: "Identifiez le groupe d'élèves bénéficiaire." }
                                    ]

                                    delegate: RowLayout {
                                        width: parent.width
                                        spacing: 12

                                        Rectangle {
                                            width: 32
                                            height: 32
                                            radius: 16
                                            color: Style.primary

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.num
                                                font.pixelSize: 11
                                                font.weight: Font.Black
                                                color: "#FFFFFF"
                                            }
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: modelData.title
                                                font.pixelSize: 11
                                                font.weight: Font.Black
                                                color: Style.textPrimary
                                                font.letterSpacing: 0.5
                                            }

                                            Text {
                                                text: modelData.desc
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                                color: Style.textSecondary
                                                wrapMode: Text.WordWrap
                                                width: parent.width
                                                lineHeight: 1.4
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: alertCol.implicitHeight + 40
                            radius: 24
                            color: Style.warningBg
                            border.color: Style.warningBorder

                            Column {
                                id: alertCol
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 12

                                RowLayout {
                                    width: parent.width
                                    spacing: 10

                                    IconLabel {
                                        iconName: "alert"
                                        iconSize: 18
                                        iconColor: Style.warningColor
                                    }

                                    Text {
                                        text: "RAPPEL DE CONFLIT"
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        color: Style.warningColor
                                        font.letterSpacing: 1
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: "Le système vérifie automatiquement la disponibilité du professeur et de la salle lors de l'assignation."
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Style.warningColor
                                    wrapMode: Text.WordWrap
                                    lineHeight: 1.5
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── Calendar View ───
        Loader {
            Layout.fillWidth: true
            active: activeView === "calendar"
            visible: active

            sourceComponent: Component {
                AppCard {
                    Column {
                        width: parent.width
                        spacing: 20

                        // Calendar Header
                        RowLayout {
                            width: parent.width

                            RowLayout {
                                spacing: 12

                                Text {
                                    text: "Calendrier Scolaire"
                                    font.pixelSize: 18
                                    font.weight: Font.Black
                                    color: Style.textPrimary
                                }

                                // Month selector
                                ComboBox {
                                    implicitWidth: 140
                                    implicitHeight: 32
                                    currentIndex: selectedMonth
                                    model: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
                                    onCurrentIndexChanged: selectedMonth = currentIndex

                                    background: Rectangle {
                                        radius: 10
                                        color: Style.bgWhite
                                        border.color: Style.borderLight
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        leftPadding: 12
                                        rightPadding: 12
                                        text: parent.displayText
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        color: Style.textPrimary
                                        font.letterSpacing: 0.5
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                // Year selector
                                ComboBox {
                                    implicitWidth: 90
                                    implicitHeight: 32
                                    currentIndex: selectedYear - 2024
                                    model: ["2024", "2025", "2026", "2027", "2028"]
                                    onCurrentIndexChanged: selectedYear = 2024 + currentIndex

                                    background: Rectangle {
                                        radius: 10
                                        color: Style.bgWhite
                                        border.color: Style.borderLight
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        leftPadding: 12
                                        rightPadding: 12
                                        text: parent.displayText
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        color: Style.textPrimary
                                        font.letterSpacing: 0.5
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            // Legend
                            Row {
                                spacing: 16

                                Row {
                                    spacing: 6

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: Style.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "FINAL"
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        color: Style.textSecondary
                                        font.letterSpacing: 0.5
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Row {
                                    spacing: 6

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: Style.warningColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "CONTRÔLE"
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        color: Style.textSecondary
                                        font.letterSpacing: 0.5
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Row {
                                    spacing: 6

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: Style.infoColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "ÉVÈNEMENT"
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        color: Style.textSecondary
                                        font.letterSpacing: 0.5
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        // Weekday headers
                        GridLayout {
                            width: parent.width
                            columns: 7
                            columnSpacing: 12

                            Repeater {
                                model: ["LUN", "MAR", "MER", "JEU", "VEN", "SAM", "DIM"]

                                SectionLabel {
                                    Layout.fillWidth: true
                                    text: modelData
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        // Calendar grid
                        GridLayout {
                            width: parent.width
                            columns: 7
                            columnSpacing: 12
                            rowSpacing: 12

                            Repeater {
                                model: 31

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 120
                                    radius: 16
                                    color: (index + 1) === 6 ? Qt.rgba(0.24, 0.35, 0.27, 0.05) : Style.bgWhite
                                    border.color: (index + 1) === 6 ? Qt.rgba(0.24, 0.35, 0.27, 0.2) : Style.borderLight

                                    property int dayNum: index + 1

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 8

                                        Text {
                                            text: dayNum.toString()
                                            font.pixelSize: 13
                                            font.weight: Font.Black
                                            color: dayNum === 6 ? Style.primary : Style.textTertiary
                                        }

                                        Column {
                                            width: parent.width
                                            spacing: 4

                                            // Exam on day 7
                                            Rectangle {
                                                visible: dayNum === 7
                                                width: parent.width
                                                height: 36
                                                radius: 10
                                                color: Style.primary

                                                Column {
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 2

                                                    Text {
                                                        text: "Coran"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Black
                                                        color: "#FFFFFF"
                                                        elide: Text.ElideRight
                                                        width: parent.width
                                                    }

                                                    Text {
                                                        text: "Classe 5A"
                                                        font.pixelSize: 8
                                                        color: "#FFFFFF"
                                                        opacity: 0.8
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        selectedItem = {
                                                            subject: "Coran",
                                                            className: "5A",
                                                            type: "Final",
                                                            day: "7",
                                                            time: "09:00",
                                                            room: "Salle B1",
                                                            professor: "Sheikh Omar",
                                                            description: "Évaluation finale du premier semestre"
                                                        }
                                                        showDetailModal = true
                                                    }
                                                }
                                            }

                                            // Exam on day 9
                                            Rectangle {
                                                visible: dayNum === 9
                                                width: parent.width
                                                height: 36
                                                radius: 10
                                                color: Style.warningColor

                                                Column {
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 2

                                                    Text {
                                                        text: "Arabe"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Black
                                                        color: "#FFFFFF"
                                                        elide: Text.ElideRight
                                                        width: parent.width
                                                    }

                                                    Text {
                                                        text: "Classe 2B"
                                                        font.pixelSize: 8
                                                        color: "#FFFFFF"
                                                        opacity: 0.8
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                }
                                            }

                                            // Exam on day 12
                                            Rectangle {
                                                visible: dayNum === 12
                                                width: parent.width
                                                height: 36
                                                radius: 10
                                                color: Style.primary

                                                Column {
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 2

                                                    Text {
                                                        text: "Histoire"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Black
                                                        color: "#FFFFFF"
                                                        elide: Text.ElideRight
                                                        width: parent.width
                                                    }

                                                    Text {
                                                        text: "Classe 3A"
                                                        font.pixelSize: 8
                                                        color: "#FFFFFF"
                                                        opacity: 0.8
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                }
                                            }

                                            // Event on day 18
                                            Rectangle {
                                                visible: dayNum === 18
                                                width: parent.width
                                                height: 36
                                                radius: 10
                                                color: Style.infoColor

                                                Column {
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 2

                                                    Text {
                                                        text: "Réunion Parents"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Black
                                                        color: "#FFFFFF"
                                                        elide: Text.ElideRight
                                                        width: parent.width
                                                    }

                                                    Text {
                                                        text: "Tous"
                                                        font.pixelSize: 8
                                                        color: "#FFFFFF"
                                                        opacity: 0.8
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: 32
        }
    }

    // ─── Assign Modal ───
    ModalOverlay {
        show: showAssignModal
        modalWidth: Math.min(parent.width - 64, 720)
        onClose: showAssignModal = false

        // Modal Header
        Rectangle {
            width: parent.width
            height: 90
            color: "#FAFBFC"
            radius: 32

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 45
                color: "#FAFBFC"
            }

            Separator {
                anchors.bottom: parent.bottom
                width: parent.width
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Rectangle {
                    width: 48
                    height: 48
                    radius: 16
                    color: modalType === "exam" ? Style.primary : modalType === "event" ? Style.warningColor : Style.infoColor

                    Text {
                        anchors.centerIn: parent
                        text: modalType === "exam" ? "✓" : modalType === "event" ? "✨" : "📚"
                        font.pixelSize: 22
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: modalType === "exam" ? "Programmer un Examen" : modalType === "event" ? "Organiser un Évènement" : "Planifier un Cours"
                        font.pixelSize: 18
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "CONFIGURATION DE LA SESSION"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.textTertiary
                        font.letterSpacing: 1
                    }
                }

                IconButton {
                    iconName: "close"
                    iconSize: 18
                    onClicked: showAssignModal = false
                }
            }
        }

        // Modal Body
        Item {
            width: parent.width
            implicitHeight: bodyGrid.implicitHeight + 60

            GridLayout {
                id: bodyGrid
                anchors.fill: parent
                anchors.leftMargin: 32
                anchors.rightMargin: 32
                anchors.topMargin: 28
                anchors.bottomMargin: 32
                columns: 2
                columnSpacing: 24
                rowSpacing: 20

                // Left column
                Column {
                    Layout.fillWidth: true
                    spacing: 20

                    // Subject/Title
                    Column {
                        width: parent.width
                        spacing: 6

                        SectionLabel {
                            text: modalType === "event" ? "TITRE DE L'ÉVÈNEMENT" : "1. MATIÈRE"
                        }

                        Rectangle {
                            width: parent.width
                            height: 44
                            radius: 12
                            color: Style.bgPage
                            border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                Text {
                                    Layout.fillWidth: true
                                    text: "Sélectionner..."
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Style.textPrimary
                                }

                                Text {
                                    text: "▾"
                                    font.pixelSize: 12
                                    color: Style.textTertiary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    // Professor
                    Column {
                        width: parent.width
                        spacing: 6
                        visible: modalType !== "event"

                        SectionLabel {
                            text: "2. RESPONSABLE / PROF"
                        }

                        Rectangle {
                            width: parent.width
                            height: 44
                            radius: 12
                            color: Style.bgPage
                            border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                Text {
                                    Layout.fillWidth: true
                                    text: "Sélectionner..."
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Style.textPrimary
                                }

                                Text {
                                    text: "▾"
                                    font.pixelSize: 12
                                    color: Style.textTertiary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    // Class
                    Column {
                        width: parent.width
                        spacing: 6

                        SectionLabel {
                            text: "CIBLE (CLASSE/GROUPE)"
                        }

                        Rectangle {
                            width: parent.width
                            height: 44
                            radius: 12
                            color: Style.bgPage
                            border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                Text {
                                    Layout.fillWidth: true
                                    text: "Sélectionner..."
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Style.textPrimary
                                }

                                Text {
                                    text: "▾"
                                    font.pixelSize: 12
                                    color: Style.textTertiary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }

                // Right column
                Column {
                    Layout.fillWidth: true
                    spacing: 20

                    // Room
                    Column {
                        width: parent.width
                        spacing: 6

                        SectionLabel {
                            text: "LIEU / SALLE"
                        }

                        Rectangle {
                            width: parent.width
                            height: 44
                            radius: 12
                            color: Style.bgPage
                            border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                Text {
                                    Layout.fillWidth: true
                                    text: "Sélectionner..."
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Style.textPrimary
                                }

                                Text {
                                    text: "▾"
                                    font.pixelSize: 12
                                    color: Style.textTertiary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    // Date & Time
                    RowLayout {
                        width: parent.width
                        spacing: 12

                        FormField {
                            Layout.fillWidth: true
                            label: "DATE"
                            text: "07/02/2026"
                        }

                        FormField {
                            Layout.fillWidth: true
                            label: "HEURE"
                            text: "08:00"
                        }
                    }

                    // Submit button
                    Rectangle {
                        width: parent.width
                        height: 52
                        radius: 16
                        color: modalType === "exam" ? Style.primary : modalType === "event" ? Style.warningColor : Style.infoColor

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "Confirmer l'Organisation"
                                font.pixelSize: 12
                                font.weight: Font.Black
                                color: "#FFFFFF"
                                font.letterSpacing: 0.5
                            }

                            Text {
                                text: "→"
                                font.pixelSize: 16
                                color: "#FFFFFF"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showAssignModal = false
                        }
                    }
                }
            }
        }
    }

    // ─── Detail Modal ───
    ModalOverlay {
        show: showDetailModal
        modalWidth: 420
        onClose: showDetailModal = false

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            RowLayout {
                width: parent.width - 64
                spacing: 12

                Badge {
                    text: selectedItem ? selectedItem.type : "Final"
                    variant: "success"
                }

                Item {
                    Layout.fillWidth: true
                }

                IconButton {
                    iconName: "close"
                    iconSize: 18
                    onClicked: showDetailModal = false
                }
            }

            Item {
                width: 1
                height: 16
            }

            Column {
                width: parent.width - 64
                spacing: 20

                Text {
                    text: selectedItem ? selectedItem.subject : "Coran"
                    font.pixelSize: 24
                    font.weight: Font.Black
                    color: Style.textPrimary
                }

                Text {
                    width: parent.width
                    text: selectedItem ? selectedItem.description : "Évaluation finale du premier semestre"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Style.textSecondary
                    wrapMode: Text.WordWrap
                }

                Column {
                    width: parent.width
                    spacing: 14

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 10
                            color: Style.bgPage

                            IconLabel {
                                anchors.centerIn: parent
                                iconName: "calendar"
                                iconSize: 14
                                iconColor: Style.primary
                            }
                        }

                        Text {
                            text: selectedItem ? (selectedItem.day + " Février 2026 • " + selectedItem.time) : "7 Février 2026 • 09:00"
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 10
                            color: Style.bgPage

                            IconLabel {
                                anchors.centerIn: parent
                                iconName: "location"
                                iconSize: 14
                                iconColor: Style.primary
                            }
                        }

                        Text {
                            text: selectedItem ? (selectedItem.room + " • " + selectedItem.className) : "Salle B1 • 5A"
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 10
                            color: Style.bgPage

                            IconLabel {
                                anchors.centerIn: parent
                                iconName: "user"
                                iconSize: 14
                                iconColor: Style.primary
                            }
                        }

                        Text {
                            text: selectedItem ? selectedItem.professor : "Sheikh Omar"
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }
                    }
                }
            }

            Item {
                width: 1
                height: 24
            }

            RowLayout {
                width: parent.width - 64
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: Style.bgPage

                    Text {
                        anchors.centerIn: parent
                        text: "MODIFIER"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: Style.errorBg

                    Text {
                        anchors.centerIn: parent
                        text: "SUPPRIMER"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.errorColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }
}
