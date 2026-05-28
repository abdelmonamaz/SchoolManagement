import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Étape 3 : Première année scolaire + tarifs ────────────────────────────────
ColumnLayout {
    id: root
    spacing: 20

    // ── Public API ──────────────────────────────────────────────────────────
    readonly property bool anneeValid: {
        if (!dateDebutField.isValid || !dateFinField.isValid) return false
        var d1 = new Date(dateDebutField.dateString)
        var d2 = new Date(dateFinField.dateString)
        if (d2.getTime() <= d1.getTime()) return false
        var maxEnd = new Date(d1); maxEnd.setMonth(maxEnd.getMonth() + 12)
        return d2.getTime() < maxEnd.getTime()
    }

    // S2 start is always S1 end + 1 day (derived, not editable)
    readonly property string _s2DateDebut: {
        if (!s1Row.rightField.isValid) return ""
        var d = new Date(s1Row.rightField.dateString)
        d.setDate(d.getDate() + 1)
        var m = d.getMonth() + 1; var day = d.getDate()
        return d.getFullYear() + "-" + (m < 10 ? "0" + m : "" + m) + "-" + (day < 10 ? "0" + day : "" + day)
    }

    readonly property bool semestresValid: {
        if (!anneeValid) return false
        if (!s1Row.rightField.isValid) return false
        var d1   = new Date(dateDebutField.dateString)
        var d2   = new Date(dateFinField.dateString)
        var s1End = new Date(s1Row.rightField.dateString)
        return s1End.getTime() > d1.getTime() && s1End.getTime() < d2.getTime()
    }

    readonly property bool canProceed: libelleField.text.trim() !== "" && anneeValid && semestresValid

    function getData() {
        return {
            libelle:                libelleField.text.trim(),
            dateDebut:              dateDebutField.dateString,
            dateFin:                dateFinField.dateString,
            s1DateFin:              s1Row.rightField.dateString,
            s2DateDebut:            root._s2DateDebut,
            tarifJeune:             parseFloat(tarifJeuneInput.text)  || 0,
            tarifAdulte:            parseFloat(tarifAdulteInput.text) || 0,
            fraisInscriptionJeune:  parseFloat(fraisJeuneInput.text)  || 0,
            fraisInscriptionAdulte: parseFloat(fraisAdulteInput.text) || 0
        }
    }

    // ── Libellé auto-fill ───────────────────────────────────────────────────
    property bool   _autoFill:  true
    property string _autoValue: ""

    function _updateLibelleAuto() {
        if (!_autoFill || !dateDebutField.isValid || !dateFinField.isValid) return
        var auto_ = dateDebutField.dateString.substring(0, 4)
                    + "-" + dateFinField.dateString.substring(0, 4)
        _autoValue = auto_
        libelleField.text = auto_
    }

    Connections {
        target: libelleField
        function onTextChanged() {
            if (libelleField.text !== root._autoValue) root._autoFill = false
        }
    }

    Component.onCompleted: {
        _autoFill = true; _autoValue = ""; _updateLibelleAuto()
        var y = new Date().getMonth() < 8 ? new Date().getFullYear() : new Date().getFullYear() + 1
        s1Row.rightField.setDate(y + "-01-14")
    }

    // ── Info banner ─────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true; height: 48; radius: 14; color: Style.primaryBg
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
            IconLabel { iconName: "info"; iconColor: Style.primary }
            Text {
                Layout.fillWidth: true
                text: qsTr("Ces paramètres s'appliqueront à la première année scolaire.")
                font.pixelSize: 12; font.bold: true; color: Style.primary; wrapMode: Text.WordWrap
            }
        }
    }

    FormField {
        id: libelleField
        Layout.fillWidth: true
        label: qsTr("LIBELLÉ DE L'ANNÉE")
        placeholder: qsTr("ex: 2025-2026")
        Component.onCompleted: {
            var y = new Date().getMonth() < 8 ? new Date().getFullYear() - 1 : new Date().getFullYear()
            text = y + "-" + (y + 1)
        }
    }

    Item {
        Layout.fillWidth: true
        height: dateDebutField.implicitHeight

        DateField {
            id: dateDebutField
            width: (parent.width - 16) / 2
            anchors.left: parent.left
            label: qsTr("DATE DE DÉBUT")
            fieldColor: Style.bgWhite
            onDateStringChanged: root._updateLibelleAuto()
            Component.onCompleted: {
                var y = new Date().getMonth() < 8 ? new Date().getFullYear() - 1 : new Date().getFullYear()
                setDate(y + "-09-01")
            }
        }
        DateField {
            id: dateFinField
            width: (parent.width - 16) / 2
            anchors.right: parent.right
            label: qsTr("DATE DE FIN")
            fieldColor: Style.bgWhite
            onDateStringChanged: root._updateLibelleAuto()
            Component.onCompleted: {
                var y = new Date().getMonth() < 8 ? new Date().getFullYear() : new Date().getFullYear() + 1
                setDate(y + "-06-30")
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true; height: 36; radius: 10; color: Style.errorBg
        visible: dateDebutField.isValid && dateFinField.isValid && !root.anneeValid
        Row {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 6
            IconLabel { iconName: "warning"; iconColor: Style.errorColor; iconSize: 14; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: new Date(dateFinField.dateString).getTime() <= new Date(dateDebutField.dateString).getTime()
                    ? qsTr("La date de fin doit être postérieure à la date de début.")
                    : qsTr("L'année scolaire ne peut pas dépasser 12 mois.")
                font.pixelSize: 11; font.bold: true; color: Style.errorColor
            }
        }
    }

    // ── Semestres ────────────────────────────────────────────────────────────
    SectionLabel { text: qsTr("PARAMÈTRES DES SEMESTRES") }

    // S1
    Rectangle {
        Layout.fillWidth: true
        height: s1Title.height + s1Row.height + 34
        radius: 10;
        color: Style.background;
        border.color: Style.primary;
        border.width: 1

        Text {
            id: s1Title
            anchors { left: parent.left;
            right: parent.right;
            top: parent.top;
            margins: 10 }
            text: qsTr("SEMESTRE 1"); font.pixelSize: 10; font.weight: Font.Black; color: Style.primary; font.letterSpacing: 1
        }

        SemesterBoundRow {
            id: s1Row
            anchors { left: parent.left; right: parent.right; top: s1Title.bottom; margins: 10 }
            anchors.topMargin: 18
            leftLabel:    qsTr("Début (fixe)")
            leftDate:     dateDebutField.isValid ? dateDebutField.dateString : ""
            rightLabel:   qsTr("Fin du S1")
            rightEditable: true
        }
    }

    // S2
    Rectangle {
        Layout.fillWidth: true
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
            leftDate:   root._s2DateDebut
            rightLabel: qsTr("Fin (fixe)")
            rightDate:  dateFinField.isValid ? dateFinField.dateString : ""
        }
    }

    // Semester validation error
    Rectangle {
        Layout.fillWidth: true; height: 32; radius: 8; color: Style.errorBg
        visible: anneeValid && !root.semestresValid
        Row {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 6
            IconLabel { iconName: "warning"; iconColor: Style.errorColor; iconSize: 12; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!s1Row.rightField.isValid)
                        return qsTr("Date de fin du S1 invalide.")
                    var s1End = new Date(s1Row.rightField.dateString)
                    var d1 = new Date(dateDebutField.dateString)
                    var d2 = new Date(dateFinField.dateString)
                    if (s1End.getTime() <= d1.getTime())
                        return qsTr("La fin du S1 doit être postérieure au début de l'année.")
                    if (s1End.getTime() >= d2.getTime())
                        return qsTr("La fin du S1 doit être antérieure à la fin de l'année.")
                    return qsTr("Date de semestre invalide.")
                }
                font.pixelSize: 10; font.bold: true; color: Style.errorColor
            }
        }
    }

    // ── Tarifs mensuels ─────────────────────────────────────────────────────
    SectionLabel { text: qsTr("TARIFS MENSUELS") }
    Rectangle {
        Layout.fillWidth: true; height: 110; radius: 14
        color: Style.bgPage; border.color: Style.borderLight
        RowLayout {
            anchors.fill: parent; anchors.margins: 18; spacing: 0
            ColumnLayout {
                spacing: 4
                SectionLabel { text: qsTr("TARIF JEUNE") }
                RowLayout { spacing: 6
                    TextField { id: tarifJeuneInput;  Layout.preferredWidth: 110; height: 48; text: "10"
                        font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary; selectByMouse: true
                        leftPadding: 12; rightPadding: 8; topPadding: 0; bottomPadding: 0; verticalAlignment: TextInput.AlignVCenter
                        validator: RegularExpressionValidator { regularExpression: /^\d{0,5}(\.\d{0,2})?$/ }
                        background: Rectangle { radius: 10; color: Style.background; border.width: parent.activeFocus ? 2 : 1
                            border.color: parent.activeFocus ? Style.primary : Style.borderLight; Behavior on border.color { ColorAnimation { duration: 120 } } } }
                    Text { text: qsTr("DT / mois"); font.pixelSize: 12; font.bold: true; color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter }
                }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 4
                SectionLabel { text: qsTr("TARIF ADULTE") }
                RowLayout { spacing: 6
                    TextField { id: tarifAdulteInput; Layout.preferredWidth: 110; height: 48; text: "20"
                        font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary; selectByMouse: true
                        leftPadding: 12; rightPadding: 8; topPadding: 0; bottomPadding: 0; verticalAlignment: TextInput.AlignVCenter
                        validator: RegularExpressionValidator { regularExpression: /^\d{0,5}(\.\d{0,2})?$/ }
                        background: Rectangle { radius: 10; color: Style.background; border.width: parent.activeFocus ? 2 : 1
                            border.color: parent.activeFocus ? Style.primary : Style.borderLight; Behavior on border.color { ColorAnimation { duration: 120 } } } }
                    Text { text: qsTr("DT / mois"); font.pixelSize: 12; font.bold: true; color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter }
                }
            }
        }
    }

    // ── Frais d'inscription ─────────────────────────────────────────────────
    SectionLabel { text: qsTr("FRAIS D'INSCRIPTION") }
    Rectangle {
        Layout.fillWidth: true; height: 110; radius: 14
        color: Style.bgPage; border.color: Style.borderLight
        RowLayout {
            anchors.fill: parent; anchors.margins: 18; spacing: 0
            ColumnLayout {
                spacing: 4
                SectionLabel { text: qsTr("FRAIS JEUNE") }
                RowLayout { spacing: 6
                    TextField { id: fraisJeuneInput;  Layout.preferredWidth: 110; height: 48; text: "0"
                        font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary; selectByMouse: true
                        leftPadding: 12; rightPadding: 8; topPadding: 0; bottomPadding: 0; verticalAlignment: TextInput.AlignVCenter
                        validator: RegularExpressionValidator { regularExpression: /^\d{0,5}(\.\d{0,2})?$/ }
                        background: Rectangle { radius: 10; color: Style.background; border.width: parent.activeFocus ? 2 : 1
                            border.color: parent.activeFocus ? Style.primary : Style.borderLight; Behavior on border.color { ColorAnimation { duration: 120 } } } }
                    Text { text: qsTr("DT"); font.pixelSize: 12; font.bold: true; color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter }
                }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 4
                SectionLabel { text: qsTr("FRAIS ADULTE") }
                RowLayout { spacing: 6
                    TextField { id: fraisAdulteInput; Layout.preferredWidth: 110; height: 48; text: "30"
                        font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary; selectByMouse: true
                        leftPadding: 12; rightPadding: 8; topPadding: 0; bottomPadding: 0; verticalAlignment: TextInput.AlignVCenter
                        validator: RegularExpressionValidator { regularExpression: /^\d{0,5}(\.\d{0,2})?$/ }
                        background: Rectangle { radius: 10; color: Style.background; border.width: parent.activeFocus ? 2 : 1
                            border.color: parent.activeFocus ? Style.primary : Style.borderLight; Behavior on border.color { ColorAnimation { duration: 120 } } } }
                    Text { text: qsTr("DT"); font.pixelSize: 12; font.bold: true; color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
