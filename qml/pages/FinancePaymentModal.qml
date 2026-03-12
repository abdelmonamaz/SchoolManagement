import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform as Platform
import UI.Components

// Payment modal — direct child of FinancePage (fills parent for z-ordering)
ModalOverlay {
    id: root
    required property var page

    modalWidth: 520
    modalRadius: 32
    show: page.showSchoolingModal
    onClose: page.showSchoolingModal = false

    // Internal state
    property bool overwrite: false

    Platform.FileDialog {
        id: fileDialog
        title: qsTr("Sélectionner un justificatif")
        fileMode: Platform.FileDialog.OpenFile
        nameFilters: ["Documents (*.pdf *.jpg *.jpeg *.png *.doc *.docx)", "Tous les fichiers (*)"]
        onAccepted: {
            var path = fileDialog.file.toString()
            path = path.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "")
            payJustifField.text = decodeURIComponent(path)
        }
    }

    // Reset form when modal opens
    onShowChanged: {
        if (!show) return
        overwrite = false
        payDateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
        payJustifField.text = ""
        if (page.payingEleveId > 0) {
            var students = studentController.students
            for (var i = 0; i < students.length; i++) {
                if (students[i].id === page.payingEleveId) {
                    payEleveCombo.currentIndex = i
                    break
                }
            }
            payMontantField.text = page.payingMontantReste > 0
                ? page.payingMontantReste.toFixed(2) : ""
        } else {
            payEleveCombo.currentIndex = -1
            payMontantField.text = ""
        }
    }

    Column {
        width: parent.width; spacing: 20; padding: 36; bottomPadding: 28

        RowLayout {
            width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
            Rectangle { width: 48; height: 48; radius: 20; color: Style.primaryBg
                IconLabel { anchors.centerIn: parent; iconName: "wallet"; iconSize: 24; iconColor: Style.primary } }
            Column { Layout.fillWidth: true; spacing: 2
                Text {
                    text: page.payingEleveId > 0 ? "Paiement — " + page.payingEleveNom : "Nouveau Paiement"
                    font.pixelSize: 17; font.weight: Font.Black; color: Style.textPrimary
                    elide: Text.ElideRight; width: parent.width
                }
                Text { text: page.selectedMonth.toUpperCase() + " " + page.selectedYear
                       font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Bold; font.letterSpacing: 1.5 }
            }
            IconButton { iconName: "close"; iconSize: 18; onClicked: page.showSchoolingModal = false }
        }
        Separator { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter }

        // ── Élève selector ────────────────────────────────────────────────────
        Column { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
            SectionLabel { text: qsTr("ÉLÈVE") }
            Rectangle { width: parent.width; height: 44; radius: 12; color: Style.bgPage; border.color: Style.borderLight
                ComboBox {
                    id: payEleveCombo
                    anchors.fill: parent; anchors.margins: 4
                    model: studentController.students; currentIndex: -1
                    background: Rectangle { color: "transparent" }
                    contentItem: Text {
                        leftPadding: 8
                        text: payEleveCombo.currentIndex >= 0
                              ? studentController.students[payEleveCombo.currentIndex].prenom + " " + studentController.students[payEleveCombo.currentIndex].nom
                              : studentController.students.length === 0 ? "Aucun élève enregistré" : "Sélectionner un élève…"
                        font.pixelSize: 13; font.bold: true; verticalAlignment: Text.AlignVCenter
                        color: payEleveCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                        elide: Text.ElideRight
                    }
                    delegate: Rectangle { width: payEleveCombo.width; height: 40
                        color: payElMa.containsMouse ? Style.bgSecondary : "transparent"
                        Text { anchors.fill: parent; leftPadding: 12; text: modelData.prenom + " " + modelData.nom
                               font.pixelSize: 13; font.bold: true; color: Style.textPrimary; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                        MouseArea { id: payElMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { payEleveCombo.currentIndex = index; payEleveCombo.popup.close() } }
                    }
                }
            }
        }

        FormField { id: payMontantField; width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
                    label: qsTr("MONTANT PAYÉ (DT)"); placeholder: qsTr("0.00"); fieldHeight: 44 }

        // ── Date et Justificatif ──────────────────────────────────────────────
        Column { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
            DateField {
                id: payDateField
                width: parent.width
                label: qsTr("DATE DU PAIEMENT")
            }

            SectionLabel { text: qsTr("JUSTIFICATIF (PIÈCE JOINTE)") }
            RowLayout { width: parent.width; spacing: 8
                Rectangle { Layout.fillWidth: true; height: 44; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                    TextInput {
                        id: payJustifField
                        anchors.fill: parent; anchors.margins: 12
                        font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                        clip: true; selectByMouse: true; readOnly: true
                        Text { visible: !payJustifField.text; text: qsTr("Aucun fichier sélectionné")
                               font: payJustifField.font; color: Style.textTertiary }
                    }
                }
                Rectangle { Layout.preferredWidth: 44; height: 44; radius: 12
                    color: browseHover.containsMouse ? Style.primary : Style.bgPage
                    border.color: browseHover.containsMouse ? Style.primary : Style.borderLight
                    Text { anchors.centerIn: parent; text: qsTr("…")
                           font.pixelSize: 16; font.bold: true
                           color: browseHover.containsMouse ? "white" : Style.textTertiary }
                    MouseArea { id: browseHover; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: fileDialog.open() }
                }
            }
        }

        // ── Mode Ajouter / Écraser ────────────────────────────────────────────
        Column { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
            SectionLabel { text: qsTr("MODE DE SAISIE") }
            Row { width: parent.width; spacing: 6
                Rectangle { width: (parent.width - 6) / 2; height: 38; radius: 10
                    color: !root.overwrite ? Style.primary : Style.bgPage
                    border.color: !root.overwrite ? Style.primary : Style.borderLight
                    Text { anchors.centerIn: parent; text: qsTr("AJOUTER")
                           font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 0.5
                           color: !root.overwrite ? "white" : Style.textTertiary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.overwrite = false }
                }
                Rectangle { width: (parent.width - 6) / 2; height: 38; radius: 10
                    color: root.overwrite ? Style.errorColor : Style.bgPage
                    border.color: root.overwrite ? Style.errorColor : Style.borderLight
                    Text { anchors.centerIn: parent; text: qsTr("ÉCRASER")
                           font.pixelSize: 10; font.weight: Font.Black; font.letterSpacing: 0.5
                           color: root.overwrite ? "white" : Style.textTertiary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.overwrite = true }
                }
            }
            Text { width: parent.width; visible: root.overwrite
                   text: qsTr("Tous les paiements existants du mois seront supprimés et remplacés par ce montant.")
                   font.pixelSize: 10; color: Style.errorColor; wrapMode: Text.WordWrap }
        }

        ModalButtons {
            width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
            cancelText: qsTr("Annuler"); confirmText: qsTr("Enregistrer")
            onCancel: {
                page.showSchoolingModal = false
                payEleveCombo.currentIndex = -1
                payMontantField.text = ""
                payJustifField.text = ""
                root.overwrite = false
            }
            onConfirm: {
                if (payEleveCombo.currentIndex < 0) return
                var montant = parseFloat(payMontantField.text.replace(",", "."))
                if (isNaN(montant) || montant <= 0) return
                var payload = {
                    eleveId: studentController.students[payEleveCombo.currentIndex].id,
                    montant: montant,
                    mois:    page.selectedMonthIndex + 1,
                    annee:   page.selectedYear,
                    datePaiement: payDateField.dateString !== "" ? payDateField.dateString : Qt.formatDate(new Date(), "yyyy-MM-dd"),
                    justificatifPath: payJustifField.text.trim()
                }
                if (root.overwrite)
                    financeController.overwritePayment(payload)
                else
                    financeController.recordPayment(payload)
                payEleveCombo.currentIndex = -1
                payMontantField.text = ""
                payJustifField.text = ""
                root.overwrite = false
            }
        }
    }
}
