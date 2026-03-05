import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

Item {
    id: staffPage
    implicitHeight: mainLayout.implicitHeight

    property bool showModal: false

    property bool showDeleteConfirm: false
    property int deleteTargetId: -1
    property string deleteTargetName: ""

    property bool showPaymentPopup: false
    property int selectedPersonnelId: 0
    property string selectedPersonnelName: ""
    property var selectedPersonnelData: null

    property bool showHistoryPopup: false
    property int historyPersonnelId: -1
    property string historyPersonnelName: ""

    property bool showErrorPopup: false
    property string errorPopupMessage: ""

    property bool showDeleteContratConfirm: false
    property int deleteContratTargetId: -1

    property int displayMonth: new Date().getMonth() + 1
    property int displayYear: new Date().getFullYear()
    property bool showAllMode: false

    property var monthNames: [
        "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
        "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
    ]

    function reloadData() {
        if (showAllMode) {
            staffController.loadAllPersonnel()
        } else {
            staffController.loadPersonnel()
        }
    }

    onDisplayMonthChanged: {
        staffController.currentMonth = displayMonth
        reloadData()
    }

    onDisplayYearChanged: {
        staffController.currentYear = displayYear
        reloadData()
    }

    onShowAllModeChanged: reloadData()

    onVisibleChanged: {
        if (visible) reloadData()
    }

    Component.onCompleted: {
        staffController.currentMonth = displayMonth
        staffController.currentYear = displayYear
        staffController.loadPersonnel()
    }

    Connections {
        target: staffController
        function onOperationSucceeded(msg) {
            console.log("StaffPage:", msg)
            showModal = false
            showPaymentPopup = false
            reloadData()
            // Si l'opération est un paiement (ou autre action affectant les finances), on recharge le journal
            financeController.loadPersonnelPaymentsForJournal(displayMonth, displayYear)
            financeController.loadAnnualBalance(displayYear)
            financeController.loadTotalBalance()
        }
        function onOperationFailed(err) {
            console.warn("StaffPage error:", err)
            errorPopupMessage = err
            showErrorPopup = true
        }
        function onPaymentDataLoaded(data) {
            if (data.sommeDue !== undefined) {
                paymentPopup.sommeDue = data.sommeDue
            }
            if (data.sommePaye !== undefined) {
                paymentPopup.sommePaye = data.sommePaye
            }
            if (data.datePaiement !== undefined) {
                paymentPopup.currentDatePaiement = data.datePaiement
            } else {
                paymentPopup.currentDatePaiement = ""
            }
            if (data.justificatifPath !== undefined) {
                paymentPopup.currentJustif = data.justificatifPath
            } else {
                paymentPopup.currentJustif = ""
            }
        }
        function onContratHistoriqueLoaded(contrats) {
            contratHistoryPopup.contrats = contrats
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        // Header
        RowLayout {
            Layout.fillWidth: true
            PageHeader {
                Layout.fillWidth: true
                title: "Gestion du Personnel"
                subtitle: "Administration des contrats et suivi de l'activité."
            }

            PrimaryButton {
                text: "Ajouter un membre"
                iconName: "plus"
                onClicked: {
                    staffFormModal.reset()
                    showModal = true
                }
            }
        }

        // Search Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            SearchField {
                Layout.fillWidth: true
                placeholder: "Rechercher par nom ou poste..."
            }

            // Show All toggle
            Rectangle {
                implicitWidth: showAllRow.implicitWidth + 20
                height: 42
                radius: 16
                color: showAllMode ? Style.primary : Style.bgWhite
                border.color: showAllMode ? Style.primary : Style.borderLight

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: showAllRow
                    anchors.centerIn: parent
                    spacing: 6

                    IconLabel {
                        iconName: "users"
                        iconSize: 14
                        iconColor: showAllMode ? "#FFFFFF" : Style.textSecondary
                    }

                    Text {
                        text: "AFFICHER TOUT"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: showAllMode ? "#FFFFFF" : Style.textSecondary
                        font.letterSpacing: 0.5
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: showAllMode = !showAllMode
                }
            }

            Rectangle {
                id: monthButton
                implicitWidth: monthRow.implicitWidth + 24
                height: 42
                radius: 16
                color: showAllMode ? Style.bgPage : Style.bgWhite
                border.color: Style.borderLight
                opacity: showAllMode ? 0.5 : 1.0

                RowLayout {
                    id: monthRow
                    anchors.centerIn: parent
                    spacing: 8

                    IconLabel {
                        iconName: "calendar"
                        iconSize: 16
                        iconColor: Style.primary
                    }

                    Text {
                        text: monthNames[displayMonth - 1].toUpperCase() + " " + displayYear
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.textPrimary
                        font.letterSpacing: 1
                    }

                    Text {
                        text: "▾"
                        font.pixelSize: 10
                        color: Style.textTertiary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        showAllMode = false
                        monthYearSelector.show = !monthYearSelector.show
                    }
                }
            }
        }

        // Staff Grid
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 20
            rowSpacing: 20

            Repeater {
                model: staffController.personnel
                delegate: StaffCard {
                    staffData: modelData
                    moisLabel: monthNames[displayMonth - 1]
                    onEditIdentityClicked: {
                        staffFormModal.populateIdentity(modelData)
                        showModal = true
                    }
                    onEditContratClicked: {
                        staffFormModal.populateEditContrat(modelData)
                        showModal = true
                    }
                    onNewContratClicked: {
                        staffFormModal.populateNewContrat(modelData)
                        showModal = true
                    }
                    onDeleteClicked: {
                        deleteTargetId = modelData.id
                        deleteTargetName = modelData.nom || "ce membre"
                        showDeleteConfirm = true
                    }
                    onPayClicked: {
                        selectedPersonnelId = modelData.id
                        selectedPersonnelName = modelData.nom
                        selectedPersonnelData = modelData
                        staffController.loadPaymentData(modelData.id, displayMonth, displayYear)
                        showPaymentPopup = true
                    }
                    onViewHistoryClicked: {
                        historyPersonnelId = modelData.id
                        historyPersonnelName = modelData.nom
                        staffController.loadContratHistorique(modelData.id)
                        showHistoryPopup = true
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: 32
        }
    }

    // Staff Form Modal
    StaffFormModal {
        id: staffFormModal
        show: showModal
        onCancelled: {
            showModal = false
            staffFormModal.reset()
        }
        onConfirmed: function(formData) {
            if (formData.mode === "identity") {
                staffController.updatePersonnel(
                    formData.personnelId,
                    formData.nom,
                    formData.telephone,
                    formData.sexe
                )
            } else if (formData.mode === "contract") {
                staffController.createContrat(
                    formData.personnelId,
                    formData.poste,
                    formData.specialite,
                    formData.modePaie,
                    formData.valeurBase,
                    formData.dateDebut,
                    formData.dateFin || "",
                    formData.joursTravail || 31
                )
            } else if (formData.mode === "editContract") {
                staffController.updateContrat(
                    formData.contratId,
                    formData.personnelId,
                    formData.poste,
                    formData.specialite,
                    formData.modePaie,
                    formData.valeurBase,
                    formData.dateDebut,
                    formData.dateFin || "",
                    formData.joursTravail || 31
                )
            } else {
                // mode "full" - new member + contract
                staffController.createPersonnel(
                    formData.nom,
                    formData.telephone,
                    formData.sexe,
                    formData.poste,
                    formData.specialite,
                    formData.modePaie,
                    formData.valeurBase,
                    formData.dateDebut,
                    formData.dateFin || "",
                    formData.joursTravail || 31
                )
            }
        }
    }

    // Popup de confirmation de suppression
    ModalOverlay {
        show: showDeleteConfirm
        modalWidth: 480
        modalRadius: 32
        onClose: showDeleteConfirm = false

        Column {
            width: parent.width
            spacing: 24
            padding: 40

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    width: 56
                    height: 56
                    radius: 20
                    color: Style.errorBg

                    IconLabel {
                        anchors.centerIn: parent
                        iconName: "alert"
                        iconSize: 28
                        iconColor: Style.errorColor
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Confirmer la suppression"
                        font.pixelSize: 22
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "CETTE ACTION EST IRRÉVERSIBLE"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.errorColor
                        font.letterSpacing: 1
                    }
                }
            }

            Rectangle {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: warningText.implicitHeight + 32
                radius: 20
                color: Style.errorBg
                border.color: Style.errorBorder

                Text {
                    id: warningText
                    anchors.fill: parent
                    anchors.margins: 16
                    text: "Êtes-vous sûr de vouloir supprimer <b>" + deleteTargetName + "</b> du personnel ? Cette action supprimera aussi tous ses contrats et ne peut pas être annulée."
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Style.errorColor
                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText
                    lineHeight: 1.5
                }
            }

            ModalButtons {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: "SUPPRIMER"
                confirmColor: Style.errorColor
                onCancel: {
                    showDeleteConfirm = false
                    deleteTargetId = -1
                    deleteTargetName = ""
                }
                onConfirm: {
                    staffController.deletePersonnel(deleteTargetId)
                    showDeleteConfirm = false
                    deleteTargetId = -1
                    deleteTargetName = ""
                }
            }
        }
    }

    // Payment Popup
    PaymentPopup {
        id: paymentPopup
        show: showPaymentPopup
        personnelId: selectedPersonnelId
        personnelName: selectedPersonnelName
        selectedMonth: displayMonth
        selectedYear: displayYear
        modePaie: selectedPersonnelData ? (selectedPersonnelData.modePaie || "Heure") : "Heure"
        joursTravailDefault: selectedPersonnelData ? (selectedPersonnelData.joursTravail || 31) : 31
        valeurBase: selectedPersonnelData ? (selectedPersonnelData.valeurBase || 0) : 0

        onSaveRequested: function(newSommeDue, newSommePaye, datePaiement, justificatifPath) {
            staffController.savePayment(
                personnelId, selectedMonth, selectedYear,
                newSommeDue, newSommePaye, datePaiement, justificatifPath
            )
        }

        onRecalculateRequested: {
            staffController.recalculateSommeDue(
                personnelId, selectedMonth, selectedYear
            )
        }

        onClose: showPaymentPopup = false
    }

    // Contrat History Popup
    ContratHistoryPopup {
        id: contratHistoryPopup
        show: showHistoryPopup
        personnelId: historyPersonnelId
        personnelName: historyPersonnelName
        onClose: showHistoryPopup = false
        onEditContratRequested: function(contratData) {
            // Build a data object compatible with populateEditContrat
            var data = {
                id: historyPersonnelId,
                contratId: contratData.contratId,
                poste: contratData.poste,
                specialite: contratData.specialite,
                modePaie: contratData.modePaie,
                valeurBase: contratData.valeurBase,
                dateDebutISO: contratData.dateDebutISO || "",
                dateFinISO: contratData.dateFinISO || ""
            }
            staffFormModal.populateEditContrat(data)
            showHistoryPopup = false
            showModal = true
        }
        onDeleteContratRequested: function(contratId) {
            deleteContratTargetId = contratId
            showDeleteContratConfirm = true
        }
    }

    // Delete Contrat Confirmation Popup
    ModalOverlay {
        show: showDeleteContratConfirm
        modalWidth: 480
        modalRadius: 32
        onClose: showDeleteContratConfirm = false

        Column {
            width: parent.width
            spacing: 24
            padding: 40

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    width: 56
                    height: 56
                    radius: 20
                    color: Style.errorBg

                    IconLabel {
                        anchors.centerIn: parent
                        iconName: "alert"
                        iconSize: 28
                        iconColor: Style.errorColor
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Supprimer le contrat"
                        font.pixelSize: 22
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "CETTE ACTION EST IRRÉVERSIBLE"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.errorColor
                        font.letterSpacing: 1
                    }
                }
            }

            Rectangle {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: deleteContratWarning.implicitHeight + 32
                radius: 20
                color: Style.errorBg
                border.color: Style.errorBorder

                Text {
                    id: deleteContratWarning
                    anchors.fill: parent
                    anchors.margins: 16
                    text: "Êtes-vous sûr de vouloir supprimer ce contrat ? Cette action ne peut pas être annulée."
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Style.errorColor
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }
            }

            ModalButtons {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: "SUPPRIMER"
                confirmColor: Style.errorColor
                onCancel: {
                    showDeleteContratConfirm = false
                    deleteContratTargetId = -1
                }
                onConfirm: {
                    staffController.deleteContrat(deleteContratTargetId)
                    showDeleteContratConfirm = false
                    showHistoryPopup = false
                    deleteContratTargetId = -1
                }
            }
        }
    }

    // Error Popup
    ModalOverlay {
        show: showErrorPopup
        modalWidth: 480
        modalRadius: 32
        onClose: showErrorPopup = false

        Column {
            width: parent.width
            spacing: 24
            padding: 40

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    width: 56
                    height: 56
                    radius: 20
                    color: Style.errorBg

                    IconLabel {
                        anchors.centerIn: parent
                        iconName: "alert"
                        iconSize: 28
                        iconColor: Style.errorColor
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Erreur"
                        font.pixelSize: 22
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "UNE ERREUR EST SURVENUE"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.errorColor
                        font.letterSpacing: 1
                    }
                }
            }

            Rectangle {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: errorMsgText.implicitHeight + 32
                radius: 20
                color: Style.errorBg
                border.color: Style.errorBorder

                Text {
                    id: errorMsgText
                    anchors.fill: parent
                    anchors.margins: 16
                    text: errorPopupMessage
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Style.errorColor
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }
            }

            ModalButtons {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                cancelText: ""
                confirmText: "COMPRIS"
                onConfirm: showErrorPopup = false
                onCancel: showErrorPopup = false
            }
        }
    }

    // MonthYearSelector avec z-index élevé pour être au-dessus de tout
    MonthYearSelector {
        id: monthYearSelector
        z: 1000
        parent: staffPage
        x: monthButton.x + monthButton.width - width
        y: monthButton.y + monthButton.height + 8

        selectedMonth: displayMonth
        selectedYear: displayYear
        onMonthYearChanged: function(month, year) {
            displayMonth = month
            displayYear = year
            console.log("Période sélectionnée:", monthNames[month - 1], year)
        }
    }
}
