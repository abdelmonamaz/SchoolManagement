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
//       modePaie: "Heure" | "Jour" | "Fixe"
//       joursTravailDefault: bitmask (ex. 31 = Lun-Ven)
//       valeurBase: taux journalier (si modePaie === "Jour")
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

    // Jour-mode properties
    property string modePaie: "Heure"
    property int joursTravailDefault: 31
    property double valeurBase: 0.0
    property int daysMask: 31   // bitmask courant dans la popup

    signal saveRequested(double newSommeDue, double newSommePaye)
    signal recalculateRequested()

    onJoursTravailDefaultChanged: daysMask = joursTravailDefault

    onOpened: {
        daysMask = root.joursTravailDefault
        if (root.modePaie === "Jour")
            sommeDueField.text = (countDaysInMonth(daysMask) * root.valeurBase).toFixed(2)
    }

    // Compte les occurrences des jours cochés dans le mois courant
    function countDaysInMonth(mask) {
        var count = 0
        var d = new Date(root.selectedYear, root.selectedMonth - 1, 1)
        while (d.getMonth() === root.selectedMonth - 1) {
            var dow = d.getDay()  // 0=Dim, 1=Lun..6=Sam
            var bit = dow === 0 ? (1 << 6) : (1 << (dow - 1))
            if (mask & bit) count++
            d.setDate(d.getDate() + 1)
        }
        return count
    }

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

        // ─── Sélecteur de jours (mode "Jour" uniquement) ───
        Column {
            width: 420
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            visible: root.modePaie === "Jour"

            SectionLabel { text: "JOURS DE TRAVAIL CE MOIS" }

            Row {
                spacing: 6
                Repeater {
                    model: ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
                    delegate: Rectangle {
                        width: 54; height: 44; radius: 10
                        property int bit: 1 << index
                        property bool active: (root.daysMask & bit) !== 0
                        color: active ? Style.primary : Style.bgPage
                        border.color: active ? Style.primary : Style.borderLight
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 10; font.weight: Font.Black
                            color: active ? "white" : Style.textTertiary
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.daysMask ^= bit
                                var nJours = root.countDaysInMonth(root.daysMask)
                                sommeDueField.text = (nJours * root.valeurBase).toFixed(2)
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }

            // Récapitulatif
            Text {
                property int nJours: root.countDaysInMonth(root.daysMask)
                text: nJours + " jour" + (nJours > 1 ? "s" : "")
                    + " × " + root.valeurBase.toFixed(2) + " DT"
                    + " = " + (nJours * root.valeurBase).toFixed(2) + " DT"
                font.pixelSize: 12; font.weight: Font.Bold
                color: Style.textSecondary
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
