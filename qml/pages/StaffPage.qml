import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

Item {
    id: staffPage
    implicitHeight: mainLayout.implicitHeight

    property bool showModal: false
    property bool isEditing: false
    property int editingId: -1

    property bool showDeleteConfirm: false
    property int deleteTargetId: -1
    property string deleteTargetName: ""

    property bool showPaymentPopup: false
    property int selectedPersonnelId: 0
    property string selectedPersonnelName: ""

    property int displayMonth: new Date().getMonth() + 1
    property int displayYear: new Date().getFullYear()

    property var monthNames: [
        "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
        "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
    ]

    onDisplayMonthChanged: {
        staffController.currentMonth = displayMonth
        staffController.loadPersonnel()
    }

    onDisplayYearChanged: {
        staffController.currentYear = displayYear
        staffController.loadPersonnel()
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
            staffController.loadPersonnel()
        }
        function onOperationFailed(err) { console.warn("StaffPage error:", err) }
        function onPaymentDataLoaded(data) {
            if (data.sommeDue !== undefined) {
                paymentPopup.sommeDue = data.sommeDue
            }
            if (data.sommePaye !== undefined) {
                paymentPopup.sommePaye = data.sommePaye
            }
        }
    }

    function simulatePay(member) {
        var total = 0
        var desc = ""
        if (member.modePaie === "Heure") {
            var hours = member.heuresTravailes || 0
            total = hours * member.valeurBase
            desc = "Calcul Horaire: " + hours + "h x " + member.valeurBase + " DT = " + total + " DT"
        } else {
            total = member.valeurBase
            desc = "Salaire Fixe: " + total + " DT / mois"
        }
        console.log("=== Simulation de paie ===")
        console.log("Membre:", member.nom)
        console.log(desc)
        console.log("Total:", total, "DT")
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
                    isEditing = false
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

            Rectangle {
                id: monthButton
                implicitWidth: monthRow.implicitWidth + 24
                height: 42
                radius: 16
                color: Style.bgWhite
                border.color: Style.borderLight

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
                    onClicked: monthYearSelector.show = !monthYearSelector.show
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
                    onEditClicked: {
                        isEditing = true
                        editingId = modelData.id
                        staffFormModal.populate(modelData)
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
                        staffController.loadPaymentData(modelData.id, displayMonth, displayYear)
                        showPaymentPopup = true
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
        isEditing: staffPage.isEditing
        onCancelled: {
            showModal = false
            staffFormModal.reset()
        }
        onConfirmed: function(formData) {
            if (isEditing) {
                staffController.updatePersonnel(
                    editingId,
                    formData.nom,
                    formData.telephone,
                    formData.poste,
                    formData.specialite,
                    formData.modePaie,
                    formData.valeurBase,
                    formData.statut
                )
            } else {
                staffController.createPersonnel(
                    formData.nom,
                    formData.telephone,
                    formData.poste,
                    formData.specialite,
                    formData.modePaie,
                    formData.valeurBase,
                    formData.statut
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
                    text: "Êtes-vous sûr de vouloir supprimer <b>" + deleteTargetName + "</b> du personnel ? Cette action ne peut pas être annulée."
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

        onSaveRequested: function(newSommeDue, newSommePaye) {
            staffController.savePayment(
                personnelId, selectedMonth, selectedYear,
                newSommeDue, newSommePaye
            )
        }

        onRecalculateRequested: {
            staffController.recalculateSommeDue(
                personnelId, selectedMonth, selectedYear
            )
        }

        onClose: showPaymentPopup = false
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
