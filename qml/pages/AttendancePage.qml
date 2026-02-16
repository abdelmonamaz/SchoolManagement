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
    property bool showCreateSeanceModal: false

    // Selected seance info for call modal
    property int selectedSeanceId: -1
    property string selectedSessionSubject: ""
    property string selectedSessionClass: ""
    property string selectedSessionProf: ""
    property string selectedSessionTime: ""

    property int selectedWeek: 6
    property string selectedMonth: "Février"
    property int selectedYear: 2026

    // Helper: month name to number
    function monthNameToNumber(name) {
        var months = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                      "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
        return months.indexOf(name) + 1
    }

    // Helper: compute ISO date range for a given week/month/year
    function computeDateRange() {
        var m = monthNameToNumber(selectedMonth)
        var dayStart = (selectedWeek - 1) * 7 + 1
        var dayEnd = dayStart + 6
        var daysInMonth = new Date(selectedYear, m, 0).getDate()
        if (dayEnd > daysInMonth) dayEnd = daysInMonth
        if (dayStart > daysInMonth) dayStart = daysInMonth

        var mm = m < 10 ? "0" + m : "" + m
        var ds = dayStart < 10 ? "0" + dayStart : "" + dayStart
        var de = dayEnd < 10 ? "0" + dayEnd : "" + dayEnd
        return {
            from: selectedYear + "-" + mm + "-" + ds + "T00:00:00",
            to: selectedYear + "-" + mm + "-" + de + "T23:59:59"
        }
    }

    function loadSeances() {
        var range = computeDateRange()
        attendanceController.loadSeancesByDateRange(range.from, range.to)
    }

    // Helper: day name from ISO date string
    function dayName(isoDate) {
        var d = new Date(isoDate)
        var days = ["DIMANCHE", "LUNDI", "MARDI", "MERCREDI", "JEUDI", "VENDREDI", "SAMEDI"]
        return days[d.getDay()]
    }

    // Helper: format time from ISO date
    function formatTime(isoDate, durationMin) {
        var d = new Date(isoDate)
        var hh = d.getHours()
        var mm = d.getMinutes()
        var startStr = (hh < 10 ? "0" + hh : hh) + ":" + (mm < 10 ? "0" + mm : mm)
        var endDate = new Date(d.getTime() + durationMin * 60000)
        var eh = endDate.getHours()
        var em = endDate.getMinutes()
        var endStr = (eh < 10 ? "0" + eh : eh) + ":" + (em < 10 ? "0" + em : em)
        return startStr + " - " + endStr
    }

    // Helper: format date dd/MM
    function formatDateShort(isoDate) {
        var d = new Date(isoDate)
        var dd = d.getDate()
        var mm = d.getMonth() + 1
        return (dd < 10 ? "0" + dd : dd) + "/" + (mm < 10 ? "0" + mm : mm)
    }

    // Lookup helpers using schoolingController data
    function findMatiereName(id) {
        var list = schoolingController.matieres
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i].nom
        return "Matière #" + id
    }

    function findClassName(id) {
        var list = schoolingController.classes
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i].nom
        return "Classe #" + id
    }

    function findProfName(id) {
        var list = staffController.professeurs
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i].prenom + " " + list[i].nom
        return "Prof #" + id
    }

    function findStudentName(id) {
        var list = studentController.students
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i].prenom + " " + list[i].nom
        return "Élève #" + id
    }

    Component.onCompleted: {
        schoolingController.loadNiveaux()
        schoolingController.loadSalles()
        staffController.loadProfesseurs()
        studentController.loadStudents()
        loadSeances()
    }

    Connections {
        target: attendanceController
        function onOperationSucceeded(msg) {
            console.log("AttendancePage:", msg)
            loadSeances()
        }
        function onOperationFailed(err) {
            console.warn("AttendancePage error:", err)
        }
    }

    // Reload when selectors change
    onSelectedWeekChanged: loadSeances()
    onSelectedMonthChanged: loadSeances()
    onSelectedYearChanged: loadSeances()

    // Group seances by day name
    function groupSeancesByDay() {
        var groups = {}
        var dayOrder = []
        var seances = attendanceController.seances
        for (var i = 0; i < seances.length; i++) {
            var s = seances[i]
            var day = dayName(s.dateHeureDebut)
            if (!(day in groups)) {
                groups[day] = []
                dayOrder.push(day)
            }
            groups[day].push(s)
        }
        return { groups: groups, order: dayOrder }
    }

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

                    // Left: Planning
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 2
                        spacing: 24

                        // Session Planning Card
                        AppCard {
                            Layout.fillWidth: true
                            title: "Planning des Présences - Semaine " + selectedWeek
                            subtitle: attendanceController.seances.length + " séance(s) cette semaine"

                            Column {
                                width: parent.width
                                spacing: 16

                                // Empty state
                                Text {
                                    visible: attendanceController.seances.length === 0
                                    text: attendanceController.loading ? "Chargement..." : "Aucune séance cette semaine"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Style.textTertiary
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    topPadding: 32
                                    bottomPadding: 32
                                }

                                // Dynamic seances grouped by day
                                Repeater {
                                    model: {
                                        var grouped = groupSeancesByDay()
                                        var items = []
                                        for (var d = 0; d < grouped.order.length; d++) {
                                            var day = grouped.order[d]
                                            items.push({ isHeader: true, dayName: day })
                                            var sessions = grouped.groups[day]
                                            for (var s = 0; s < sessions.length; s++) {
                                                items.push({ isHeader: false, seance: sessions[s] })
                                            }
                                        }
                                        return items
                                    }

                                    delegate: Loader {
                                        width: parent.width
                                        sourceComponent: modelData.isHeader ? dayHeaderComp : seanceCardComp
                                        property var itemData: modelData
                                    }
                                }
                            }
                        }

                        // Add Seance button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 16
                            color: Style.bgWhite
                            border.color: Style.borderLight
                            border.width: 2

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "+"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Style.primary
                                }

                                Text {
                                    text: "NOUVELLE SÉANCE"
                                    font.pixelSize: 11
                                    font.weight: Font.Black
                                    color: Style.primary
                                    font.letterSpacing: 1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: showCreateSeanceModal = true
                            }
                        }
                    }

                    // Right sidebar
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 24

                        AppCard {
                            Layout.fillWidth: true
                            title: "Résumé de la Semaine"

                            Column {
                                width: parent.width
                                spacing: 16

                                RowLayout {
                                    width: parent.width

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Séances planifiées"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Style.textSecondary
                                    }

                                    Text {
                                        text: attendanceController.seances.length
                                        font.pixelSize: 18
                                        font.weight: Font.Black
                                        color: Style.primary
                                    }
                                }

                                Separator { width: parent.width }

                                RowLayout {
                                    width: parent.width
                                    spacing: 12

                                    Rectangle {
                                        width: 40; height: 40; radius: 12
                                        color: Style.successBg
                                        Text {
                                            anchors.centerIn: parent
                                            text: "C"; font.pixelSize: 14; font.bold: true
                                            color: Style.successColor
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text {
                                            text: "Cours"; font.pixelSize: 12; font.bold: true
                                            color: Style.textPrimary
                                        }
                                        Text {
                                            text: {
                                                var c = 0; var sl = attendanceController.seances
                                                for (var i = 0; i < sl.length; i++)
                                                    if (sl[i].typeSeance === "Cours") c++
                                                return c + " séance(s)"
                                            }
                                            font.pixelSize: 9; font.weight: Font.Bold
                                            color: Style.textTertiary
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 12

                                    Rectangle {
                                        width: 40; height: 40; radius: 12
                                        color: Style.warningBg
                                        Text {
                                            anchors.centerIn: parent
                                            text: "E"; font.pixelSize: 14; font.bold: true
                                            color: Style.warningColor
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text {
                                            text: "Examens"; font.pixelSize: 12; font.bold: true
                                            color: Style.textPrimary
                                        }
                                        Text {
                                            text: {
                                                var c = 0; var sl = attendanceController.seances
                                                for (var i = 0; i < sl.length; i++)
                                                    if (sl[i].typeSeance === "Examen") c++
                                                return c + " séance(s)"
                                            }
                                            font.pixelSize: 9; font.weight: Font.Bold
                                            color: Style.textTertiary
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
                                    width: parent.width; spacing: 12

                                    Rectangle {
                                        width: 40; height: 40; radius: 12
                                        color: Style.successBg
                                        Text {
                                            anchors.centerIn: parent
                                            text: "P"; font.pixelSize: 14; font.bold: true
                                            color: Style.successColor
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text {
                                            text: "Participations chargées"
                                            font.pixelSize: 12; font.bold: true
                                            color: Style.textPrimary
                                        }
                                        Text {
                                            text: attendanceController.participations.length + " ENREGISTREMENT(S)"
                                            font.pixelSize: 9; font.weight: Font.Bold
                                            color: Style.textTertiary
                                        }
                                    }
                                }

                                Separator { width: parent.width }

                                Text {
                                    visible: attendanceController.errorMessage.length > 0
                                    text: attendanceController.errorMessage
                                    font.pixelSize: 11; font.bold: true
                                    color: Style.errorColor
                                    wrapMode: Text.Wrap; width: parent.width
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
                    title: "Historique des Séances"

                    Column {
                        width: parent.width
                        spacing: 0

                        RowLayout {
                            width: parent.width
                            height: 40

                            SectionLabel {
                                Layout.fillWidth: true; text: "DATE / SÉANCE"; font.pixelSize: 10
                            }
                            SectionLabel {
                                Layout.preferredWidth: 120; text: "CLASSE"; font.pixelSize: 10
                            }
                            SectionLabel {
                                Layout.preferredWidth: 100; text: "TYPE"; font.pixelSize: 10
                            }
                            SectionLabel {
                                Layout.preferredWidth: 100; text: "ACTION"; font.pixelSize: 10
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Separator { width: parent.width }

                        Text {
                            visible: attendanceController.seances.length === 0
                            text: attendanceController.loading ? "Chargement..." : "Aucune séance trouvée"
                            font.pixelSize: 13; font.bold: true; color: Style.textTertiary
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                            topPadding: 32; bottomPadding: 32
                        }

                        Repeater {
                            model: attendanceController.seances

                            delegate: Column {
                                width: parent.width

                                RowLayout {
                                    width: parent.width; height: 52

                                    Text {
                                        Layout.fillWidth: true
                                        text: formatDateShort(modelData.dateHeureDebut) + " - " + findMatiereName(modelData.matiereId)
                                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                    }

                                    Text {
                                        Layout.preferredWidth: 120
                                        text: findClassName(modelData.classeId)
                                        font.pixelSize: 12; font.bold: true; color: Style.textSecondary
                                    }

                                    Badge {
                                        Layout.preferredWidth: 100
                                        text: modelData.typeSeance
                                        variant: modelData.typeSeance === "Cours" ? "info" : "warning"
                                    }

                                    Text {
                                        Layout.preferredWidth: 100
                                        text: "CONSULTER"
                                        font.pixelSize: 10; font.weight: Font.Black
                                        color: Style.primary; horizontalAlignment: Text.AlignRight

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                selectedSeanceId = modelData.id
                                                selectedSessionSubject = findMatiereName(modelData.matiereId)
                                                selectedSessionClass = findClassName(modelData.classeId)
                                                selectedSessionProf = findProfName(modelData.profId)
                                                selectedSessionTime = formatTime(modelData.dateHeureDebut, modelData.dureeMinutes)
                                                attendanceController.loadParticipations(modelData.id)
                                                showCallModal = true
                                            }
                                        }
                                    }
                                }

                                Separator { width: parent.width }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }

    // ─── Day Header Component ───
    Component {
        id: dayHeaderComp

        SectionLabel {
            text: itemData.dayName
            font.pixelSize: 10
            topPadding: 8
        }
    }

    // ─── Seance Card Component ───
    Component {
        id: seanceCardComp

        Rectangle {
            width: parent ? parent.width : 200
            height: 72
            radius: 16
            color: Style.bgWhite
            border.color: seanceCardMa.containsMouse ? Style.primary : Style.borderLight

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Rectangle {
                    width: 40; height: 40; radius: 12
                    color: itemData.seance.typeSeance === "Cours" ? Style.successBg : Style.warningBg

                    Text {
                        anchors.centerIn: parent
                        text: findClassName(itemData.seance.classeId)
                        font.pixelSize: 11; font.bold: true
                        color: itemData.seance.typeSeance === "Cours" ? Style.successColor : Style.warningColor
                    }
                }

                Column {
                    Layout.fillWidth: true; spacing: 2

                    Text {
                        text: findMatiereName(itemData.seance.matiereId)
                        font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                    }
                    Text {
                        text: formatTime(itemData.seance.dateHeureDebut, itemData.seance.dureeMinutes) + " - " + findProfName(itemData.seance.profId)
                        font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary
                    }
                }

                Row {
                    spacing: 4
                    IconButton {
                        iconName: "delete"; iconSize: 14
                        hoverColor: Style.errorColor
                        onClicked: attendanceController.deleteSeance(itemData.seance.id)
                    }
                }
            }

            MouseArea {
                id: seanceCardMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    selectedSeanceId = itemData.seance.id
                    selectedSessionSubject = findMatiereName(itemData.seance.matiereId)
                    selectedSessionClass = findClassName(itemData.seance.classeId)
                    selectedSessionProf = findProfName(itemData.seance.profId)
                    selectedSessionTime = formatTime(itemData.seance.dateHeureDebut, itemData.seance.dureeMinutes)
                    attendanceController.loadParticipations(itemData.seance.id)
                    showCallModal = true
                }
            }
        }
    }

    // ─── Call Modal ───
    ModalOverlay {
        show: showCallModal
        modalWidth: Math.min(parent.width - 64, 900)
        onClose: showCallModal = false

        // Modal Header
        Rectangle {
            width: parent.width; height: 80
            color: "#FAFBFC"; radius: 32

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 40; color: "#FAFBFC"
            }

            Separator { anchors.bottom: parent.bottom; width: parent.width }

            RowLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 14

                Column {
                    Layout.fillWidth: true; spacing: 4

                    RowLayout {
                        spacing: 10
                        Text {
                            text: selectedSessionSubject
                            font.pixelSize: 20; font.weight: Font.Black; color: Style.textPrimary
                        }
                        Badge { text: "Classe " + selectedSessionClass; variant: "info" }
                    }

                    Text {
                        text: selectedSessionProf + " - " + selectedSessionTime
                        font.pixelSize: 10; font.weight: Font.Bold
                        color: Style.textTertiary; font.letterSpacing: 1
                    }
                }

                OutlineButton {
                    text: "Ajouter Invité"; iconName: "plus"
                    onClicked: showGuestModal = true
                }

                IconButton {
                    iconName: "close"; iconSize: 18
                    onClicked: showCallModal = false
                }
            }
        }

        // Student Cards Grid
        Item {
            width: parent.width
            implicitHeight: studentGrid.implicitHeight + 48

            Text {
                visible: attendanceController.participations.length === 0
                anchors.centerIn: parent
                text: attendanceController.loading ? "Chargement des participations..." : "Aucune participation enregistrée pour cette séance"
                font.pixelSize: 13; font.bold: true; color: Style.textTertiary
            }

            GridLayout {
                id: studentGrid
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 24
                columns: 4; columnSpacing: 16; rowSpacing: 16

                Repeater {
                    model: attendanceController.participations

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: studentCardCol.implicitHeight + 32
                        radius: 24; color: Style.bgWhite; border.color: Style.borderLight

                        property string currentStatus: {
                            if (modelData.statut === "Présent") return "present"
                            if (modelData.statut === "Retard") return "late"
                            return "absent"
                        }

                        Column {
                            id: studentCardCol
                            anchors.fill: parent; anchors.margins: 16; spacing: 12

                            Rectangle {
                                width: 56; height: 56; radius: 20
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Style.bgSecondary; border.color: "#FFFFFF"; border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: findStudentName(modelData.eleveId).charAt(0)
                                    font.pixelSize: 18; font.bold: true; color: Style.primary
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: findStudentName(modelData.eleveId)
                                font.pixelSize: 11; font.bold: true; color: Style.textPrimary
                                elide: Text.ElideRight; width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Badge {
                                visible: modelData.estInvite === true
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Invité"; variant: "info"
                            }

                            // Status Buttons
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 6

                                // Present
                                Rectangle {
                                    width: 32; height: 32; radius: 10
                                    color: currentStatus === "present" ? Style.successColor : Style.bgPage
                                    border.color: currentStatus === "present" ? Style.successColor : Style.borderLight
                                    Text {
                                        anchors.centerIn: parent; text: "P"
                                        font.pixelSize: 12; font.bold: true
                                        color: currentStatus === "present" ? "#FFFFFF" : Style.textTertiary
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            attendanceController.updateParticipation(modelData.id, {
                                                seanceId: modelData.seanceId, eleveId: modelData.eleveId,
                                                statut: "Présent", note: modelData.note !== undefined ? modelData.note : -1,
                                                estInvite: modelData.estInvite
                                            })
                                            attendanceController.loadParticipations(selectedSeanceId)
                                        }
                                    }
                                }

                                // Late
                                Rectangle {
                                    width: 32; height: 32; radius: 10
                                    color: currentStatus === "late" ? Style.warningColor : Style.bgPage
                                    border.color: currentStatus === "late" ? Style.warningColor : Style.borderLight
                                    Text {
                                        anchors.centerIn: parent; text: "R"
                                        font.pixelSize: 12; font.bold: true
                                        color: currentStatus === "late" ? "#FFFFFF" : Style.textTertiary
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            attendanceController.updateParticipation(modelData.id, {
                                                seanceId: modelData.seanceId, eleveId: modelData.eleveId,
                                                statut: "Retard", note: modelData.note !== undefined ? modelData.note : -1,
                                                estInvite: modelData.estInvite
                                            })
                                            attendanceController.loadParticipations(selectedSeanceId)
                                        }
                                    }
                                }

                                // Absent
                                Rectangle {
                                    width: 32; height: 32; radius: 10
                                    color: currentStatus === "absent" ? Style.errorColor : Style.bgPage
                                    border.color: currentStatus === "absent" ? Style.errorColor : Style.borderLight
                                    Text {
                                        anchors.centerIn: parent; text: "A"
                                        font.pixelSize: 12; font.bold: true
                                        color: currentStatus === "absent" ? "#FFFFFF" : Style.textTertiary
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            attendanceController.updateParticipation(modelData.id, {
                                                seanceId: modelData.seanceId, eleveId: modelData.eleveId,
                                                statut: "Absent", note: modelData.note !== undefined ? modelData.note : -1,
                                                estInvite: modelData.estInvite
                                            })
                                            attendanceController.loadParticipations(selectedSeanceId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Modal Footer
        Rectangle {
            width: parent.width; height: 80; color: "#FAFBFC"

            Separator { anchors.top: parent.top; width: parent.width }

            RowLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 16

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 48; radius: 16
                    color: Style.bgWhite; border.color: Style.borderLight
                    Text {
                        anchors.centerIn: parent; text: "FERMER"
                        font.pixelSize: 11; font.weight: Font.Black; color: Style.textTertiary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: showCallModal = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 2
                    height: 48; radius: 16; color: Style.primary
                    Text {
                        anchors.centerIn: parent; text: "ENREGISTRER L'APPEL"
                        font.pixelSize: 11; font.weight: Font.Black
                        color: "#FFFFFF"; font.letterSpacing: 1
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
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
            width: parent.width; spacing: 0; padding: 32

            Text {
                text: "Ajouter un Invité"
                font.pixelSize: 22; font.weight: Font.Black
                color: Style.textPrimary; bottomPadding: 24
            }

            FormField {
                id: guestNameField
                width: parent.width - 64
                label: "NOM DE L'ÉLÈVE INVITÉ"
                placeholder: "Chercher ou saisir un nom..."
            }

            Item { width: 1; height: 24 }

            ModalButtons {
                width: parent.width - 64
                confirmText: "AJOUTER"
                confirmColor: Style.successColor
                onCancel: showGuestModal = false
                onConfirm: {
                    attendanceController.recordParticipation({
                        seanceId: selectedSeanceId,
                        eleveId: 0,
                        statut: "Présent",
                        note: -1,
                        estInvite: true
                    })
                    attendanceController.loadParticipations(selectedSeanceId)
                    showGuestModal = false
                }
            }
        }
    }

    // ─── Create Seance Modal ───
    ModalOverlay {
        show: showCreateSeanceModal
        modalWidth: 480
        onClose: showCreateSeanceModal = false

        Column {
            width: parent.width; spacing: 0; padding: 32

            Text {
                text: "Nouvelle Séance"
                font.pixelSize: 22; font.weight: Font.Black
                color: Style.textPrimary; bottomPadding: 24
            }

            Column {
                width: parent.width - 64; spacing: 18

                Column {
                    width: parent.width; spacing: 6
                    SectionLabel { text: "CLASSE" }
                    ComboBox {
                        id: newSeanceClasse; width: parent.width
                        model: schoolingController.classes
                        textRole: "nom"; valueRole: "id"
                        background: Rectangle {
                            implicitHeight: 44; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 6
                    SectionLabel { text: "MATIÈRE" }
                    ComboBox {
                        id: newSeanceMatiere; width: parent.width
                        model: schoolingController.matieres
                        textRole: "nom"; valueRole: "id"
                        background: Rectangle {
                            implicitHeight: 44; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 6
                    SectionLabel { text: "PROFESSEUR" }
                    ComboBox {
                        id: newSeanceProf; width: parent.width
                        model: {
                            var profs = staffController.professeurs
                            var items = []
                            for (var i = 0; i < profs.length; i++)
                                items.push({ displayName: profs[i].prenom + " " + profs[i].nom, id: profs[i].id })
                            return items
                        }
                        textRole: "displayName"; valueRole: "id"
                        background: Rectangle {
                            implicitHeight: 44; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 6
                    SectionLabel { text: "SALLE" }
                    ComboBox {
                        id: newSeanceSalle; width: parent.width
                        model: schoolingController.salles
                        textRole: "nom"; valueRole: "id"
                        background: Rectangle {
                            implicitHeight: 44; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                        }
                    }
                }

                FormField {
                    id: newSeanceDateTime; width: parent.width
                    label: "DATE ET HEURE (ISO)"
                    placeholder: "2026-02-16T08:00:00"
                }

                FormField {
                    id: newSeanceDuration; width: parent.width
                    label: "DURÉE (MINUTES)"
                    placeholder: "60"
                }

                Column {
                    width: parent.width; spacing: 6
                    SectionLabel { text: "TYPE" }
                    ComboBox {
                        id: newSeanceType; width: parent.width
                        model: ["Cours", "Examen", "Événement"]
                        background: Rectangle {
                            implicitHeight: 44; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                        }
                    }
                }
            }

            Item { width: 1; height: 24 }

            ModalButtons {
                width: parent.width - 64
                confirmText: "CRÉER"
                onCancel: showCreateSeanceModal = false
                onConfirm: {
                    attendanceController.createSeance({
                        classeId: newSeanceClasse.currentValue,
                        matiereId: newSeanceMatiere.currentValue,
                        profId: newSeanceProf.currentValue,
                        salleId: newSeanceSalle.currentValue,
                        dateHeureDebut: newSeanceDateTime.text,
                        dureeMinutes: parseInt(newSeanceDuration.text) || 60,
                        typeSeance: newSeanceType.currentText
                    })
                    showCreateSeanceModal = false
                }
            }
        }
    }

    // ─── Incident Modal ───
    ModalOverlay {
        show: showIncidentModal
        modalWidth: 420
        onClose: showIncidentModal = false

        Column {
            width: parent.width; spacing: 0; padding: 32

            Text {
                text: "Signaler un Incident"
                font.pixelSize: 22; font.weight: Font.Black
                color: Style.textPrimary; bottomPadding: 24
            }

            Column {
                width: parent.width - 64; spacing: 18

                Column {
                    width: parent.width; spacing: 6
                    SectionLabel { text: "NATURE DE L'INCIDENT" }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            Text {
                                Layout.fillWidth: true; text: "Retard"
                                font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                            }
                            Text { text: "▾"; font.pixelSize: 12; color: Style.textTertiary }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
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

            Item { width: 1; height: 24 }

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
