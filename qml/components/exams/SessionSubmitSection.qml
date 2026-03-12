import QtQuick
import QtQuick.Layouts
import UI.Components

// Bottom section of the session form: course-count badge,
// over-limit warning, confirmation dialog, and submit button.
// All session creation is scoped to the active school year
// (the backend resolves the year from dateHeureDebut via findAnneeScolaireIdForDate).
Column {
    id: root
    spacing: 12

    // ── Required form data ─────────────────────────────────────────
    required property bool   isCourse
    required property bool   isExam
    required property bool   isEvent
    required property bool   formValid
    required property string formDate
    required property string formTime
    required property int    formDuree
    required property string formTitre
    required property int    formMatiereId
    required property int    formProfId
    required property int    formSalleId
    required property int    formClasseId
    required property string formRecurrence
    required property string formDescriptif

    // ── Internal UI state ──────────────────────────────────────────
    property bool showOverLimitWarning: false
    property bool showConfirmSubmit:    false

    function reset() {
        showOverLimitWarning = false
        showConfirmSubmit    = false
    }

    // ── Course count badge ─────────────────────────────────────────
    Rectangle {
        width: parent.width; height: 40; radius: 12
        visible: root.isCourse && root.formMatiereId >= 0 && root.formClasseId >= 0

        readonly property int  cnt:      examsController.courseCountInfo["count"] !== undefined
                                         ? examsController.courseCountInfo["count"] : 0
        readonly property int  lim:      examsController.courseCountInfo["limit"] !== undefined
                                         ? examsController.courseCountInfo["limit"] : 0
        readonly property bool isAtLim:  lim > 0 && cnt >= lim
        readonly property bool isNearLim: lim > 0 && cnt >= lim - 2 && cnt < lim

        color:        isAtLim   ? Style.errorBorder : isNearLim ? Style.warningBg : Style.successBg
        border.color: isAtLim   ? Style.errorBorder : isNearLim ? Style.warningBorder : Style.successColor

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8
            Text {
                text: parent.parent.isAtLim || parent.parent.isNearLim ? "⚠" : "✓"
                font.pixelSize: 14
                color: parent.parent.isAtLim ? Style.errorColor : parent.parent.isNearLim ? Style.warningColor : Style.successColor
            }
            Text {
                Layout.fillWidth: true
                text: {
                    var b = parent.parent
                    if (b.lim <= 0) return b.cnt + " séance(s) planifiée(s) cette année scolaire"
                    return b.cnt + " / " + b.lim + " séances planifiées"
                           + (b.isAtLim ? "  — Limite annuelle atteinte" : "")
                }
                font.pixelSize: 11; font.weight: Font.Bold
                color: parent.parent.isAtLim ? Style.errorColor : parent.parent.isNearLim ? Style.warningColor : Style.zitouna
            }
        }
    }

    // ── Over-limit warning ─────────────────────────────────────────
    Rectangle {
        id: overLimitBox
        width: parent.width
        height: isVisible ? 104 : 0; visible: isVisible
        readonly property bool isVisible:
            root.showOverLimitWarning && root.isCourse && root.formRecurrence === "none"
        radius: 14; color: Style.warningBorder; border.color: Style.warningBorder; clip: true
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10
            RowLayout {
                width: parent.width; spacing: 8
                Text { text: "⚠"; font.pixelSize: 16; color: Style.warningColor }
                Text {
                    Layout.fillWidth: true
                    text: "Le nombre de séances prévu ("
                          + (examsController.courseCountInfo["limit"] || 0)
                          + "/an) est déjà atteint. Continuer quand même ?"
                    font.pixelSize: 12; font.weight: Font.Bold; color: Style.warningColor
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
                    color: forceCreateMa.containsMouse ? Style.warningColor : Style.warningColor
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "CRÉER QUAND MÊME"; font.pixelSize: 10; font.weight: Font.Black; color: Style.background }
                    MouseArea { id: forceCreateMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.showOverLimitWarning = false; root.showConfirmSubmit = true } }
                }
            }
        }
    }

    // ── Confirmation ───────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: root.showConfirmSubmit ? 96 : 0; visible: root.showConfirmSubmit
        radius: 14; color: Style.successBg; border.color: Style.successColor; clip: true
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10
            Text {
                width: parent.width
                text: root.isCourse ? "Confirmer la planification du cours ?"
                    : root.isExam   ? "Confirmer la planification de l'épreuve \"" + root.formTitre + "\" ?"
                    :                 "Confirmer l'organisation de l'événement ?"
                font.pixelSize: 12; font.weight: Font.Bold; color: Style.zitounaDark
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
                    color: okConfirmMa.containsMouse ? Style.successColor : Style.successColor
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "OUI, CONFIRMER"; font.pixelSize: 10; font.weight: Font.Black; color: Style.background }
                    MouseArea {
                        id: okConfirmMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showConfirmSubmit = false
                            // Build ISO datetime — year scoping handled by backend via findAnneeScolaireIdForDate
                            var parts = root.formDate.split("/")
                            if (parts.length !== 3) return
                            var isoDate = parts[2] + "-" + parts[1] + "-" + parts[0]
                                          + "T" + root.formTime + ":00"
                            var data = {
                                "dateHeureDebut": isoDate,
                                "dureeMinutes":   root.formDuree,
                                "titre":          root.formTitre
                            }
                            if (root.isCourse) {
                                data["matiereId"]  = root.formMatiereId
                                data["profId"]     = root.formProfId
                                data["salleId"]    = root.formSalleId
                                data["classeId"]   = root.formClasseId
                                data["typeSeance"] = "Cours"
                                examsController.createCourseWithRecurrence(data, root.formRecurrence)
                            } else if (root.isExam) {
                                data["matiereId"]  = root.formMatiereId
                                data["profId"]     = root.formProfId
                                data["salleId"]    = root.formSalleId
                                data["classeId"]   = root.formClasseId
                                data["typeSeance"] = "Examen"
                                examsController.createExam(data)
                            } else {
                                if (root.formSalleId >= 0)  data["salleId"]    = root.formSalleId
                                if (root.formDescriptif)    data["descriptif"] = root.formDescriptif
                                data["typeSeance"] = "Événement"
                                examsController.createExam(data)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Main submit button ─────────────────────────────────────────
    Rectangle {
        width: parent.width; height: 52; radius: 16
        visible: !root.showConfirmSubmit && !root.showOverLimitWarning
        opacity: root.formValid ? 1.0 : 0.5
        color: !root.formValid
               ? Style.bgTertiary
               : submitMa.containsMouse
                   ? (root.isExam ? Style.primaryDark : root.isEvent ? Style.warningColor : Style.chart3)
                   : (root.isExam ? Style.primary     : root.isEvent ? Style.warningColor : Style.infoColor)
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent; spacing: 8
            Text { text: "Confirmer l'Organisation"; font.pixelSize: 12; font.weight: Font.Black; color: Style.background; font.letterSpacing: 0.5 }
            Text { text: "→"; font.pixelSize: 16; color: Style.background }
        }

        MouseArea {
            id: submitMa
            anchors.fill: parent; hoverEnabled: true
            cursorShape: root.formValid ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: root.formValid
            onClicked: {
                if (root.isCourse && root.formRecurrence === "none") {
                    var cnt = examsController.courseCountInfo["count"] !== undefined
                              ? examsController.courseCountInfo["count"] : 0
                    var lim = examsController.courseCountInfo["limit"] !== undefined
                              ? examsController.courseCountInfo["limit"] : 0
                    if (lim > 0 && cnt >= lim) { root.showOverLimitWarning = true; return }
                }
                root.showConfirmSubmit = true
            }
        }
    }
}
