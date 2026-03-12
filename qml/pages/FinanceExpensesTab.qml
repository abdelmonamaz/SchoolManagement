import QtQuick
import QtQuick.Layouts
import UI.Components

AppCard {
    id: tab
    required property var page

    // ── Local state ──────────────────────────────────────────────────────────
    property string viewMode: "depenses" // "depenses" ou "personnel"

    // ── Helpers ───────────────────────────────────────────────────────────────
    function isoToFr(d) {
        if (!d || d === "") return "—"
        var p = d.split("-"); if (p.length < 3) return d
        return p[2] + "/" + p[1] + "/" + p[0]
    }

    // ── Filtered depenses ─────────────────────────────────────────────────────
    readonly property var filteredDepenses: {
        var deps = financeController.depenses
        var q = page.searchTerm.toLowerCase()
        if (q === "") return deps
        var result = []
        for (var i = 0; i < deps.length; i++) {
            if (deps[i].libelle.toLowerCase().indexOf(q) >= 0 ||
                deps[i].categorie.toLowerCase().indexOf(q) >= 0 ||
                (deps[i].notes && deps[i].notes.toLowerCase().indexOf(q) >= 0))
                result.push(deps[i])
        }
        return result
    }

    // ── Filtered personnel ────────────────────────────────────────────────────
    readonly property var allPersonnelRows: {
        var staff = staffController.personnel
        var pays = financeController.personnelPaymentsForJournal
        var q = page.searchTerm.toLowerCase()
        var result = []

        var payMap = {}
        for (var i = 0; i < pays.length; i++) {
            payMap[pays[i].personnelId] = pays[i]
        }

        for (var j = 0; j < staff.length; j++) {
            var s = staff[j]
            var nomComplet = (s.prenom + " " + s.nom).toLowerCase()
            if (q !== "" && nomComplet.indexOf(q) < 0) continue

            var p = payMap[s.id]
            var sommeDue = p ? p.sommeDue : 0
            var sommePaye = p ? p.sommePaye : 0
            var reste = Math.max(0, sommeDue - sommePaye)
            var status = "pending"
            if (sommeDue > 0) {
                if (sommePaye >= sommeDue) status = "paid"
                else if (sommePaye > 0) status = "partial"
            } else if (sommePaye > 0) {
                status = "paid" // a payé qque chose même si due est 0
            }

            result.push({
                id: s.id, nom: s.nom, prenom: s.prenom, poste: s.poste, modePaie: s.modePaie,
                joursTravail: s.joursTravail, valeurBase: s.valeurBase,
                sommeDue: sommeDue, sommePaye: sommePaye, reste: reste, status: status,
                staffObj: s, paymentObj: p
            })
        }
        return result
    }

    // ── AppCard header ────────────────────────────────────────────────────────
    title:    (tab.viewMode === "depenses" ? "Dépenses" : "Paiement Personnel") + " — " + page.selectedMonth + " " + page.selectedYear
    subtitle: tab.viewMode === "depenses" ? "Charges enregistrées ce mois" : "Suivi des paiements du personnel"

    headerAction: Component {
        Row {
            spacing: 8
            Rectangle {
                width: 110; height: 32; radius: 8
                color: tab.viewMode === "depenses" ? Style.primary : Style.bgPage
                border.color: tab.viewMode === "depenses" ? Style.primary : Style.borderLight
                Text {
                    anchors.centerIn: parent; text: qsTr("DÉPENSES")
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: tab.viewMode === "depenses" ? "white" : Style.textSecondary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: tab.viewMode = "depenses"
                }
            }
            Rectangle {
                width: 110; height: 32; radius: 8
                color: tab.viewMode === "personnel" ? Style.primary : Style.bgPage
                border.color: tab.viewMode === "personnel" ? Style.primary : Style.borderLight
                Text {
                    anchors.centerIn: parent; text: qsTr("PERSONNEL")
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: tab.viewMode === "personnel" ? "white" : Style.textSecondary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tab.viewMode = "personnel"
                        staffController.currentMonth = page.selectedMonthIndex + 1
                        staffController.currentYear = page.selectedYear
                        staffController.loadPersonnel()
                    }
                }
            }
        }
    }

    // ── Column widths ─────────────────────────────────────────────────────────
    readonly property int wCateg:   110
    readonly property int wDate:    100
    readonly property int wMontant: 130
    readonly property int wActions:  72

    PaymentPopup {
        id: personnelPaymentModal
        show: false
        onSaveRequested: function(newSommeDue, newSommePaye, datePaiement, justificatifPath) {
            staffController.savePayment(
                personnelId, selectedMonth, selectedYear,
                newSommeDue, newSommePaye, datePaiement, justificatifPath
            )
            financeController.loadPersonnelPaymentsForJournal(selectedMonth, selectedYear)
            financeController.loadAnnualBalance(selectedYear)
            financeController.loadTotalBalance()
            show = false
        }
        onRecalculateRequested: {
            staffController.recalculateSommeDue(
                personnelId, selectedMonth, selectedYear
            )
        }
        onClose: show = false
    }

    Connections {
        target: staffController
        function onPaymentDataLoaded(data) {
            if (data.sommeDue !== undefined) {
                personnelPaymentModal.sommeDue = data.sommeDue
            }
            if (data.sommePaye !== undefined) {
                personnelPaymentModal.sommePaye = data.sommePaye
            }
        }
    }

    Column {
        width: parent.width; spacing: 16

        // Loading
        Item { width: parent.width; height: 48; visible: financeController.loading || staffController.loading
            Text { anchors.centerIn: parent; text: qsTr("Chargement…"); font.pixelSize: 13; color: Style.textTertiary } }

        // ── Empty state (Dépenses) ───────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 16
            visible: tab.viewMode === "depenses" && !financeController.loading && tab.filteredDepenses.length === 0
            Item { width: 1; height: 24 }
            Rectangle { width: 56; height: 56; radius: 20; color: Style.errorBg
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "receipt"; iconSize: 24; iconColor: Style.errorColor } }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: page.searchTerm !== ""
                         ? "Aucun résultat pour \"" + page.searchTerm + "\""
                         : "Aucune dépense pour " + page.selectedMonth + " " + page.selectedYear
                   font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary }
            PrimaryButton { anchors.horizontalCenter: parent.horizontalCenter
                visible: page.searchTerm === ""
                text: qsTr("Enregistrer une dépense"); iconName: "plus"
                onClicked: page.showExpenseModal = true }
            Item { width: 1; height: 24 }
        }

        // ── Empty state (Personnel) ───────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 16
            visible: tab.viewMode === "personnel" && !staffController.loading && tab.allPersonnelRows.length === 0
            Item { width: 1; height: 24 }
            Rectangle { width: 56; height: 56; radius: 20; color: Style.primaryBg
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "users"; iconSize: 24; iconColor: Style.primary } }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: page.searchTerm !== ""
                         ? "Aucun résultat pour \"" + page.searchTerm + "\""
                         : "Aucun membre du personnel enregistré."
                   font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary }
            Item { width: 1; height: 24 }
        }

        // ── Table header (Dépenses) ──────────────────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 40
            visible: tab.viewMode === "depenses" && tab.filteredDepenses.length > 0
            spacing: 12
            SectionLabel { Layout.fillWidth: true; text: qsTr("LIBELLÉ") }
            SectionLabel { Layout.preferredWidth: tab.wCateg;   text: qsTr("CATÉGORIE");  horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wDate;    text: qsTr("DATE");       horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wMontant; text: qsTr("MONTANT");    horizontalAlignment: Text.AlignHCenter }
            Item { Layout.preferredWidth: tab.wActions }
        }
        Separator { width: parent.width; visible: tab.viewMode === "depenses" && tab.filteredDepenses.length > 0 }

        // ── Table rows (Dépenses) ────────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 0; visible: tab.viewMode === "depenses"
            Repeater {
                model: tab.filteredDepenses
                delegate: Column {
                    width: parent.width
                    Rectangle {
                        width: parent.width; height: 64
                        color: dMa.containsMouse ? Style.bgPage : "transparent"
                        MouseArea { id: dMa; anchors.fill: parent; hoverEnabled: true; z: -1 }

                        RowLayout {
                            anchors.fill: parent; spacing: 12

                            // Libellé + notes/catégorie sous-texte
                            Column {
                                Layout.fillWidth: true; spacing: 3
                                Text { text: modelData.libelle
                                       font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                       elide: Text.ElideRight; width: parent.width }
                                Text {
                                    text: modelData.notes && modelData.notes !== ""
                                          ? modelData.notes : modelData.categorie
                                    font.pixelSize: 10; color: Style.textTertiary
                                    elide: Text.ElideRight; width: parent.width
                                }
                            }

                            // Catégorie (badge)
                            Item {
                                Layout.preferredWidth: tab.wCateg; height: 22
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.min(badgeLbl.implicitWidth + 16, tab.wCateg); height: 22; radius: 6
                                    color: Style.bgPage; border.color: Style.borderLight
                                    Text { id: badgeLbl; anchors.centerIn: parent; text: modelData.categorie
                                           font.pixelSize: 8; font.weight: Font.Black; color: Style.textSecondary }
                                }
                            }

                            // Date
                            Text {
                                Layout.preferredWidth: tab.wDate
                                text: tab.isoToFr(modelData.date)
                                font.pixelSize: 11; font.weight: Font.Medium; color: Style.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // Montant
                            Text {
                                Layout.preferredWidth: tab.wMontant
                                text: modelData.montant.toFixed(2) + " DT"
                                font.pixelSize: 13; font.weight: Font.Black; color: Style.errorColor
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // Actions
                            RowLayout {
                                Layout.preferredWidth: tab.wActions; spacing: 4
                                IconButton {
                                    iconName: "edit"; iconSize: 16; hoverColor: Style.primary
                                    onClicked: {
                                        page.editingDepense     = modelData
                                        page.showEditExpenseModal = true
                                    }
                                }
                                IconButton {
                                    iconName: "trash"; iconSize: 16; hoverColor: Style.errorColor
                                    onClicked: {
                                        page.deleteType      = "depense"
                                        page.deleteItemId    = modelData.id
                                        page.deleteItemName  = modelData.libelle
                                        page.showDeleteModal = true
                                    }
                                }
                            }
                        }
                    }
                    Separator { width: parent.width }
                }
            }
        }

        // ── Table header (Personnel) ─────────────────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 40
            visible: tab.viewMode === "personnel" && tab.allPersonnelRows.length > 0
            spacing: 12
            SectionLabel { Layout.fillWidth: true; text: qsTr("EMPLOYÉ") }
            SectionLabel { Layout.preferredWidth: 100; text: qsTr("SALAIRE / DUE");  horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: 88;  text: qsTr("PAYÉ");        horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: 100; text: qsTr("STATUT");      horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: 80;  text: qsTr("ACTION");      horizontalAlignment: Text.AlignHCenter }
        }
        Separator { width: parent.width; visible: tab.viewMode === "personnel" && tab.allPersonnelRows.length > 0 }

        // ── Table rows (Personnel) ────────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 0; visible: tab.viewMode === "personnel"
            Repeater {
                model: tab.allPersonnelRows
                delegate: Column {
                    width: parent.width
                    Rectangle {
                        width: parent.width; height: 64
                        color: sRowMa.containsMouse ? Style.bgPage : "transparent"
                        MouseArea { id: sRowMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
                        RowLayout { anchors.fill: parent; spacing: 12
                            Column { Layout.fillWidth: true; spacing: 3
                                Text { text: modelData.prenom + " " + modelData.nom
                                       font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                       elide: Text.ElideRight; width: parent.width }
                                Text { text: modelData.poste + " · " + modelData.modePaie
                                       font.pixelSize: 10; color: Style.textTertiary }
                            }
                            Text { Layout.preferredWidth: 100; text: modelData.sommeDue.toFixed(2) + " DT"
                                   horizontalAlignment: Text.AlignHCenter
                                   font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                            Text { Layout.preferredWidth: 88
                                   text: modelData.sommePaye > 0 ? modelData.sommePaye.toFixed(2) + " DT" : "—"
                                   horizontalAlignment: Text.AlignHCenter
                                   font.pixelSize: 12; font.weight: Font.Bold
                                   color: modelData.sommePaye > 0 ? Style.successColor : Style.textTertiary }
                            Item { Layout.preferredWidth: 100; implicitHeight: 24
                                Badge { anchors.centerIn: parent
                                    text: modelData.status === "paid"    ? "Payé"
                                        : modelData.status === "partial" ? "Partiel"
                                        :                                  "En attente"
                                    variant: modelData.status === "paid"    ? "success"
                                           : modelData.status === "partial" ? "warning" : "neutral" }
                            }
                            Item { Layout.preferredWidth: 80; implicitHeight: 56
                                Rectangle { anchors.centerIn: parent
                                    width: 70; height: 28; radius: 8
                                    color: payStaffBtn.containsMouse ? Style.primary : Style.primaryBg
                                    Text { anchors.centerIn: parent
                                           text: modelData.status === "paid" ? "MODIFIER" : "PAYER"
                                           font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.4
                                           color: payStaffBtn.containsMouse ? "white" : Style.primary }
                                    MouseArea { id: payStaffBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            personnelPaymentModal.personnelId = modelData.id
                                            personnelPaymentModal.personnelName = modelData.prenom + " " + modelData.nom
                                            personnelPaymentModal.selectedMonth = page.selectedMonthIndex + 1
                                            personnelPaymentModal.selectedYear = page.selectedYear
                                            personnelPaymentModal.modePaie = modelData.modePaie || "Heure"
                                            personnelPaymentModal.joursTravailDefault = modelData.joursTravail || 31
                                            personnelPaymentModal.valeurBase = modelData.valeurBase || 0
                                            
                                            // Request latest payment data
                                            staffController.loadPaymentData(modelData.id, page.selectedMonthIndex + 1, page.selectedYear)
                                            
                                            // Initialize with current known values
                                            personnelPaymentModal.sommeDue = modelData.sommeDue
                                            personnelPaymentModal.sommePaye = modelData.sommePaye

                                            if (modelData.paymentObj) {
                                                var ds = modelData.paymentObj.dateModification
                                                if (ds && ds.length > 10) ds = ds.substring(0, 10)
                                                personnelPaymentModal.currentDatePaiement = ds || ""
                                            } else {
                                                personnelPaymentModal.currentDatePaiement = ""
                                            }

                                            personnelPaymentModal.show = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Separator { width: parent.width }
                }
            }
        }


        // ── Résumé total ──────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            visible: tab.viewMode === "depenses" && tab.filteredDepenses.length > 0
            implicitHeight: totRow.implicitHeight + 20; radius: 14; color: Style.errorBg
            RowLayout {
                id: totRow
                anchors.fill: parent; anchors.verticalCenter: parent.verticalCenter;anchors.leftMargin: 16; anchors.rightMargin: 16;spacing: 8
                IconLabel { iconName: "calculator"; iconSize: 16; iconColor: Style.errorColor }
                Text { text: qsTr("TOTAL DÉPENSES"); font.pixelSize: 11; font.weight: Font.Black
                       color: Style.errorColor; Layout.fillWidth: true }
                Text {
                    text: {
                        var total = 0
                        for (var i = 0; i < tab.filteredDepenses.length; i++)
                            total += tab.filteredDepenses[i].montant
                        return total.toFixed(2) + " DT"
                    }
                    font.pixelSize: 16; font.weight: Font.Black; color: Style.errorColor
                }
            }
        }

        Rectangle {
            width: parent.width
            visible: tab.viewMode === "personnel" && tab.allPersonnelRows.length > 0
            implicitHeight: totStaffRow.implicitHeight + 20; radius: 14; color: Style.errorBg
            RowLayout {
                id: totStaffRow
                anchors.fill: parent; anchors.verticalCenter: parent.verticalCenter;anchors.leftMargin: 16; anchors.rightMargin: 16;spacing: 8
                IconLabel { iconName: "calculator"; iconSize: 16; iconColor: Style.errorColor }
                Text { text: qsTr("TOTAL SALAIRES VERSÉS"); font.pixelSize: 11; font.weight: Font.Black
                       color: Style.errorColor; Layout.fillWidth: true }
                Text {
                    text: {
                        var total = 0
                        for (var i = 0; i < tab.allPersonnelRows.length; i++)
                            total += tab.allPersonnelRows[i].sommePaye
                        return total.toFixed(2) + " DT"
                    }
                    font.pixelSize: 16; font.weight: Font.Black; color: Style.errorColor
                }
            }
        }
    }
}
