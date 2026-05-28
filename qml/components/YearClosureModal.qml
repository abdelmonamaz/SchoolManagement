import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ═══════════════════════════════════════════════════════════════════
//  Wizard Clôture d'Année Scolaire — 5 étapes
//  Étape 1 : Vue d'ensemble (stats)
//  Étape 2 : Progressions (résultats interactifs par élève)
//  Étape 3 : Archivage (bilan séances + matières)
//  Étape 4 : Rapports (résumé des actions)
//  Étape 5 : Confirmation (nouvelle année + semestres + clôture)
// ═══════════════════════════════════════════════════════════════════
Popup {
    id: root

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.92, 960)
    modal: true
    padding: 0
    closePolicy: Popup.NoAutoClose

    property int currentStep: 1
    readonly property int totalSteps: 5

    // Données initiales pour step 2 (le composant gère ensuite son propre état)
    property var progressions: []

    // Stats shorthand
    readonly property var stats: yearClosureController.closureStats
    readonly property var incomplete: yearClosureController.incompleteSessions

    // Snapshot des progressions capturé au passage étape 2 → 3 (pour step4 et payload clôture)
    property var _closureProgressions: []

    function _buildProgressionsCopy(src) {
        var copy = []
        for (var i = 0; i < src.length; i++) {
            var p = src[i]
            var moy = (p.moyenneAnnuelle !== undefined) ? p.moyenneAnnuelle : -1.0
            var res = (p.resultat !== "" && p.resultat !== "En cours") ? p.resultat : "En cours"
            var nSuivantId = (p.niveauxSuivants && p.niveauxSuivants.length > 0) ? p.niveauxSuivants[0].id : 0
            if (res === "En cours" && moy >= 0) {
                if (moy >= 10) { res = "Réussi" }
                else           { res = "Redoublant"; nSuivantId = 0 }
            }
            copy.push({
                inscriptionId:   p.inscriptionId,
                eleveId:         p.eleveId,
                nom:             p.nom,
                prenom:          p.prenom,
                categorie:       p.categorie,
                niveauActuelId:  p.niveauActuelId,
                niveauActuelNom: p.niveauActuelNom,
                resultat:        res,
                niveauxSuivants: p.niveauxSuivants,
                niveauSuivantId: nSuivantId,
                moyenneAnnuelle: moy
            })
        }
        return copy
    }

    function reset() {
        currentStep = 1
        progressions = []
    }

    function _autoFillNewYear() {
        if (!stats || !stats.anneeActiveLibelle) return
        var parts = stats.anneeActiveLibelle.split("-")
        if (parts.length !== 2) return
        var y1n = parseInt(parts[0]) + 1
        var y2n = parseInt(parts[1]) + 1
        var debut = y1n + "-09-01"
        var fin   = y2n + "-06-30"
        step5.setDebutDate(debut)
        step5.setFinDate(fin)
        step5.libelleAutoFill = true
        step5.newLabel = y1n + "-" + y2n
    }

    onOpened: {
        reset()
        progressions = _buildProgressionsCopy(yearClosureController.studentProgressions)
        _autoFillNewYear()
    }

    Overlay.modal: Rectangle { color: Qt.alpha(Style.foreground, 0.80) }
    background: Rectangle { radius: 20; color: Style.bgWhite }

    Connections {
        target: yearClosureController

        function onClosureSuccess(newYearLabel) {
            root.close()
            setupController.checkInitialized()
        }
        function onClosureError(message) {
            errorText.text = message
            errorPopup.open()
        }
        function onStudentProgressionsChanged() {
            if (!root.visible) return
            var src = yearClosureController.studentProgressions
            if (src.length === 0) return
            progressions = root._buildProgressionsCopy(src)
        }
        function onClosureStatsChanged() {
            if (!root.visible) return
            root._autoFillNewYear()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 80; radius: 20; color: Style.textPrimary
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 20; color: Style.textPrimary }

            RowLayout {
                anchors { fill: parent; margins: 24 }
                spacing: 16

                Rectangle {
                    width: 44; height: 44; radius: 12; color: Qt.rgba(1, 1, 1, 0.15)
                    Text { anchors.centerIn: parent; text: qsTr("🔒"); font.pixelSize: 20 }
                }
                Column {
                    spacing: 2
                    Text { text: qsTr("Clôture d'Année Scolaire"); font.pixelSize: 18; font.bold: true; color: "white" }
                    Text { text: stats ? (qsTr("Année ") + stats.anneeActiveLibelle) : ""; font.pixelSize: 13; color: Qt.rgba(1,1,1,0.7) }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 32; height: 32; radius: 8; color: Qt.rgba(1,1,1,0.15)
                    Text { anchors.centerIn: parent; text: qsTr("✕"); color: "white"; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                }
            }
        }

        // ── Step indicator ───────────────────────────────────────────
        Item {
            Layout.fillWidth: true; height: 100

            Row {
                id: stepRow
                anchors.centerIn: parent; spacing: 0

                property var stepDefs: [
                    { label: qsTr("Vue\nd'ensemble"), icon: "📊" },
                    { label: qsTr("Progressions"),    icon: "📈" },
                    { label: qsTr("Archivage"),       icon: "📦" },
                    { label: qsTr("Rapports"),        icon: "📄" },
                    { label: qsTr("Confirmation"),    icon: "🔒" }
                ]

                Repeater {
                    model: stepRow.stepDefs
                    delegate: Row {
                        spacing: 0
                        Column {
                            width: 80; spacing: 6
                            Rectangle {
                                x: (parent.width - width) / 2
                                width: 52; height: 52; radius: 26
                                color: {
                                    if (index + 1 < currentStep) return Style.successColor
                                    if (index + 1 === currentStep) return Style.textPrimary
                                    return "transparent"
                                }
                                border.color: {
                                    if (index + 1 < currentStep) return Style.successColor
                                    if (index + 1 === currentStep) return Style.textPrimary
                                    return Style.borderMedium
                                }
                                border.width: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: (index + 1 < currentStep) ? "✓" : modelData.icon
                                    font.pixelSize: (index + 1 < currentStep) ? 18 : 20
                                    color: {
                                        if (index + 1 <= currentStep) return "white"
                                        return Style.textTertiary
                                    }
                                }
                            }
                            Text {
                                width: parent.width; horizontalAlignment: Text.AlignHCenter
                                text: modelData.label; font.pixelSize: 11
                                font.bold: index + 1 === currentStep
                                color: {
                                    if (index + 1 < currentStep) return Style.successColor
                                    if (index + 1 === currentStep) return Style.textPrimary
                                    return Style.textTertiary
                                }
                                wrapMode: Text.WordWrap
                            }
                        }
                        Rectangle {
                            visible: index < 4; width: 60; height: 2; y: 26
                            color: (index + 1 < currentStep) ? Style.successColor : Style.borderLight
                        }
                    }
                }
            }
        }

        // ── Content area ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 440
            color: Style.bgPage

            ClosureStep1Stats {
                anchors { fill: parent; margins: 24 }
                visible: currentStep === 1
                stats: root.stats
                incomplete: root.incomplete
            }

            ClosureStep2Progressions {
                id: step2Comp
                anchors { fill: parent; margins: 16 }
                visible: currentStep === 2
                progressions: root.progressions
            }

            ClosureStep3Archivage {
                anchors { fill: parent; margins: 24 }
                visible: currentStep === 3
                incomplete: root.incomplete
            }

            ClosureStep4Rapports {
                anchors { fill: parent; margins: 24 }
                visible: currentStep === 4
                progressions: root._closureProgressions
            }

            ClosureStep5Confirmation {
                id: step5
                anchors { fill: parent; margins: 24 }
                visible: currentStep === 5
                stats: root.stats
                onClosureRequested: {
                    var payload = []
                    for (var i = 0; i < root._closureProgressions.length; i++) {
                        var p = root._closureProgressions[i]
                        payload.push({
                            inscriptionId:   p.inscriptionId,
                            eleveId:         p.eleveId,
                            niveauActuelId:  p.niveauActuelId,
                            categorie:       p.categorie,
                            resultat:        p.resultat,
                            niveauSuivantId: p.resultat === "Réussi" ? p.niveauSuivantId : 0
                        })
                    }
                    yearClosureController.executeYearClosure(
                        step5.newLabel, step5.newDebut, step5.newFin,
                        payload, step5.s1DateFin, step5.s2DateDebut)
                }
            }
        }

        // ── Footer navigation ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 72; color: Style.bgWhite; radius: 20
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 20; color: Style.bgWhite }
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Style.borderLight }

            RowLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 12

                // Précédent
                Rectangle {
                    width: 120; height: 40; radius: 10
                    color: currentStep > 1 ? Style.bgPage : "transparent"
                    border.color: currentStep > 1 ? Style.borderMedium : "transparent"; border.width: 1
                    visible: currentStep > 1
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: qsTr("‹"); font.pixelSize: 16; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: qsTr("Précédent"); font.pixelSize: 13; color: Style.textSecondary }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (currentStep > 1) currentStep-- }
                }

                Item { Layout.fillWidth: true }

                Text { text: qsTr("Étape ") + currentStep + " sur " + totalSteps; font.pixelSize: 12; color: Style.textTertiary }

                Item { Layout.fillWidth: true }

                // Annuler (only step 1)
                Rectangle {
                    visible: currentStep === 1; width: 100; height: 40; radius: 10
                    color: Style.bgPage; border.color: Style.borderMedium; border.width: 1
                    Text { anchors.centerIn: parent; text: qsTr("Annuler"); font.pixelSize: 13; color: Style.textSecondary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                }

                // Suivant (steps 1–4)
                Rectangle {
                    visible: currentStep < 5; width: 120; height: 40; radius: 10
                    color: (currentStep === 2 && !step2Comp.step2Valid) ? Style.borderLight : Style.textPrimary
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: qsTr("Suivant"); font.pixelSize: 13; font.bold: true; color: "white" }
                        Text { text: qsTr("›"); font.pixelSize: 16; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !(currentStep === 2 && !step2Comp.step2Valid)
                        cursorShape: (currentStep === 2 && !step2Comp.step2Valid) ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (currentStep < 5) {
                                if (currentStep === 2) {
                                    // Capturer l'état final avant de quitter l'étape 2
                                    root._closureProgressions = step2Comp.getProgressions()
                                    yearClosureController.loadArchivageStats()
                                }
                                currentStep++
                                if (currentStep === 5)
                                    Qt.callLater(function() { step5.focusLabel() })
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Error popup ──────────────────────────────────────────────────
    Popup {
        id: errorPopup
        parent: Overlay.overlay; anchors.centerIn: parent
        width: 400; padding: 24; modal: true
        background: Rectangle { radius: 14; color: Style.bgWhite }

        Column {
            width: parent.width; spacing: 16
            Row {
                spacing: 10
                Text { text: qsTr("❌"); font.pixelSize: 18 }
                Text { text: qsTr("Erreur"); font.pixelSize: 16; font.bold: true; color: Style.textPrimary }
            }
            Text {
                id: errorText
                width: parent.width; font.pixelSize: 13; color: Style.textSecondary; wrapMode: Text.WordWrap
            }
            Rectangle {
                width: parent.width; height: 40; radius: 10; color: Style.textPrimary
                Text { anchors.centerIn: parent; text: qsTr("Fermer"); font.pixelSize: 13; font.bold: true; color: "white" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: errorPopup.close() }
            }
        }
    }
}
