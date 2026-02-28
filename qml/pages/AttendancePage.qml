import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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

    // ─── Call Modal ───
    ModalOverlay {
        show: showCallModal
        modalWidth: Math.min(parent.width - 64, 900)
        modalColor: "#FAFBFC"
        onClose: showCallModal = false

        // Header
        Item {
            width: parent.width; height: 80
            Separator  { anchors.bottom: parent.bottom; width: parent.width }

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

                OutlineButton { text: "Ajouter Invité"; iconName: "plus"; onClicked: showGuestModal = true }
                IconButton    { iconName: "close"; iconSize: 18; onClicked: showCallModal = false }
            }
        }

        // Students grid (all students in the class)
        Rectangle {
            width: parent.width
            implicitHeight: studentGrid.implicitHeight + 48
            color: Style.bgWhite

            Text {
                visible: attendanceController.loading
                anchors.centerIn: parent
                text: "Chargement..."
                font.pixelSize: 13; font.bold: true; color: Style.textTertiary
            }

            GridLayout {
                id: studentGrid
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: 24
                columns: 4; columnSpacing: 16; rowSpacing: 16

                Repeater {
                    model: attendancePage.callModalStudents

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: cardCol.implicitHeight + 32
                        radius: 24
                        color: Style.bgWhite
                        border.color: isGuest ? "#BAE6FD" : Style.borderLight

                        // Staged statut: updated locally; defaults to "Présent" until explicitly changed
                        property string statut: {
                            var sid = modelData.id
                            return attendancePage.stagedStatuts.hasOwnProperty(sid)
                                   ? attendancePage.stagedStatuts[sid] : "Présent"
                        }

                        // Guest detection: reactive to participations changes
                        property bool isGuest: {
                            var parts = attendanceController.participations
                            for (var i = 0; i < parts.length; i++)
                                if (parts[i].eleveId === modelData.id && parts[i].estInvite) return true
                            return false
                        }
                        property int guestParticipationId: {
                            var parts = attendanceController.participations
                            for (var i = 0; i < parts.length; i++)
                                if (parts[i].eleveId === modelData.id && parts[i].estInvite) return parts[i].id
                            return -1
                        }

                        // Remove button — top-right corner, guests only
                        Rectangle {
                            visible: isGuest
                            anchors.top: parent.top; anchors.right: parent.right
                            anchors.topMargin: 8; anchors.rightMargin: 8
                            width: 24; height: 24; radius: 8
                            color: removeMa.containsMouse ? Style.errorColor : "#FEE2E2"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 10; font.bold: true
                                color: removeMa.containsMouse ? "#FFFFFF" : Style.errorColor
                            }
                            MouseArea {
                                id: removeMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (guestParticipationId !== -1) {
                                        attendanceController.deleteParticipation(guestParticipationId)
                                        attendanceController.loadParticipations(attendancePage.selectedSeanceId)
                                    }
                                }
                            }
                        }

                        Column {
                            id: cardCol
                            anchors.fill: parent; anchors.margins: 16; spacing: 12

                            Rectangle {
                                width: 56; height: 56; radius: 20
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: isGuest ? "#E0F2FE" : Style.bgSecondary
                                border.color: "#FFFFFF"; border.width: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.prenom.charAt(0)
                                    font.pixelSize: 18; font.bold: true
                                    color: isGuest ? "#0284C7" : Style.primary
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.prenom + " " + modelData.nom
                                font.pixelSize: 11; font.bold: true; color: Style.textPrimary
                                elide: Text.ElideRight; width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // "INVITÉ" badge — only for guests
                            Rectangle {
                                visible: isGuest
                                anchors.horizontalCenter: parent.horizontalCenter
                                implicitWidth: guestLbl.implicitWidth + 12
                                height: 18; radius: 6
                                color: "#E0F2FE"
                                Text {
                                    id: guestLbl
                                    anchors.centerIn: parent
                                    text: "INVITÉ"
                                    font.pixelSize: 8; font.weight: Font.Black
                                    color: "#0284C7"; font.letterSpacing: 0.5
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 8

                                Rectangle {
                                    width: 40; height: 32; radius: 10
                                    color: statut === "Présent" ? Style.successColor : Style.bgPage
                                    border.color: statut === "Présent" ? Style.successColor : Style.borderLight
                                    Text { anchors.centerIn: parent; text: "P"; font.pixelSize: 12; font.bold: true; color: statut === "Présent" ? "#FFFFFF" : Style.textTertiary }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: attendancePage.setStagedStatut(modelData.id, "Présent") }
                                }

                                Rectangle {
                                    width: 40; height: 32; radius: 10
                                    color: statut === "Absent" ? Style.errorColor : Style.bgPage
                                    border.color: statut === "Absent" ? Style.errorColor : Style.borderLight
                                    Text { anchors.centerIn: parent; text: "A"; font.pixelSize: 12; font.bold: true; color: statut === "Absent" ? "#FFFFFF" : Style.textTertiary }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: attendancePage.setStagedStatut(modelData.id, "Absent") }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Footer
        Item {
            width: parent.width; height: 80
            Separator { anchors.top: parent.top; width: parent.width }

            RowLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 16

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 48; radius: 16; color: Style.bgWhite; border.color: Style.borderLight
                    Text { anchors.centerIn: parent; text: "FERMER"; font.pixelSize: 11; font.weight: Font.Black; color: Style.textTertiary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: showCallModal = false }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 48; radius: 16; color: Style.primary
                    Text { anchors.centerIn: parent; text: "CONFIRMER L'APPEL"; font.pixelSize: 11; font.weight: Font.Black; color: "#FFFFFF"; font.letterSpacing: 1 }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var parts = attendanceController.participations
                            var ep = {}
                            for (var i = 0; i < parts.length; i++) ep[parts[i].eleveId] = parts[i]
                            var students = attendancePage.classStudents
                            for (var j = 0; j < students.length; j++) {
                                var sid = students[j].id
                                var s = attendancePage.stagedStatuts.hasOwnProperty(sid) ? attendancePage.stagedStatuts[sid] : "Présent"
                                if (ep[sid] !== undefined)
                                    attendanceController.updateParticipation(ep[sid].id, { seanceId: selectedSeanceId, eleveId: sid, statut: s, note: ep[sid].note !== undefined ? ep[sid].note : -1, estInvite: false })
                                else
                                    attendanceController.recordParticipation({ seanceId: selectedSeanceId, eleveId: sid, statut: s, note: -1, estInvite: false })
                            }
                            var v = Object.assign({}, attendancePage.validatedSeances)
                            v[selectedSeanceId] = true; attendancePage.validatedSeances = v
                            attendanceController.setPresenceValide(selectedSeanceId, true)
                            showCallModal = false
                        }
                    }
                }
            }
        }
    }

    // ─── Guest Modal ───
    ModalOverlay {
        show: showGuestModal
        modalWidth: 440
        modalColor: "#FAFBFC"
        onClose: { showGuestModal = false; guestSearch.text = "" }

        // Header
        Item {
            width: parent.width; height: 72
            Separator  { anchors.bottom: parent.bottom; width: parent.width }

            RowLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 12

                Column {
                    Layout.fillWidth: true; spacing: 2
                    Text { text: "Ajouter un Invité"; font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: "Même niveau · autre classe"; font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
                }

                IconButton { iconName: "close"; onClicked: { showGuestModal = false; guestSearch.text = "" } }
            }
        }

        // Body: search + list
        Item {
            width: parent.width
            implicitHeight: guestBodyCol.implicitHeight + 40

            Column {
                id: guestBodyCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                spacing: 12

                // Search field
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage
                    border.color: guestSearch.activeFocus ? Style.primary : Style.borderLight

                    HoverHandler { cursorShape: Qt.IBeamCursor }

                    TextInput {
                        id: guestSearch
                        anchors.fill: parent; anchors.margins: 12
                        font.pixelSize: 13; color: Style.textPrimary
                        selectByMouse: true

                        Text {
                            visible: !parent.text
                            text: "Rechercher par nom..."
                            font: parent.font; color: Style.textTertiary
                        }
                    }
                }

                // Student list
                ListView {
                    id: guestList
                    width: parent.width
                    height: Math.min(contentHeight, 280)
                    clip: true
                    spacing: 4
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    model: {
                        var candidates = attendancePage.guestCandidates
                        var q = guestSearch.text.toLowerCase().trim()
                        if (!q) return candidates
                        var r = []
                        for (var i = 0; i < candidates.length; i++) {
                            var n = (candidates[i].prenom + " " + candidates[i].nom).toLowerCase()
                            if (n.indexOf(q) !== -1) r.push(candidates[i])
                        }
                        return r
                    }

                    delegate: Rectangle {
                        width: guestList.width; height: 56; radius: 12
                        color: guestItemMa.containsMouse ? Style.bgSecondary : Style.bgPage
                        border.color: Style.borderLight

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12

                            Rectangle {
                                width: 36; height: 36; radius: 12; color: Style.primaryBg
                                Text { anchors.centerIn: parent; text: modelData.prenom.charAt(0); font.pixelSize: 14; font.bold: true; color: Style.primary }
                            }

                            Column {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: modelData.prenom + " " + modelData.nom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                Text { text: attendancePage.findClassName(modelData.classeId); font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
                            }

                            Rectangle {
                                width: 60; height: 30; radius: 8; color: Style.primary
                                Text { anchors.centerIn: parent; text: "INVITER"; font.pixelSize: 9; font.weight: Font.Black; color: "#FFFFFF" }
                            }
                        }

                        MouseArea {
                            id: guestItemMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                attendanceController.recordParticipation({
                                    seanceId: attendancePage.selectedSeanceId,
                                    eleveId: modelData.id, statut: "Présent", note: -1, estInvite: true
                                })
                                attendanceController.loadParticipations(attendancePage.selectedSeanceId)
                                showGuestModal = false
                                guestSearch.text = ""
                            }
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: guestList.count === 0
                        text: guestSearch.text ? "Aucun résultat pour \"" + guestSearch.text + "\"" : "Aucun élève disponible dans le même niveau"
                        font.pixelSize: 12; font.italic: true; color: Style.textTertiary
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 40
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

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
