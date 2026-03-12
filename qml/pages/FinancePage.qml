import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: financePage
    implicitHeight: mainLayout.implicitHeight

    // ── Navigation ──────────────────────────────────────────────────────────
    property string activeTab:          "schooling"
    property int    selectedMonthIndex: new Date().getMonth()
    property int    selectedYear:       new Date().getFullYear()
    property string searchTerm:         ""

    readonly property var    monthNames: ["Janvier","Février","Mars","Avril","Mai","Juin",
                                          "Juillet","Août","Septembre","Octobre","Novembre","Décembre"]
    readonly property string selectedMonth: monthNames[selectedMonthIndex]

    function navigateMonth(delta) {
        var idx = selectedMonthIndex + delta
        if (idx < 0)  { idx = 11; selectedYear-- }
        if (idx > 11) { idx = 0;  selectedYear++ }
        selectedMonthIndex = idx
    }

    // ── Modal & editing state ────────────────────────────────────────────────
    property bool   payOverwrite:        false
    property bool   showSchoolingModal:  false
    property bool   showDonationModal:   false
    property bool   showEditDonModal:    false
    property var    editingDon:          null
    property var    pendingDon:          null
    property string pendingDonNom:       ""

    property bool   showProjectModal:    false
    property bool   showEditProjectModal:false
    property var    editingProject:      null

    property bool   showExpenseModal:    false
    property bool   showDeleteModal:     false
    property bool   showEditModal:       false
    property bool   showEditConfirmModal: false
    property string deleteType:          ""
    property string deleteItemName:      ""
    property int    deleteItemId:        -1

    property int    payingEleveId:        -1
    property string payingEleveNom:        ""
    property double payingMontantReste:    0.0
    property int    editingPayId:         -1
    property int    editingEleveId:       -1
    property string editingEleveNom:      ""
    property double editingCurrentAmount: 0.0
    property double editingNewAmount:     0.0

    property var    editingDepense:       null
    property bool   showEditExpenseModal: false

    // ── Helpers ──────────────────────────────────────────────────────────────
    function isoToFr(d) {
        if (!d || d === "") return "—"
        var p = d.split("-"); if (p.length < 3) return d
        return p[2] + "/" + p[1] + "/" + p[0]
    }
    function studentDisplayName(eleveId) {
        var list = studentController.students
        for (var i = 0; i < list.length; i++)
            if (list[i].id === eleveId) return list[i].prenom + " " + list[i].nom
        return "Élève #" + eleveId
    }

    function getSchoolYear() {
        var month = selectedMonthIndex + 1;
        if (month >= 9) {
            return selectedYear + "-" + (selectedYear + 1);
        } else {
            return (selectedYear - 1) + "-" + selectedYear;
        }
    }

    // Reactive payments list for the edit modal
    readonly property var currentEditingPayments: {
        var id   = financePage.editingEleveId
        var pays = financeController.payments
        if (id <= 0) return []
        var result = []
        for (var i = 0; i < pays.length; i++)
            if (pays[i].eleveId === id) result.push(pays[i])
        return result
    }

    // ── Data loading ──────────────────────────────────────────────────────────
    Component.onCompleted: {
        studentController.loadStudents()
        studentController.loadEnrollmentsForActiveYear()
        financeController.loadPaymentsByMonth(selectedMonthIndex + 1, selectedYear)
        financeController.loadProjets()
        financeController.loadDonateurs()
        financeController.loadAllDons()
        financeController.loadDepensesByMonth(selectedMonthIndex + 1, selectedYear)
        financeController.loadTarifs(selectedMonthIndex + 1, selectedYear)
        financeController.loadPersonnelPaymentsForJournal(selectedMonthIndex + 1, selectedYear)
        staffController.currentMonth = selectedMonthIndex + 1
        staffController.currentYear = selectedYear
        staffController.loadPersonnel()
        financeController.loadAnnualBalanceForAccountingYear(selectedYear, selectedMonthIndex + 1)
        financeController.loadTotalBalance()
    }
    onSelectedMonthIndexChanged: {
        studentController.loadStudents()
        studentController.loadEnrollmentsForActiveYear()
        financeController.loadPaymentsByMonth(selectedMonthIndex + 1, selectedYear)
        financeController.loadDepensesByMonth(selectedMonthIndex + 1, selectedYear)
        financeController.loadTarifs(selectedMonthIndex + 1, selectedYear)
        financeController.loadPersonnelPaymentsForJournal(selectedMonthIndex + 1, selectedYear)
        staffController.currentMonth = selectedMonthIndex + 1
        staffController.currentYear = selectedYear
        staffController.loadPersonnel()
    }
    onSelectedYearChanged: {
        studentController.loadStudents()
        studentController.loadEnrollmentsForActiveYear()
        financeController.loadPaymentsByMonth(selectedMonthIndex + 1, selectedYear)
        financeController.loadDepensesByMonth(selectedMonthIndex + 1, selectedYear)
        financeController.loadTarifs(selectedMonthIndex + 1, selectedYear)
        financeController.loadPersonnelPaymentsForJournal(selectedMonthIndex + 1, selectedYear)
        staffController.currentMonth = selectedMonthIndex + 1
        staffController.currentYear = selectedYear
        staffController.loadPersonnel()
        financeController.loadAnnualBalanceForAccountingYear(selectedYear, selectedMonthIndex + 1)
    }

    onVisibleChanged: {
        if (visible) {
            staffController.currentMonth = selectedMonthIndex + 1
            staffController.currentYear = selectedYear
            staffController.loadPersonnel()
            studentController.loadStudents()
            studentController.loadEnrollmentsForActiveYear()
            financeController.loadAnnualBalanceForAccountingYear(selectedYear, selectedMonthIndex + 1)
        }
    }

    // ── Backend connections ───────────────────────────────────────────────────
    Connections {
        target: financeController

        function onDonateursChanged() {
            if (!financePage.pendingDon || financePage.pendingDonNom === "") return
            var list = financeController.donateurs
            for (var i = 0; i < list.length; i++) {
                if (list[i].nom === financePage.pendingDonNom) {
                    var payload = financePage.pendingDon
                    payload.donateurId = list[i].id
                    financeController.recordDon(payload)
                    financePage.pendingDonNom = ""
                    financePage.pendingDon    = null
                    break
                }
            }
        }

        function onOperationSucceeded(message) {
            financeController.loadPaymentsByMonth(financePage.selectedMonthIndex + 1, financePage.selectedYear)
            financeController.loadAllDons()
            financeController.loadProjets()

            // Recharger les dépenses si nécessaire
            if (message === "Depense.created" || message === "Depense.updated" || message === "Depense.deleted")
                financeController.loadDepensesByMonth(financePage.selectedMonthIndex + 1, financePage.selectedYear)

            // Recharger les bilans après toute opération financière
            financeController.loadAnnualBalance(financePage.selectedYear)
            financeController.loadTotalBalance()

            financePage.showSchoolingModal    = false
            financePage.showDonationModal     = false
            financePage.showEditDonModal      = false
            financePage.showExpenseModal      = false
            financePage.showEditExpenseModal  = false
            financePage.showDeleteModal       = false
            financePage.showEditConfirmModal  = false
            // showEditModal intentionally NOT closed — stays open for multi-payment editing
        }

        function onOperationFailed(errorMessage) {
            console.warn("[Finance] Opération échouée :", errorMessage)
            financeController.loadAllDons()
            financeController.loadDonateurs()
        }
    }
    
    Connections {
        target: studentController
        function onOperationSucceeded(message) {
            if (message === "Inscription mise à jour" || message === "Nouvelle année inscrite"
                    || message === "Inscription supprimée" || message === "Élève inscrit") {
                studentController.loadStudents()
                studentController.loadEnrollmentsForActiveYear()
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // LAYOUT
    // ════════════════════════════════════════════════════════════════════════
    ColumnLayout {
        id: mainLayout
        anchors.left:  parent.left
        anchors.right: parent.right
        spacing: 32

        // ─── Header ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 16
            PageHeader { Layout.fillWidth: true
                title: qsTr("Finance & Trésorerie")
                subtitle: qsTr("Gestion mensuelle des flux financiers · ") + selectedMonth + " " + selectedYear }
            Row {
                spacing: 4
                Rectangle { width: 32; height: 36; radius: 10
                    color: prevMonthMa.containsMouse ? Style.bgSecondary : Style.bgPage; border.color: Style.borderLight
                    Text { anchors.centerIn: parent; text: qsTr("‹"); font.pixelSize: 18; font.bold: true; color: Style.textSecondary }
                    MouseArea { id: prevMonthMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: financePage.navigateMonth(-1) }
                }
                Rectangle {
                    id: pillRect
                    implicitWidth: monthPillRow.implicitWidth + 20; height: 36; radius: 10
                    color: monthPicker.show ? Style.bgPage : Style.bgWhite
                    border.color: monthPicker.show ? Style.primary : Style.borderLight
                    RowLayout { id: monthPillRow; anchors.centerIn: parent; spacing: 6
                        IconLabel { iconName: "calendar"; iconSize: 14; iconColor: Style.primary }
                        Text { text: financePage.selectedMonth + " " + financePage.selectedYear
                               font.pixelSize: 10; font.weight: Font.Black; color: Style.textPrimary; font.letterSpacing: 0.5 }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var pos = pillRect.mapToItem(financePage, 0, pillRect.height + 4)
                            monthPicker.x = Math.min(pos.x, financePage.width - monthPicker.width)
                            monthPicker.y = pos.y
                            monthPicker.selectedMonth = financePage.selectedMonthIndex + 1
                            monthPicker.selectedYear  = financePage.selectedYear
                            monthPicker.show = !monthPicker.show
                        }
                    }
                }
                Rectangle { width: 32; height: 36; radius: 10
                    color: nextMonthMa.containsMouse ? Style.bgSecondary : Style.bgPage; border.color: Style.borderLight
                    Text { anchors.centerIn: parent; text: qsTr("›"); font.pixelSize: 18; font.bold: true; color: Style.textSecondary }
                    MouseArea { id: nextMonthMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: financePage.navigateMonth(1) }
                }
            }
        }

        // ─── Tab bar ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 60; color: "transparent"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Style.borderLight }
            RowLayout { anchors.fill: parent; spacing: 32
                Repeater {
                    model: [
                        { id: "schooling",  label: qsTr("Scolarité"),       icon: "wallet"   },
                        { id: "donations",  label: qsTr("Dons & Waqf"),     icon: "heart"    },
                        { id: "expenses",   label: qsTr("Dépenses"),         icon: "receipt"  },
                        { id: "donateurs",  label: qsTr("Donateurs"),        icon: "users"    },
                        { id: "journal",    label: qsTr("Journal Unifié"),   icon: "history"  }
                    ]
                    delegate: Item {
                        Layout.fillHeight: true; implicitWidth: tabContent.implicitWidth
                        RowLayout { id: tabContent; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            IconLabel { iconName: modelData.icon; iconSize: 18; iconColor: activeTab === modelData.id ? Style.primary : Style.textTertiary }
                            Text { text: modelData.label; font.pixelSize: 13; font.bold: true; color: activeTab === modelData.id ? Style.primary : Style.textTertiary }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 4; radius: 2
                                    color: activeTab === modelData.id ? Style.primary : "transparent" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { activeTab = modelData.id; searchTerm = "" } }
                    }
                }
            }
        }

        // ─── Filter bar ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 16
            visible: activeTab === "schooling" || activeTab === "expenses"
            SearchField { Layout.fillWidth: true; placeholder: qsTr("Rechercher…"); onTextChanged: searchTerm = text }
            PrimaryButton {
                text: activeTab === "schooling" ? "Nouveau Paiement" : "Nouveau Frais"
                iconName: "plus"
                onClicked: {
                    if (activeTab === "schooling") {
                        financePage.payingEleveId = -1; financePage.payingEleveNom = ""
                        financePage.payingMontantReste = 0; showSchoolingModal = true
                    } else {
                        showExpenseModal  = true
                    }
                }
            }
        }

        // ─── Tab content (lazy-loaded) ────────────────────────────────────────
        Loader { Layout.fillWidth: true; active: activeTab === "schooling"; visible: active
                 sourceComponent: Component { FinanceSchoolingTab { page: financePage } } }
        Loader { Layout.fillWidth: true; active: activeTab === "donations"; visible: active
                 sourceComponent: Component { FinanceDonationsTab { page: financePage } } }
        Loader { Layout.fillWidth: true; active: activeTab === "expenses"; visible: active
                 sourceComponent: Component { FinanceExpensesTab { page: financePage } } }
        Loader { Layout.fillWidth: true; active: activeTab === "donateurs"; visible: active
                 sourceComponent: Component { FinanceDonateursTab { page: financePage } } }
        Loader { Layout.fillWidth: true; active: activeTab === "journal"; visible: active
                 sourceComponent: Component { FinanceJournalTab { page: financePage } } }

        Item { Layout.preferredHeight: 32 }
    }

    // ════════════════════════════════════════════════════════════════════════
    // MODALS (direct children of financePage so ModalOverlay fills the page)
    // ════════════════════════════════════════════════════════════════════════
    FinancePaymentModal  { page: financePage }
    FinanceEditModals    { page: financePage }
    FinanceDonationModal { page: financePage }
    FinanceDonationModal { page: financePage; editMode: true }
    FinanceExpenseModal  { page: financePage }
    FinanceExpenseModal  { page: financePage; editMode: true }

    // ── Delete confirmation ───────────────────────────────────────────────────
    ModalOverlay {
        show: showDeleteModal; modalWidth: 460; modalRadius: 28
        onClose: showDeleteModal = false
        Column { width: parent.width; spacing: 20; padding: 36; bottomPadding: 28
            RowLayout { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                Rectangle { width: 48; height: 48; radius: 20; color: Style.errorBg
                    IconLabel { anchors.centerIn: parent; iconName: "alert"; iconSize: 24; iconColor: Style.errorColor } }
                Column { Layout.fillWidth: true; spacing: 2
                    Text { text: qsTr("Confirmer la suppression"); font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: qsTr("CETTE ACTION EST IRRÉVERSIBLE"); font.pixelSize: 9; color: Style.errorColor; font.weight: Font.Bold; font.letterSpacing: 1 }
                }
                IconButton { iconName: "close"; iconSize: 18; onClicked: showDeleteModal = false }
            }
            Rectangle { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: delText.implicitHeight + 28; radius: 14; color: Style.errorBg; border.color: Style.errorBorder
                Text { id: delText; anchors.fill: parent; anchors.margins: 14
                    text: qsTr("Supprimer ") + (deleteType === "payment" ? "le paiement"
                                       : deleteType === "depense" ? "la dépense"
                                       : deleteType === "projet" ? "le projet"
                                       : "le don") + " <b>" + deleteItemName + "</b> ?"
                    font.pixelSize: 13; font.weight: Font.Medium; color: Style.errorColor
                    wrapMode: Text.WordWrap; textFormat: Text.RichText; lineHeight: 1.5 }
            }
            ModalButtons { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
                cancelText: qsTr("Annuler"); confirmText: qsTr("SUPPRIMER"); confirmColor: Style.errorColor
                onCancel: showDeleteModal = false
                onConfirm: {
                    if (financePage.deleteType === "payment")
                        financeController.deletePayment(financePage.deleteItemId)
                    else if (financePage.deleteType === "depense")
                        financeController.deleteDepense(financePage.deleteItemId)
                    else if (financePage.deleteType === "projet")
                        financeController.deleteProjet(financePage.deleteItemId)
                    else if (financePage.deleteType === "don")
                        financeController.deleteDon(financePage.deleteItemId)
                    showDeleteModal = false
                }
            }
        }
    }

    FinanceProjectModal { page: financePage }

    // ── Month/year picker (floating) ──────────────────────────────────────────
    MonthYearSelector {
        id: monthPicker; z: 200
        onMonthYearChanged: function(month, year) {
            financePage.selectedMonthIndex = month - 1
            financePage.selectedYear = year
        }
    }
}
