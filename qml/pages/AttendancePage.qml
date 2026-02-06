import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: attendancePage
    implicitHeight: mainLayout.implicitHeight

    property string viewMode: "current"
    property bool showCallModal: false
    property bool showGuestModal: false
    property bool showIncidentModal: false
    property string selectedSessionSubject: ""
    property string selectedSessionClass: ""
    property string selectedSessionProf: ""
    property string selectedSessionTime: ""
    property int selectedWeek: 6
    property string selectedMonth: "Février"
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
                title: "Gestion des Présences"
                subtitle: "Pilotage hebdomadaire de l'appel et suivi des sessions."
            }

            Row {
                spacing: 8

                // Week selector
                ComboBox {
                    id: weekCombo
                    model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
                    currentIndex: selectedWeek - 1
                    onCurrentValueChanged: selectedWeek = currentValue
                    width: 110

                    background: Rectangle {
                        implicitWidth: 110
                        implicitHeight: 36
                        radius: 12
                        color: Style.bgPage
                        border.color: weekCombo.pressed ? Style.primary : Style.borderLight
                    }

                    contentItem: Text {
                        leftPadding: 12
                        rightPadding: 12
                        text: "Sem. " + weekCombo.currentValue
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.textSecondary
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Month selector
                ComboBox {
                    id: monthCombo
                    model: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
                    currentIndex: 1
                    onCurrentTextChanged: selectedMonth = currentText
                    width: 120

                    background: Rectangle {
                        implicitWidth: 120
                        implicitHeight: 36
                        radius: 12
                        color: Style.bgPage
                        border.color: monthCombo.pressed ? Style.primary : Style.borderLight
                    }

                    contentItem: Text {
                        leftPadding: 12
                        rightPadding: 12
                        text: monthCombo.displayText
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.textSecondary
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Year selector
                ComboBox {
                    id: yearCombo
                    model: [2024, 2025, 2026]
                    currentIndex: 2
                    onCurrentValueChanged: selectedYear = currentValue
                    width: 90

                    background: Rectangle {
                        implicitWidth: 90
                        implicitHeight: 36
                        radius: 12
                        color: Style.bgPage
                        border.color: yearCombo.pressed ? Style.primary : Style.borderLight
                    }

                    contentItem: Text {
                        leftPadding: 12
                        rightPadding: 12
                        text: yearCombo.currentValue
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.textSecondary
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // View toggle
                Rectangle {
                    width: viewToggleRow.implicitWidth + 16
                    height: 42
                    radius: 16
                    color: Style.bgSecondary

                    Row {
                        id: viewToggleRow
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: currentLabel.implicitWidth + 32
                            height: 34
                            radius: 12
                            color: viewMode === "current" ? Style.primary : "transparent"

                            Text {
                                id: currentLabel
                                anchors.centerIn: parent
                                text: "Semaine Actuelle"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: viewMode === "current" ? "#FFFFFF" : Style.textTertiary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: viewMode = "current"
                            }
                        }

                        Rectangle {
                            width: historyLabel.implicitWidth + 32
                            height: 34
                            radius: 12
                            color: viewMode === "history" ? Style.primary : "transparent"

                            Text {
                                id: historyLabel
                                anchors.centerIn: parent
                                text: "Archives"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: viewMode === "history" ? "#FFFFFF" : Style.textTertiary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: viewMode = "history"
                            }
                        }
                    }
                }
            }
        }

        // ─── Current Week View ───
        Loader {
            Layout.fillWidth: true
            active: viewMode === "current"
            visible: active

            sourceComponent: Component {
                RowLayout {
                    spacing: 24

                    // Left: Planning & Incidents
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 2
                        spacing: 24

                        // Session Planning Card
                        AppCard {
                            Layout.fillWidth: true
                            title: "Planning des Présences - Semaine " + selectedWeek
                            subtitle: "Appels à effectuer ou déjà complétés"

                            Column {
                                width: parent.width
                                spacing: 16

                                // Lundi
                                Column {
                                    width: parent.width
                                    spacing: 8

                                    SectionLabel {
                                        text: "LUNDI"
                                        font.pixelSize: 10
                                    }

                                    RowLayout {
                                        width: parent.width
                                        spacing: 12

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 72
                                            radius: 16
                                            color: Style.bgWhite
                                            border.color: sessionMa1.containsMouse ? Style.primary : Style.borderLight

                                            Behavior on border.color {
                                                ColorAnimation { duration: 150 }
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 16
                                                spacing: 12

                                                Rectangle {
                                                    width: 40
                                                    height: 40
                                                    radius: 12
                                                    color: Style.successBg

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "3A"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: Style.successColor
                                                    }
                                                }

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        text: "Langue Arabe"
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: Style.textPrimary
                                                    }

                                                    Text {
                                                        text: "08:00 - 10:00"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Bold
                                                        color: Style.textTertiary
                                                    }
                                                }

                                                Text {
                                                    text: "✓"
                                                    font.pixelSize: 16
                                                    color: Style.successColor
                                                }
                                            }

                                            MouseArea {
                                                id: sessionMa1
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    selectedSessionSubject = "Langue Arabe"
                                                    selectedSessionClass = "3A"
                                                    selectedSessionProf = "Sheikh Omar"
                                                    selectedSessionTime = "08:00 - 10:00"
                                                    showCallModal = true
                                                }
                                            }
                                        }
                                    }
                                }

                                // Mardi
                                Column {
                                    width: parent.width
                                    spacing: 8

                                    SectionLabel {
                                        text: "MARDI"
                                        font.pixelSize: 10
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 72
                                        radius: 16
                                        color: Style.bgWhite
                                        border.color: sessionMa2.containsMouse ? Style.primary : Style.borderLight

                                        Behavior on border.color {
                                            ColorAnimation { duration: 150 }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 12

                                            Rectangle {
                                                width: 40
                                                height: 40
                                                radius: 12
                                                color: Style.successBg

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "2B"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: Style.successColor
                                                }
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: "Coran (Hifz)"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: Style.textPrimary
                                                }

                                                Text {
                                                    text: "10:15 - 12:15"
                                                    font.pixelSize: 9
                                                    font.weight: Font.Bold
                                                    color: Style.textTertiary
                                                }
                                            }

                                            Text {
                                                text: "✓"
                                                font.pixelSize: 16
                                                color: Style.successColor
                                            }
                                        }

                                        MouseArea {
                                            id: sessionMa2
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                selectedSessionSubject = "Coran (Hifz)"
                                                selectedSessionClass = "2B"
                                                selectedSessionProf = "Mme. Fatma"
                                                selectedSessionTime = "10:15 - 12:15"
                                                showCallModal = true
                                            }
                                        }
                                    }
                                }

                                // Mercredi
                                Column {
                                    width: parent.width
                                    spacing: 8

                                    SectionLabel {
                                        text: "MERCREDI"
                                        font.pixelSize: 10
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 72
                                        radius: 16
                                        color: Style.bgWhite
                                        border.color: sessionMa3.containsMouse ? Style.primary : Style.borderLight

                                        Behavior on border.color {
                                            ColorAnimation { duration: 150 }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 12

                                            Rectangle {
                                                width: 40
                                                height: 40
                                                radius: 12
                                                color: Style.successBg

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "4C"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: Style.successColor
                                                }
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: "Éducation Islamique"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: Style.textPrimary
                                                }

                                                Text {
                                                    text: "08:00 - 10:00"
                                                    font.pixelSize: 9
                                                    font.weight: Font.Bold
                                                    color: Style.textTertiary
                                                }
                                            }

                                            Text {
                                                text: "✓"
                                                font.pixelSize: 16
                                                color: Style.successColor
                                            }
                                        }

                                        MouseArea {
                                            id: sessionMa3
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                selectedSessionSubject = "Éducation Islamique"
                                                selectedSessionClass = "4C"
                                                selectedSessionProf = "Sheikh Ahmed"
                                                selectedSessionTime = "08:00 - 10:00"
                                                showCallModal = true
                                            }
                                        }
                                    }
                                }

                                // Jeudi
                                Column {
                                    width: parent.width
                                    spacing: 8

                                    SectionLabel {
                                        text: "JEUDI"
                                        font.pixelSize: 10
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 72
                                        radius: 16
                                        color: Style.bgWhite
                                        border.color: sessionMa4.containsMouse ? Style.primary : Style.borderLight

                                        Behavior on border.color {
                                            ColorAnimation { duration: 150 }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 12

                                            Rectangle {
                                                width: 40
                                                height: 40
                                                radius: 12
                                                color: Style.warningBg

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "1A"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: Style.warningColor
                                                }
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: "Mathématiques"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: Style.textPrimary
                                                }

                                                Text {
                                                    text: "14:00 - 16:00"
                                                    font.pixelSize: 9
                                                    font.weight: Font.Bold
                                                    color: Style.textTertiary
                                                }
                                            }

                                            Text {
                                                text: "›"
                                                font.pixelSize: 18
                                                color: Style.textTertiary
                                            }
                                        }

                                        MouseArea {
                                            id: sessionMa4
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                selectedSessionSubject = "Mathématiques"
                                                selectedSessionClass = "1A"
                                                selectedSessionProf = "M. Youssef"
                                                selectedSessionTime = "14:00 - 16:00"
                                                showCallModal = true
                                            }
                                        }
                                    }
                                }

                                // Vendredi
                                Column {
                                    width: parent.width
                                    spacing: 8

                                    SectionLabel {
                                        text: "VENDREDI"
                                        font.pixelSize: 10
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 72
                                        radius: 16
                                        color: Style.bgWhite
                                        border.color: sessionMa5.containsMouse ? Style.primary : Style.borderLight

                                        Behavior on border.color {
                                            ColorAnimation { duration: 150 }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 12

                                            Rectangle {
                                                width: 40
                                                height: 40
                                                radius: 12
                                                color: Style.warningBg

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "3A"
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: Style.warningColor
                                                }
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: "Fiqh"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: Style.textPrimary
                                                }

                                                Text {
                                                    text: "08:00 - 10:00"
                                                    font.pixelSize: 9
                                                    font.weight: Font.Bold
                                                    color: Style.textTertiary
                                                }
                                            }

                                            Text {
                                                text: "›"
                                                font.pixelSize: 18
                                                color: Style.textTertiary
                                            }
                                        }

                                        MouseArea {
                                            id: sessionMa5
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                selectedSessionSubject = "Fiqh"
                                                selectedSessionClass = "3A"
                                                selectedSessionProf = "Sheikh Omar"
                                                selectedSessionTime = "08:00 - 10:00"
                                                showCallModal = true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Incident Journal
                        AppCard {
                            Layout.fillWidth: true
                            title: "Journal des Incidents & Retards"

                            Column {
                                width: parent.width
                                spacing: 0

                                // Table header
                                RowLayout {
                                    width: parent.width
                                    height: 40

                                    SectionLabel {
                                        Layout.fillWidth: true
                                        text: "ÉLÈVE"
                                        font.pixelSize: 10
                                    }

                                    SectionLabel {
                                        Layout.preferredWidth: 140
                                        text: "TYPE"
                                        font.pixelSize: 10
                                    }

                                    SectionLabel {
                                        Layout.preferredWidth: 80
                                        text: "ACTION"
                                        font.pixelSize: 10
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                Separator {
                                    width: parent.width
                                }

                                Repeater {
                                    model: ListModel {
                                        ListElement {
                                            name: "Yassine Mansour"
                                            className: "3A"
                                            incidentType: "Retard injustifié"
                                            incidentDate: "06/02/2026"
                                            typeVariant: "warning"
                                        }
                                        ListElement {
                                            name: "Sara Khalil"
                                            className: "2B"
                                            incidentType: "Sortie prématurée"
                                            incidentDate: "05/02/2026"
                                            typeVariant: "error"
                                        }
                                        ListElement {
                                            name: "Amine Ben Salem"
                                            className: "3A"
                                            incidentType: "Absence répétée"
                                            incidentDate: "04/02/2026"
                                            typeVariant: "error"
                                        }
                                    }

                                    delegate: Column {
                                        width: parent.width

                                        RowLayout {
                                            width: parent.width
                                            height: 60

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: model.name
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    color: Style.textPrimary
                                                }

                                                Text {
                                                    text: model.className + " • " + model.incidentDate
                                                    font.pixelSize: 10
                                                    font.weight: Font.Bold
                                                    color: Style.textTertiary
                                                }
                                            }

                                            Badge {
                                                Layout.preferredWidth: 140
                                                text: model.incidentType
                                                variant: model.typeVariant
                                            }

                                            Row {
                                                Layout.preferredWidth: 80
                                                Layout.alignment: Qt.AlignRight
                                                spacing: 4

                                                IconButton {
                                                    iconName: "edit"
                                                    iconSize: 14
                                                }

                                                IconButton {
                                                    iconName: "delete"
                                                    iconSize: 14
                                                    hoverColor: Style.errorColor
                                                }
                                            }
                                        }

                                        Separator {
                                            width: parent.width
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Right sidebar: Analyse de Présence
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 24

                        AppCard {
                            Layout.fillWidth: true
                            title: "Analyse de Présence"

                            Column {
                                width: parent.width
                                spacing: 16

                                RowLayout {
                                    width: parent.width

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Taux Moyen"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Style.textSecondary
                                    }

                                    Text {
                                        text: "94%"
                                        font.pixelSize: 18
                                        font.weight: Font.Black
                                        color: Style.successColor
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 8
                                    radius: 4
                                    color: Style.bgSecondary

                                    Rectangle {
                                        width: parent.width * 0.94
                                        height: parent.height
                                        radius: parent.radius
                                        color: Style.successColor
                                    }
                                }

                                Item {
                                    width: 1
                                    height: 8
                                }

                                // Breakdown by class
                                Repeater {
                                    model: [
                                        { className: "Classe 3A", rate: "96%", progress: 0.96 },
                                        { className: "Classe 2B", rate: "91%", progress: 0.91 },
                                        { className: "Classe 4C", rate: "98%", progress: 0.98 },
                                        { className: "Classe 1A", rate: "88%", progress: 0.88 }
                                    ]

                                    delegate: Column {
                                        width: parent.width
                                        spacing: 6

                                        RowLayout {
                                            width: parent.width

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.className
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: Style.textPrimary
                                            }

                                            Text {
                                                text: modelData.rate
                                                font.pixelSize: 12
                                                font.weight: Font.Black
                                                color: Style.textTertiary
                                            }
                                        }

                                        ProgressBar_ {
                                            width: parent.width
                                            value: modelData.progress
                                        }
                                    }
                                }
                            }
                        }

                        // Quick Stats
                        AppCard {
                            Layout.fillWidth: true
                            title: "Statistiques Rapides"

                            Column {
                                width: parent.width
                                spacing: 14

                                RowLayout {
                                    width: parent.width
                                    spacing: 12

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 12
                                        color: Style.successBg

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            font.pixelSize: 16
                                            color: Style.successColor
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: "Présents Aujourd'hui"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Style.textPrimary
                                        }

                                        Text {
                                            text: "87 / 92 ÉLÈVES"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: Style.textTertiary
                                        }
                                    }
                                }

                                Separator {
                                    width: parent.width
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 12

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 12
                                        color: Style.warningBg

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⏰"
                                            font.pixelSize: 16
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: "Retards cette Semaine"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Style.textPrimary
                                        }

                                        Text {
                                            text: "3 INCIDENTS"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: Style.warningColor
                                        }
                                    }
                                }

                                Separator {
                                    width: parent.width
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 12

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 12
                                        color: Style.errorBg

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⚠"
                                            font.pixelSize: 16
                                            color: Style.errorColor
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: "Absences Répétées"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Style.textPrimary
                                        }

                                        Text {
                                            text: "1 ÉLÈVE EN ALERTE"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: Style.errorColor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── History View ───
        Loader {
            Layout.fillWidth: true
            active: viewMode === "history"
            visible: active

            sourceComponent: Component {
                AppCard {
                    title: "Historique Complet"

                    Column {
                        width: parent.width
                        spacing: 0

                        RowLayout {
                            width: parent.width
                            height: 40

                            SectionLabel {
                                Layout.fillWidth: true
                                text: "DATE / SÉANCE"
                                font.pixelSize: 10
                            }

                            SectionLabel {
                                Layout.preferredWidth: 100
                                text: "ACTION"
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Separator {
                            width: parent.width
                        }

                        Repeater {
                            model: ListModel {
                                ListElement {
                                    label: "05/02 - Langue Arabe (3A)"
                                }
                                ListElement {
                                    label: "05/02 - Coran (2B)"
                                }
                                ListElement {
                                    label: "04/02 - Éducation Islamique (4C)"
                                }
                                ListElement {
                                    label: "03/02 - Coran Hifz (2B)"
                                }
                                ListElement {
                                    label: "02/02 - Langue Arabe (3A)"
                                }
                            }

                            delegate: Column {
                                width: parent.width

                                RowLayout {
                                    width: parent.width
                                    height: 52

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.label
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Style.textPrimary
                                    }

                                    Text {
                                        Layout.preferredWidth: 100
                                        text: "CONSULTER"
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        color: Style.primary
                                        horizontalAlignment: Text.AlignRight

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                selectedSessionSubject = "Langue Arabe"
                                                selectedSessionClass = "3A"
                                                selectedSessionProf = "Sheikh Omar"
                                                selectedSessionTime = "08:00 - 10:00"
                                                showCallModal = true
                                            }
                                        }
                                    }
                                }

                                Separator {
                                    width: parent.width
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

    // ─── Call Modal ───
    ModalOverlay {
        show: showCallModal
        modalWidth: Math.min(parent.width - 64, 900)
        onClose: showCallModal = false

        // Modal Header
        Rectangle {
            width: parent.width
            height: 80
            color: "#FAFBFC"
            radius: 32

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 40
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

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        spacing: 10

                        Text {
                            text: selectedSessionSubject
                            font.pixelSize: 20
                            font.weight: Font.Black
                            color: Style.textPrimary
                        }

                        Badge {
                            text: "Classe " + selectedSessionClass
                            variant: "info"
                        }
                    }

                    Text {
                        text: selectedSessionProf + " • " + selectedSessionTime
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Style.textTertiary
                        font.letterSpacing: 1
                    }
                }

                OutlineButton {
                    text: "Ajouter Invité"
                    iconName: "plus"
                    onClicked: showGuestModal = true
                }

                IconButton {
                    iconName: "close"
                    iconSize: 18
                    onClicked: showCallModal = false
                }
            }
        }

        // Student Cards Grid
        Item {
            width: parent.width
            implicitHeight: studentGrid.implicitHeight + 48

            GridLayout {
                id: studentGrid
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                columns: 4
                columnSpacing: 16
                rowSpacing: 16

                Repeater {
                    model: ListModel {
                        ListElement {
                            name: "Yassine Mansour"
                            status: "present"
                        }
                        ListElement {
                            name: "Sara Khalil"
                            status: "present"
                        }
                        ListElement {
                            name: "Amine Ben Salem"
                            status: "present"
                        }
                        ListElement {
                            name: "Layla Mansour"
                            status: "late"
                        }
                        ListElement {
                            name: "Zaid Al-Harbi"
                            status: "absent"
                        }
                    }

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: studentCardCol.implicitHeight + 32
                        radius: 24
                        color: Style.bgWhite
                        border.color: Style.borderLight

                        Column {
                            id: studentCardCol
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            // Avatar
                            Rectangle {
                                width: 56
                                height: 56
                                radius: 20
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Style.bgSecondary
                                border.color: "#FFFFFF"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: model.name.charAt(0)
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: Style.primary
                                }
                            }

                            // Name
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: model.name
                                font.pixelSize: 11
                                font.bold: true
                                color: Style.textPrimary
                                elide: Text.ElideRight
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // Status Buttons
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 6

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 10
                                    color: model.status === "present" ? Style.successColor : Style.bgPage
                                    border.color: model.status === "present" ? Style.successColor : Style.borderLight

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: model.status === "present" ? "#FFFFFF" : Style.textTertiary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 10
                                    color: model.status === "late" ? Style.warningColor : Style.bgPage
                                    border.color: model.status === "late" ? Style.warningColor : Style.borderLight

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⏰"
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 10
                                    color: model.status === "absent" ? Style.errorColor : Style.bgPage
                                    border.color: model.status === "absent" ? Style.errorColor : Style.borderLight

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: model.status === "absent" ? "#FFFFFF" : Style.textTertiary
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
            }
        }

        // Modal Footer (custom - not using ModalButtons)
        Rectangle {
            width: parent.width
            height: 80
            color: "#FAFBFC"

            Separator {
                anchors.top: parent.top
                width: parent.width
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    height: 48
                    radius: 16
                    color: Style.bgWhite
                    border.color: Style.borderLight

                    Text {
                        anchors.centerIn: parent
                        text: "FERMER"
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: Style.textTertiary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showCallModal = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    height: 48
                    radius: 16
                    color: Style.primary

                    Text {
                        anchors.centerIn: parent
                        text: "ENREGISTRER L'APPEL"
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: "#FFFFFF"
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showCallModal = false
                    }
                }
            }
        }
    }

    // ─── Guest Modal ───
    ModalOverlay {
        show: showGuestModal
        modalWidth: 420
        onClose: showGuestModal = false

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Ajouter un Invité"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
                bottomPadding: 24
            }

            FormField {
                width: parent.width - 64
                label: "NOM DE L'ÉLÈVE INVITÉ"
                placeholder: "Chercher ou saisir un nom..."
            }

            Item {
                width: 1
                height: 24
            }

            ModalButtons {
                width: parent.width - 64
                confirmText: "AJOUTER"
                confirmColor: Style.successColor
                onCancel: showGuestModal = false
                onConfirm: showGuestModal = false
            }
        }
    }

    // ─── Incident Modal ───
    ModalOverlay {
        show: showIncidentModal
        modalWidth: 420
        onClose: showIncidentModal = false

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: "Signaler un Incident"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
                bottomPadding: 24
            }

            Column {
                width: parent.width - 64
                spacing: 18

                Column {
                    width: parent.width
                    spacing: 6

                    SectionLabel {
                        text: "NATURE DE L'INCIDENT"
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
                                text: "Retard"
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

                FormField {
                    width: parent.width
                    label: "COMMENTAIRE (OPTIONNEL)"
                    placeholder: "Détails de l'incident..."
                    fieldHeight: 100
                    Component.onCompleted: inputItem.wrapMode = TextInput.Wrap
                }
            }

            Item {
                width: 1
                height: 24
            }

            ModalButtons {
                width: parent.width - 64
                confirmText: "SIGNALER & NOTIFIER"
                confirmColor: Style.warningColor
                onCancel: showIncidentModal = false
                onConfirm: showIncidentModal = false
            }
        }
    }
}
