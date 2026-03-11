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

    // ── Helpers ─────────────────────────────────────────────────────
    function selectedMatiere() {
        var list = schoolingController.matieres
        for (var i = 0; i < list.length; i++)
            if (list[i].id === formMatiereId) return list[i]
        return null
    }

    function resetForm() {
        formTitre       = ""; formDescriptif  = ""
        formNiveauId    = -1; formMatiereId   = -1
        formProfId      = -1; formClasseId    = -1
        formSalleId     = -1; formDate        = ""
        formTime        = "08:00"; formDuree  = 120
        formRecurrence  = "none"; showAllEpreuves = false
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
        color: "#FAFBFC"; radius: 32
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 45; color: "#FAFBFC" }
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
                    text: "CONFIGURATION DE LA SESSION"
                    font.pixelSize: 9; font.weight: Font.Bold
                    color: Style.textTertiary; font.letterSpacing: 1
                }
            }
            IconButton { iconName: "close"; iconSize: 18; onClicked: root.close() }
        }
    }

    // ─── Body ────────────────────────────────────────────────────────
    Item {
        width: parent.width
        implicitHeight: bodyGrid.implicitHeight + 60

        GridLayout {
            id: bodyGrid
            anchors.fill: parent
            anchors.leftMargin: 32; anchors.rightMargin: 32
            anchors.topMargin: 28; anchors.bottomMargin: 32
            columns: 2; columnSpacing: 24; rowSpacing: 20

            // ── Titre (Événement) ──────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 6
                visible: root.isEvent
                SectionLabel { text: "NOM DE L'ÉVÈNEMENT" }
                FormField {
                    id: titreField; width: parent.width
                    placeholder: "Ex: Journée portes ouvertes..."
                    onTextChanged: root.formTitre = text
                }
            }

            // ── Niveau (Cours & Examen) ────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                visible: !root.isEvent
                SectionLabel { text: "NIVEAU" }
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
                SectionLabel { text: "CLASSE" }
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

            // ── Matière (Cours & Examen) ───────────────────────────
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: root.isExam ? 2 : 1
                Layout.preferredWidth: 1; spacing: 6
                visible: !root.isEvent
                SectionLabel { text: "MATIÈRE" }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage
                    border.color: root.formNiveauId < 0 ? Style.bgTertiary : Style.borderLight
                    opacity: root.formNiveauId < 0 ? 0.6 : 1.0
                    ComboBox {
                        id: modalMatiereCombo
                        anchors.fill: parent; anchors.margins: 4
                        enabled: root.formNiveauId >= 0
                        model: schoolingController.matieres
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
                SectionLabel { text: "CLASSE" }
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
                SectionLabel { text: "DESCRIPTIF (OPTIONNEL)" }
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
                            Text { visible: !descriptifField.text; text: "Description de l'évènement..."; font: descriptifField.font; color: Style.textTertiary }
                        }
                    }
                }
            }

            // ── Date ─────────────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: "DATE" }
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

            // ── Heure ─────────────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: "HEURE" }
                FormField { id: heureFormField; width: parent.width; text: "08:00"; onTextChanged: root.formTime = text }
            }

            // ── Durée ─────────────────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: "DURÉE (MINUTES)" }
                FormField {
                    id: dureeFormField; width: parent.width; text: "120"
                    validator: IntValidator { bottom: 15; top: 480 }
                    onTextChanged: { var v = parseInt(text); if (!isNaN(v)) root.formDuree = v }
                }
            }

            // ── Récurrence (Cours) ────────────────────────────────
            Column {
                Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 8
                visible: root.isCourse
                SectionLabel { text: "RÉCURRENCE (OPTIONNEL)" }
                RowLayout {
                    width: parent.width; spacing: 12
                    Repeater {
                        model: [
                            { key: "remaining", label: "SEMAINES RESTANTES" },
                            { key: "full",      label: "TOUTE L'ANNÉE SCOLAIRE" }
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
                                    Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF"; visible: root.formRecurrence === modelData.key }
                                }
                                Text { Layout.fillWidth: true; text: modelData.label; font.pixelSize: 10; font.weight: Font.Black; color: Style.textPrimary }
                            }
                            MouseArea { id: recMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.formRecurrence = root.formRecurrence === modelData.key ? "none" : modelData.key }
                        }
                    }
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
            }
        }
    }
}
