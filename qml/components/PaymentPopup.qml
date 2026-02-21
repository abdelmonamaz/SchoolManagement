import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

// Popup de gestion des paiements mensuels du personnel
// Usage:
//   PaymentPopup {
//       show: showPayment
//       personnelId: staffId
//       personnelName: staffName
//       selectedMonth: currentMonth
//       selectedYear: currentYear
//       sommeDue: dueAmount
//       sommePaye: paidAmount
//       onSaveRequested: function(newDue, newPaid) { ... }
//       onRecalculateRequested: { ... }
//   }
ModalOverlay {
    id: root

    property int personnelId: 0
    property string personnelName: ""
    property int selectedMonth: 1
    property int selectedYear: 2026
    property double sommeDue: 0
    property double sommePaye: 0

    signal saveRequested(double newSommeDue, double newSommePaye)
    signal recalculateRequested()

    modalWidth: 560

    Column {
        width: parent.width
        spacing: 20
        padding: 40
        bottomPadding: 32

        // Header
        Text {
            width: 420
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Paiement - " + personnelName
            font.pixelSize: 24
            font.weight: Font.Black
            color: Style.textPrimary
        }

        // Date affichée (readonly)
        Rectangle {
            width: 420
            anchors.horizontalCenter: parent.horizontalCenter
            height: 48
            radius: 12
            color: Style.infoBg
            border.color: Style.infoBorder

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                IconLabel {
                    iconName: "calendar"
                    iconColor: Style.infoColor
                }
                Text {
                    text: getMonthName(selectedMonth) + " " + selectedYear
                    font.pixelSize: 14
                    font.bold: true
                    color: Style.infoColor
                }
            }
        }

        // Somme due
        FormField {
            id: sommeDueField
            width: 420
            anchors.horizontalCenter: parent.horizontalCenter
            label: "SOMME DUE (DT)"
            text: String(root.sommeDue.toFixed(2))
            validator: RegularExpressionValidator {
                regularExpression: /^\d*\.?\d{0,2}$/
            }
        }

        // Somme payée
        FormField {
            id: sommePayeeField
            width: 420
            anchors.horizontalCenter: parent.horizontalCenter
            label: "SOMME PAYÉE (DT)"
            text: String(root.sommePaye.toFixed(2))
            validator: RegularExpressionValidator {
                regularExpression: /^\d*\.?\d{0,2}$/
            }
        }

        // Bouton Recalculer
        OutlineButton {
            width: 420
            anchors.horizontalCenter: parent.horizontalCenter
            text: "RECALCULER LA SOMME DUE"
            iconName: "refresh-cw"
            onClicked: root.recalculateRequested()
        }

        // Spacer avant les boutons
        Item {
            width: 1
            height: 8
        }

        // Buttons
        ModalButtons {
            width: 420
            anchors.horizontalCenter: parent.horizontalCenter
            confirmText: "ENREGISTRER"
            onCancel: root.close()
            onConfirm: {
                root.saveRequested(
                    parseFloat(sommeDueField.text) || 0,
                    parseFloat(sommePayeeField.text) || 0
                )
            }
        }
    }

    function getMonthName(m) {
        const months = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                       "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"];
        return months[m - 1] || "";
    }
}
