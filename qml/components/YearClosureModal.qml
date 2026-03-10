import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

// ═══════════════════════════════════════════════════════════════════
//  Wizard Clôture d'Année Scolaire — 5 étapes
//  Étape 1 : Vue d'ensemble (stats)
//  Étape 2 : Progressions (résultats interactifs par élève)
//  Étape 3 : Archivage (info + séances incomplètes)
//  Étape 4 : Rapports (résumé des actions)
//  Étape 5 : Confirmation (nouvelle année + clôture)
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

    // Working copy of progressions (step 2 edits)
    property var progressions: []

    // Step 5 fields
    property string newLabel:  ""
    property string newDebut:  ""
    property string newFin:    ""
    property bool   libelleAutoFill: true

    // Computed from progressions
    readonly property int nbDecides: {
        var c = 0
        for (var i = 0; i < progressions.length; i++)
            if (progressions[i].resultat !== "En cours") c++
        return c
    }
    readonly property bool step2Valid: progressions.length > 0 && nbDecides === progressions.length
    readonly property bool step5Valid: newLabel.trim().length > 0 && newDebut.length === 10 && newFin.length === 10

    // Stats shorthand
    readonly property var stats: yearClosureController.closureStats
    readonly property var incomplete: yearClosureController.incompleteSessions

    function autoLibelle() {
        if (!libelleAutoFill || newDebut.length < 4 || newFin.length < 4) return
        var y1 = parseInt(newDebut.substring(0, 4))
        var y2 = parseInt(newFin.substring(0, 4))
        newLabel = y1 + "-" + y2
    }

    function reset() {
        currentStep = 1
        progressions = []
        newLabel = ""; newDebut = ""; newFin = ""; libelleAutoFill = true
    }

    onOpened: {
        reset()
        // Copy progressions from controller
        var src = yearClosureController.studentProgressions
        var copy = []
        for (var i = 0; i < src.length; i++) {
            var p = src[i]
            var moy = (p.moyenneAnnuelle !== undefined) ? p.moyenneAnnuelle : -1.0
            // Auto-fill resultat from average if still "En cours"
            var res = (p.resultat !== "" && p.resultat !== "En cours") ? p.resultat : "En cours"
            var nSuivantId = (p.niveauxSuivants && p.niveauxSuivants.length > 0) ? p.niveauxSuivants[0].id : 0
            if (res === "En cours" && moy >= 0) {
                if (moy >= 10) {
                    res = "Réussi"
                } else {
                    res = "Redoublant"
                    nSuivantId = 0
                }
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
        progressions = copy

        // Auto-fill new year label from active year
        if (stats && stats.anneeActiveLibelle) {
            var parts = stats.anneeActiveLibelle.split("-")
            if (parts.length === 2) {
                var y1n = parseInt(parts[0]) + 1
                var y2n = parseInt(parts[1]) + 1
                newLabel = y1n + "-" + y2n
                newDebut = y1n + "-09-01"
                newFin   = y2n + "-06-30"
                libelleAutoFill = true
                dateField5Debut.setDate(newDebut)
                dateField5Fin.setDate(newFin)
            }
        }
    }

    Overlay.modal: Rectangle { color: "#0F172ACC" }
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

        // Async data arrives after open() — populate progressions when ready
        function onStudentProgressionsChanged() {
            if (!root.visible) return
            var src = yearClosureController.studentProgressions
            if (src.length === 0) return
            var copy = []
            for (var i = 0; i < src.length; i++) {
                var p = src[i]
                var moy = (p.moyenneAnnuelle !== undefined) ? p.moyenneAnnuelle : -1.0
                var res = (p.resultat !== "" && p.resultat !== "En cours") ? p.resultat : "En cours"
                var nSuivantId = (p.niveauxSuivants && p.niveauxSuivants.length > 0) ? p.niveauxSuivants[0].id : 0
                if (res === "En cours" && moy >= 0) {
                    if (moy >= 10) {
                        res = "Réussi"
                    } else {
                        res = "Redoublant"
                        nSuivantId = 0
                    }
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
            progressions = copy
        }

        // Async stats arrive — auto-fill new year fields when ready
        function onClosureStatsChanged() {
            if (!root.visible) return
            var s = yearClosureController.closureStats
            if (s && s.anneeActiveLibelle) {
                var parts = s.anneeActiveLibelle.split("-")
                if (parts.length === 2) {
                    var y1n = parseInt(parts[0]) + 1
                    var y2n = parseInt(parts[1]) + 1
                    newLabel = y1n + "-" + y2n
                    newDebut = y1n + "-09-01"
                    newFin   = y2n + "-06-30"
                    libelleAutoFill = true
                    dateField5Debut.setDate(newDebut)
                    dateField5Fin.setDate(newFin)
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 80
            radius: 20
            color: Style.textPrimary

            // Bottom corners square
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20
                color: Style.textPrimary
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Rectangle {
                    width: 44; height: 44; radius: 12
                    color: Qt.rgba(1, 1, 1, 0.15)
                    Text {
                        anchors.centerIn: parent
                        text: "🔒"; font.pixelSize: 20
                    }
                }

                Column {
                    spacing: 2
                    Text {
                        text: "Clôture d'Année Scolaire"
                        font.pixelSize: 18; font.bold: true
                        color: "white"
                    }
                    Text {
                        text: stats ? ("Année " + stats.anneeActiveLibelle) : ""
                        font.pixelSize: 13
                        color: Qt.rgba(1,1,1,0.7)
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: Qt.rgba(1,1,1,0.15)
                    Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.pixelSize: 14 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }
        }

        // ── Step indicator ───────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            height: 100

            Row {
                id: stepRow
                anchors.centerIn: parent
                spacing: 0

                property var stepDefs: [
                    { label: "Vue\nd'ensemble", icon: "📊" },
                    { label: "Progressions",    icon: "📈" },
                    { label: "Archivage",       icon: "📦" },
                    { label: "Rapports",        icon: "📄" },
                    { label: "Confirmation",    icon: "🔒" }
                ]

                Repeater {
                    model: stepRow.stepDefs
                    delegate: Row {
                        spacing: 0

                        // Circle + label — column width 80, circle centered horizontally
                        Column {
                            width: 80
                            spacing: 6
                            Rectangle {
                                x: (parent.width - width) / 2   // center 52px circle in 80px column
                                width: 52; height: 52; radius: 26
                                color: {
                                    if (index + 1 < currentStep) return "#22C55E"
                                    if (index + 1 === currentStep) return Style.textPrimary
                                    return "transparent"
                                }
                                border.color: {
                                    if (index + 1 < currentStep) return "#22C55E"
                                    if (index + 1 === currentStep) return Style.textPrimary
                                    return Style.borderMedium
                                }
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: (index + 1 < currentStep) ? "✓" : modelData.icon
                                    font.pixelSize: (index + 1 < currentStep) ? 18 : 20
                                    color: (index + 1 <= currentStep) ? "white"
                                           : Style.textTertiary
                                }
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.label
                                font.pixelSize: 11
                                font.bold: index + 1 === currentStep
                                color: {
                                    if (index + 1 < currentStep) return "#22C55E"
                                    if (index + 1 === currentStep) return Style.textPrimary
                                    return Style.textTertiary
                                }
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Connector line (except last) — y=26 = center of 52px circle
                        Rectangle {
                            visible: index < 4
                            width: 60; height: 2
                            y: 26
                            color: (index + 1 < currentStep) ? "#22C55E" : Style.borderLight
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

            // Step 1: Vue d'ensemble
            ScrollView {
                id: step1Scroll
                anchors.fill: parent
                anchors.margins: 24
                visible: currentStep === 1
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: step1Scroll.width
                    spacing: 16

                    // Warning critical
                    Rectangle {
                        width: parent.width
                        height: warnCol.implicitHeight + 32
                        radius: 12
                        color: "#FFFBEB"
                        border.color: "#F59E0B"
                        border.width: 1

                        Column {
                            id: warnCol
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 10

                            Row {
                                spacing: 10
                                Text { text: "⚠️"; font.pixelSize: 16 }
                                Text {
                                    text: "Attention : Action Critique"
                                    font.pixelSize: 15; font.bold: true
                                    color: "#B45309"
                                }
                            }
                            Text {
                                width: parent.width
                                text: "La clôture d'année scolaire est une opération <b>irréversible</b> qui va :"
                                textFormat: Text.RichText
                                font.pixelSize: 13; color: "#92400E"
                                wrapMode: Text.WordWrap
                            }
                            Repeater {
                                model: [
                                    "Archiver définitivement toutes les notes et bulletins de l'année " + (stats ? stats.anneeActiveLibelle : ""),
                                    "Verrouiller les modifications sur les données académiques de cette année",
                                    "Faire passer automatiquement les étudiants qui ont réussi au niveau supérieur",
                                    "Marquer les étudiants de niveau terminal comme diplômés"
                                ]
                                delegate: Row {
                                    spacing: 8
                                    Text { text: "•"; font.pixelSize: 13; color: "#92400E" }
                                    Text {
                                        width: warnCol.width - 16
                                        text: modelData; font.pixelSize: 13; color: "#92400E"
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }

                    // Stat cards 2x2
                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 12

                        Repeater {
                            model: [
                                { label: "Étudiants Inscrits", sub: "Année " + (stats ? stats.anneeActiveLibelle : ""),
                                  value: stats ? stats.studentsInscrits : 0, color: "#F0FDF4", accent: "#16A34A" },
                                { label: "Taux de Réussite", sub: "Global tous niveaux",
                                  value: (stats ? stats.tauxReussite : 0) + "%", color: "#EFF6FF", accent: "#2563EB" },
                                { label: "Diplômés", sub: "Niveau terminal complété",
                                  value: stats ? stats.diplomes : 0, color: "#FAF5FF", accent: "#7C3AED" },
                                { label: "Redoublants", sub: "Tous niveaux confondus",
                                  value: stats ? stats.redoublants : 0, color: "#FFF1F2", accent: "#E11D48" }
                            ]
                            delegate: Rectangle {
                                width: (step1Scroll.width - 12) / 2
                                height: 90
                                radius: 12
                                color: modelData.color
                                border.color: Qt.rgba(0,0,0,0.05)
                                border.width: 1

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text {
                                            text: "" + modelData.value
                                            font.pixelSize: 28; font.bold: true
                                            color: modelData.accent
                                        }
                                        Text { text: modelData.label; font.pixelSize: 13; font.bold: true; color: modelData.accent }
                                        Text { text: modelData.sub; font.pixelSize: 11; color: Qt.darker(modelData.accent, 1.2) }
                                    }
                                }
                            }
                        }
                    }

                    // Incomplete sessions warning
                    Rectangle {
                        width: parent.width
                        visible: incomplete && incomplete.length > 0
                        height: visible ? incomplCol.implicitHeight + 24 : 0
                        radius: 12; color: "#FFF7ED"
                        border.color: "#F97316"; border.width: 1

                        Column {
                            id: incomplCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 6
                            Row {
                                spacing: 8
                                Text { text: "⚠️"; font.pixelSize: 14 }
                                Text {
                                    text: (incomplete ? incomplete.length : 0) + " séance(s) non validée(s)"
                                    font.pixelSize: 13; font.bold: true; color: "#C2410C"
                                }
                            }
                            Text {
                                width: parent.width
                                text: "Ces séances passées n'ont pas d'enregistrement de présence. Vous pouvez continuer, elles seront archivées telles quelles."
                                font.pixelSize: 12; color: "#9A3412"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // Backup recommendation
                    Rectangle {
                        width: parent.width
                        height: backupRow.implicitHeight + 24
                        radius: 12; color: "#EFF6FF"
                        border.color: "#BFDBFE"; border.width: 1

                        Row {
                            id: backupRow
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                            spacing: 10
                            Text { text: "🛡️"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                width: parent.width - 30
                                text: "Sauvegarde recommandée : Avant de procéder à la clôture, assurez-vous d'avoir effectué une sauvegarde complète de la base de données dans l'onglet \"Sauvegarde & Data\" des Paramètres."
                                font.pixelSize: 12; color: "#1D4ED8"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // Step 2: Progressions
            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                visible: currentStep === 2

                // Summary bar
                Rectangle {
                    width: parent.width
                    height: 40; radius: 10
                    color: step2Valid ? "#F0FDF4" : "#FFFBEB"
                    border.color: step2Valid ? "#86EFAC" : "#FCD34D"; border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: step2Valid ? "✅" : "⏳"; font.pixelSize: 14 }
                        Text {
                            text: nbDecides + " / " + progressions.length + " résultats décidés"
                                  + (step2Valid ? " — Prêt à continuer" : " — Décidez tous les résultats")
                            font.pixelSize: 13; font.bold: true
                            color: step2Valid ? "#15803D" : "#92400E"
                        }
                    }
                }

                // List
                ListView {
                    width: parent.width
                    height: parent.height - 48
                    clip: true
                    model: progressions
                    spacing: 4

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: progDelegate
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 66
                        radius: 10
                        color: Style.bgWhite
                        border.color: {
                            var r = modelData.resultat
                            if (r === "Réussi")     return "#86EFAC"
                            if (r === "Redoublant") return "#FCA5A5"
                            return Style.borderLight
                        }
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Avatar
                            Rectangle {
                                width: 38; height: 38; radius: 19
                                color: {
                                    var r = modelData.resultat
                                    if (r === "Réussi")     return "#DCFCE7"
                                    if (r === "Redoublant") return "#FEE2E2"
                                    return Style.bgPage
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.nom.charAt(0)
                                    font.pixelSize: 15; font.bold: true
                                    color: {
                                        var r = modelData.resultat
                                        if (r === "Réussi")     return "#15803D"
                                        if (r === "Redoublant") return "#DC2626"
                                        return Style.textSecondary
                                    }
                                }
                            }

                            // Name + niveau
                            Column {
                                Layout.preferredWidth: 160
                                spacing: 2
                                Text {
                                    text: modelData.nom + " " + modelData.prenom
                                    font.pixelSize: 13; font.bold: true
                                    color: Style.textPrimary
                                    elide: Text.ElideRight; width: parent.width
                                }
                                Text {
                                    text: modelData.niveauActuelNom
                                    font.pixelSize: 11; color: Style.textSecondary
                                    elide: Text.ElideRight; width: parent.width
                                }
                            }

                            // Average grade badge
                            Rectangle {
                                width: 56; height: 28; radius: 8
                                visible: modelData.moyenneAnnuelle !== undefined
                                color: {
                                    var m = modelData.moyenneAnnuelle
                                    if (m < 0) return "#F1F5F9"
                                    return m >= 10 ? "#DCFCE7" : "#FEE2E2"
                                }
                                border.color: {
                                    var m = modelData.moyenneAnnuelle
                                    if (m < 0) return Style.borderLight
                                    return m >= 10 ? "#86EFAC" : "#FCA5A5"
                                }
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        var m = modelData.moyenneAnnuelle
                                        return m < 0 ? "—" : m.toFixed(1)
                                    }
                                    font.pixelSize: 12; font.bold: true
                                    color: {
                                        var m = modelData.moyenneAnnuelle
                                        if (m < 0) return Style.textTertiary
                                        return m >= 10 ? "#16A34A" : "#DC2626"
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Réussi button
                            Rectangle {
                                width: 80; height: 30; radius: 8
                                color: modelData.resultat === "Réussi" ? "#16A34A" : Style.bgPage
                                border.color: modelData.resultat === "Réussi" ? "#16A34A" : Style.borderMedium
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Réussi"
                                    font.pixelSize: 12; font.bold: true
                                    color: modelData.resultat === "Réussi" ? "white" : Style.textSecondary
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var copy = progressions.slice()
                                        var item = Object.assign({}, copy[index])
                                        item.resultat = "Réussi"
                                        // Set default next niveau
                                        if (item.niveauxSuivants && item.niveauxSuivants.length > 0)
                                            item.niveauSuivantId = item.niveauxSuivants[0].id
                                        else
                                            item.niveauSuivantId = 0
                                        copy[index] = item
                                        progressions = copy
                                    }
                                }
                            }

                            // Redoublant button
                            Rectangle {
                                width: 90; height: 30; radius: 8
                                color: modelData.resultat === "Redoublant" ? "#DC2626" : Style.bgPage
                                border.color: modelData.resultat === "Redoublant" ? "#DC2626" : Style.borderMedium
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Redoublant"
                                    font.pixelSize: 12; font.bold: true
                                    color: modelData.resultat === "Redoublant" ? "white" : Style.textSecondary
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var copy = progressions.slice()
                                        var item = Object.assign({}, copy[index])
                                        item.resultat = "Redoublant"
                                        item.niveauSuivantId = 0
                                        copy[index] = item
                                        progressions = copy
                                    }
                                }
                            }

                            // Next niveau display / selector
                            Rectangle {
                                width: 160; height: 30; radius: 8
                                color: Style.bgPage
                                border.color: Style.borderLight; border.width: 1
                                visible: modelData.resultat !== "En cours"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: {
                                            var r = modelData.resultat
                                            if (r === "Redoublant") return "↩"
                                            if (r === "Réussi") {
                                                return (modelData.niveauSuivantId > 0) ? "→" : "🎓"
                                            }
                                            return ""
                                        }
                                        font.pixelSize: 13
                                        color: Style.textSecondary
                                    }

                                    Text {
                                        text: {
                                            var r = modelData.resultat
                                            if (r === "Redoublant") return modelData.niveauActuelNom
                                            if (r === "Réussi") {
                                                if (modelData.niveauSuivantId <= 0) return "Diplômé"
                                                // Find name in niveauxSuivants
                                                for (var i = 0; i < modelData.niveauxSuivants.length; i++) {
                                                    if (modelData.niveauxSuivants[i].id === modelData.niveauSuivantId)
                                                        return modelData.niveauxSuivants[i].nom
                                                }
                                            }
                                            return ""
                                        }
                                        font.pixelSize: 11; font.bold: true
                                        color: {
                                            var r = modelData.resultat
                                            if (r === "Redoublant") return "#DC2626"
                                            if (r === "Réussi" && modelData.niveauSuivantId <= 0) return "#7C3AED"
                                            return "#16A34A"
                                        }
                                        elide: Text.ElideRight
                                        width: (modelData.resultat === "Réussi" && modelData.niveauxSuivants && modelData.niveauxSuivants.length > 1) ? 100 : 130
                                    }
                                }

                                // Dropdown chevron if multiple choices
                                Text {
                                    anchors.right: parent.right; anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: modelData.resultat === "Réussi"
                                             && modelData.niveauxSuivants
                                             && modelData.niveauxSuivants.length > 1
                                    text: "▾"; font.pixelSize: 12; color: Style.textSecondary
                                }

                                // Click to cycle through next niveaux (if multiple)
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: (modelData.resultat === "Réussi"
                                                  && modelData.niveauxSuivants
                                                  && modelData.niveauxSuivants.length > 1)
                                                 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: modelData.resultat === "Réussi"
                                             && modelData.niveauxSuivants
                                             && modelData.niveauxSuivants.length > 1
                                    onClicked: {
                                        var copy = progressions.slice()
                                        var item = Object.assign({}, copy[index])
                                        var suivants = item.niveauxSuivants
                                        var curIdx = 0
                                        for (var i = 0; i < suivants.length; i++) {
                                            if (suivants[i].id === item.niveauSuivantId) { curIdx = i; break }
                                        }
                                        curIdx = (curIdx + 1) % suivants.length
                                        item.niveauSuivantId = suivants[curIdx].id
                                        copy[index] = item
                                        progressions = copy
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Step 3: Archivage
            ScrollView {
                id: step3Scroll
                anchors.fill: parent; anchors.margins: 24
                visible: currentStep === 3
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: step3Scroll.width
                    spacing: 16

                    readonly property var arch: yearClosureController.archivageStats

                    // ── Global sessions KPIs ──────────────────────────────────
                    Text {
                        text: "Bilan des séances"
                        font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                    }

                    Grid {
                        width: parent.width; columns: 3; spacing: 10
                        Repeater {
                            model: [
                                { label: "Cours prévus",    value: parent.parent.arch ? parent.parent.arch.coursTotal   : 0, accent: "#2563EB", bg: "#EFF6FF" },
                                { label: "Cours validés",   value: parent.parent.arch ? parent.parent.arch.coursValides : 0, accent: "#16A34A", bg: "#F0FDF4" },
                                { label: "Examens",         value: parent.parent.arch ? parent.parent.arch.examensTotal : 0, accent: "#7C3AED", bg: "#FAF5FF" }
                            ]
                            delegate: Rectangle {
                                width: (step3Scroll.width - 20) / 3; height: 64
                                radius: 10; color: modelData.bg
                                border.color: Qt.rgba(0,0,0,0.05); border.width: 1
                                Column {
                                    anchors.centerIn: parent; spacing: 4
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "" + modelData.value; font.pixelSize: 22; font.bold: true; color: modelData.accent }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; font.pixelSize: 11; color: modelData.accent }
                                }
                            }
                        }
                    }

                    // ── Global presence rate ──────────────────────────────────
                    Rectangle {
                        width: parent.width; height: presRow.implicitHeight + 20
                        radius: 10; color: "#F8FAFC"
                        border.color: Style.borderLight; border.width: 1
                        Row {
                            id: presRow
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 14 }
                            spacing: 12
                            Text { text: "📊"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Taux de présence global :"; font.pixelSize: 13; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: (parent.parent.parent.arch ? parent.parent.parent.arch.tauxPresenceGlobal : 0) + " %"
                                font.pixelSize: 15; font.bold: true
                                color: {
                                    var r = parent.parent.parent.arch ? parent.parent.parent.arch.tauxPresenceGlobal : 0
                                    return r >= 75 ? "#16A34A" : r >= 50 ? "#D97706" : "#DC2626"
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "| Notes examens saisies : " + (parent.parent.parent.arch ? parent.parent.parent.arch.examensAvecNotes : 0) + "/" + (parent.parent.parent.arch ? parent.parent.parent.arch.examensTotal : 0)
                                font.pixelSize: 12; color: Style.textTertiary; anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // ── Per-matière breakdown ─────────────────────────────────
                    Text {
                        text: "Détail par matière"
                        font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                        visible: parent.arch && parent.arch.matieres && parent.arch.matieres.length > 0
                    }

                    Repeater {
                        model: parent.arch ? parent.arch.matieres : []
                        delegate: Rectangle {
                            width: step3Scroll.width
                            height: matCol.implicitHeight + 20
                            radius: 12; color: Style.bgWhite
                            border.color: Style.borderLight; border.width: 1

                            Column {
                                id: matCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 8

                                // Header
                                Row {
                                    width: parent.width; spacing: 8
                                    Text { text: "📚"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.nom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "·"; font.pixelSize: 13; color: Style.textTertiary; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.niveauNom; font.pixelSize: 11; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                                    Item { width: 1; height: 1 }  // spacer
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Présence : " + modelData.presenceRate + "%"
                                        font.pixelSize: 11; font.bold: true
                                        color: modelData.presenceRate >= 75 ? "#16A34A" : modelData.presenceRate >= 50 ? "#D97706" : "#DC2626"
                                    }
                                }

                                // Sessions bar
                                Row {
                                    spacing: 8
                                    Text {
                                        text: "Cours : " + modelData.coursValides + "/" + modelData.coursTotal + " validés"
                                        font.pixelSize: 11; color: Style.textSecondary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Rectangle {
                                        width: 120; height: 6; radius: 3
                                        color: Style.bgTertiary
                                        anchors.verticalCenter: parent.verticalCenter
                                        Rectangle {
                                            width: modelData.coursTotal > 0 ? parent.width * modelData.coursValides / modelData.coursTotal : 0
                                            height: parent.height; radius: parent.radius
                                            color: "#16A34A"
                                        }
                                    }
                                }

                                // Exams
                                Repeater {
                                    model: modelData.examens
                                    delegate: Row {
                                        spacing: 6
                                        Text {
                                            text: modelData.notesEntrees ? "✅" : "⚠️"
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            text: modelData.titre + " (" + modelData.date + ") — "
                                                  + (modelData.notesEntrees
                                                     ? "Notes saisies (" + modelData.notesSaisies + "/" + modelData.totalPart + ")"
                                                     : modelData.totalPart > 0
                                                       ? "Notes incomplètes (" + modelData.notesSaisies + "/" + modelData.totalPart + ")"
                                                       : "Aucune participation enregistrée")
                                            font.pixelSize: 11
                                            color: modelData.notesEntrees ? "#16A34A" : "#D97706"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Incomplete sessions ───────────────────────────────────
                    Rectangle {
                        width: parent.width
                        visible: incomplete && incomplete.length > 0
                        height: visible ? incompl3Col.implicitHeight + 24 : 0
                        radius: 12; color: "#FFF7ED"
                        border.color: "#F97316"; border.width: 1

                        Column {
                            id: incompl3Col
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 8
                            Row {
                                spacing: 8
                                Text { text: "⚠️"; font.pixelSize: 14 }
                                Text {
                                    text: (incomplete ? incomplete.length : 0) + " séance(s) sans enregistrement de présence"
                                    font.pixelSize: 13; font.bold: true; color: "#C2410C"
                                }
                            }
                            Repeater {
                                model: incomplete
                                delegate: Row {
                                    spacing: 8
                                    Text { text: "•"; font.pixelSize: 12; color: "#9A3412" }
                                    Text {
                                        text: "[" + modelData.type + "] " + modelData.titre + " — " + modelData.date
                                        font.pixelSize: 12; color: "#9A3412"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Step 4: Rapports
            ScrollView {
                id: step4Scroll
                anchors.fill: parent; anchors.margins: 24
                visible: currentStep === 4
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: step4Scroll.width
                    spacing: 16

                    // Computed from progressions
                    property int nbPromus: {
                        var c = 0
                        for (var i = 0; i < progressions.length; i++)
                            if (progressions[i].resultat === "Réussi" && progressions[i].niveauSuivantId > 0) c++
                        return c
                    }
                    property int nbDiplomesStep: {
                        var c = 0
                        for (var i = 0; i < progressions.length; i++)
                            if (progressions[i].resultat === "Réussi" && progressions[i].niveauSuivantId <= 0) c++
                        return c
                    }
                    property int nbRedoublants: {
                        var c = 0
                        for (var i = 0; i < progressions.length; i++)
                            if (progressions[i].resultat === "Redoublant") c++
                        return c
                    }

                    Text {
                        text: "Résumé des actions"
                        font.pixelSize: 16; font.bold: true; color: Style.textPrimary
                    }

                    Grid {
                        width: parent.width; columns: 3; spacing: 12

                        Repeater {
                            model: [
                                { label: "Promus",      icon: "↑", value: parent.parent.nbPromus,      color: "#F0FDF4", accent: "#16A34A" },
                                { label: "Redoublants", icon: "↩", value: parent.parent.nbRedoublants, color: "#FFF1F2", accent: "#E11D48" },
                                { label: "Diplômés",    icon: "🎓", value: parent.parent.nbDiplomesStep, color: "#FAF5FF", accent: "#7C3AED" }
                            ]
                            delegate: Rectangle {
                                width: (step4Scroll.width - 24) / 3; height: 80
                                radius: 12; color: modelData.color
                                border.color: Qt.rgba(0,0,0,0.06); border.width: 1

                                Column {
                                    anchors.centerIn: parent; spacing: 6
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "" + modelData.value
                                        font.pixelSize: 26; font.bold: true; color: modelData.accent
                                    }
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 4
                                        Text { text: modelData.icon; font.pixelSize: 13 }
                                        Text { text: modelData.label; font.pixelSize: 12; font.bold: true; color: modelData.accent }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Après la clôture"
                        font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                    }

                    Repeater {
                        model: [
                            "Une nouvelle année scolaire sera créée",
                            "Les " + step4Summary.nbPromus + " élèves promus seront inscrits au niveau suivant",
                            "Les " + step4Summary.nbRedoublants + " redoublants seront inscrits au même niveau",
                            "Les " + step4Summary.nbDiplomesStep + " diplômés ne recevront pas de nouvelle inscription"
                        ]
                        delegate: Row {
                            spacing: 10
                            Rectangle { width: 6; height: 6; radius: 3; color: Style.primary; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData; font.pixelSize: 13; color: Style.textSecondary; wrapMode: Text.WordWrap; width: step4Scroll.width - 20 }
                        }
                    }
                }

                // Helper for above Repeater to access parent values
                Item {
                    id: step4Summary
                    property int nbPromus: {
                        var c = 0
                        for (var i = 0; i < progressions.length; i++)
                            if (progressions[i].resultat === "Réussi" && progressions[i].niveauSuivantId > 0) c++
                        return c
                    }
                    property int nbDiplomesStep: {
                        var c = 0
                        for (var i = 0; i < progressions.length; i++)
                            if (progressions[i].resultat === "Réussi" && progressions[i].niveauSuivantId <= 0) c++
                        return c
                    }
                    property int nbRedoublants: {
                        var c = 0
                        for (var i = 0; i < progressions.length; i++)
                            if (progressions[i].resultat === "Redoublant") c++
                        return c
                    }
                }
            }

            // Step 5: Confirmation
            ScrollView {
                id: step5Scroll
                anchors.fill: parent; anchors.margins: 24
                visible: currentStep === 5
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: step5Scroll.width
                    spacing: 16

                    Text {
                        text: "Paramètres de la nouvelle année scolaire"
                        font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                    }

                    // New year label
                    Column {
                        width: parent.width; spacing: 6
                        Text { text: "Libellé de l'année"; font.pixelSize: 12; color: Style.textSecondary }
                        Rectangle {
                            width: parent.width; height: 44; radius: 10
                            color: Style.bgWhite
                            border.color: labelInput.activeFocus ? Style.primary : Style.borderMedium
                            border.width: labelInput.activeFocus ? 2 : 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            TextInput {
                                id: labelInput
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                                text: newLabel
                                font.pixelSize: 13; color: Style.textPrimary
                                selectByMouse: true
                                cursorVisible: activeFocus
                                onTextChanged: { newLabel = text; libelleAutoFill = false }
                            }
                            Text {
                                visible: labelInput.text === ""
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
                                text: "Ex : 2026-2027"; font.pixelSize: 13; color: Style.textTertiary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: labelInput.forceActiveFocus()
                            }
                        }
                    }

                    Row {
                        width: parent.width; spacing: 12

                        DateField {
                            id: dateField5Debut
                            width: (parent.width - 12) / 2
                            label: "DATE DE DÉBUT"
                            fieldColor: Style.bgWhite
                            onDateStringChanged: {
                                newDebut = dateString
                                if (isValid && libelleAutoFill) root.autoLibelle()
                            }
                        }

                        DateField {
                            id: dateField5Fin
                            width: (parent.width - 12) / 2
                            label: "DATE DE FIN"
                            fieldColor: Style.bgWhite
                            onDateStringChanged: {
                                newFin = dateString
                                if (isValid && libelleAutoFill) root.autoLibelle()
                            }
                        }
                    }

                    // Warning important
                    Rectangle {
                        width: parent.width; height: impWarn.implicitHeight + 24
                        radius: 12; color: "#FFFBEB"
                        border.color: "#F59E0B"; border.width: 1

                        Column {
                            id: impWarn
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 8
                            Row {
                                spacing: 8
                                Text { text: "⚠️"; font.pixelSize: 14 }
                                Text { text: "Avertissement Important"; font.pixelSize: 14; font.bold: true; color: "#B45309" }
                            }
                            Text {
                                width: parent.width
                                text: "Une fois la clôture effectuée, il sera <b>impossible de revenir en arrière</b>. Assurez-vous d'avoir vérifié toutes les données et effectué une sauvegarde complète avant de continuer."
                                textFormat: Text.RichText; font.pixelSize: 13; color: "#92400E"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // Final close button
                    Rectangle {
                        width: parent.width; height: 52; radius: 14
                        color: step5Valid ? "#DC2626" : Style.borderMedium

                        Behavior on color { ColorAnimation { duration: 200 } }

                        Row {
                            anchors.centerIn: parent; spacing: 10
                            Text { text: "🔒"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: "CLÔTURER L'ANNÉE SCOLAIRE " + (stats ? stats.anneeActiveLibelle.toUpperCase() : "")
                                font.pixelSize: 13; font.bold: true; color: "white"
                                font.letterSpacing: 0.5
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: step5Valid && !yearClosureController.isLoading
                            cursorShape: step5Valid ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                            onClicked: {
                                // Build the final progressions payload
                                var payload = []
                                for (var i = 0; i < progressions.length; i++) {
                                    var p = progressions[i]
                                    payload.push({
                                        inscriptionId:  p.inscriptionId,
                                        eleveId:        p.eleveId,
                                        niveauActuelId: p.niveauActuelId,
                                        categorie:      p.categorie,
                                        resultat:       p.resultat,
                                        niveauSuivantId: p.resultat === "Réussi" ? p.niveauSuivantId : 0
                                    })
                                }
                                yearClosureController.executeYearClosure(newLabel, newDebut, newFin, payload)
                            }
                        }
                    }
                }
            }
        }

        // ── Footer navigation ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 72
            color: Style.bgWhite
            radius: 20

            // Top corners square
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20
                color: Style.bgWhite
            }

            // Thin top separator
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: Style.borderLight
            }

            RowLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 12

                // Précédent
                Rectangle {
                    width: 120; height: 40; radius: 10
                    color: currentStep > 1 ? Style.bgPage : "transparent"
                    border.color: currentStep > 1 ? Style.borderMedium : "transparent"; border.width: 1
                    visible: currentStep > 1

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "‹"; font.pixelSize: 16; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Précédent"; font.pixelSize: 13; color: Style.textSecondary }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (currentStep > 1) currentStep--
                    }
                }

                Item { Layout.fillWidth: true }

                // Step counter
                Text {
                    text: "Étape " + currentStep + " sur " + totalSteps
                    font.pixelSize: 12; color: Style.textTertiary
                }

                Item { Layout.fillWidth: true }

                // Annuler (only step 1)
                Rectangle {
                    visible: currentStep === 1
                    width: 100; height: 40; radius: 10
                    color: Style.bgPage
                    border.color: Style.borderMedium; border.width: 1
                    Text { anchors.centerIn: parent; text: "Annuler"; font.pixelSize: 13; color: Style.textSecondary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                }

                // Suivant (steps 1-4)
                Rectangle {
                    visible: currentStep < 5
                    width: 120; height: 40; radius: 10
                    color: {
                        if (currentStep === 2 && !step2Valid) return Style.borderLight
                        return Style.textPrimary
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "Suivant"; font.pixelSize: 13; font.bold: true; color: "white" }
                        Text { text: "›"; font.pixelSize: 16; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !(currentStep === 2 && !step2Valid)
                        cursorShape: (currentStep === 2 && !step2Valid) ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (currentStep < 5) {
                                if (currentStep === 2)
                                    yearClosureController.loadArchivageStats()
                                currentStep++
                                if (currentStep === 5)
                                    Qt.callLater(function() { labelInput.forceActiveFocus() })
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
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 400; padding: 24
        modal: true

        background: Rectangle { radius: 14; color: Style.bgWhite }

        Column {
            width: parent.width; spacing: 16

            Row {
                spacing: 10
                Text { text: "❌"; font.pixelSize: 18 }
                Text { text: "Erreur"; font.pixelSize: 16; font.bold: true; color: Style.textPrimary }
            }

            Text {
                id: errorText
                width: parent.width
                font.pixelSize: 13; color: Style.textSecondary
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width; height: 40; radius: 10
                color: Style.textPrimary
                Text { anchors.centerIn: parent; text: "Fermer"; font.pixelSize: 13; font.bold: true; color: "white" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: errorPopup.close() }
            }
        }
    }
}
