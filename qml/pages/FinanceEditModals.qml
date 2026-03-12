import QtQuick
import QtQuick.Layouts
import Qt.labs.platform as Platform
import UI.Components

// Wraps both edit modal and edit-confirm modal.
// Must be a direct child of FinancePage so ModalOverlay can fill the page.
Item {
    id: root
    required property var page
    anchors.fill: parent

    // State for additional payment fields during edit
    property string editCurrentDate: ""
    property string editCurrentJustif: ""

    Platform.FileDialog {
        id: editFileDialog
        title: "Sélectionner un justificatif"
        fileMode: Platform.FileDialog.OpenFile
        nameFilters: ["Documents (*.pdf *.jpg *.jpeg *.png *.doc *.docx)", "Tous les fichiers (*)"]
        onAccepted: {
            var path = editFileDialog.file.toString()
            path = path.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "")
            editJustifField.text = decodeURIComponent(path)
        }
    }

    // ── Edit modal ────────────────────────────────────────────────────────────
    ModalOverlay {
        id: editModalOverlay
        show: page.showEditModal
        modalWidth: 520; modalRadius: 32
        
        onClose: {
            page.showEditModal = false
            page.editingPayId = -1
            editNewAmountField.text = ""
            root.editCurrentDate = ""
            root.editCurrentJustif = ""
            editJustifField.text = ""
        }

        onShowChanged: {
            if (!show) {
                page.editingPayId = -1
                editNewAmountField.text = ""
                root.editCurrentDate = ""
                root.editCurrentJustif = ""
                editJustifField.text = ""
            } else {
                editDateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
            }
        }

        Column {
            width: parent.width; spacing: 20; padding: 36; bottomPadding: 28

            RowLayout {
                width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                Rectangle { width: 48; height: 48; radius: 20; color: Style.warningBg || Style.warningBorder
                    IconLabel { anchors.centerIn: parent; iconName: "edit"; iconSize: 22; iconColor: Style.warningColor || Style.warningColor } }
                Column { Layout.fillWidth: true; spacing: 2
                    Text { text: "Modifier un paiement"; font.pixelSize: 17; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: page.editingEleveNom + " · " + page.selectedMonth + " " + page.selectedYear
                           font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium
                           elide: Text.ElideRight; width: parent.width }
                }
                IconButton { iconName: "close"; iconSize: 18; onClicked: editModalOverlay.onClose() }
            }
            Separator { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter }

            // ── Payment list ─────────────────────────────────────────────────
            Column { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                SectionLabel { text: "PAIEMENTS DU MOIS" }
                Column { width: parent.width; spacing: 6
                    Repeater {
                        model: page.currentEditingPayments
                        delegate: Rectangle {
                            width: parent.width; height: 52; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                            RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
                                Column { Layout.fillWidth: true; spacing: 2
                                    Text { text: page.isoToFr(modelData.datePaiement); font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }
                                    Text { text: modelData.montantPaye.toFixed(2) + " DT"; font.pixelSize: 14; font.weight: Font.Black; color: Style.primary }
                                }
                                Rectangle { width: 90; height: 32; radius: 8
                                    color: editPayMa.containsMouse ? Style.primary : Style.primaryBg
                                    Text { anchors.centerIn: parent; text: "MODIFIER"
                                           font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                                           color: editPayMa.containsMouse ? "white" : Style.primary }
                                    MouseArea { id: editPayMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            page.editingPayId         = modelData.id
                                            page.editingCurrentAmount = modelData.montantPaye
                                            root.editCurrentDate      = modelData.datePaiement || ""
                                            root.editCurrentJustif    = modelData.justificatifPath || ""
                                            
                                            editNewAmountField.text   = modelData.montantPaye.toFixed(2)
                                            if (root.editCurrentDate) {
                                                editDateField.setDate(root.editCurrentDate)
                                            } else {
                                                editDateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
                                            }
                                            editJustifField.text      = root.editCurrentJustif
                                            
                                            editNewAmountField.forceActiveFocus()
                                        }
                                    }
                                }
                                Rectangle { width: 32; height: 32; radius: 8
                                    color: delInlineMa.containsMouse ? Style.errorBorder : Style.bgPage
                                    border.color: delInlineMa.containsMouse ? Style.errorColor : Style.borderLight
                                    IconLabel { anchors.centerIn: parent; iconName: "trash"; iconSize: 14
                                                iconColor: delInlineMa.containsMouse ? Style.errorColor : Style.textTertiary }
                                    MouseArea { id: delInlineMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            page.deleteType     = "payment"
                                            page.deleteItemId   = modelData.id
                                            page.deleteItemName = modelData.montantPaye.toFixed(2) + " DT"
                                            page.showDeleteModal = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text { width: parent.width; visible: page.currentEditingPayments.length === 0
                           text: "Aucun paiement enregistré pour ce mois."
                           font.pixelSize: 12; color: Style.textTertiary; horizontalAlignment: Text.AlignHCenter }
                }
            }

            // ── Edit form (always visible but disabled if none selected) ─────────────
            Column { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                opacity: page.editingPayId > 0 ? 1.0 : 0.5
                enabled: page.editingPayId > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Separator { width: parent.width }
                Row { spacing: 8
                    Text { text: "Montant actuel : "; font.pixelSize: 12; color: Style.textTertiary; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: (page.editingPayId > 0 ? page.editingCurrentAmount.toFixed(2) : "0.00") + " DT"; font.pixelSize: 13; font.weight: Font.Black; color: Style.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                }
                FormField { id: editNewAmountField; width: parent.width
                            label: "NOUVEAU MONTANT (DT)"; placeholder: "0.00"; fieldHeight: 44 }
                
                DateField {
                    id: editDateField
                    width: parent.width
                    label: "DATE DU PAIEMENT"
                }

                SectionLabel { text: "JUSTIFICATIF (PIÈCE JOINTE)" }
                RowLayout { width: parent.width; spacing: 8
                    Rectangle { Layout.fillWidth: true; height: 44; radius: 12
                                color: Style.bgPage; border.color: Style.borderLight
                        TextInput {
                            id: editJustifField
                            anchors.fill: parent; anchors.margins: 12
                            font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                            clip: true; selectByMouse: true; readOnly: true
                            Text { visible: !editJustifField.text; text: "Aucun fichier sélectionné"
                                   font: editJustifField.font; color: Style.textTertiary }
                        }
                    }
                    Rectangle { Layout.preferredWidth: 44; height: 44; radius: 12
                        color: editBrowseHover.containsMouse ? Style.primary : Style.bgPage
                        border.color: editBrowseHover.containsMouse ? Style.primary : Style.borderLight
                        Text { anchors.centerIn: parent; text: "…"
                               font.pixelSize: 16; font.bold: true
                               color: editBrowseHover.containsMouse ? "white" : Style.textTertiary }
                        MouseArea { id: editBrowseHover; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: editFileDialog.open() }
                    }
                }
                            
                Rectangle { width: parent.width; height: 44; radius: 12
                    color: confirmEditBtnMa.containsMouse ? Style.primary : Style.primaryBg
                    Text { anchors.centerIn: parent; text: "ENREGISTRER"
                           font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 0.5
                           color: confirmEditBtnMa.containsMouse ? "white" : Style.primary }
                    MouseArea { id: confirmEditBtnMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var newAmt = parseFloat(editNewAmountField.text.replace(",", "."))
                            if (isNaN(newAmt) || newAmt < 0) return
                            page.editingNewAmount     = newAmt
                            root.editCurrentDate      = editDateField.dateString !== "" ? editDateField.dateString : Qt.formatDate(new Date(), "yyyy-MM-dd")
                            root.editCurrentJustif    = editJustifField.text.trim()
                            page.showEditModal        = false
                            page.showEditConfirmModal = true
                        }
                    }
                }
            }
        }
    }

    // ── Edit confirm modal ────────────────────────────────────────────────────
    ModalOverlay {
        show: page.showEditConfirmModal
        modalWidth: 460; modalRadius: 28
        onClose: { page.showEditConfirmModal = false; page.showEditModal = true }

        Column {
            width: parent.width; spacing: 20; padding: 36; bottomPadding: 28

            RowLayout {
                width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                Rectangle { width: 48; height: 48; radius: 20
                    color: page.editingNewAmount === 0 ? Style.errorBg : (Style.warningBg || Style.warningBorder)
                    IconLabel { anchors.centerIn: parent
                        iconName: page.editingNewAmount === 0 ? "trash" : "edit"; iconSize: 24
                        iconColor: page.editingNewAmount === 0 ? Style.errorColor : (Style.warningColor || Style.warningColor) }
                }
                Column { Layout.fillWidth: true; spacing: 2
                    Text { text: page.editingNewAmount === 0 ? "Confirmer la suppression" : "Confirmer la modification"
                           font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: page.editingEleveNom; font.pixelSize: 11; color: Style.textTertiary; font.weight: Font.Medium }
                }
                IconButton { iconName: "close"; iconSize: 18
                    onClicked: { page.showEditConfirmModal = false; page.showEditModal = true } }
            }

            Rectangle { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: confirmEditText.implicitHeight + 28; radius: 14
                color: page.editingNewAmount === 0 ? Style.errorBg : Style.warningBorder
                border.color: page.editingNewAmount === 0 ? Style.errorBorder : Style.warningColor
                Text { id: confirmEditText; anchors.fill: parent; anchors.margins: 14
                    text: page.editingNewAmount === 0
                        ? "Supprimer ce paiement de <b>" + page.editingCurrentAmount.toFixed(2) + " DT</b> ?"
                        : "Modifier ce paiement de <b>" + page.editingCurrentAmount.toFixed(2)
                          + " DT</b> à <b>" + page.editingNewAmount.toFixed(2) + " DT</b> ?"
                    font.pixelSize: 13; font.weight: Font.Medium
                    color: page.editingNewAmount === 0 ? Style.errorColor : Style.warningColor
                    wrapMode: Text.WordWrap; textFormat: Text.RichText; lineHeight: 1.5
                }
            }

            ModalButtons {
                width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: page.editingNewAmount === 0 ? "SUPPRIMER" : "CONFIRMER"
                confirmColor: page.editingNewAmount === 0 ? Style.errorColor : Style.primary
                onCancel: { page.showEditConfirmModal = false; page.showEditModal = true }
                onConfirm: {
                    if (page.editingNewAmount === 0)
                        financeController.deletePayment(page.editingPayId)
                    else
                        financeController.updatePayment(page.editingPayId, { 
                            montant: page.editingNewAmount,
                            datePaiement: root.editCurrentDate,
                            justificatifPath: root.editCurrentJustif
                        })
                    
                    // Reset edit state
                    page.editingPayId         = -1
                    editNewAmountField.text = ""
                    root.editCurrentDate = ""
                    root.editCurrentJustif = ""
                    editJustifField.text = ""

                    page.showEditConfirmModal = false
                    page.showEditModal        = true
                }
            }
        }
    }
}
