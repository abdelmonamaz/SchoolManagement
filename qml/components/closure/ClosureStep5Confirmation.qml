import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Clôture Étape 5 : Confirmation nouvelle année + semestres ─────────────────
ScrollView {
    id: root
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    required property var stats

    // ── Exposed state ──────────────────────────────────────────────────
    property string newLabel:     ""
    property string newDebut:     ""
    property string newFin:       ""
    property string s1DateFin:    ""
    readonly property string s2DateDebut: {
        if (s1DateFin.length !== 10) return ""
        var d = new Date(s1DateFin)
        if (isNaN(d)) return ""
        d.setDate(d.getDate() + 1)
        var m = d.getMonth() + 1; var day = d.getDate()
        return d.getFullYear() + "-" + (m < 10 ? "0" + m : "" + m) + "-" + (day < 10 ? "0" + day : "" + day)
    }
    property bool   libelleAutoFill: true

    // ── Validation ─────────────────────────────────────────────────────
    readonly property bool anneeValid:
        newLabel.trim().length > 0 && newDebut.length === 10 && newFin.length === 10

    readonly property bool semestresValid: {
        if (!anneeValid) return false
        if (s1DateFin.length !== 10) return false
        var d1   = new Date(newDebut)
        var d2   = new Date(newFin)
        var s1End = new Date(s1DateFin)
        if (isNaN(d1) || isNaN(d2) || isNaN(s1End)) return false
        return s1End > d1 && s1End < d2
    }

    readonly property bool step5Valid: anneeValid && semestresValid

    signal closureRequested(var payload)

    function autoLibelle() {
        if (!libelleAutoFill || newDebut.length < 4 || newFin.length < 4) return
        var y1 = parseInt(newDebut.substring(0, 4))
        var y2 = parseInt(newFin.substring(0, 4))
        root.newLabel = y1 + "-" + y2
        labelInput.text = root.newLabel
    }

    function _updateSemesterDefaults() {
        if (newDebut.length !== 10) return
        var d1 = new Date(newDebut)
        if (isNaN(d1)) return
        var nextYear = d1.getFullYear() + 1
        if (!s1Row.rightField.isValid || s1DateFin === "") {
            var def1 = nextYear + "-01-14"
            root.s1DateFin = def1
            s1Row.rightField.setDate(def1)
        }
    }

    Column {
        width: root.width
        spacing: 16

        // ── Section : Nouvelle année scolaire ──────────────────────────
        Text { text: qsTr("Paramètres de la nouvelle année scolaire"); font.pixelSize: 14; font.bold: true; color: Style.textPrimary }

        // Libellé
        Column {
            width: parent.width; spacing: 6
            Text { text: qsTr("Libellé de l'année"); font.pixelSize: 12; color: Style.textSecondary }
            Rectangle {
                width: parent.width; height: 44; radius: 10; color: Style.bgWhite
                border.color: labelInput.activeFocus ? Style.primary : Style.borderMedium
                border.width: labelInput.activeFocus ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 150 } }
                TextInput {
                    id: labelInput
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                    text: root.newLabel; font.pixelSize: 13; color: Style.textPrimary
                    selectByMouse: true; cursorVisible: activeFocus
                    onTextChanged: { root.newLabel = text; root.libelleAutoFill = false }
                }
                Text {
                    visible: labelInput.text === ""
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
                    text: qsTr("Ex : 2026-2027"); font.pixelSize: 13; color: Style.textTertiary
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: labelInput.forceActiveFocus() }
            }
        }

        // Dates de l'année
        Row {
            width: parent.width; spacing: 12

            DateField {
                id: dateField5Debut
                width: (parent.width - 12) / 2; label: qsTr("DATE DE DÉBUT"); fieldColor: Style.bgWhite
                onDateStringChanged: {
                    root.newDebut = dateString
                    if (isValid && root.libelleAutoFill) root.autoLibelle()
                    if (isValid) root._updateSemesterDefaults()
                }
            }

            DateField {
                id: dateField5Fin
                width: (parent.width - 12) / 2; label: qsTr("DATE DE FIN"); fieldColor: Style.bgWhite
                onDateStringChanged: {
                    root.newFin = dateString
                    if (isValid && root.libelleAutoFill) root.autoLibelle()
                }
            }
        }

        // Année validation error
        Rectangle {
            width: parent.width; height: 32; radius: 8; color: Style.errorBg
            visible: newDebut.length === 10 && newFin.length === 10 && !anneeValid
            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                IconLabel { iconName: "warning"; iconColor: Style.errorColor; iconSize: 12 }
                Text { Layout.fillWidth: true; text: qsTr("Libellé requis et dates de l'année invalides."); font.pixelSize: 10; font.bold: true; color: Style.errorColor }
            }
        }

        // ── Section : Semestres ────────────────────────────────────────
        SectionLabel { text: qsTr("PARAMÈTRES DES SEMESTRES") }

        Rectangle {
            width: parent.width; height: semCol.implicitHeight + 24; radius: 14
            color: Style.bgPage; border.color: Style.borderLight

            Column {
                id: semCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 12

                // S1
                Rectangle {
                    width: parent.width
                    height: s1Title.height + s1Row.height + 34
                    radius: 10; color: Style.background; border.color: Style.primary; border.width: 1

                    Text {
                        id: s1Title
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        text: qsTr("SEMESTRE 1"); font.pixelSize: 10; font.weight: Font.Black; color: Style.primary; font.letterSpacing: 1
                    }

                    SemesterBoundRow {
                        id: s1Row
                        anchors { left: parent.left; right: parent.right; top: s1Title.bottom; margins: 10 }
                        anchors.topMargin: 18
                        leftLabel:    qsTr("Début (fixe)")
                        leftDate:     root.newDebut
                        rightLabel:   qsTr("Fin du S1")
                        rightEditable: true
                    }
                    Connections {
                        target: s1Row.rightField
                        function onDateStringChanged() { root.s1DateFin = s1Row.rightField.dateString }
                    }
                }

                // S2
                Rectangle {
                    width: parent.width
                    height: s2Title.height + s2Row.height + 34
                    radius: 10; color: Style.background; border.color: Style.infoColor; border.width: 1

                    Text {
                        id: s2Title
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        text: qsTr("SEMESTRE 2"); font.pixelSize: 10; font.weight: Font.Black; color: Style.infoColor; font.letterSpacing: 1
                    }

                    SemesterBoundRow {
                        id: s2Row
                        anchors { left: parent.left; right: parent.right; top: s2Title.bottom; margins: 10 }
                        anchors.topMargin: 18
                        leftLabel:  qsTr("Début du S2 (fixe)")
                        leftDate:   root.s2DateDebut
                        rightLabel: qsTr("Fin (fixe)")
                        rightDate:  root.newFin
                    }
                }

                // Semester validation error
                Rectangle {
                    width: parent.width; height: 32; radius: 8; color: Style.errorBg
                    visible: anneeValid && !root.semestresValid
                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        IconLabel { iconName: "warning"; iconColor: Style.errorColor; iconSize: 12 }
                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (root.s1DateFin.length !== 10)
                                    return qsTr("Date de fin du S1 invalide.")
                                var s1End = new Date(root.s1DateFin)
                                var d1 = new Date(root.newDebut); var d2 = new Date(root.newFin)
                                if (s1End <= d1) return qsTr("La fin du S1 doit être postérieure au début de l'année.")
                                if (s1End >= d2) return qsTr("La fin du S1 doit être antérieure à la fin de l'année.")
                                return qsTr("Date de semestre invalide.")
                            }
                            font.pixelSize: 10; font.bold: true; color: Style.errorColor
                        }
                    }
                }
            }
        }

        // ── Warning important ──────────────────────────────────────────
        Rectangle {
            width: parent.width; height: impWarn.implicitHeight + 24
            radius: 12; color: Style.warningBg; border.color: Style.warningColor; border.width: 1
            Column {
                id: impWarn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 8
                Row {
                    spacing: 8
                    Text { text: qsTr("⚠️"); font.pixelSize: 14 }
                    Text { text: qsTr("Avertissement Important"); font.pixelSize: 14; font.bold: true; color: Style.warningColor }
                }
                Text {
                    width: parent.width
                    text: qsTr("Une fois la clôture effectuée, il sera <b>impossible de revenir en arrière</b>. Assurez-vous d'avoir vérifié toutes les données et effectué une sauvegarde complète avant de continuer.")
                    textFormat: Text.RichText; font.pixelSize: 13; color: Style.warningColor; wrapMode: Text.WordWrap
                }
            }
        }

        // ── Final close button ─────────────────────────────────────────
        Rectangle {
            width: parent.width; height: 52; radius: 14
            color: root.step5Valid ? Style.errorColor : Style.borderLight
            Behavior on color { ColorAnimation { duration: 200 } }

            Row {
                anchors.centerIn: parent; spacing: 10
                Text { text: qsTr("🔒"); font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter; color: "white" }
                Text {
                    text: qsTr("CLÔTURER L'ANNÉE SCOLAIRE ") + (root.stats ? root.stats.anneeActiveLibelle.toUpperCase() : "")
                    font.pixelSize: 13; font.bold: true; color: "white"; font.letterSpacing: 0.5
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.step5Valid && !yearClosureController.isLoading
                cursorShape: root.step5Valid ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                onClicked: root.closureRequested({})
            }
        }
    }

    // Public setDate helpers for parent to call
    function setDebutDate(iso) { dateField5Debut.setDate(iso); root.newDebut = iso }
    function setFinDate(iso)   { dateField5Fin.setDate(iso);   root.newFin   = iso }
    function focusLabel()      { labelInput.forceActiveFocus() }
}
