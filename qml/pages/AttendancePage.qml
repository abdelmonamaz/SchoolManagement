import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import UI.Components

Item {
    id: attendancePage
    implicitHeight: mainLayout.implicitHeight

    property bool showCallModal:  false
    property bool showGuestModal: false

    property int    selectedSeanceId:       -1
    property string selectedSessionSubject: ""
    property string selectedSessionClass:   ""
    property string selectedSessionProf:    ""
    property string selectedSessionTime:    ""
    property string selectedSessionDate:    ""

    property bool showFutureConfirmModal: false

    property int selectedWeek:     1
    property int selectedWeekYear: new Date().getFullYear()
    property int selectedClasseId: 0
    property var validatedSeances:  ({})   // seanceId → true, marks confirmed seances this session
    property var stagedStatuts:     ({})   // studentId → "Présent"/"Absent", local changes before confirm
    property bool stagedInitialized: false

    // Shared column widths for header + data rows
    readonly property int colClasse: 120
    readonly property int colType:   100
    readonly property int colAction: 150

    readonly property var classStudents: {
        var result = [], all = studentController.students
        for (var i = 0; i < all.length; i++)
            if (all[i].classeId === selectedClasseId) result.push(all[i])
        return result
    }

    // Call modal model: class students + any already-recorded guests (estInvite=true)
    readonly property var callModalStudents: {
        var regularIds = {}, result = []
        var students = classStudents
        for (var i = 0; i < students.length; i++) {
            regularIds[students[i].id] = true
            result.push(students[i])
        }
        var parts = attendanceController.participations
        var all = studentController.students
        for (var j = 0; j < parts.length; j++) {
            if (parts[j].estInvite && !regularIds[parts[j].eleveId]) {
                for (var k = 0; k < all.length; k++) {
                    if (all[k].id === parts[j].eleveId) { result.push(all[k]); break }
                }
            }
        }
        return result
    }

    // Students eligible as guests: same niveau, different class
    readonly property var guestCandidates: {
        if (selectedClasseId <= 0) return []
        var classes = schoolingController.allClasses
        var currentNiveauId = -1
        for (var i = 0; i < classes.length; i++) {
            if (classes[i].id === selectedClasseId) { currentNiveauId = classes[i].niveauId; break }
        }
        if (currentNiveauId === -1) return []
        var sameNiveauClassIds = []
        for (var j = 0; j < classes.length; j++) {
            if (classes[j].niveauId === currentNiveauId && classes[j].id !== selectedClasseId)
                sameNiveauClassIds.push(classes[j].id)
        }
        var all = studentController.students, result = []
        for (var k = 0; k < all.length; k++) {
            if (sameNiveauClassIds.indexOf(all[k].classeId) !== -1) result.push(all[k])
        }
        return result
    }

    function setStagedStatut(sid, s) {
        var u = Object.assign({}, stagedStatuts); u[sid] = s; stagedStatuts = u
    }
    function initStagedFromDB() {
        var s = {}, p = attendanceController.participations
        for (var i = 0; i < p.length; i++) s[p[i].eleveId] = p[i].statut
        stagedStatuts = s; stagedInitialized = true
    }

    // ─── ISO week → date range ───
    function weekDateRange(week, year) {
        var onejan   = new Date(year, 0, 1)
        var isoDay   = onejan.getDay() === 0 ? 7 : onejan.getDay()
        var mondayW1 = new Date(year, 0, 1 + (1 - isoDay))
        var start    = new Date(mondayW1)
        start.setDate(mondayW1.getDate() + (week - 1) * 7)
        var end = new Date(start)
        end.setDate(start.getDate() + 6)
        return { start: start, end: end }
    }

    function pad2(n) { return n < 10 ? "0" + n : "" + n }

    function weekRangeLabel(week, year) {
        var months = ["Jan","Fév","Mar","Avr","Mai","Juin","Juil","Août","Sep","Oct","Nov","Déc"]
        var r = weekDateRange(week, year)
        var s = r.start, e = r.end
        var sStr = s.getDate() + " " + months[s.getMonth()]
        var eStr = e.getDate() + " " + months[e.getMonth()] + " " + e.getFullYear()
        return sStr + " — " + eStr
    }

    function navigateWeek(delta) {
        var maxW    = weekPickerPopup.maxWeeksInYear(selectedWeekYear)
        var newWeek = selectedWeek + delta
        var newYear = selectedWeekYear
        if (newWeek < 1) {
            newYear -= 1
            newWeek  = weekPickerPopup.maxWeeksInYear(newYear)
        } else if (newWeek > maxW) {
            newYear += 1
            newWeek  = 1
        }
        selectedWeek     = newWeek
        selectedWeekYear = newYear
        loadSeances()
    }

    function loadSeances() {
        var r    = weekDateRange(selectedWeek, selectedWeekYear)
        var from = r.start.getFullYear() + "-" + pad2(r.start.getMonth() + 1) + "-" + pad2(r.start.getDate()) + "T00:00:00"
        var to   = r.end.getFullYear()   + "-" + pad2(r.end.getMonth()   + 1) + "-" + pad2(r.end.getDate())   + "T23:59:59"
        attendanceController.loadSeancesByDateRange(from, to)
    }

    function dayName(isoDate) {
        return ["DIM","LUN","MAR","MER","JEU","VEN","SAM"][new Date(isoDate).getDay()]
    }
    function formatTime(isoDate, durationMin) {
        var d = new Date(isoDate), e = new Date(d.getTime() + durationMin * 60000)
        return pad2(d.getHours()) + ":" + pad2(d.getMinutes()) + " - " + pad2(e.getHours()) + ":" + pad2(e.getMinutes())
    }
    function formatDateShort(isoDate) {
        var d = new Date(isoDate)
        return pad2(d.getDate()) + "/" + pad2(d.getMonth() + 1)
    }
    function findMatiereName(id) {
        var m = schoolingController.allMatieres; for (var i = 0; i < m.length; i++) if (m[i].id === id) return m[i].nom; return "Matière #" + id
    }
    function findClassName(id) {
        var m = schoolingController.allClasses; for (var i = 0; i < m.length; i++) if (m[i].id === id) return m[i].nom; return "Classe #" + id
    }
    function findProfName(id) {
        var m = staffController.personnel; for (var i = 0; i < m.length; i++) if (m[i].id === id) return m[i].prenom + " " + m[i].nom; return "Prof #" + id
    }
    function findStudentName(id) {
        var m = studentController.students; for (var i = 0; i < m.length; i++) if (m[i].id === id) return m[i].prenom + " " + m[i].nom; return "Élève #" + id
    }

    Component.onCompleted: {
        schoolingController.loadNiveaux()
        schoolingController.loadSalles()
        schoolingController.loadAllClasses()
        schoolingController.loadAllMatieres()
        staffController.loadAllPersonnel()
        studentController.loadStudents()
        selectedWeek     = weekPickerPopup.currentWeekNumber()
        selectedWeekYear = new Date().getFullYear()
        loadSeances()
    }

    onVisibleChanged: {
        if (visible) loadSeances()
    }

    Connections {
        target: attendanceController
        function onOperationSucceeded(msg) { console.log("AttendancePage:", msg); loadSeances() }
        function onOperationFailed(err)    { console.warn("AttendancePage error:", err) }
        function onParticipationsChanged() { if (showCallModal && !stagedInitialized) initStagedFromDB() }
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
                subtitle: "Pilotage hebdomadaire de l'appel et suivi des séances."
            }

            // Navigation semaine : ◀ [Sem. X · Année] ▶ + date range
            Column {
                spacing: 4

            Row {
                spacing: 4

                // ◀ Semaine précédente
                Rectangle {
                    width: 32; height: 36; radius: 10
                    color: attPrevWeekMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "‹"; font.pixelSize: 18; font.bold: true
                        color: Style.textSecondary
                    }
                    MouseArea {
                        id: attPrevWeekMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: attendancePage.navigateWeek(-1)
                    }
                }

                // Semaine courante — clic pour ouvrir le picker
                Rectangle {
                    implicitWidth: attWeekBtnRow.implicitWidth + 20
                    height: 36; radius: 10
                    color: attWeekBtnMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: attWeekBtnRow
                        anchors.centerIn: parent; spacing: 6
                        IconLabel { iconName: "calendar"; iconSize: 14; iconColor: Style.primary }
                        Text {
                            text: "Sem. " + selectedWeek + "  ·  " + selectedWeekYear
                            font.pixelSize: 9; font.weight: Font.Black
                            color: Style.textPrimary; font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: attWeekBtnMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: weekPickerPopup.open()
                    }
                }

                // ▶ Semaine suivante
                Rectangle {
                    width: 32; height: 36; radius: 10
                    color: attNextWeekMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "›"; font.pixelSize: 18; font.bold: true
                        color: Style.textSecondary
                    }
                    MouseArea {
                        id: attNextWeekMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: attendancePage.navigateWeek(1)
                    }
                }
            } // fin Row

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: attendancePage.weekRangeLabel(selectedWeek, selectedWeekYear)
                font.pixelSize: 9; font.weight: Font.Bold
                color: Style.textSecondary
                horizontalAlignment: Text.AlignHCenter
            }

            } // fin Column
        }

        // ─── Seances Table Card ───
        AppCard {
            Layout.fillWidth: true

            Column {
                width: parent.width
                spacing: 0

                // Table header
                Row {
                    width: parent.width; height: 40

                    Item {
                        width: parent.width - attendancePage.colClasse - attendancePage.colType - attendancePage.colAction
                        height: parent.height
                        SectionLabel { anchors.verticalCenter: parent.verticalCenter; text: "DATE / SÉANCE"; font.pixelSize: 10 }
                    }
                    Item {
                        width: attendancePage.colClasse; height: parent.height
                        SectionLabel { anchors.centerIn: parent; text: "CLASSE"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                    }
                    Item {
                        width: attendancePage.colType; height: parent.height
                        SectionLabel { anchors.verticalCenter: parent.verticalCenter; text: "TYPE"; font.pixelSize: 10 }
                    }
                    Item {
                        width: attendancePage.colAction; height: parent.height
                        SectionLabel { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "ACTION"; font.pixelSize: 10; horizontalAlignment: Text.AlignRight }
                    }
                }

                Separator { width: parent.width }

                // Empty state
                Item {
                    width: parent.width; height: 80
                    visible: attendanceController.seances.length === 0
                    Text {
                        anchors.centerIn: parent
                        text: attendanceController.loading ? "Chargement..." : "Aucune séance pour cette semaine"
                        font.pixelSize: 13; font.italic: true; color: Style.textTertiary
                    }
                }

                // Data rows
                Repeater {
                    model: attendanceController.seances

                    delegate: Column {
                        width: parent.width
                        property bool validated: modelData.presenceValide === true || attendancePage.validatedSeances[modelData.id] === true

                        Rectangle {
                            width: parent.width; height: 60
                            color: validated ? "#F0FDF4" : "transparent"

                            Row {
                                anchors.fill: parent

                                // Date + Matière + Horaire + Prof
                                Item {
                                    width: parent.width - attendancePage.colClasse - attendancePage.colType - attendancePage.colAction
                                    height: parent.height
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                        Text {
                                            text: dayName(modelData.dateHeureDebut) + "  " + formatDateShort(modelData.dateHeureDebut) + "  ·  "
                                                + findMatiereName(modelData.matiereId)
                                                + (modelData.titre ? "  —  " + modelData.titre : "")
                                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                            elide: Text.ElideRight
                                            width: parent.parent.width
                                        }
                                        Text {
                                            text: formatTime(modelData.dateHeureDebut, modelData.dureeMinutes) + "  ·  " + findProfName(modelData.profId)
                                            font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary
                                        }
                                    }
                                }

                                // Classe
                                Item {
                                    width: attendancePage.colClasse; height: parent.height
                                    Text {
                                        anchors.centerIn: parent
                                        text: findClassName(modelData.classeId)
                                        font.pixelSize: 12; font.bold: true; color: Style.textSecondary
                                        elide: Text.ElideRight; width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                // Type badge
                                Item {
                                    width: attendancePage.colType; height: parent.height
                                    Badge {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.typeSeance
                                        variant: modelData.typeSeance === "Cours" ? "info" : "warning"
                                    }
                                }

                                // Valider / Modifier Présence button
                                Item {
                                    width: attendancePage.colAction; height: parent.height
                                    Rectangle {
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        implicitWidth: valLbl.implicitWidth + 24
                                        height: 32; radius: 10
                                        color: validated
                                               ? (valMa.containsMouse ? "#059669" : Style.successColor)
                                               : (valMa.containsMouse ? Style.primaryDark : Style.primary)
                                        Text {
                                            id: valLbl; anchors.centerIn: parent
                                            text: validated ? "Modifier Présence" : "Valider Présence"
                                            font.pixelSize: 10; font.weight: Font.Black; color: "#FFFFFF"
                                        }
                                        MouseArea {
                                            id: valMa; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                selectedSeanceId       = modelData.id
                                                selectedClasseId       = modelData.classeId
                                                selectedSessionSubject = findMatiereName(modelData.matiereId)
                                                                      + (modelData.titre ? " — " + modelData.titre : "")
                                                selectedSessionClass   = findClassName(modelData.classeId)
                                                selectedSessionProf    = findProfName(modelData.profId)
                                                selectedSessionTime    = formatTime(modelData.dateHeureDebut, modelData.dureeMinutes)
                                                selectedSessionDate    = modelData.dateHeureDebut
                                                stagedStatuts          = {}
                                                stagedInitialized      = false
                                                attendanceController.loadParticipations(modelData.id)
                                                showCallModal          = true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Separator { width: parent.width }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }

    AttendanceModals { page: attendancePage }

    // ─── Week Picker Popup ───
    WeekPickerPopup {
        id: weekPickerPopup
        onConfirmed: function(week, year) {
            attendancePage.selectedWeek     = week
            attendancePage.selectedWeekYear = year
            attendancePage.loadSeances()
        }
    }
}
