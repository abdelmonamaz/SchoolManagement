import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform as Platform
import UI.Components

ModalOverlay {
    id: root
    required property var page

    property bool editMode: false

    show: editMode ? page.showEditExpenseModal : page.showExpenseModal
    modalWidth: 500; modalRadius: 32
    onClose: _close()

    // ── State ────────────────────────────────────────────────────────────────
    property string selectedCategorie: "Autre"

    // ── File dialog ───────────────────────────────────────────────────────────
    Platform.FileDialog {
        id: fileDialog
        title: "Sélectionner un justificatif"
        fileMode: Platform.FileDialog.OpenFile
        nameFilters: ["Documents (*.pdf *.jpg *.jpeg *.png *.doc *.docx)", "Tous les fichiers (*)"]
        onAccepted: {
            var path = fileDialog.file.toString()
            path = path.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "")
            justifField.text = decodeURIComponent(path)
        }
    }

    // ── Pre-fill for edit mode ────────────────────────────────────────────────
    function _populate(dep) {
        if (!dep) return
        libelleField.text      = dep.libelle || ""
        montantField.text      = dep.montant > 0 ? dep.montant.toFixed(2) : ""
        notesField.text        = dep.notes || ""
        justifField.text       = dep.justificatifPath || ""
        root.selectedCategorie = dep.categorie || "Autre"
        if (dep.date && dep.date !== "") dateField.setDate(dep.date)
        else dateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
    }

    // ── Reset ─────────────────────────────────────────────────────────────────
    function _close() {
        if (editMode) page.showEditExpenseModal = false
        else          page.showExpenseModal     = false
        libelleField.text = ""; montantField.text = ""
        notesField.text   = ""; justifField.text  = ""
        root.selectedCategorie = "Autre"
        dateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
    }

    onShowChanged: {
        if (show) {
            if (editMode && page.editingDepense) _populate(page.editingDepense)
            else dateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        width: parent.width; spacing: 0

        // Header
        Column {
            width: parent.width; padding: 32; bottomPadding: 20; spacing: 16
            RowLayout {
                width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                Rectangle { width: 48; height: 48; radius: 20
                    color: editMode ? Style.primaryBg : Style.errorBg
                    IconLabel { anchors.centerIn: parent
                                iconName: editMode ? "edit" : "receipt"; iconSize: 24
                                iconColor: editMode ? Style.primary : Style.errorColor } }
                Column { Layout.fillWidth: true; spacing: 2
                    Text { text: editMode ? "Modifier la Dépense" : "Nouvelle Dépense"
                           font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: "Enregistrement comptable"
                           font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
                }
                IconButton { iconName: "close"; iconSize: 18; onClicked: _close() }
            }
            Separator { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter }
        }

        // Scrollable form
        Flickable {
            id: formFlick
            width: parent.width
            height: Math.min(contentHeight, 420)
            contentWidth: parent.width
            contentHeight: formInner.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: ScrollBar {
                policy: formFlick.contentHeight > formFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            }

            Column {
                id: formInner
                width: parent.width - 64
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 4; bottomPadding: 16; spacing: 18

                FormField { id: libelleField; width: parent.width
                            label: "LIBELLÉ *"
                            placeholder: "Ex: Fournitures, Électricité, Loyer…"
                            fieldHeight: 44 }

                FormField { id: montantField; width: parent.width
                            label: "MONTANT (DT) *"; placeholder: "0.00"; fieldHeight: 44
                            validator: RegularExpressionValidator {
                                regularExpression: /^\d*\.?\d{0,2}$/
                            } }

                Column { width: parent.width; spacing: 6
                    SectionLabel { text: "CATÉGORIE" }
                    Flow { width: parent.width; spacing: 6
                        Repeater {
                            model: ["Fournitures", "Loyer", "Services", "Autre"]
                            delegate: Rectangle {
                                implicitWidth: catText.implicitWidth + 24; height: 34; radius: 10
                                color: root.selectedCategorie === modelData ? Style.primary : Style.bgPage
                                border.color: root.selectedCategorie === modelData ? Style.primary : Style.borderLight
                                Text { id: catText; anchors.centerIn: parent; text: modelData
                                       font.pixelSize: 11; font.weight: Font.Black
                                       color: root.selectedCategorie === modelData ? "white" : Style.textTertiary }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedCategorie = modelData }
                            }
                        }
                    }
                }

                DateField { id: dateField; width: parent.width; label: "DATE DE LA DÉPENSE" }

                FormField { id: notesField; width: parent.width
                            label: "NOTES / COMMENTAIRES"
                            placeholder: "Informations supplémentaires…"
                            fieldHeight: 44 }

                Column { width: parent.width; spacing: 6
                    SectionLabel { text: "JUSTIFICATIF (PIÈCE JOINTE)" }
                    RowLayout { width: parent.width; spacing: 8
                        Rectangle { Layout.fillWidth: true; height: 44; radius: 12
                                    color: Style.bgPage; border.color: Style.borderLight
                            TextInput {
                                id: justifField
                                anchors.fill: parent; anchors.margins: 12
                                font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                                clip: true; selectByMouse: true; readOnly: true
                                Text { visible: !justifField.text; text: "Aucun fichier sélectionné"
                                       font: justifField.font; color: Style.textTertiary }
                            }
                        }
                        Rectangle { Layout.preferredWidth: 44; height: 44; radius: 12
                            color: jBrowse.containsMouse ? Style.primary : Style.bgPage
                            border.color: jBrowse.containsMouse ? Style.primary : Style.borderLight
                            Text { anchors.centerIn: parent; text: "…"
                                   font.pixelSize: 16; font.bold: true
                                   color: jBrowse.containsMouse ? "white" : Style.textTertiary }
                            MouseArea { id: jBrowse; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor; onClicked: fileDialog.open() }
                        }
                    }
                }
            }
        }

        // Buttons
        Column {
            width: parent.width; topPadding: 16; bottomPadding: 28
            ModalButtons {
                width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: editMode ? "Enregistrer les modifications" : "Enregistrer la dépense"
                onCancel: _close()
                onConfirm: {
                    if (libelleField.text.trim() === "") return
                    var montant = parseFloat(montantField.text.replace(",", "."))
                    if (isNaN(montant) || montant <= 0) return

                    var payload = {
                        libelle:          libelleField.text.trim(),
                        montant:          montant,
                        date:             dateField.dateString !== ""
                                          ? dateField.dateString
                                          : Qt.formatDate(new Date(), "yyyy-MM-dd"),
                        categorie:        root.selectedCategorie,
                        notes:            notesField.text.trim(),
                        justificatifPath: justifField.text.trim()
                    }

                    if (editMode)
                        financeController.updateDepense(page.editingDepense.id, payload)
                    else
                        financeController.createDepense(payload)
                    _close()
                }
            }
        }
    }
}
