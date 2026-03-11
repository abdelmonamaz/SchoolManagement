import QtQuick
import QtQuick.Layouts
import UI.Components

AppCard {
    id: tab
    required property var page   // reference to FinancePage root item

    // ── Local state ──────────────────────────────────────────────────────────
    property string statusFilter: "all"
    property int    currentPage:  0
    property string viewMode:     "mensuel" // "mensuel" or "inscription"

    // Reset page when filter / search change
    Connections {
        target: page
        function onSearchTermChanged() { tab.currentPage = 0 }
    }
    onStatusFilterChanged: currentPage = 0
    onViewModeChanged: {
        currentPage = 0
        statusFilter = "all"
    }
    onCurrentPageCountChanged: {
        if (currentPage >= currentPageCount)
            currentPage = Math.max(0, currentPageCount - 1)
    }

    EnrollmentEditModal {
        id: editEnrollmentModal
        niveaux: schoolingController.niveaux
    }

    Connections {
        target: studentController
        function onOperationSucceeded(message) {
            if (message === "Inscription mise à jour" || message === "Nouvelle année inscrite"
                    || message === "Inscription supprimée") {
                editEnrollmentModal.show = false
            }
        }
    }


    // ── Computed — active-year range check ──────────────────────────────────
    // Uses integer year*12+month to avoid UTC/local-time Date comparison bugs.
    // mensuel  : show from date_debut month onwards
    // inscription : show from date_debut - 1 month (pre-registration period)
    readonly property bool isInActiveYear: {
        var at = setupController.activeTarifs
        if (!at || !at.dateDebut || !at.dateFin) return false
        var selVal = page.selectedYear * 12 + (page.selectedMonthIndex + 1)
        var dp = at.dateDebut.split("-")
        var fp = at.dateFin.split("-")
        var debutVal = parseInt(dp[0]) * 12 + parseInt(dp[1])
        var finVal   = parseInt(fp[0]) * 12 + parseInt(fp[1])
        if (tab.viewMode === "inscription") debutVal -= 1
        return selVal >= debutVal && selVal <= finVal
    }

    // ── Computed — tarif helper ──────────────────────────────────────────────
    function tarifForCategorie(categorie) {
        if (!setupController.activeTarifs) return categorie === "Adulte" ? 250.0 : 150.0
        return categorie === "Adulte"
               ? setupController.activeTarifs.tarifAdulte
               : setupController.activeTarifs.tarifJeune
    }

    // ── Computed — all rows ──────────────────────────────────────────────────
    readonly property var allRows: {
        var _students = studentController.students
        var rows = []

        if (tab.viewMode === "mensuel") {
            var _payments = financeController.payments
            var _tarifs   = setupController.activeTarifs   // tracked for reactivity

            var payMap = {}
            for (var i = 0; i < _payments.length; i++) {
                var pay = _payments[i]
                var eid = pay.eleveId
                if (!payMap[eid]) payMap[eid] = 0
                payMap[eid] += pay.montantPaye
            }
            for (var j = 0; j < _students.length; j++) {
                var s = _students[j]
                if (!s.classeId || s.classeId <= 0) continue
                var montantDu    = tarifForCategorie(s.categorie)
                var montantPaye  = payMap[s.id] || 0
                var montantReste = Math.max(0, montantDu - montantPaye)
                var status = (montantReste <= 0) ? "paid"
                           : (montantPaye > 0)   ? "partial"
                           :                       "pending"
                rows.push({ id: s.id, nom: s.nom, prenom: s.prenom, categorie: s.categorie,
                            classeId: s.classeId, montantDu: montantDu,
                            montantPaye: montantPaye, montantReste: montantReste, status: status,
                            studentObj: s })
            }
        } else {
            var _enrollments = studentController.enrollmentsByYear
            var enrollMap = {}
            for (var k = 0; k < _enrollments.length; k++) {
                enrollMap[_enrollments[k].eleveId] = _enrollments[k]
            }
            for (var m = 0; m < _students.length; m++) {
                var stu = _students[m]
                var enr = enrollMap[stu.id]
                if (!enr) continue // Usually shouldn't happen if students are filtered by year
                var amtDu    = enr.montantInscription
                var amtPaye  = enr.fraisInscriptionPaye ? amtDu : 0
                var amtReste = enr.fraisInscriptionPaye ? 0 : amtDu
                var enrStatus = enr.fraisInscriptionPaye ? "paid" : "pending"
                rows.push({ id: stu.id, nom: stu.nom, prenom: stu.prenom, categorie: stu.categorie,
                            classeId: stu.classeId, montantDu: amtDu,
                            montantPaye: amtPaye, montantReste: amtReste, status: enrStatus,
                            enrollmentData: enr, studentObj: stu })
            }
        }
        return rows
    }

    readonly property var allStats: {
        var rows = tab.allRows
        var paid = 0, partial = 0, pending = 0, totalDu = 0, totalPaye = 0
        for (var i = 0; i < rows.length; i++) {
            if      (rows[i].status === "paid")    paid++
            else if (rows[i].status === "partial") partial++
            else                                   pending++
            totalDu   += rows[i].montantDu
            totalPaye += rows[i].montantPaye
        }
        return { total: rows.length, paid: paid, partial: partial, pending: pending,
                 totalDu: totalDu, totalPaye: totalPaye }
    }

    readonly property var filteredRows: {
        var q = page.searchTerm.toLowerCase()
        var f = tab.statusFilter
        var rows = tab.allRows
        var result = []
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i]
            if (f !== "all" && r.status !== f) continue
            if (q !== "") {
                var name = (r.prenom + " " + r.nom).toLowerCase()
                if (name.indexOf(q) < 0) continue
            }
            result.push(r)
        }
        return result
    }

    readonly property int currentPageCount: Math.max(1, Math.ceil(filteredRows.length / 10))

    readonly property var pagedRows: {
        var p = tab.currentPage
        return tab.filteredRows.slice(p * 10, p * 10 + 10)
    }

    // ── AppCard header ───────────────────────────────────────────────────────
    title:    (tab.viewMode === "mensuel" ? "Scolarité — " + page.selectedMonth + " " + page.selectedYear : "Inscriptions — Année " + page.getSchoolYear())
    subtitle: allStats.total + " élèves inscrits · "
            + allStats.paid    + " payés · "
            + (tab.viewMode === "mensuel" ? allStats.partial + " partiels · " : "")
            + allStats.pending + " en attente"
    
    headerAction: Component {
        Row {
            spacing: 8
            Rectangle {
                width: 110; height: 32; radius: 8
                color: tab.viewMode === "mensuel" ? Style.primary : Style.bgPage
                border.color: tab.viewMode === "mensuel" ? Style.primary : Style.borderLight
                Text {
                    anchors.centerIn: parent; text: "MENSUALITÉS"
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: tab.viewMode === "mensuel" ? "white" : Style.textSecondary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: tab.viewMode = "mensuel"
                }
            }
            Rectangle {
                width: 110; height: 32; radius: 8
                color: tab.viewMode === "inscription" ? Style.primary : Style.bgPage
                border.color: tab.viewMode === "inscription" ? Style.primary : Style.borderLight
                Text {
                    anchors.centerIn: parent; text: "INSCRIPTIONS"
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: tab.viewMode === "inscription" ? "white" : Style.textSecondary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: tab.viewMode = "inscription"
                }
            }
        }
    }

    Column {
        width: parent.width; spacing: 16

        // ── Stats bar ────────────────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: 68; radius: 14
            color: Style.bgPage; border.color: Style.borderLight
            visible: tab.isInActiveYear && tab.allStats.total > 0
            RowLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 0
                Column { Layout.fillWidth: true; spacing: 3
                    Text { text: "EN ATTENTE"; font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.8; color: Style.errorColor }
                    Text { text: tab.allStats.pending; font.pixelSize: 22; font.weight: Font.Black; color: Style.errorColor }
                }
                Rectangle { width: 1; height: 36; color: Style.borderLight; visible: tab.viewMode === "mensuel" }
                Column { Layout.fillWidth: true; spacing: 3; leftPadding: 16; visible: tab.viewMode === "mensuel"
                    Text { text: "PARTIEL"; font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.8; color: Style.warningColor }
                    Text { text: tab.allStats.partial; font.pixelSize: 22; font.weight: Font.Black; color: Style.warningColor }
                }
                Rectangle { width: 1; height: 36; color: Style.borderLight }
                Column { Layout.fillWidth: true; spacing: 3; leftPadding: 16
                    Text { text: "PAYÉS"; font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.8; color: Style.successColor }
                    Text { text: tab.allStats.paid; font.pixelSize: 22; font.weight: Font.Black; color: Style.successColor }
                }
                Rectangle { width: 1; height: 36; color: Style.borderLight }
                Column { Layout.preferredWidth: 220; spacing: 6; leftPadding: 16
                    RowLayout {
                        width: parent.width - 16; spacing: 4
                        Text { Layout.fillWidth: true; text: "COLLECTÉ"; font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.8; color: Style.textTertiary }
                        Text {
                            text: tab.allStats.totalPaye.toFixed(0) + " / " + tab.allStats.totalDu.toFixed(0) + " DT"
                            font.pixelSize: 9; font.weight: Font.Black; color: Style.textSecondary
                        }
                    }
                    Rectangle { width: parent.width - 16; height: 8; radius: 4; color: Style.bgSecondary
                        Rectangle {
                            width: tab.allStats.totalDu > 0
                                   ? Math.min(parent.width * tab.allStats.totalPaye / tab.allStats.totalDu, parent.width) : 0
                            height: parent.height; radius: parent.radius; color: Style.successColor
                        }
                    }
                    Text {
                        text: tab.allStats.totalDu > 0
                              ? Math.round(100 * tab.allStats.totalPaye / tab.allStats.totalDu) + "% collecté" : "0% collecté"
                        font.pixelSize: 9; font.weight: Font.Black; color: Style.textTertiary
                    }
                }
            }
        }

        // ── Status filter pills ──────────────────────────────────────────────
        Row {
            spacing: 8; visible: tab.isInActiveYear
            Repeater {
                model: tab.viewMode === "mensuel" ? [
                    { key: "all",     label: "Tous (" + tab.allRows.length + ")" },
                    { key: "pending", label: "En attente (" + tab.allStats.pending + ")" },
                    { key: "partial", label: "Partiel (" + tab.allStats.partial + ")"    },
                    { key: "paid",    label: "Payés (" + tab.allStats.paid + ")"         }
                ] : [
                    { key: "all",     label: "Tous (" + tab.allRows.length + ")" },
                    { key: "pending", label: "En attente (" + tab.allStats.pending + ")" },
                    { key: "paid",    label: "Payés (" + tab.allStats.paid + ")"         }
                ]
                delegate: Rectangle {
                    property bool active: tab.statusFilter === modelData.key
                    implicitWidth: fpTxt.implicitWidth + 20; height: 30; radius: 8
                    color: active ? Style.primaryBg : Style.bgWhite
                    border.color: active ? Style.primary : Style.borderLight
                    Text { id: fpTxt; anchors.centerIn: parent; text: modelData.label
                           font.pixelSize: 10; font.weight: Font.Bold
                           color: active ? Style.primary : Style.textSecondary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: tab.statusFilter = modelData.key }
                }
            }
        }

        // ── Loading / empty / out-of-range states ────────────────────────────
        Item { width: parent.width; height: 48; visible: financeController.loading || studentController.loading
            Text { anchors.centerIn: parent; text: "Chargement…"; font.pixelSize: 13; color: Style.textTertiary } }

        // Hors de l'année scolaire active
        Column { width: parent.width; spacing: 8
            visible: !tab.isInActiveYear && !(financeController.loading || studentController.loading)
            Item { width: 1; height: 16 }
            Rectangle { width: 56; height: 56; radius: 20; color: Style.bgSecondary
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "calendar"; iconSize: 24; iconColor: Style.textTertiary } }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Hors de l'année scolaire active"
                font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: setupController.activeTarifs
                      ? "Année active : " + setupController.activeTarifs.libelle
                      : "Aucune année scolaire active configurée"
                font.pixelSize: 11; color: Style.textTertiary
            }
            Item { width: 1; height: 16 }
        }

        // Dans l'année active mais aucun résultat
        Column { width: parent.width; spacing: 16
            visible: tab.isInActiveYear && !(financeController.loading || studentController.loading) && tab.filteredRows.length === 0
            Item { width: 1; height: 16 }
            Rectangle { width: 56; height: 56; radius: 20; color: Style.primaryBg
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "wallet"; iconSize: 24; iconColor: Style.primary } }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tab.allStats.total === 0       ? "Aucun élève inscrit pour " + (tab.viewMode === "mensuel" ? "ce mois" : "cette année")
                    : page.searchTerm !== ""          ? "Aucun résultat pour \"" + page.searchTerm + "\""
                    :                                   "Aucun élève dans cette catégorie"
                font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary
            }
            Item { width: 1; height: 16 }
        }

        // ── Table header ─────────────────────────────────────────────────────
        RowLayout { width: parent.width; height: 36; visible: tab.isInActiveYear && tab.filteredRows.length > 0; spacing: 0
            SectionLabel { Layout.fillWidth: true; Layout.rightMargin: 16; text: "ÉLÈVE" }
            SectionLabel { Layout.preferredWidth: 100; text: tab.viewMode === "mensuel" ? "MENSUALITÉ" : "FRAIS INSCR.";  horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: 88;  text: "PAYÉ";        horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: 88;  text: "RESTE";       horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: 100; text: "STATUT";      horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: 80;  text: "ACTION";      horizontalAlignment: Text.AlignHCenter }
        }
        Separator { width: parent.width; visible: tab.isInActiveYear && tab.filteredRows.length > 0 }

        // ── Rows ─────────────────────────────────────────────────────────────
        Column {
            width: parent.width; spacing: 0; visible: tab.isInActiveYear && tab.filteredRows.length > 0
            Repeater {
                model: tab.pagedRows
                delegate: Column {
                    width: parent.width
                    Rectangle {
                        width: parent.width; height: 64
                        color: sRowMa.containsMouse ? Style.bgPage : "transparent"
                        MouseArea { id: sRowMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
                        RowLayout { anchors.fill: parent; spacing: 0
                            Column { Layout.fillWidth: true; Layout.rightMargin: 16; spacing: 3
                                Text { text: modelData.prenom + " " + modelData.nom
                                       font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                       elide: Text.ElideRight; width: parent.width }
                                Text { text: modelData.categorie === "Adulte"
                                            ? "Adulte · " + modelData.montantDu.toFixed(0) + " DT"
                                            : "Jeune · "  + modelData.montantDu.toFixed(0) + " DT"
                                       font.pixelSize: 10; color: Style.textTertiary }
                            }
                            Text { Layout.preferredWidth: 100; text: modelData.montantDu.toFixed(0) + " DT"
                                   horizontalAlignment: Text.AlignHCenter
                                   font.pixelSize: 12; font.weight: Font.Bold; color: Style.textSecondary }
                            Text { Layout.preferredWidth: 88
                                   text: modelData.montantPaye > 0 ? modelData.montantPaye.toFixed(2) + " DT" : "—"
                                   horizontalAlignment: Text.AlignHCenter
                                   font.pixelSize: 12; font.weight: Font.Bold
                                   color: modelData.montantPaye > 0 ? Style.successColor : Style.textTertiary }
                            Text { Layout.preferredWidth: 88
                                   text: modelData.montantReste > 0 ? modelData.montantReste.toFixed(2) + " DT" : "—"
                                   horizontalAlignment: Text.AlignHCenter
                                   font.pixelSize: 12; font.weight: Font.Bold
                                   color: modelData.montantReste > 0 ? Style.errorColor : Style.textTertiary }
                            Item { Layout.preferredWidth: 100; implicitHeight: 24
                                Badge { anchors.centerIn: parent
                                    text: modelData.status === "paid"    ? "Payé"
                                        : modelData.status === "partial" ? "Partiel"
                                        :                                  "En attente"
                                    variant: modelData.status === "paid"    ? "success"
                                           : modelData.status === "partial" ? "warning" : "neutral" }
                            }
                            Item { Layout.preferredWidth: 80; implicitHeight: 56
                                Rectangle { anchors.centerIn: parent; visible: modelData.status !== "paid"
                                    width: 70; height: 28; radius: 8
                                    color: payBtnMa.containsMouse ? Style.primary : Style.primaryBg
                                    Text { anchors.centerIn: parent
                                           text: (tab.viewMode === "mensuel" && modelData.status === "partial") ? "COMPLÉTER" : "PAYER"
                                           font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.4
                                           color: payBtnMa.containsMouse ? "white" : Style.primary }
                                    MouseArea { id: payBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (tab.viewMode === "mensuel") {
                                                page.payingEleveId      = modelData.id
                                                page.payingEleveNom     = modelData.prenom + " " + modelData.nom
                                                page.payingMontantReste = modelData.montantReste
                                                page.showSchoolingModal = true
                                            } else {
                                                // Edit Enrollment Modal
                                                editEnrollmentModal.student = modelData.studentObj
                                                editEnrollmentModal.enrollmentData = modelData.enrollmentData
                                                editEnrollmentModal.show = true
                                            }
                                        }
                                    }
                                }
                                Rectangle { anchors.centerIn: parent; visible: modelData.status === "paid"
                                    width: 34; height: 28; radius: 8
                                    color: editBtnMa.containsMouse ? Style.bgSecondary : Style.bgPage
                                    border.color: Style.borderLight
                                    IconLabel { anchors.centerIn: parent; iconName: "edit"; iconSize: 14; iconColor: Style.textSecondary }
                                    MouseArea { id: editBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (tab.viewMode === "mensuel") {
                                                page.editingEleveId  = modelData.id
                                                page.editingEleveNom = modelData.prenom + " " + modelData.nom
                                                page.showEditModal   = true
                                            } else {
                                                // Edit Enrollment Modal
                                                editEnrollmentModal.student = modelData.studentObj
                                                editEnrollmentModal.enrollmentData = modelData.enrollmentData
                                                editEnrollmentModal.show = true
                                            }
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

        // ── Pagination ───────────────────────────────────────────────────────
        RowLayout { width: parent.width; visible: tab.currentPageCount > 1
            Item { Layout.fillWidth: true }
            Rectangle { width: 32; height: 32; radius: 8
                color: pagePrevMa.containsMouse ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderLight; opacity: tab.currentPage === 0 ? 0.4 : 1.0
                Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 16; font.bold: true; color: Style.textSecondary }
                MouseArea { id: pagePrevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (tab.currentPage > 0) tab.currentPage-- }
            }
            Text { text: "Page " + (tab.currentPage + 1) + " / " + tab.currentPageCount
                        + "  ·  " + tab.filteredRows.length + " élève(s)"
                   font.pixelSize: 11; font.weight: Font.Bold; color: Style.textSecondary }
            Rectangle { width: 32; height: 32; radius: 8
                color: pageNextMa.containsMouse ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderLight; opacity: tab.currentPage >= tab.currentPageCount - 1 ? 0.4 : 1.0
                Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 16; font.bold: true; color: Style.textSecondary }
                MouseArea { id: pageNextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (tab.currentPage < tab.currentPageCount - 1) tab.currentPage++ }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
