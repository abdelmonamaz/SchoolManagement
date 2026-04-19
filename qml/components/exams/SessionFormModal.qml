import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import UI.Components

ModalOverlay {
    id: root

    required property string modalType
    required property int pageWidth
    signal datePickerRequested

    modalWidth: Math.min(pageWidth - 64, 720)

    property bool isEvent:  modalType === "event"
    property bool isExam:   modalType === "exam"
    property bool isCourse: modalType === "course"

    // ── Form state ──────────────────────────────────────────────────
    property string formTitre:      ""
    property int    formNiveauId:   -1
    property int    formMatiereId:  -1
    property int    formProfId:     -1
    property int    formClasseId:   -1
    property int    formSalleId:    -1
    property string formDate:       ""
    property string formTime:       "08:00"
    property int    formDuree:      120
    property string formRecurrence: "none"
    property string formDescriptif: ""

    // showAllEpreuves is bound through EpreuvePickerSection
    property bool showAllEpreuves: false

    // ── Semester awareness ───────────────────────────────────────────
    // 0 = non déterminé/tous, 1 = S1, 2 = S2
    property int formSemestreNum: 0
    readonly property bool hasSemestres: setupController.activeSemestres.length >= 2

    // ── Helpers ─────────────────────────────────────────────────────
    function selectedMatiere() {
        var list = schoolingController.matieres
        for (var i = 0; i < list.length; i++)
            if (list[i].id === formMatiereId) return list[i]
        return null
    }

    // Retourne le numéro de semestre correspondant à une date ISO (YYYY-MM-DD).
    // Si dateStr vide → utilise la date du jour.
    function detectSemestreFromDate(dateStr) {
        if (!hasSemestres) return 0
        var sems = setupController.activeSemestres
        // Normalisation : DD/MM/YYYY → YYYY-MM-DD
        var iso = dateStr
        if (dateStr && dateStr.indexOf("/") >= 0) {
            var p = dateStr.split("/")
            if (p.length === 3) iso = p[2] + "-" + p[1] + "-" + p[0]
        }
        if (!iso) iso = new Date().toISOString().substring(0, 10)
        for (var i = 0; i < sems.length; i++)
            if (iso >= sems[i].dateDebut && iso <= sems[i].dateFin) return sems[i].numero
        // Hors plage : retourner le premier semestre
        return sems.length > 0 ? sems[0].numero : 1
    }

    // Liste des matières filtrées par semestre (semestreNumero 0 = toute l'année → toujours inclus)
    readonly property var filteredMatieres: {
        var m = schoolingController.matieres
        if (!hasSemestres || formSemestreNum <= 0) return m
        var out = []
        for (var i = 0; i < m.length; i++)
            if (m[i].semestreNumero === 0 || m[i].semestreNumero === formSemestreNum)
                out.push(m[i])
        return out
    }

    // Quand la date change → mettre à jour le semestre automatiquement
    onFormDateChanged: {
        if (hasSemestres)
            formSemestreNum = detectSemestreFromDate(formDate)
    }

    // Quand la liste filtrée change → désélectionner la matière si elle n'y est plus
    onFilteredMatieresChanged: {
        if (formMatiereId >= 0) {
            var found = false
            for (var i = 0; i < filteredMatieres.length; i++)
                if (filteredMatieres[i].id === formMatiereId) { found = true; break }
            if (!found) {
                formMatiereId = -1
                if (modalMatiereCombo) modalMatiereCombo.currentIndex = -1
            }
        }
    }

    Component.onCompleted: {
        if (hasSemestres) formSemestreNum = detectSemestreFromDate("")
    }

    // ── Semester-awareness ───────────────────────────────────────────
    readonly property var   _selMatiere:  selectedMatiere()
    readonly property int   _semestreNum: _selMatiere ? (_selMatiere.semestreNumero || 0) : 0
    readonly property var   _semestre: {
        if (_semestreNum <= 0) return null
        var sems = setupController.activeSemestres
        for (var i = 0; i < sems.length; i++)
            if (sems[i].numero === _semestreNum) return sems[i]
        return null
    }

    // formDate is DD/MM/YYYY — convert to YYYY-MM-DD for comparison
    readonly property string _formDateIso: {
        if (!formDate) return ""
        var p = formDate.split("/")
        if (p.length !== 3) return ""
        return p[2] + "-" + p[1] + "-" + p[0]
    }
    readonly property bool _dateOutOfSemestre: {
        if (!isCourse || _semestreNum <= 0 || !_semestre || !_formDateIso) return false
        return _formDateIso < _semestre.dateDebut || _formDateIso > _semestre.dateFin
    }

    function resetForm() {
        formTitre       = ""; formDescriptif  = ""
        formNiveauId    = -1; formMatiereId   = -1
        formProfId      = -1; formClasseId    = -1
        formSalleId     = -1; formDate        = ""
        formTime        = "08:00"; formDuree  = 120
        formRecurrence  = "none"; showAllEpreuves = false
        formSemestreNum = hasSemestres ? detectSemestreFromDate("") : 0
        if (titreField)           titreField.text = ""
        if (descriptifField)      descriptifField.text = ""
        if (heureFormField)       heureFormField.text = "08:00"
        if (dureeFormField)       dureeFormField.text = "120"
        if (modalNiveauCombo)     modalNiveauCombo.currentIndex     = -1
        if (modalMatiereCombo)    modalMatiereCombo.currentIndex    = -1
        if (modalClasseCombo)     modalClasseCombo.currentIndex     = -1
        if (modalClasseComboExam) modalClasseComboExam.currentIndex = -1
        if (modalProfCombo)       modalProfCombo.reset()
        if (modalSalleCombo)      modalSalleCombo.reset()
        if (submitSection)        submitSection.reset()
    }

    // ─── Header ─────────────────────────────────────────────────────
    Rectangle {
        width: parent.width; height: 90
        color: Style.background; radius: 32
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 45; color: Style.background }
        Separator  { anchors.bottom: parent.bottom; width: parent.width }

        RowLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 14
            Rectangle {
                width: 48; height: 48; radius: 16
                color: root.isExam ? Style.primary : root.isEvent ? Style.warningColor : Style.infoColor
                Text {
                    anchors.centerIn: parent
                    text: root.isExam ? "✓" : root.isEvent ? "✨" : "📚"
                    font.pixelSize: 22
                }
            }
            Column {
                Layout.fillWidth: true; spacing: 2
                Text {
                    text: root.isExam   ? "Programmer un Examen"
                        : root.isEvent  ? "Organiser un Évènement"
                        :                 "Planifier un Cours"
                    font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary
                }
                Text {
                    text: qsTr("CONFIGURATION DE LA SESSION")
                    font.pixelSize: 9; font.weight: Font.Bold
                    color: Style.textTertiary; font.letterSpacing: 1
                }
            }
            IconButton { iconName: "close"; iconSize: 18; onClicked: root.close() }
        }
    }

    // ─── Body (scrollable) ───────────────────────────────────────────
    Flickable {
        id: bodyFlickable
        width: parent.width
        // Limite la hauteur à l'écran disponible moins l'en-tête (90) et les marges (80)
        property real maxBodyHeight: (Overlay.overlay ? Overlay.overlay.height : 800) - 90 - 70
        height: Math.min(bodyGrid.implicitHeight + 60, maxBodyHeight)
        contentWidth: width
        contentHeight: bodyGrid.implicitHeight + 60
        clip: true
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        GridLayout {
            id: bodyGrid
            x: 32; y: 28
            width: bodyFlickable.width - 64
            columns: 2; columnSpacing: 24; rowSpacing: 20

            // ── Titre (Événement) ──────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 6
                visible: root.isEvent
                SectionLabel { text: qsTr("NOM DE L'ÉVÈNEMENT") }
                FormField {
                    id: titreField; width: parent.width
                    placeholder: qsTr("Ex: Journée portes ouvertes...")
                    onTextChanged: root.formTitre = text
                }
            }

            // ── Niveau (Cours & Examen) ────────────────────────────
            Column {
                Layout.fillWidth: true
                // En mode cours, Niveau prend toute la largeur pour laisser place au sélecteur de semestre
                Layout.columnSpan: root.isExam ? 1 : 2
                Layout.preferredWidth: 1; spacing: 6
                visible: !root.isEvent
                SectionLabel { text: qsTr("NIVEAU") }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight
                    ComboBox {
                        id: modalNiveauCombo
                        anchors.fill: parent; anchors.margins: 4
                        model: schoolingController.niveaux
                        textRole: "nom"; valueRole: "id"; currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalNiveauCombo.currentIndex >= 0
                                  ? modalNiveauCombo.currentText : "Sélectionner le niveau..."
                            font.pixelSize: 13; font.weight: Font.Bold; leftPadding: 8
                            color: modalNiveauCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCurrentValueChanged: {
                            if (currentIndex >= 0) {
                                root.formNiveauId = currentValue
                                schoolingController.loadMatieresByNiveau(currentValue)
                                schoolingController.loadClassesByNiveau(currentValue)
                                modalMatiereCombo.currentIndex    = -1
                                modalClasseCombo.currentIndex     = -1
                                modalClasseComboExam.currentIndex = -1
                                root.formMatiereId = -1; root.formClasseId = -1; root.formTitre = ""
                                if (titreField) titreField.text = ""
                            }
                        }
                    }
                }
            }

            // ── Classe (Examen — même ligne que Niveau) ────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                visible: root.isExam
                SectionLabel { text: qsTr("CLASSE") }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage
                    border.color: root.formNiveauId < 0 ? Style.bgTertiary : Style.borderLight
                    opacity: root.formNiveauId < 0 ? 0.6 : 1.0
                    ComboBox {
                        id: modalClasseComboExam
                        anchors.fill: parent; anchors.margins: 4
                        enabled: root.formNiveauId >= 0
                        model: schoolingController.classes
                        textRole: "nom"; valueRole: "id"; currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalClasseComboExam.currentIndex >= 0
                                  ? modalClasseComboExam.currentText
                                  : root.formNiveauId < 0 ? "Choisir un niveau d'abord..." : "Sélectionner..."
                            font.pixelSize: 13; font.weight: Font.Bold; leftPadding: 8
                            color: modalClasseComboExam.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCurrentValueChanged: {
                            if (currentIndex >= 0) {
                                root.formClasseId = currentValue
                                if (root.formMatiereId >= 0)
                                    examsController.loadScheduledExamTitles(root.formMatiereId, currentValue)
                            }
                        }
                    }
                }
            }

            // ── Sélecteur de semestre (Cours & Examen) ─────────────
            // Visible uniquement quand l'année scolaire comporte des semestres.
            // Le semestre est pré-sélectionné via la date ; l'utilisateur peut l'ajuster.
            Column {
                Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 6
                visible: !root.isEvent && root.hasSemestres

                SectionLabel { text: qsTr("SEMESTRE") }

                Row {
                    spacing: 8
                    Repeater {
                        model: [
                            { label: qsTr("Semestre 1"), abbr: "S1", value: 1 },
                            { label: qsTr("Semestre 2"), abbr: "S2", value: 2 }
                        ]
                        Rectangle {
                            id: semBtnForm
                            property var d: modelData
                            readonly property bool active: root.formSemestreNum === d.value
                            width: 120; height: 36; radius: 10
                            color: active ? (d.value === 1 ? Style.primaryBg : Qt.rgba(0.1, 0.5, 0.9, 0.08))
                                          : Style.bgPage
                            border.color: active ? (d.value === 1 ? Style.primary : Style.infoColor)
                                                 : Style.borderLight
                            border.width: active ? 1.5 : 1
                            Behavior on color        { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent; spacing: 6
                                Text {
                                    text: semBtnForm.d.abbr
                                    font.pixelSize: 12; font.weight: Font.Black
                                    color: semBtnForm.active
                                           ? (semBtnForm.d.value === 1 ? Style.primary : Style.infoColor)
                                           : Style.textTertiary
                                }
                                Text {
                                    text: semBtnForm.d.label
                                    font.pixelSize: 11; font.bold: semBtnForm.active
                                    color: semBtnForm.active
                                           ? (semBtnForm.d.value === 1 ? Style.primary : Style.infoColor)
                                           : Style.textTertiary
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.formSemestreNum = semBtnForm.d.value
                            }
                        }
                    }
                }
            }

            // ── Matière (Cours & Examen) ───────────────────────────
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: root.isExam ? 2 : 1
                Layout.preferredWidth: 1; spacing: 6
                visible: !root.isEvent
                SectionLabel { text: qsTr("MATIÈRE") }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage
                    border.color: root.formNiveauId < 0 ? Style.bgTertiary : Style.borderLight
                    opacity: root.formNiveauId < 0 ? 0.6 : 1.0
                    ComboBox {
                        id: modalMatiereCombo
                        anchors.fill: parent; anchors.margins: 4
                        enabled: root.formNiveauId >= 0
                        model: root.filteredMatieres
                        textRole: "nom"; valueRole: "id"; currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalMatiereCombo.currentIndex >= 0
                                  ? modalMatiereCombo.currentText
                                  : root.formNiveauId < 0 ? "Choisir un niveau d'abord..." : "Sélectionner..."
                            font.pixelSize: 13; font.weight: Font.Bold; leftPadding: 8
                            color: modalMatiereCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCurrentValueChanged: {
                            if (currentIndex < 0) return
                            root.formMatiereId = currentValue
                            if (root.isCourse) {
                                var mats = schoolingController.matieres
                                for (var i = 0; i < mats.length; i++) {
                                    if (mats[i].id === currentValue && mats[i].dureeSeanceMinutes > 0) {
                                        dureeFormField.text = String(mats[i].dureeSeanceMinutes); break
                                    }
                                }
                                if (root.formClasseId >= 0)
                                    examsController.loadCourseCountForMatiereClasse(currentValue, root.formClasseId)
                            }
                            if (root.isExam) {
                                schoolingController.loadMatiereExamens(currentValue)
                                if (root.formClasseId >= 0)
                                    examsController.loadScheduledExamTitles(currentValue, root.formClasseId)
                            }
                            root.formTitre = ""
                            if (titreField) titreField.text = ""
                        }
                    }
                }
            }

            // ── Épreuve picker (Examen) ────────────────────────────
            EpreuvePickerSection {
                Layout.fillWidth: true; Layout.columnSpan: 2
                visible: root.isExam
                formMatiereId:  root.formMatiereId
                formClasseId:   root.formClasseId
                formTitre:      root.formTitre
                showAllEpreuves: root.showAllEpreuves
                onTitreSelected:   function(t) { root.formTitre = t }
                onShowAllChanged:  function(v) { root.showAllEpreuves = v }
            }

            // ── Classe (Cours) ────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                visible: root.isCourse
                SectionLabel { text: qsTr("CLASSE") }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage
                    border.color: root.formNiveauId < 0 ? Style.bgTertiary : Style.borderLight
                    opacity: root.formNiveauId < 0 ? 0.6 : 1.0
                    ComboBox {
                        id: modalClasseCombo
                        anchors.fill: parent; anchors.margins: 4
                        enabled: root.formNiveauId >= 0
                        model: schoolingController.classes
                        textRole: "nom"; valueRole: "id"; currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalClasseCombo.currentIndex >= 0
                                  ? modalClasseCombo.currentText
                                  : root.formNiveauId < 0 ? "Choisir un niveau d'abord..." : "Sélectionner..."
                            font.pixelSize: 13; font.weight: Font.Bold; leftPadding: 8
                            color: modalClasseCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCurrentValueChanged: {
                            if (currentIndex >= 0) {
                                root.formClasseId = currentValue
                                if (root.isCourse && root.formMatiereId >= 0)
                                    examsController.loadCourseCountForMatiereClasse(root.formMatiereId, currentValue)
                            }
                        }
                    }
                }
            }

            // ── Professeur ────────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                visible: !root.isEvent
                SectionLabel { text: root.isExam ? "PROFESSEUR (OPTIONNEL)" : "PROFESSEUR" }
                FormComboWithReset {
                    id: modalProfCombo; width: parent.width
                    model:      staffController.enseignants
                    showReset:  root.isExam
                    onValueSelected: function(v) { root.formProfId = v }
                    onValueCleared:  function()  { root.formProfId = -1 }
                }
            }

            // ── Salle ─────────────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: root.isEvent ? "SALLE (OPTIONNEL)" : "SALLE" }
                FormComboWithReset {
                    id: modalSalleCombo; width: parent.width
                    model:      schoolingController.salles
                    showReset:  root.isEvent
                    onValueSelected: function(v) { root.formSalleId = v }
                    onValueCleared:  function()  { root.formSalleId = -1 }
                }
            }

            // ── Descriptif (Événement) ────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 6
                visible: root.isEvent
                SectionLabel { text: qsTr("DESCRIPTIF (OPTIONNEL)") }
                Rectangle {
                    width: parent.width; height: 80; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight
                    Flickable {
                        anchors.fill: parent; anchors.margins: 12
                        contentWidth: width; contentHeight: descriptifField.implicitHeight
                        clip: true; flickableDirection: Flickable.VerticalFlick
                        TextEdit {
                            id: descriptifField; width: parent.width
                            font.pixelSize: 13; font.weight: Font.Bold; color: Style.textPrimary
                            wrapMode: TextEdit.Wrap; selectByMouse: true
                            onTextChanged: root.formDescriptif = text
                            Text { visible: !descriptifField.text; text: qsTr("Description de l'évènement..."); font: descriptifField.font; color: Style.textTertiary }
                        }
                    }
                }
            }

            // ── Date ─────────────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: qsTr("DATE") }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage
                    border.color: dateMa.containsMouse ? Style.primary : Style.borderLight
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                        IconLabel { iconName: "calendar"; iconSize: 14; iconColor: Style.primary }
                        Text {
                            Layout.fillWidth: true
                            text: root.formDate ? root.formDate : "Cliquer pour choisir..."
                            font.pixelSize: 13; font.weight: Font.Bold
                            color: root.formDate ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    MouseArea { id: dateMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.datePickerRequested() }
                }
            }

            // ── Warning date hors semestre ────────────────────────
            Rectangle {
                Layout.fillWidth: true; Layout.columnSpan: 2
                height: 36; radius: 10; color: Style.warningBg
                border.color: Style.warningColor; border.width: 1
                visible: root._dateOutOfSemestre
                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    IconLabel { iconName: "warning"; iconColor: Style.warningColor; iconSize: 13 }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Cette date est hors de la plage du Semestre %1 (%2 → %3)")
                              .arg(root._semestreNum)
                              .arg(root._semestre ? root._semestre.dateDebut : "")
                              .arg(root._semestre ? root._semestre.dateFin   : "")
                        font.pixelSize: 11; font.bold: true; color: Style.warningColor
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // ── Heure ─────────────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: qsTr("HEURE") }
                FormField { id: heureFormField; width: parent.width; text: qsTr("08:00"); onTextChanged: root.formTime = text }
            }

            // ── Durée ─────────────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: qsTr("DURÉE (MINUTES)") }
                FormField {
                    id: dureeFormField; width: parent.width; text: qsTr("120")
                    validator: IntValidator { bottom: 15; top: 480 }
                    onTextChanged: { var v = parseInt(text); if (!isNaN(v)) root.formDuree = v }
                }
            }

            // ── Récurrence (Cours) ────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 8
                visible: root.isCourse

                readonly property string _fullLabel: {
                    if (root._semestreNum === 1) return qsTr("TOUT LE SEMESTRE 1")
                    if (root._semestreNum === 2) return qsTr("TOUT LE SEMESTRE 2")
                    return qsTr("TOUTE L'ANNÉE SCOLAIRE")
                }

                SectionLabel { text: qsTr("RÉCURRENCE (OPTIONNEL)") }
                RowLayout {
                    width: parent.width; spacing: 12
                    Repeater {
                        model: [
                            { key: "remaining", label: qsTr("SEMAINES RESTANTES") },
                            { key: "full",      label: parent.parent._fullLabel }
                        ]
                        Rectangle {
                            Layout.fillWidth: true; height: 44; radius: 12
                            color: recMa.containsMouse ? Style.bgSecondary : Style.bgPage
                            border.color: root.formRecurrence === modelData.key ? Style.primary : Style.borderLight
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                Rectangle {
                                    width: 18; height: 18; radius: 4
                                    color: root.formRecurrence === modelData.key ? Style.primary : "transparent"
                                    border.color: root.formRecurrence === modelData.key ? Style.primary : Style.borderMedium
                                    border.width: 1.5
                                    Text { anchors.centerIn: parent; text: qsTr("✓"); font.pixelSize: 10; font.weight: Font.Bold; color: Style.background; visible: root.formRecurrence === modelData.key }
                                }
                                Text { Layout.fillWidth: true; text: modelData.label; font.pixelSize: 10; font.weight: Font.Black; color: Style.textPrimary }
                            }
                            MouseArea { id: recMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.formRecurrence = root.formRecurrence === modelData.key ? "none" : modelData.key }
                        }
                    }
                }

                // Semester date range when "full" is selected on a semestred matière
                SemesterBoundRow {
                    width: parent.width
                    visible: root.formRecurrence === "full" && root._semestre !== null
                    leftLabel:  root._semestreNum === 1 ? qsTr("DÉBUT DU SEMESTRE 1") : qsTr("DÉBUT DU SEMESTRE 2")
                    leftDate:   root._semestre ? root._semestre.dateDebut : ""
                    rightLabel: root._semestreNum === 1 ? qsTr("FIN DU SEMESTRE 1")   : qsTr("FIN DU SEMESTRE 2")
                    rightDate:  root._semestre ? root._semestre.dateFin   : ""
                }
            }

            // ── Submit section (count badge + warning + confirm + button) ──
            SessionSubmitSection {
                id: submitSection
                Layout.fillWidth: true; Layout.columnSpan: 2
                isCourse: root.isCourse; isExam: root.isExam; isEvent: root.isEvent
                formValid: {
                    if (!root.formDate) return false
                    if (root.isCourse)  return root.formMatiereId >= 0 && root.formProfId >= 0 && root.formClasseId >= 0 && root.formSalleId >= 0
                    if (root.isExam)    return root.formTitre.length > 0 && root.formMatiereId >= 0 && root.formClasseId >= 0 && root.formSalleId >= 0
                    return root.formTitre.length > 0
                }
                formDate: root.formDate; formTime: root.formTime; formDuree: root.formDuree
                formTitre: root.formTitre; formMatiereId: root.formMatiereId
                formProfId: root.formProfId; formSalleId: root.formSalleId
                formClasseId: root.formClasseId; formRecurrence: root.formRecurrence
                formDescriptif: root.formDescriptif
                semestreStart: (root.formRecurrence === "full" && root._semestre) ? root._semestre.dateDebut : ""
                semestreEnd:   (root.formRecurrence === "full" && root._semestre) ? root._semestre.dateFin   : ""
            }
        }
    }
}
