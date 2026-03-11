import QtQuick
import QtQuick.Layouts
import UI.Components

AppCard {
    id: tab
    required property var page

    Component.onCompleted: {
        financeController.loadAnnualBalanceForAccountingYear(page.selectedYear, page.selectedMonthIndex + 1)
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    function isoToFr(d) {
        if (!d || d === "") return "—"
        var p = d.split("-"); if (p.length < 3) return d
        return p[2] + "/" + p[1] + "/" + p[0]
    }
    function studentName(eleveId) {
        var list = studentController.students
        for (var i = 0; i < list.length; i++)
            if (list[i].id === eleveId)
                return list[i].prenom + " " + list[i].nom
        return "Élève #" + eleveId
    }
    function donateurName(donateurId) {
        var list = financeController.donateurs
        for (var i = 0; i < list.length; i++)
            if (list[i].id === donateurId) return list[i].nom
        return "Donateur #" + donateurId
    }
    function personnelName(personnelId) {
        var lists = [staffController.personnel, staffController.enseignants]
        for (var k = 0; k < lists.length; k++) {
            var list = lists[k]
            for (var i = 0; i < list.length; i++) {
                if (list[i].id === personnelId) {
                    var prenom = list[i].prenom || ""
                    var nom    = list[i].nom    || ""
                    return (prenom + " " + nom).trim() || ("Personnel #" + personnelId)
                }
            }
        }
        return "Personnel #" + personnelId
    }

    // ── Journal entries ──────────────────────────────────────────────────────
    readonly property var journalEntries: {
        var _pay      = financeController.payments
        var _dons     = financeController.dons
        var _staffPay = financeController.personnelPaymentsForJournal
        var _deps     = financeController.depenses
        var _personnel = staffController.personnel   // tracked dependency
        var _enseignants = staffController.enseignants
        var m = page.selectedMonthIndex + 1
        var y = page.selectedYear
        var entries = []

        // Student monthly payments (already filtered by month by controller)
        for (var i = 0; i < _pay.length; i++) {
            entries.push({
                date:   _pay[i].datePaiement,
                name:   studentName(_pay[i].eleveId),
                type:   "Scolarité",
                amount: _pay[i].montantPaye,
                flow:   "in"
            })
        }

        // Student enrollments (filter by month)
        var _enrollments = studentController.enrollmentsByYear
        if (_enrollments) {
            for (var e = 0; e < _enrollments.length; e++) {
                var enr = _enrollments[e]
                if (!enr.fraisInscriptionPaye || !enr.dateInscription) continue
                var edp = enr.dateInscription.split("-")
                if (edp.length < 3) continue
                if (parseInt(edp[1]) !== m || parseInt(edp[0]) !== y) continue
                entries.push({
                    date:   enr.dateInscription,
                    name:   studentName(enr.eleveId),
                    type:   "Frais Inscription",
                    amount: enr.montantInscription,
                    flow:   "in"
                })
            }
        }

        // Donations — filter by selected month
        for (var j = 0; j < _dons.length; j++) {
            var don = _dons[j]
            if (!don.dateDon) continue
            var dp = don.dateDon.split("-")
            if (dp.length < 3) continue
            if (parseInt(dp[1]) !== m || parseInt(dp[0]) !== y) continue
            var donMontant = don.montantEffectif !== undefined
                             ? don.montantEffectif
                             : (don.natureDon === "Nature" ? don.valeurEstimee : don.montant)
            var donType = "Don" + (don.natureDon === "Nature" ? " (Nature)" : "")
            entries.push({
                date:   don.dateDon,
                name:   donateurName(don.donateurId),
                type:   donType,
                amount: donMontant,
                flow:   "in"
            })
        }

        // Personnel salary payments — outgoing
        for (var k = 0; k < _staffPay.length; k++) {
            var sp = _staffPay[k]
            if (sp.sommePaye <= 0) continue
            entries.push({
                date:   sp.datePaiement || sp.dateModification || "",
                name:   personnelName(sp.personnelId),
                type:   "Salaire",
                amount: sp.sommePaye,
                flow:   "out"
            })
        }

        // Dépenses (already filtered by month by controller)
        for (var d = 0; d < _deps.length; d++) {
            var dep = _deps[d]
            entries.push({
                date:   dep.date || "",
                name:   dep.libelle,
                type:   dep.categorie || "Dépense",
                amount: dep.montant,
                flow:   "out"
            })
        }

        entries.sort(function(a, b) { return a.date > b.date ? -1 : a.date < b.date ? 1 : 0 })
        return entries
    }

    readonly property double totalIn: {
        var t = 0; var e = journalEntries
        for (var i = 0; i < e.length; i++) if (e[i].flow === "in") t += e[i].amount
        return t
    }
    readonly property double totalOut: {
        var t = 0; var e = journalEntries
        for (var i = 0; i < e.length; i++) if (e[i].flow === "out") t += e[i].amount
        return t
    }

    // ── AppCard header ───────────────────────────────────────────────────────
    title:    "Journal — " + page.selectedMonth + " " + page.selectedYear
    subtitle: "Vue consolidée des flux financiers du mois"

    Column {
        width: parent.width; spacing: 16

        Item { width: parent.width; height: 48; visible: financeController.loading
            Text { anchors.centerIn: parent; text: "Chargement…"; font.pixelSize: 13; color: Style.textTertiary } }

        Column { width: parent.width; spacing: 12
            visible: !financeController.loading && tab.journalEntries.length === 0
            Item { width: 1; height: 32 }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: "Aucune transaction pour " + page.selectedMonth + " " + page.selectedYear
                   font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary }
            Item { width: 1; height: 32 }
        }

        // ── Table header ─────────────────────────────────────────────────────
        RowLayout { width: parent.width; height: 40; visible: tab.journalEntries.length > 0
            SectionLabel { Layout.preferredWidth: 110; text: "DATE" }
            SectionLabel { Layout.fillWidth: true;     text: "BÉNÉFICIAIRE / DONATEUR" }
            SectionLabel { Layout.preferredWidth: 100; text: "TYPE" }
            SectionLabel { Layout.preferredWidth: 130; text: "MONTANT" }
            SectionLabel { Layout.preferredWidth: 56;  text: "FLUX"; horizontalAlignment: Text.AlignRight }
        }
        Separator { width: parent.width; visible: tab.journalEntries.length > 0 }

        // ── Rows ─────────────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 0
            Repeater {
                model: tab.journalEntries
                delegate: Column {
                    width: parent.width
                    Rectangle { width: parent.width; height: 60
                        color: jRowMa.containsMouse ? Style.bgPage : "transparent"
                        MouseArea { id: jRowMa; anchors.fill: parent; hoverEnabled: true }
                        RowLayout { anchors.fill: parent; spacing: 12
                            Text { Layout.preferredWidth: 110; text: tab.isoToFr(modelData.date)
                                   font.pixelSize: 11; font.bold: true; color: Style.textTertiary }
                            Text { Layout.fillWidth: true; text: modelData.name
                                   font.pixelSize: 13; font.bold: true; color: Style.textPrimary; elide: Text.ElideRight }
                            Text { Layout.preferredWidth: 100; text: modelData.type
                                   font.pixelSize: 9; font.weight: Font.Black
                                   color: modelData.flow === "out" ? Style.errorColor : Style.textSecondary
                                   font.letterSpacing: 1 }
                            Text {
                                Layout.preferredWidth: 130
                                text: (modelData.flow === "in" ? "+" : "−") + modelData.amount.toFixed(2) + " DT"
                                font.pixelSize: 13; font.weight: Font.Black
                                color: modelData.flow === "in" ? Style.successColor : Style.errorColor
                            }
                            Rectangle { Layout.preferredWidth: 56; width: 40; height: 40; radius: 12
                                color: modelData.flow === "in" ? Style.successBg : Style.errorBg
                                IconLabel { anchors.centerIn: parent
                                    iconName: modelData.flow === "in" ? "trending-up" : "trending-down"
                                    iconSize: 16
                                    iconColor: modelData.flow === "in" ? Style.successColor : Style.errorColor
                                }
                            }
                        }
                    }
                    Separator { width: parent.width }
                }
            }
        }

        // ── Summary bar ──────────────────────────────────────────────────────
        RowLayout {
            width: parent.width; spacing: 12
            visible: tab.journalEntries.length > 0

            Rectangle { Layout.fillWidth: true; height: 52; radius: 12
                color: Style.successBg; border.color: Style.successBorder
                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                    Text { Layout.fillWidth: true
                           text: "ENTRÉES — " + page.selectedMonth.toUpperCase() + " " + page.selectedYear
                           font.pixelSize: 10; font.weight: Font.Black; color: Style.successColor; font.letterSpacing: 0.5 }
                    Text { text: tab.totalIn.toFixed(2) + " DT"
                           font.pixelSize: 15; font.weight: Font.Black; color: Style.successColor }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 52; radius: 12
                color: Style.errorBg; border.color: Style.errorBorder
                visible: tab.totalOut > 0
                RowLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                    Text { Layout.fillWidth: true
                           text: "SORTIES — " + page.selectedMonth.toUpperCase() + " " + page.selectedYear
                           font.pixelSize: 10; font.weight: Font.Black; color: Style.errorColor; font.letterSpacing: 0.5 }
                    Text { text: tab.totalOut.toFixed(2) + " DT"
                           font.pixelSize: 15; font.weight: Font.Black; color: Style.errorColor }
                }
            }
        }

        // ── Bilan Annuel ──────────────────────────────────────────────────────
        Rectangle {
            width: parent.width; radius: 16
            implicitHeight: bilanAnnuelCol.implicitHeight + 32
            color: Style.bgPage; border.color: Style.borderLight
            visible: !!(financeController.annualBalance && financeController.annualBalance.libelle)

            Column {
                id: bilanAnnuelCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 12

                RowLayout {
                    width: parent.width
                    IconLabel { iconName: "calendar"; iconSize: 16; iconColor: Style.primary }
                    Text { Layout.fillWidth: true
                           text: "BILAN ANNUEL — " + (financeController.annualBalance.libelle || page.selectedYear)
                           font.pixelSize: 11; font.weight: Font.Black; color: Style.primary; font.letterSpacing: 0.5 }
                }

                RowLayout {
                    width: parent.width; spacing: 8
                    // Entrées annuelles
                    Rectangle {
                        Layout.fillWidth: true; height: 60; radius: 12; color: Style.successBg
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: "ENTRÉES " + (financeController.annualBalance.libelle || page.selectedYear)
                                   font.pixelSize: 8; font.weight: Font.Black; color: Style.successColor; font.letterSpacing: 0.5 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: (financeController.annualBalance.entrees || 0).toFixed(2) + " DT"
                                   font.pixelSize: 14; font.weight: Font.Black; color: Style.successColor }
                        }
                    }
                    // Sorties annuelles
                    Rectangle {
                        Layout.fillWidth: true; height: 60; radius: 12; color: Style.errorBg
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: "SORTIES " + (financeController.annualBalance.libelle || page.selectedYear)
                                   font.pixelSize: 8; font.weight: Font.Black; color: Style.errorColor; font.letterSpacing: 0.5 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: (financeController.annualBalance.sorties || 0).toFixed(2) + " DT"
                                   font.pixelSize: 14; font.weight: Font.Black; color: Style.errorColor }
                        }
                    }
                    // Solde annuel
                    Rectangle {
                        Layout.fillWidth: true; height: 60; radius: 12
                        color: (financeController.annualBalance.solde || 0) >= 0 ? Style.successBg : Style.errorBg
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: "SOLDE " + (financeController.annualBalance.libelle || page.selectedYear)
                                   font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.5
                                   color: (financeController.annualBalance.solde || 0) >= 0 ? Style.successColor : Style.errorColor }
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: {
                                       var s = financeController.annualBalance.solde || 0
                                       return (s >= 0 ? "+" : "") + s.toFixed(2) + " DT"
                                   }
                                   font.pixelSize: 14; font.weight: Font.Black
                                   color: (financeController.annualBalance.solde || 0) >= 0 ? Style.successColor : Style.errorColor }
                        }
                    }
                }

                // Détail annuel
                RowLayout {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: [
                            { lbl: "Scolarité",  val: financeController.annualBalance.scolarite || 0, pos: true },
                            { lbl: "Inscriptions", val: financeController.annualBalance.inscriptions || 0, pos: true },
                            { lbl: "Dons",       val: financeController.annualBalance.dons      || 0, pos: true },
                            { lbl: "Dépenses",   val: financeController.annualBalance.depenses  || 0, pos: false },
                            { lbl: "Salaires",   val: financeController.annualBalance.salaires  || 0, pos: false }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true; height: 40; radius: 10
                            color: Style.bgWhite; border.color: Style.borderLight
                            Column {
                                anchors.centerIn: parent; spacing: 1
                                Text { anchors.horizontalCenter: parent.horizontalCenter
                                       text: modelData.lbl
                                       font.pixelSize: 8; font.weight: Font.Black; color: Style.textTertiary }
                                Text { anchors.horizontalCenter: parent.horizontalCenter
                                       text: modelData.val.toFixed(0) + " DT"
                                       font.pixelSize: 10; font.weight: Font.Black
                                       color: modelData.pos ? Style.successColor : Style.errorColor }
                            }
                        }
                    }
                }
            }
        }

        // ── Bilan Total de l'Association ──────────────────────────────────────
        Rectangle {
            width: parent.width; radius: 16
            implicitHeight: bilanTotalCol.implicitHeight + 32
            color: Style.primaryBg; border.color: Style.primary

            Column {
                id: bilanTotalCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 12

                RowLayout {
                    width: parent.width
                    IconLabel { iconName: "trending-up"; iconSize: 16; iconColor: Style.primary }
                    Text { Layout.fillWidth: true
                           text: "BILAN TOTAL DE L'ASSOCIATION"
                           font.pixelSize: 11; font.weight: Font.Black; color: Style.primary; font.letterSpacing: 0.5 }
                }

                RowLayout {
                    width: parent.width; spacing: 8
                    Rectangle {
                        Layout.fillWidth: true; height: 64; radius: 12; color: Style.successBg
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: "TOTAL ENTRÉES"
                                   font.pixelSize: 8; font.weight: Font.Black; color: Style.successColor; font.letterSpacing: 0.5 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: (financeController.totalBalance.entrees || 0).toFixed(2) + " DT"
                                   font.pixelSize: 16; font.weight: Font.Black; color: Style.successColor }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 64; radius: 12; color: Style.errorBg
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: "TOTAL SORTIES"
                                   font.pixelSize: 8; font.weight: Font.Black; color: Style.errorColor; font.letterSpacing: 0.5 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: (financeController.totalBalance.sorties || 0).toFixed(2) + " DT"
                                   font.pixelSize: 16; font.weight: Font.Black; color: Style.errorColor }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 64; radius: 12
                        color: (financeController.totalBalance.solde || 0) >= 0 ? Style.successBg : Style.errorBg
                        border.color: (financeController.totalBalance.solde || 0) >= 0 ? Style.successBorder : Style.errorBorder
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: "SOLDE GLOBAL"
                                   font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.5
                                   color: (financeController.totalBalance.solde || 0) >= 0 ? Style.successColor : Style.errorColor }
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                   text: {
                                       var s = financeController.totalBalance.solde || 0
                                       return (s >= 0 ? "+" : "") + s.toFixed(2) + " DT"
                                   }
                                   font.pixelSize: 16; font.weight: Font.Black
                                   color: (financeController.totalBalance.solde || 0) >= 0 ? Style.successColor : Style.errorColor }
                        }
                    }
                }

                // Détail total
                RowLayout {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: [
                            { lbl: "Scolarité",  val: financeController.totalBalance.scolarite || 0, pos: true },
                            { lbl: "Inscriptions", val: financeController.totalBalance.inscriptions || 0, pos: true },
                            { lbl: "Dons",       val: financeController.totalBalance.dons      || 0, pos: true },
                            { lbl: "Dépenses",   val: financeController.totalBalance.depenses  || 0, pos: false },
                            { lbl: "Salaires",   val: financeController.totalBalance.salaires  || 0, pos: false }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true; height: 40; radius: 10
                            color: Style.bgWhite; border.color: Style.borderLight
                            Column {
                                anchors.centerIn: parent; spacing: 1
                                Text { anchors.horizontalCenter: parent.horizontalCenter
                                       text: modelData.lbl
                                       font.pixelSize: 8; font.weight: Font.Black; color: Style.textTertiary }
                                Text { anchors.horizontalCenter: parent.horizontalCenter
                                       text: modelData.val.toFixed(0) + " DT"
                                       font.pixelSize: 10; font.weight: Font.Black
                                       color: modelData.pos ? Style.successColor : Style.errorColor }
                            }
                        }
                    }
                }
            }
        }
    }
}
