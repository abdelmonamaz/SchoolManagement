import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

AppCard {
    id: tab
    required property var page

    // ── Helpers ──────────────────────────────────────────────────────────────
    function donateurName(id) {
        var list = financeController.donateurs
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i].nom
        return "Donateur #" + id
    }
    function projetName(id) {
        if (id <= 0) return "Général"
        var list = financeController.projets
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i].nom
        return "Projet #" + id
    }
    function isoToFr(d) {
        if (!d || d === "") return "—"
        var p = d.split("-"); if (p.length < 3) return d
        return p[2] + "/" + p[1] + "/" + p[0]
    }

    // ── Filtered dons ────────────────────────────────────────────────────────
    readonly property var filteredDons: {
        var _dons = financeController.dons
        var m = page.selectedMonthIndex + 1
        var y = page.selectedYear
        var q = page.searchTerm.toLowerCase()
        var result = []
        for (var i = 0; i < _dons.length; i++) {
            var don = _dons[i]
            if (!don.dateDon) continue
            var dp = don.dateDon.split("-")
            if (dp.length < 3) continue
            if (parseInt(dp[1]) !== m || parseInt(dp[0]) !== y) continue
            if (q !== "") {
                if (donateurName(don.donateurId).toLowerCase().indexOf(q) < 0) continue
            }
            result.push(don)
        }
        return result
    }

    // ── AppCard header ───────────────────────────────────────────────────────
    title:    "Dons & Waqf — " + page.selectedMonth + " " + page.selectedYear
    subtitle: "Donations enregistrées ce mois"

    // ── Largeurs de colonnes (partagées header ↔ lignes) ─────────────────────
    readonly property int wProjet:   130
    readonly property int wNature:   90
    readonly property int wDate:     100
    readonly property int wMontant:  120
    readonly property int wActions:  72   // 2 boutons × 32 + espacement

    Column {
        width: parent.width; spacing: 16

        Item { width: parent.width; height: 48; visible: financeController.loading
            Text { anchors.centerIn: parent; text: "Chargement…"; font.pixelSize: 13; color: Style.textTertiary } }

        // ── Empty state ──────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 16
            visible: !financeController.loading && tab.filteredDons.length === 0
            Item { width: 1; height: 24 }
            Rectangle { width: 56; height: 56; radius: 20; color: "#FEF3C7"
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "heart"; iconSize: 24; iconColor: "#D97706" } }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: page.searchTerm !== "" ? "Aucun résultat pour \"" + page.searchTerm + "\""
                                                : "Aucun don pour " + page.selectedMonth + " " + page.selectedYear
                   font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary }
            PrimaryButton { anchors.horizontalCenter: parent.horizontalCenter
                visible: page.searchTerm === ""; text: "Enregistrer un don"; iconName: "plus"
                onClicked: page.showDonationModal = true }
            Item { width: 1; height: 24 }
        }

        // ── Table header ─────────────────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 40
            visible: tab.filteredDons.length > 0
            spacing: 12

            // DONATEUR : aligné à gauche (fillWidth)
            SectionLabel { Layout.fillWidth: true; text: "DONATEUR" }

            // Colonnes centrées
            SectionLabel {
                Layout.preferredWidth: tab.wProjet
                text: "PROJET"
                horizontalAlignment: Text.AlignHCenter
            }
            SectionLabel {
                Layout.preferredWidth: tab.wNature
                text: "NATURE"
                horizontalAlignment: Text.AlignHCenter
            }
            SectionLabel {
                Layout.preferredWidth: tab.wDate
                text: "DATE"
                horizontalAlignment: Text.AlignHCenter
            }
            SectionLabel {
                Layout.preferredWidth: tab.wMontant
                text: "MONTANT"
                horizontalAlignment: Text.AlignHCenter
            }
            // Colonne actions (vide)
            Item { Layout.preferredWidth: tab.wActions }
        }
        Separator { width: parent.width; visible: tab.filteredDons.length > 0 }

        // ── Table rows ───────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 0
            Repeater {
                model: tab.filteredDons
                delegate: Column {
                    width: parent.width
                    Rectangle {
                        width: parent.width; height: 68
                        color: dRowMa.containsMouse ? Style.bgPage : "transparent"
                        MouseArea { id: dRowMa; anchors.fill: parent; hoverEnabled: true; z: -1 }

                        RowLayout {
                            anchors.fill: parent; spacing: 12

                            // ── DONATEUR (gauche, fillWidth) ──────────────
                            Column {
                                Layout.fillWidth: true; spacing: 3
                                Text { text: tab.donateurName(modelData.donateurId)
                                       font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                       elide: Text.ElideRight; width: parent.width }
                                Text {
                                    text: modelData.natureDon === "Nature"
                                          ? (modelData.descriptionMateriel || "Don en nature")
                                          : (modelData.modePaiement || "Espèces")
                                    font.pixelSize: 10; color: Style.textTertiary
                                    elide: Text.ElideRight; width: parent.width
                                }
                            }

                            // ── PROJET (centré) ───────────────────────────
                            Text {
                                Layout.preferredWidth: tab.wProjet
                                text: tab.projetName(modelData.projetId)
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: Style.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            // ── NATURE (badge centré) ─────────────────────
                            Item {
                                Layout.preferredWidth: tab.wNature
                                height: 22
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 76; height: 22; radius: 6
                                    color: modelData.natureDon === "Nature" ? "#FEF3C7" : Style.primaryBg
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.natureDon === "Nature" ? "EN NATURE" : "NUMÉRAIRE"
                                        font.pixelSize: 8; font.weight: Font.Black
                                        color: modelData.natureDon === "Nature" ? "#D97706" : Style.primary
                                    }
                                }
                            }

                            // ── DATE (centrée) ────────────────────────────
                            Text {
                                Layout.preferredWidth: tab.wDate
                                text: tab.isoToFr(modelData.dateDon)
                                font.pixelSize: 11; font.weight: Font.Medium
                                color: Style.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // ── MONTANT (centré) ──────────────────────────
                            Text {
                                Layout.preferredWidth: tab.wMontant
                                text: (modelData.montantEffectif !== undefined
                                       ? modelData.montantEffectif
                                       : (modelData.natureDon === "Nature"
                                          ? modelData.valeurEstimee : modelData.montant)
                                      ).toFixed(2) + " DT"
                                font.pixelSize: 13; font.weight: Font.Black
                                color: Style.successColor
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // ── ACTIONS : édition + suppression ──────────
                            RowLayout {
                                Layout.preferredWidth: tab.wActions
                                spacing: 4
                                IconButton {
                                    iconName: "edit"; iconSize: 16
                                    hoverColor: Style.primary
                                    onClicked: {
                                        page.editingDon      = modelData
                                        page.showEditDonModal = true
                                    }
                                }
                                IconButton {
                                    iconName: "trash"; iconSize: 16
                                    hoverColor: Style.errorColor
                                    onClicked: {
                                        page.deleteType     = "don"
                                        page.deleteItemId   = modelData.id
                                        page.deleteItemName = tab.donateurName(modelData.donateurId)
                                        page.showDeleteModal = true
                                    }
                                }
                            }
                        }
                    }
                    Separator { width: parent.width }
                }
            }
        }

        // ── Campaigns section ────────────────────────────────────────────────
        Column { width: parent.width; spacing: 12
            visible: financeController.projets.length > 0
            Item { width: 1; height: 8 }
            Separator { width: parent.width }
            SectionLabel { text: "CAMPAGNES DE FINANCEMENT" }
            Flow { width: parent.width; spacing: 12
                Repeater {
                    model: financeController.projets
                    delegate: Rectangle {
                        width: Math.max((parent.width - 12) / 2, 200); height: 76; radius: 14
                        color: Style.bgPage; border.color: Style.borderLight
                        Column { anchors.fill: parent; anchors.margins: 14; spacing: 4
                            RowLayout { width: parent.width; spacing: 8
                                Text { Layout.fillWidth: true; text: modelData.nom
                                       font.pixelSize: 13; font.bold: true; color: Style.textPrimary; elide: Text.ElideRight }
                                Badge { text: modelData.statut
                                    variant: modelData.statut === "Terminé" ? "success"
                                           : modelData.statut === "En pause" ? "warning" : "neutral" }
                            }
                            Text { text: modelData.description || "—"; font.pixelSize: 10; color: Style.textTertiary; elide: Text.ElideRight; width: parent.width }
                            Text { text: "Objectif : " + modelData.objectifFinancier.toFixed(0) + " DT"; font.pixelSize: 10; font.weight: Font.Black; color: Style.primary }
                        }
                    }
                }
            }
        }
    }
}
