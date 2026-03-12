import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import UI.Components

ModalOverlay {
    id: root
    required property var page

    property bool editMode: false

    show: editMode ? page.showEditProjectModal : page.showProjectModal
    modalWidth: 500; modalRadius: 32
    onClose: _close()

    function _populate(p) {
        if (!p) return
        nomField.text = p.nom || ""
        descField.text = p.description || ""
        objectifField.text = p.objectifFinancier > 0 ? p.objectifFinancier.toFixed(2) : ""
        if (p.dateDebut && p.dateDebut !== "") dateDebutField.setDate(p.dateDebut)
        if (p.dateFin && p.dateFin !== "") dateFinField.setDate(p.dateFin)
    }

    function _close() {
        if (editMode) page.showEditProjectModal = false
        else          page.showProjectModal     = false
        nomField.text = ""; descField.text = ""; objectifField.text = ""
        dateDebutField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
        dateFinField.setDate("")
    }

    onShowChanged: {
        if (show) {
            if (editMode && page.editingProject) _populate(page.editingProject)
            else {
                dateDebutField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
                dateFinField.setDate("")
            }
        }
    }

    Column {
        width: parent.width; spacing: 0

        // Header
        Column {
            width: parent.width; padding: 32; bottomPadding: 20; spacing: 16
            RowLayout {
                width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                Rectangle { width: 48; height: 48; radius: 20
                    color: editMode ? Style.primaryBg : Style.successBg
                    IconLabel { anchors.centerIn: parent
                                iconName: editMode ? "edit" : "target"; iconSize: 24
                                iconColor: editMode ? Style.primary : Style.successColor } }
                Column { Layout.fillWidth: true; spacing: 2
                    Text { text: editMode ? "Modifier le Projet" : "Nouveau Projet"
                           font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: "Gestion des projets de l'association"
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

                FormField { id: nomField; width: parent.width
                            label: "NOM DU PROJET *"
                            placeholder: "Ex: Rénovation école..."
                            fieldHeight: 44 }

                FormField { id: descField; width: parent.width
                            label: "DESCRIPTION"
                            placeholder: "Objectifs, détails..."
                            fieldHeight: 44 }

                FormField { id: objectifField; width: parent.width
                            label: "OBJECTIF FINANCIER (DT) *"; placeholder: "0.00"; fieldHeight: 44
                            validator: RegularExpressionValidator {
                                regularExpression: /^\d*\.?\d{0,2}$/
                            } }

                DateField { id: dateDebutField; width: parent.width; label: "DATE DE DÉBUT *" }
                DateField { id: dateFinField; width: parent.width; label: "DATE DE FIN (Optionnelle)" }
            }
        }

        // Buttons
        Column {
            width: parent.width; topPadding: 16; bottomPadding: 28
            ModalButtons {
                width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: editMode ? "Enregistrer les modifications" : "Créer le projet"
                onCancel: _close()
                onConfirm: {
                    if (nomField.text.trim() === "") return
                    var objectif = parseFloat(objectifField.text.replace(",", "."))
                    if (isNaN(objectif) || objectif <= 0) return

                    var payload = {
                        nom:               nomField.text.trim(),
                        description:       descField.text.trim(),
                        objectifFinancier: objectif,
                        dateDebut:         dateDebutField.dateString !== "" ? dateDebutField.dateString : Qt.formatDate(new Date(), "yyyy-MM-dd"),
                        dateFin:           dateFinField.dateString,
                        statut:            editMode ? page.editingProject.statut : "En cours"
                    }

                    if (editMode)
                        financeController.updateProjet(page.editingProject.id, payload)
                    else
                        financeController.createProjet(payload)
                    _close()
                }
            }
        }
    }
}