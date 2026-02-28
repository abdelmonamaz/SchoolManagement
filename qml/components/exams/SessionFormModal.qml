import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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

    // ── Form state ──
    property string formTitre:       ""
    property int    formNiveauId:    -1
    property int    formMatiereId:   -1
    property int    formProfId:      -1
    property int    formClasseId:    -1
    property int    formSalleId:     -1
    property string formDate:        ""
    property string formTime:        "08:00"
    property int    formDuree:       120
    property string formRecurrence:  "none"
    property string formDescriptif:  ""

    // ── UI state ──
    property bool   showConfirmSubmit:    false
    property bool   showOverLimitWarning: false
    property bool   showAllEpreuves:      false   // exam: montrer aussi les épreuves déjà planifiées

    // ── Helpers ──
    // Returns the selected matière object (or null)
    function selectedMatiere() {
        var list = schoolingController.matieres
        for (var i = 0; i < list.length; i++)
            if (list[i].id === formMatiereId) return list[i]
        return null
    }

    // Returns true if épreuve titre is already scheduled
    function isTitreScheduled(titre) {
        var titles = examsController.scheduledExamTitles
        for (var i = 0; i < titles.length; i++)
            if (titles[i] === titre) return true
        return false
    }

    function resetForm() {
        formTitre        = ""
        formDescriptif   = ""
        formNiveauId     = -1
        formMatiereId    = -1
        formProfId       = -1
        formClasseId     = -1
        formSalleId      = -1
        formDate         = ""
        formTime         = "08:00"
        formDuree        = 120
        formRecurrence   = "none"
        showConfirmSubmit    = false
        showOverLimitWarning = false
        showAllEpreuves      = false
        if (titreField)       titreField.text = ""
        if (descriptifField)  descriptifField.text = ""
        if (heureFormField)   heureFormField.text = "08:00"
        if (dureeFormField)   dureeFormField.text = "120"
        if (modalNiveauCombo)    modalNiveauCombo.currentIndex    = -1
        if (modalMatiereCombo)   modalMatiereCombo.currentIndex   = -1
        if (modalClasseCombo)    modalClasseCombo.currentIndex    = -1
        if (modalClasseComboExam) modalClasseComboExam.currentIndex = -1
        if (modalProfCombo)      modalProfCombo.currentIndex      = -1
        if (modalSalleCombo)     modalSalleCombo.currentIndex     = -1
    }

    // ─── Header ───
    Rectangle {
        width: parent.width
        height: 90
        color: "#FAFBFC"
        radius: 32

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 45
            color: "#FAFBFC"
        }

        Separator { anchors.bottom: parent.bottom; width: parent.width }

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
                    text: root.isExam ? "Programmer un Examen" : root.isEvent ? "Organiser un Évènement" : "Planifier un Cours"
                    font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary
                }
                Text {
                    text: "CONFIGURATION DE LA SESSION"
                    font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary; font.letterSpacing: 1
                }
            }

            IconButton { iconName: "close"; iconSize: 18; onClicked: root.close() }
        }
    }

    // ─── Body ───
    Item {
        width: parent.width
        implicitHeight: bodyGrid.implicitHeight + 60

        GridLayout {
            id: bodyGrid
            anchors.fill: parent
            anchors.leftMargin: 32; anchors.rightMargin: 32
            anchors.topMargin: 28; anchors.bottomMargin: 32
            columns: 2
            columnSpacing: 24; rowSpacing: 20

            // ── Titre (Événement uniquement — pour l'examen le titre vient de l'épreuve choisie) ──
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 6
                visible: root.isEvent

                SectionLabel { text: "NOM DE L'ÉVÈNEMENT" }
                FormField {
                    id: titreField
                    width: parent.width
                    placeholder: "Ex: Journée portes ouvertes..."
                    onTextChanged: root.formTitre = text
                }
            }

            // ── Niveau (Cours & Examen) ──
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
                        textRole: "nom"; valueRole: "id"
                        currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalNiveauCombo.currentIndex >= 0 ? modalNiveauCombo.currentText : "Sélectionner le niveau..."
                            font.pixelSize: 13; font.bold: true
                            color: modalNiveauCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter; leftPadding: 8
                        }
                        onCurrentValueChanged: {
                            if (currentIndex >= 0) {
                                root.formNiveauId = currentValue
                                schoolingController.loadMatieresByNiveau(currentValue)
                                schoolingController.loadClassesByNiveau(currentValue)
                                modalMatiereCombo.currentIndex      = -1
                                modalClasseCombo.currentIndex       = -1
                                modalClasseComboExam.currentIndex   = -1
                                root.formMatiereId = -1
                                root.formClasseId  = -1
                                root.formTitre     = ""
                                if (titreField) titreField.text = ""
                            }
                        }
                    }
                }
            }

            // ── Classe (Exam : 2e colonne de la ligne Niveau ; Cours : voir après Matière) ──
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                visible: root.isExam   // For exam: Niveau | Classe on same row

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
                        textRole: "nom"; valueRole: "id"
                        currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalClasseComboExam.currentIndex >= 0 ? modalClasseComboExam.currentText
                                : root.formNiveauId < 0 ? "Choisir un niveau d'abord..." : "Sélectionner..."
                            font.pixelSize: 13; font.bold: true
                            color: modalClasseComboExam.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter; leftPadding: 8
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

            // ── Matière (Cours & Examen) — pleine largeur pour exam, demi pour cours ──
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: root.isExam ? 2 : 1
                Layout.preferredWidth: 1
                spacing: 6
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
                        textRole: "nom"; valueRole: "id"
                        currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalMatiereCombo.currentIndex >= 0 ? modalMatiereCombo.currentText
                                : root.formNiveauId < 0 ? "Choisir un niveau d'abord..." : "Sélectionner..."
                            font.pixelSize: 13; font.bold: true
                            color: modalMatiereCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter; leftPadding: 8
                        }
                        onCurrentValueChanged: {
                            if (currentIndex < 0) return
                            root.formMatiereId = currentValue

                            // Auto-fill duration from matière config (cours only)
                            if (root.isCourse) {
                                var mats = schoolingController.matieres
                                for (var i = 0; i < mats.length; i++) {
                                    if (mats[i].id === currentValue && mats[i].dureeSeanceMinutes > 0) {
                                        dureeFormField.text = String(mats[i].dureeSeanceMinutes)
                                        break
                                    }
                                }
                                if (root.formClasseId >= 0)
                                    examsController.loadCourseCountForMatiereClasse(currentValue, root.formClasseId)
                            }

                            // For exam: load épreuves + already-scheduled titles
                            if (root.isExam) {
                                schoolingController.loadMatiereExamens(currentValue)
                                if (root.formClasseId >= 0)
                                    examsController.loadScheduledExamTitles(currentValue, root.formClasseId)
                            }

                            // Reset dependent fields
                            root.formTitre = ""
                            if (titreField) titreField.text = ""
                        }
                    }
                }
            }

            // ── Épreuve picker (Examen uniquement) ──
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 8
                visible: root.isExam

                // Section header: label always + checkbox when matière+classe sont sélectionnés
                RowLayout {
                    width: parent.width

                    SectionLabel {
                        Layout.fillWidth: true
                        text: "ÉPREUVE À PLANIFIER"
                    }

                    // Checkbox "afficher aussi les déjà planifiées" (visible seulement quand on a les données)
                    RowLayout {
                        spacing: 6
                        visible: root.formMatiereId >= 0 && root.formClasseId >= 0

                        Rectangle {
                            width: 16; height: 16; radius: 4
                            color: root.showAllEpreuves ? Style.primary : "transparent"
                            border.color: root.showAllEpreuves ? Style.primary : Style.borderMedium
                            border.width: 1.5
                            Text {
                                anchors.centerIn: parent; text: "✓"
                                font.pixelSize: 9; font.bold: true; color: "#FFFFFF"
                                visible: root.showAllEpreuves
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.showAllEpreuves = !root.showAllEpreuves
                            }
                        }
                        Text {
                            text: "Inclure les épreuves déjà planifiées"
                            font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary
                        }
                    }
                }

                // Placeholder: matière ou classe pas encore sélectionnée
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight
                    visible: root.formMatiereId < 0 || root.formClasseId < 0

                    Text {
                        anchors.centerIn: parent
                        text: root.formMatiereId < 0 && root.formClasseId < 0
                              ? "Sélectionnez une classe et une matière pour voir les épreuves"
                              : root.formClasseId < 0
                              ? "Sélectionnez une classe pour voir les épreuves"
                              : "Sélectionnez une matière pour voir les épreuves"
                        font.pixelSize: 11; font.italic: true; color: Style.textTertiary
                        width: parent.width - 24
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Contenu épreuves (matière + classe sélectionnées)
                Column {
                    width: parent.width
                    spacing: 8
                    visible: root.formMatiereId >= 0 && root.formClasseId >= 0

                    // No épreuves defined
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight
                        visible: schoolingController.matiereExamens.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: "Aucune épreuve définie pour cette matière"
                            font.pixelSize: 11; font.italic: true; color: Style.textTertiary
                            wrapMode: Text.WordWrap
                            width: parent.width - 24
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // List of épreuves
                    Flow {
                        width: parent.width; spacing: 8
                        visible: schoolingController.matiereExamens.length > 0

                        Repeater {
                            model: schoolingController.matiereExamens

                            delegate: Item {
                                property bool isDone: root.isTitreScheduled(modelData.titre)
                                property bool isSelected: root.formTitre === modelData.titre
                                // Skip already-scheduled unless showAllEpreuves
                                visible: root.showAllEpreuves || !isDone
                                width: visible ? epreuveRow.implicitWidth + 24 : 0
                                height: visible ? 40 : 0

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: isSelected ? Style.primary
                                         : isDone     ? "#F1F5F9"
                                         : epreuveMa.containsMouse ? Style.primaryBg : Style.bgPage
                                    border.color: isSelected ? Style.primary
                                                : isDone     ? Style.borderLight
                                                : epreuveMa.containsMouse ? Style.primary : Style.borderLight
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        id: epreuveRow
                                        anchors.centerIn: parent; spacing: 6

                                        Text {
                                            text: isDone ? "✓ " + modelData.titre : modelData.titre
                                            font.pixelSize: 12; font.bold: true
                                            color: isSelected ? "#FFFFFF"
                                                 : isDone     ? Style.textTertiary
                                                 : epreuveMa.containsMouse ? Style.primary : Style.textPrimary
                                        }
                                    }

                                    MouseArea {
                                        id: epreuveMa
                                        anchors.fill: parent; hoverEnabled: true
                                        cursorShape: isDone && !root.showAllEpreuves ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        onClicked: {
                                            root.formTitre = modelData.titre
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Classe (Cours uniquement — garde sa position d'origine) ──
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
                        textRole: "nom"; valueRole: "id"
                        currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalClasseCombo.currentIndex >= 0 ? modalClasseCombo.currentText
                                : root.formNiveauId < 0 ? "Choisir un niveau d'abord..." : "Sélectionner..."
                            font.pixelSize: 13; font.bold: true
                            color: modalClasseCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter; leftPadding: 8
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

            // ── Professeur (Cours & Examen) ──
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                visible: !root.isEvent

                SectionLabel { text: root.isExam ? "PROFESSEUR (OPTIONNEL)" : "PROFESSEUR" }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight

                    ComboBox {
                        id: modalProfCombo
                        anchors.fill: parent; anchors.margins: 4
                        model: staffController.enseignants
                        textRole: "nom"; valueRole: "id"
                        currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalProfCombo.currentIndex >= 0 ? modalProfCombo.currentText : "Sélectionner..."
                            font.pixelSize: 13; font.bold: true
                            color: modalProfCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter; leftPadding: 8
                        }
                        onCurrentValueChanged: if (currentIndex >= 0) root.formProfId = currentValue

                        popup: Popup {
                            y: modalProfCombo.height - 1
                            width: modalProfCombo.width
                            implicitHeight: Math.min(profPopupCol.implicitHeight + 2, 220)
                            padding: 1

                            contentItem: Flickable {
                                clip: true
                                contentHeight: profPopupCol.implicitHeight
                                flickableDirection: Flickable.VerticalFlick

                                Column {
                                    id: profPopupCol
                                    width: parent.width

                                    Rectangle {
                                        width: parent.width; height: 36
                                        color: profResetMa.containsMouse ? Style.bgSecondary : "transparent"
                                        visible: root.isExam

                                        Text {
                                            anchors.fill: parent; leftPadding: 12
                                            text: "Sélectionner..."
                                            font.pixelSize: 13; font.italic: true; font.bold: true
                                            color: Style.textTertiary
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        MouseArea {
                                            id: profResetMa
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { modalProfCombo.currentIndex = -1; root.formProfId = -1; modalProfCombo.popup.close() }
                                        }
                                    }

                                    Repeater {
                                        model: staffController.enseignants
                                        Rectangle {
                                            width: profPopupCol.width; height: 36
                                            color: profItemMa.containsMouse ? Style.bgSecondary : (modalProfCombo.currentIndex === index ? Style.bgPage : "transparent")

                                            Text {
                                                anchors.fill: parent; leftPadding: 12
                                                text: modelData.nom || ""
                                                font.pixelSize: 13; font.bold: true
                                                color: Style.textPrimary
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            MouseArea {
                                                id: profItemMa
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { modalProfCombo.currentIndex = index; modalProfCombo.popup.close() }
                                            }
                                        }
                                    }
                                }
                            }

                            background: Rectangle { radius: 8; border.color: Style.borderLight; color: "#FFFFFF" }
                        }
                    }
                }
            }

            // ── Salle (tous, optionnel pour événement) ──
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6

                SectionLabel { text: root.isEvent ? "SALLE (OPTIONNEL)" : "SALLE" }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight

                    ComboBox {
                        id: modalSalleCombo
                        anchors.fill: parent; anchors.margins: 4
                        model: schoolingController.salles
                        textRole: "nom"; valueRole: "id"
                        currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: modalSalleCombo.currentIndex >= 0 ? modalSalleCombo.currentText : "Sélectionner..."
                            font.pixelSize: 13; font.bold: true
                            color: modalSalleCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter; leftPadding: 8
                        }
                        onCurrentValueChanged: if (currentIndex >= 0) root.formSalleId = currentValue

                        popup: Popup {
                            y: modalSalleCombo.height - 1
                            width: modalSalleCombo.width
                            implicitHeight: Math.min(sallePopupCol.implicitHeight + 2, 220)
                            padding: 1

                            contentItem: Flickable {
                                clip: true
                                contentHeight: sallePopupCol.implicitHeight
                                flickableDirection: Flickable.VerticalFlick

                                Column {
                                    id: sallePopupCol
                                    width: parent.width

                                    Rectangle {
                                        width: parent.width; height: 36
                                        color: salleResetMa.containsMouse ? Style.bgSecondary : "transparent"
                                        visible: root.isEvent

                                        Text {
                                            anchors.fill: parent; leftPadding: 12
                                            text: "Sélectionner..."
                                            font.pixelSize: 13; font.italic: true; font.bold: true
                                            color: Style.textTertiary
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        MouseArea {
                                            id: salleResetMa
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { modalSalleCombo.currentIndex = -1; root.formSalleId = -1; modalSalleCombo.popup.close() }
                                        }
                                    }

                                    Repeater {
                                        model: schoolingController.salles
                                        Rectangle {
                                            width: sallePopupCol.width; height: 36
                                            color: salleItemMa.containsMouse ? Style.bgSecondary : (modalSalleCombo.currentIndex === index ? Style.bgPage : "transparent")

                                            Text {
                                                anchors.fill: parent; leftPadding: 12
                                                text: modelData.nom || ""
                                                font.pixelSize: 13; font.bold: true
                                                color: Style.textPrimary
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            MouseArea {
                                                id: salleItemMa
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { modalSalleCombo.currentIndex = index; modalSalleCombo.popup.close() }
                                            }
                                        }
                                    }
                                }
                            }

                            background: Rectangle { radius: 8; border.color: Style.borderLight; color: "#FFFFFF" }
                        }
                    }
                }
            }

            // ── Descriptif (Événement uniquement) ──
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 6
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
                            id: descriptifField
                            width: parent.width
                            font.pixelSize: 13; font.bold: true
                            color: Style.textPrimary
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            onTextChanged: root.formDescriptif = text

                            Text {
                                visible: !descriptifField.text
                                text: "Description de l'évènement..."
                                font: descriptifField.font
                                color: Style.textTertiary
                            }
                        }
                    }
                }
            }

            // ── Date ──
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
                            font.pixelSize: 13; font.bold: true
                            color: root.formDate ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: dateMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.datePickerRequested()
                    }
                }
            }

            // ── Heure ──
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: "HEURE" }
                FormField {
                    id: heureFormField
                    width: parent.width
                    text: "08:00"
                    onTextChanged: root.formTime = text
                }
            }

            // ── Durée ──
            Column {
                Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                SectionLabel { text: "DURÉE (MINUTES)" }
                FormField {
                    id: dureeFormField
                    width: parent.width
                    text: "120"
                    validator: IntValidator { bottom: 15; top: 480 }
                    onTextChanged: {
                        var v = parseInt(text)
                        if (!isNaN(v)) root.formDuree = v
                    }
                }
            }

            // ── Récurrence (cours uniquement) ──
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 8
                visible: root.isCourse

                SectionLabel { text: "RÉCURRENCE (OPTIONNEL)" }

                RowLayout {
                    width: parent.width; spacing: 12

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: 12
                        color: remainingMa.containsMouse ? Style.bgSecondary : Style.bgPage
                        border.color: root.formRecurrence === "remaining" ? Style.primary : Style.borderLight
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            Rectangle {
                                width: 18; height: 18; radius: 4
                                color: root.formRecurrence === "remaining" ? Style.primary : "transparent"
                                border.color: root.formRecurrence === "remaining" ? Style.primary : Style.borderMedium
                                border.width: 1.5
                                Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 10; font.bold: true; color: "#FFFFFF"; visible: root.formRecurrence === "remaining" }
                            }
                            Text { Layout.fillWidth: true; text: "SEMAINES RESTANTES"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textPrimary }
                        }

                        MouseArea { id: remainingMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.formRecurrence = root.formRecurrence === "remaining" ? "none" : "remaining" }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: 12
                        color: fullMa.containsMouse ? Style.bgSecondary : Style.bgPage
                        border.color: root.formRecurrence === "full" ? Style.primary : Style.borderLight
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            Rectangle {
                                width: 18; height: 18; radius: 4
                                color: root.formRecurrence === "full" ? Style.primary : "transparent"
                                border.color: root.formRecurrence === "full" ? Style.primary : Style.borderMedium
                                border.width: 1.5
                                Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 10; font.bold: true; color: "#FFFFFF"; visible: root.formRecurrence === "full" }
                            }
                            Text { Layout.fillWidth: true; text: "TOUTE L'ANNÉE SCOLAIRE"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textPrimary }
                        }

                        MouseArea { id: fullMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.formRecurrence = root.formRecurrence === "full" ? "none" : "full" }
                    }
                }
            }

            // ── Compteur séances cours (visible quand matière + classe choisis) ──
            Rectangle {
                id: courseCountBadge
                Layout.fillWidth: true
                Layout.columnSpan: 2
                height: 40; radius: 12
                visible: root.isCourse && root.formMatiereId >= 0 && root.formClasseId >= 0

                readonly property int  courseCount: examsController.courseCountInfo["count"]  !== undefined ? examsController.courseCountInfo["count"]  : 0
                readonly property int  courseLimit: examsController.courseCountInfo["limit"]  !== undefined ? examsController.courseCountInfo["limit"]  : 0
                readonly property bool isAtLimit:   courseLimit > 0 && courseCount >= courseLimit
                readonly property bool isNearLimit: courseLimit > 0 && courseCount >= courseLimit - 2 && courseCount < courseLimit

                color: isAtLimit   ? "#FEE2E2"
                     : isNearLimit ? "#FFF7ED"
                     : "#F0FDF4"
                border.color: isAtLimit   ? "#FECACA"
                            : isNearLimit ? "#FED7AA"
                            : "#BBF7D0"

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8
                    Text {
                        text: courseCountBadge.isAtLimit ? "⚠" : courseCountBadge.isNearLimit ? "⚠" : "✓"
                        font.pixelSize: 14
                        color: courseCountBadge.isAtLimit ? "#DC2626" : courseCountBadge.isNearLimit ? "#D97706" : "#16A34A"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (courseCountBadge.courseLimit <= 0)
                                return courseCountBadge.courseCount + " séance(s) planifiée(s) cette année scolaire"
                            return courseCountBadge.courseCount + " / " + courseCountBadge.courseLimit + " séances planifiées"
                                 + (courseCountBadge.isAtLimit ? "  — Limite annuelle atteinte" : "")
                        }
                        font.pixelSize: 11; font.weight: Font.Bold
                        color: courseCountBadge.isAtLimit   ? "#DC2626"
                             : courseCountBadge.isNearLimit ? "#92400E"
                             : "#166534"
                    }
                }
            }

            // ── Zone Submit / Avertissement / Confirmation ──
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 12

                readonly property bool formValid: {
                    if (!root.formDate) return false
                    if (root.isCourse)
                        return root.formMatiereId >= 0 && root.formProfId >= 0 && root.formClasseId >= 0 && root.formSalleId >= 0
                    if (root.isExam)
                        return root.formTitre.length > 0 && root.formMatiereId >= 0 && root.formClasseId >= 0 && root.formSalleId >= 0
                    return root.formTitre.length > 0
                }

                // ── Avertissement dépassement limite (cours, session unique) ──
                Rectangle {
                    width: parent.width
                    height: overLimitVisible ? 104 : 0
                    visible: overLimitVisible
                    radius: 14
                    color: "#FEF3C7"; border.color: "#FCD34D"
                    clip: true

                    readonly property bool overLimitVisible:
                        root.showOverLimitWarning &&
                        root.isCourse && root.formRecurrence === "none"

                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Column {
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                        spacing: 10

                        RowLayout {
                            width: parent.width; spacing: 8
                            Text { text: "⚠"; font.pixelSize: 16; color: "#D97706" }
                            Text {
                                Layout.fillWidth: true
                                text: "Le nombre de séances prévu (" + (examsController.courseCountInfo["limit"] || 0) + "/an) est déjà atteint. Continuer quand même ?"
                                font.pixelSize: 12; font.weight: Font.Bold; color: "#78350F"
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            width: parent.width; spacing: 10

                            Rectangle {
                                Layout.fillWidth: true; height: 36; radius: 10
                                color: cancelWarnMa.containsMouse ? Style.bgSecondary : Style.bgPage
                                border.color: Style.borderLight
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "ANNULER"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary }
                                MouseArea { id: cancelWarnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showOverLimitWarning = false }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 36; radius: 10
                                color: forceCreateMa.containsMouse ? "#D97706" : "#F59E0B"
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "CRÉER QUAND MÊME"; font.pixelSize: 10; font.weight: Font.Black; color: "#FFFFFF" }
                                MouseArea {
                                    id: forceCreateMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.showOverLimitWarning = false
                                        root.showConfirmSubmit    = true
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Confirmation avant création ──
                Rectangle {
                    width: parent.width
                    height: root.showConfirmSubmit ? 96 : 0
                    visible: root.showConfirmSubmit
                    radius: 14
                    color: "#F0FDF4"; border.color: "#BBF7D0"
                    clip: true

                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Column {
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                        spacing: 10

                        Text {
                            width: parent.width
                            text: root.isCourse
                                  ? "Confirmer la planification du cours ?"
                                  : root.isExam
                                  ? "Confirmer la planification de l'épreuve \"" + root.formTitre + "\" ?"
                                  : "Confirmer l'organisation de l'événement ?"
                            font.pixelSize: 12; font.weight: Font.Bold; color: "#14532D"
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            width: parent.width; spacing: 10

                            Rectangle {
                                Layout.fillWidth: true; height: 36; radius: 10
                                color: cancelConfirmMa.containsMouse ? Style.bgSecondary : Style.bgPage
                                border.color: Style.borderLight
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "NON"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary }
                                MouseArea { id: cancelConfirmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showConfirmSubmit = false }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 36; radius: 10
                                color: okConfirmMa.containsMouse ? "#16A34A" : Style.successColor
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "OUI, CONFIRMER"; font.pixelSize: 10; font.weight: Font.Black; color: "#FFFFFF" }
                                MouseArea {
                                    id: okConfirmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.showConfirmSubmit = false
                                        var parts  = root.formDate.split("/")
                                        var isoDate = ""
                                        if (parts.length === 3)
                                            isoDate = parts[2] + "-" + parts[1] + "-" + parts[0] + "T" + root.formTime + ":00"
                                        if (!isoDate) return

                                        var data = {
                                            "dateHeureDebut": isoDate,
                                            "dureeMinutes":   root.formDuree,
                                            "titre":          root.formTitre
                                        }

                                        if (root.isCourse) {
                                            data["matiereId"] = root.formMatiereId
                                            data["profId"]    = root.formProfId
                                            data["salleId"]   = root.formSalleId
                                            data["classeId"]  = root.formClasseId
                                            data["typeSeance"] = "Cours"
                                            examsController.createCourseWithRecurrence(data, root.formRecurrence)
                                        } else if (root.isExam) {
                                            data["matiereId"] = root.formMatiereId
                                            data["profId"]    = root.formProfId
                                            data["salleId"]   = root.formSalleId
                                            data["classeId"]  = root.formClasseId
                                            data["typeSeance"] = "Examen"
                                            examsController.createExam(data)
                                        } else {
                                            if (root.formSalleId >= 0) data["salleId"] = root.formSalleId
                                            if (root.formDescriptif)   data["descriptif"] = root.formDescriptif
                                            data["typeSeance"] = "Événement"
                                            examsController.createExam(data)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Bouton submit principal (caché en mode avertissement/confirm) ──
                Rectangle {
                    width: parent.width; height: 52; radius: 16
                    visible: !root.showConfirmSubmit && !root.showOverLimitWarning

                    readonly property bool formValid: parent.formValid

                    opacity: formValid ? 1.0 : 0.5
                    color: !formValid ? Style.bgTertiary
                         : submitMa.containsMouse
                             ? (root.isExam ? Style.primaryDark : root.isEvent ? "#D97706" : "#1D4ED8")
                             : (root.isExam ? Style.primary : root.isEvent ? Style.warningColor : Style.infoColor)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "Confirmer l'Organisation"; font.pixelSize: 12; font.weight: Font.Black; color: "#FFFFFF"; font.letterSpacing: 0.5 }
                        Text { text: "→"; font.pixelSize: 16; color: "#FFFFFF" }
                    }

                    MouseArea {
                        id: submitMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: parent.formValid ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: parent.formValid

                        onClicked: {
                            // Cours: check over-limit before confirming
                            if (root.isCourse && root.formRecurrence === "none") {
                                var cnt = examsController.courseCountInfo["count"]  !== undefined ? examsController.courseCountInfo["count"]  : 0
                                var lim = examsController.courseCountInfo["limit"]  !== undefined ? examsController.courseCountInfo["limit"]  : 0
                                if (lim > 0 && cnt >= lim) {
                                    root.showOverLimitWarning = true
                                    return
                                }
                            }
                            root.showConfirmSubmit = true
                        }
                    }
                }
            }
        }
    }
}
