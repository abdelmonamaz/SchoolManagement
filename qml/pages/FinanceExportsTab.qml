import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform as Platform
import UI.Components

Item {
    id: tab
    required property var page

    implicitHeight: mainCol.implicitHeight

    // ── State ─────────────────────────────────────────────────────────────────
    property int    exportMonth:   new Date().getMonth() + 1
    property int    exportYear:    new Date().getFullYear()
    property int    exerciceYear:  new Date().getFullYear()
    property string pendingExport: ""
    property bool   exporting:     false
    property string toastMsg:      ""
    property bool   toastError:    false
    property bool   toastVisible:  false

    // ── Exercice range ────────────────────────────────────────────────────────
    function getExerciceRange(startYear) {
        var assoc = setupController.associationData
        var debut = assoc.exerciceDebut || "01-01"
        var fin   = assoc.exerciceFin   || "12-31"
        if (debut.length >= 8) {
            var sy = parseInt(debut.substring(0, 4))
            var ey = parseInt(fin.substring(0, 4))
            return { from: debut, to: fin, label: sy === ey ? String(sy) : sy + "-" + ey }
        }
        var dm = parseInt(debut.split("-")[0])
        var fm = parseInt(fin.split("-")[0])
        var endYear = (fm < dm) ? startYear + 1 : startYear
        return {
            from:  startYear + "-" + debut,
            to:    endYear   + "-" + fin,
            label: startYear === endYear ? String(startYear) : startYear + "-" + endYear
        }
    }

    readonly property var currentExercice: getExerciceRange(exerciceYear)

    readonly property var monthNames: [
        qsTr("Janvier"), qsTr("Février"), qsTr("Mars"), qsTr("Avril"),
        qsTr("Mai"), qsTr("Juin"), qsTr("Juillet"), qsTr("Août"),
        qsTr("Septembre"), qsTr("Octobre"), qsTr("Novembre"), qsTr("Décembre")
    ]
    readonly property var yearList: {
        var cur = new Date().getFullYear(); var list = []
        for (var y = cur + 1; y >= 2020; y--) list.push(y)
        return list
    }

    // ── File dialog ───────────────────────────────────────────────────────────
    Platform.FileDialog {
        id: saveDialog
        title: qsTr("Enregistrer le fichier CSV")
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["Fichiers CSV (*.csv)", "Tous les fichiers (*)"]
        defaultSuffix: "csv"
        onAccepted: {
            var path = saveDialog.file.toString()
            path = path.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "")
            path = decodeURIComponent(path)
            var nom = setupController.associationData.nomAssociation || ""
            tab.exporting = true
            switch (tab.pendingExport) {
                case "paiements":   financeController.exportMonthlyPaiementsCSV(tab.exportMonth, tab.exportYear, nom, path); break
                case "dons_m":      financeController.exportMonthlyDonsCSV(tab.exportMonth, tab.exportYear, nom, path); break
                case "depenses":    financeController.exportMonthlyDepensesCSV(tab.exportMonth, tab.exportYear, nom, path); break
                case "salaires":    financeController.exportMonthlySalairesCSV(tab.exportMonth, tab.exportYear, nom, path); break
                case "dons_annuel": financeController.exportRegistreDonsAnnuelCSV(tab.currentExercice.from, tab.currentExercice.to, nom, path); break
                case "caisse":      financeController.exportLivreCaisseCSV(tab.currentExercice.from, tab.currentExercice.to, nom, path); break
                case "bilan":       financeController.exportBilanExerciceCSV(tab.currentExercice.from, tab.currentExercice.to, nom, path); break
            }
        }
        onRejected: { tab.exporting = false; tab.pendingExport = "" }
    }

    // ── Toast ─────────────────────────────────────────────────────────────────
    Timer {
        id: toastTimer; interval: 3500
        onTriggered: tab.toastVisible = false
    }
    function showToast(msg, isError) {
        tab.toastMsg = msg; tab.toastError = isError
        tab.toastVisible = true; toastTimer.restart()
    }

    Connections {
        target: financeController
        function onExportSucceeded(message) {
            tab.exporting = false; tab.pendingExport = ""
            tab.showToast(message, false)
        }
        function onExportFailed(error) {
            tab.exporting = false; tab.pendingExport = ""
            tab.showToast("Erreur : " + error, true)
        }
    }

    // ── Toast overlay ─────────────────────────────────────────────────────────
    Rectangle {
        z: 100
        anchors.bottom: parent.bottom; anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: toastRow.implicitWidth + 32; height: 40; radius: 20
        color: tab.toastError ? Style.errorColor : Style.successColor
        visible: tab.toastVisible
        opacity: tab.toastVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Row {
            id: toastRow; anchors.centerIn: parent; spacing: 8
            IconLabel { iconName: tab.toastError ? "alert" : "check"; iconSize: 14; iconColor: "white" }
            Text { text: tab.toastMsg; font.pixelSize: 11; font.weight: Font.Bold; color: "white" }
        }
    }

    // ── Main content ──────────────────────────────────────────────────────────
    Column {
        id: mainCol
        width: parent.width
        spacing: 0

        // ── Card wrapper ──────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: innerCol.height + 48
            radius: Style.radiusRound
            color: Style.bgWhite
            border.color: Style.borderLight

            Column {
                id: innerCol
                x: 24; y: 24
                width: parent.width - 48
                spacing: 28

                // Card header
                Column {
                    width: parent.width; spacing: 4
                    Text {
                        text: qsTr("Documents Légaux")
                        font.pixelSize: 16; font.bold: true; color: Style.textPrimary
                    }
                    Text {
                        text: qsTr("Exports CSV conformes à la réglementation tunisienne (Décret-loi 2011-88)")
                        font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary
                    }
                    Rectangle { width: parent.width; height: 1; color: Style.borderLight }
                }

                // ══ DOCUMENTS MENSUELS ═══════════════════════════════════════
                Column {
                    width: parent.width; spacing: 16

                    // Section header
                    Row {
                        width: parent.width; spacing: 10
                        Rectangle { width: 4; height: 18; radius: 2; color: Style.primary; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: qsTr("DOCUMENTS MENSUELS")
                            font.pixelSize: 11; font.weight: Font.Black
                            font.letterSpacing: 1; color: Style.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Period selector
                    Row {
                        spacing: 10

                        Text {
                            text: qsTr("Période :"); font.pixelSize: 12; color: Style.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 130; height: 36; radius: 10
                            color: Style.bgPage; border.color: Style.borderLight
                            Row {
                                anchors.fill: parent; anchors.margins: 8; spacing: 6
                                ComboBox {
                                    id: monthCombo
                                    width: parent.width - 22
                                    height: parent.height
                                    model: tab.monthNames
                                    background: Item {}
                                    indicator: Item {}
                                    contentItem: Text {
                                        text: monthCombo.displayText
                                        font.pixelSize: 12; color: Style.textPrimary
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    delegate: ItemDelegate {
                                        width: monthCombo.width
                                        contentItem: Text { text: modelData; font.pixelSize: 12; color: Style.textPrimary }
                                    }
                                    Component.onCompleted: currentIndex = tab.exportMonth - 1
                                    onActivated: tab.exportMonth = index + 1
                                }
                                IconLabel {
                                    anchors.verticalCenter: parent.verticalCenter
                                    iconName: "chevron-down"; iconSize: 10; iconColor: Style.textTertiary
                                }
                            }
                        }

                        Rectangle {
                            width: 130; height: 36; radius: 10
                            color: Style.bgPage; border.color: Style.borderLight
                            Row {
                                anchors.fill: parent; anchors.margins: 8; spacing: 6
                                ComboBox {
                                    id: yearCombo
                                    width: parent.width - 22
                                    height: parent.height
                                    model: tab.yearList
                                    background: Item {}
                                    indicator: Item {}
                                    contentItem: Text {
                                        text: yearCombo.displayText
                                        font.pixelSize: 12; color: Style.textPrimary
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    delegate: ItemDelegate {
                                        width: yearCombo.width
                                        contentItem: Text { text: modelData; font.pixelSize: 12; color: Style.textPrimary }
                                    }
                                    Component.onCompleted: {
                                        for (var i = 0; i < tab.yearList.length; i++) {
                                            if (tab.yearList[i] === tab.exportYear) { currentIndex = i; break }
                                        }
                                    }
                                    onActivated: tab.exportYear = tab.yearList[index]
                                }
                                IconLabel {
                                    anchors.verticalCenter: parent.verticalCenter
                                    iconName: "chevron-down"; iconSize: 10; iconColor: Style.textTertiary
                                }
                            }
                        }
                    }

                    // 4 monthly cards
                    Row {
                        width: parent.width; spacing: 12
                        ExportDocCard {
                            width: (parent.width - 36) / 4
                            docIcon: "wallet"; colorKey: "primary"
                            docTitle: qsTr("Paiements Scolarité")
                            docDesc: qsTr("Paiements mensuels reçus des élèves avec N° reçu")
                            isLoading: tab.exporting && tab.pendingExport === "paiements"
                            onGenerate: { tab.pendingExport = "paiements"; saveDialog.open() }
                        }
                        ExportDocCard {
                            width: (parent.width - 36) / 4
                            docIcon: "heart"; colorKey: "success"
                            docTitle: qsTr("Dons du Mois")
                            docDesc: qsTr("Donations enregistrées ce mois avec identité donateur")
                            isLoading: tab.exporting && tab.pendingExport === "dons_m"
                            onGenerate: { tab.pendingExport = "dons_m"; saveDialog.open() }
                        }
                        ExportDocCard {
                            width: (parent.width - 36) / 4
                            docIcon: "receipt"; colorKey: "error"
                            docTitle: qsTr("Dépenses")
                            docDesc: qsTr("Charges et dépenses mensuelles par catégorie")
                            isLoading: tab.exporting && tab.pendingExport === "depenses"
                            onGenerate: { tab.pendingExport = "depenses"; saveDialog.open() }
                        }
                        ExportDocCard {
                            width: (parent.width - 36) / 4
                            docIcon: "users"; colorKey: "warning"
                            docTitle: qsTr("Salaires Personnel")
                            docDesc: qsTr("Paiements du personnel pour le mois sélectionné")
                            isLoading: tab.exporting && tab.pendingExport === "salaires"
                            onGenerate: { tab.pendingExport = "salaires"; saveDialog.open() }
                        }
                    }
                }

                // Separator
                Rectangle { width: parent.width; height: 1; color: Style.borderLight }

                // ══ EXERCICE COMPTABLE ════════════════════════════════════════
                Column {
                    width: parent.width; spacing: 16

                    // Section header
                    Row {
                        width: parent.width; spacing: 10
                        Rectangle { width: 4; height: 18; radius: 2; color: Style.successColor; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: qsTr("DOCUMENTS ANNUELS — EXERCICE COMPTABLE")
                            font.pixelSize: 11; font.weight: Font.Black
                            font.letterSpacing: 1; color: Style.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Exercice selector
                    Row {
                        spacing: 10

                        Text {
                            text: qsTr("Exercice :"); font.pixelSize: 12; color: Style.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 130; height: 36; radius: 10
                            color: Style.bgPage; border.color: Style.borderLight
                            Row {
                                anchors.fill: parent; anchors.margins: 8; spacing: 6
                                ComboBox {
                                    id: exerciceCombo
                                    width: parent.width - 22
                                    height: parent.height
                                    model: tab.yearList
                                    background: Item {}
                                    indicator: Item {}
                                    contentItem: Text {
                                        text: exerciceCombo.displayText
                                        font.pixelSize: 12; color: Style.textPrimary
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    delegate: ItemDelegate {
                                        width: exerciceCombo.width
                                        contentItem: Text { text: modelData; font.pixelSize: 12; color: Style.textPrimary }
                                    }
                                    Component.onCompleted: {
                                        for (var i = 0; i < tab.yearList.length; i++) {
                                            if (tab.yearList[i] === tab.exerciceYear) { currentIndex = i; break }
                                        }
                                    }
                                    onActivated: tab.exerciceYear = tab.yearList[index]
                                }
                                IconLabel {
                                    anchors.verticalCenter: parent.verticalCenter
                                    iconName: "chevron-down"; iconSize: 10; iconColor: Style.textTertiary
                                }
                            }
                        }

                        // Date range badge
                        Rectangle {
                            height: 36; radius: 10
                            width: badgeRow.implicitWidth + 20
                            color: Style.successBg; border.color: Style.successColor
                            Row {
                                id: badgeRow; anchors.centerIn: parent; spacing: 6
                                IconLabel { iconName: "calendar"; iconSize: 12; iconColor: Style.successColor }
                                Text {
                                    text: {
                                        var r = tab.currentExercice
                                        var fd = r.from.split("-"); var td = r.to.split("-")
                                        var fromFr = (fd.length>=3 ? fd[2]+"/"+fd[1]+"/"+fd[0] : r.from)
                                        var toFr   = (td.length>=3 ? td[2]+"/"+td[1]+"/"+td[0] : r.to)
                                        return fromFr + " → " + toFr
                                    }
                                    font.pixelSize: 11; font.weight: Font.Bold; color: Style.successColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "(" + qsTr("Exercice") + " " + tab.currentExercice.label + ")"
                                    font.pixelSize: 9; color: Style.successColor; font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // 3 annual cards
                    Row {
                        width: parent.width; spacing: 12
                        ExportDocCard {
                            width: (parent.width - 24) / 3
                            docIcon: "book"; colorKey: "primary"
                            docTitle: qsTr("Registre des Dons")
                            docDesc: qsTr("Registre légal annuel avec identité complète des donateurs (exigé par loi)")
                            isLoading: tab.exporting && tab.pendingExport === "dons_annuel"
                            onGenerate: { tab.pendingExport = "dons_annuel"; saveDialog.open() }
                        }
                        ExportDocCard {
                            width: (parent.width - 24) / 3
                            docIcon: "history"; colorKey: "success"
                            docTitle: qsTr("Livre de Caisse")
                            docDesc: qsTr("Toutes les opérations financières de l'exercice avec solde cumulé")
                            isLoading: tab.exporting && tab.pendingExport === "caisse"
                            onGenerate: { tab.pendingExport = "caisse"; saveDialog.open() }
                        }
                        ExportDocCard {
                            width: (parent.width - 24) / 3
                            docIcon: "calculator"; colorKey: "neutral"
                            docTitle: qsTr("Bilan de l'Exercice")
                            docDesc: qsTr("Synthèse entrées/sorties par catégorie avec solde net de l'exercice")
                            isLoading: tab.exporting && tab.pendingExport === "bilan"
                            onGenerate: { tab.pendingExport = "bilan"; saveDialog.open() }
                        }
                    }
                }

                Item { height: 8 }
            }
        }
    }
}
