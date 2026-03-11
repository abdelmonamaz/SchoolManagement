import QtQuick
import QtQuick.Layouts
import UI.Components

AppCard {
    id: tab
    required property var page

    // ── State ─────────────────────────────────────────────────────────────────
    property string viewMode:     "dons" // "dons" | "projets"
    
    // Projets state
    property string projectStatusFilter: "Tous" // "Tous" | "En cours" | "Terminé"
    property string projectSearch: ""

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

    // ── Filtered list (Dons) ─────────────────────────────────────────────────
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

    // ── Filtered list (Projets) ───────────────────────────────────────────────
    readonly property var filteredProjets: {
        var list = financeController.projets
        var q = tab.projectSearch.toLowerCase()
        var result = []
        for (var i = 0; i < list.length; i++) {
            var p = list[i]
            if (tab.projectStatusFilter !== "Tous" && p.statut !== tab.projectStatusFilter) continue
            if (q !== "") {
                if (p.nom.toLowerCase().indexOf(q) < 0 && 
                    (p.description || "").toLowerCase().indexOf(q) < 0) continue
            }
            result.push(p)
        }
        return result
    }
    
    readonly property var projetsStats: {
        var list = financeController.projets
        var enCours = 0, termine = 0
        for(var i = 0; i < list.length; i++) {
            if (list[i].statut === "Terminé" || list[i].statut === "Termine") termine++
            else if (list[i].statut === "En cours") enCours++
        }
        return { total: list.length, enCours: enCours, termine: termine }
    }

    // ── AppCard header ───────────────────────────────────────────────────────
    title:    tab.viewMode === "dons" ? "Dons & Revenue — " + page.selectedMonth + " " + page.selectedYear : "Projets de l'association"
    subtitle: tab.viewMode === "dons" ? "Donations enregistrées ce mois" : projetsStats.total + " projet(s) au total"

    headerAction: Component {
        Row {
            spacing: 8
            Rectangle {
                width: 110; height: 32; radius: 8
                color: tab.viewMode === "dons" ? Style.primary : Style.bgPage
                border.color: tab.viewMode === "dons" ? Style.primary : Style.borderLight
                Text {
                    anchors.centerIn: parent; text: "DONS"
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: tab.viewMode === "dons" ? "white" : Style.textSecondary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { tab.viewMode = "dons"; tab.projectSearch = "" }
                }
            }
            Rectangle {
                width: 110; height: 32; radius: 8
                color: tab.viewMode === "projets" ? Style.primary : Style.bgPage
                border.color: tab.viewMode === "projets" ? Style.primary : Style.borderLight
                Text {
                    anchors.centerIn: parent; text: "PROJETS"
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: tab.viewMode === "projets" ? "white" : Style.textSecondary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { tab.viewMode = "projets"; page.searchTerm = "" }
                }
            }
        }
    }

    // ── Largeurs de colonnes (partagées header ↔ lignes) ─────────────────────
    readonly property int wProjet:   130
    readonly property int wNature:   90
    readonly property int wDate:     100
    readonly property int wMontant:  120
    readonly property int wMontantProj: 180
    readonly property int wActions:  72
    readonly property int wStatus:   100

    Column {
        width: parent.width; spacing: 16

        // ── Top bar: recherche + actions ─────────────────────────────────────
        RowLayout {
            width: parent.width; spacing: 12

            // Recherche locale
            Rectangle {
                Layout.fillWidth: true; height: 40; radius: 12
                color: Style.bgPage; border.color: Style.borderLight
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8
                    IconLabel { iconName: "search"; iconSize: 14; iconColor: Style.textTertiary }
                    TextInput {
                        id: localSearchField
                        Layout.fillWidth: true
                        font.pixelSize: 13; color: Style.textPrimary
                        text: tab.viewMode === "dons" ? page.searchTerm : tab.projectSearch
                        onTextChanged: {
                            if (tab.viewMode === "dons") page.searchTerm = text
                            else tab.projectSearch = text
                        }
                        Text {
                            visible: !localSearchField.text
                            text: tab.viewMode === "dons" ? "Rechercher un donateur..." : "Rechercher un projet…"
                            font: localSearchField.font; color: Style.textTertiary
                        }
                    }
                }
            }

            // Boutons d'action : Nouveau Don
            Rectangle {
                visible: tab.viewMode === "dons"
                height: 40; implicitWidth: newDonRow.implicitWidth + 24; radius: 12
                color: newDonMa.containsMouse ? Style.primaryDark : Style.primary
                RowLayout {
                    id: newDonRow
                    anchors.centerIn: parent; spacing: 6
                    IconLabel { iconName: "plus"; iconSize: 14; iconColor: "white" }
                    Text { text: "Nouveau Don"; font.pixelSize: 11; font.weight: Font.Black; color: "white" }
                }
                MouseArea { id: newDonMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.showDonationModal = true }
            }

            // Boutons d'action : Nouveau Projet
            Rectangle {
                visible: tab.viewMode === "projets"
                height: 40; implicitWidth: newProjRow.implicitWidth + 24; radius: 12
                color: newProjMa.containsMouse ? Style.primaryDark : Style.primary
                RowLayout {
                    id: newProjRow
                    anchors.centerIn: parent; spacing: 6
                    IconLabel { iconName: "plus"; iconSize: 14; iconColor: "white" }
                    Text { text: "Nouveau Projet"; font.pixelSize: 11; font.weight: Font.Black; color: "white" }
                }
                MouseArea { id: newProjMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { page.editingProject = null; page.showProjectModal = true } }
            }
        }

        Row { spacing: 6; visible: tab.viewMode === "projets"
            Repeater {
                model: ["Tous", "En cours", "Terminé"]
                delegate: Rectangle {
                    width: 90; height: 34; radius: 10
                    color: tab.projectStatusFilter === modelData ? Style.primary : Style.bgPage
                    border.color: tab.projectStatusFilter === modelData ? Style.primary : Style.borderLight
                    Text { anchors.centerIn: parent; text: modelData.toUpperCase()
                           font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                           color: tab.projectStatusFilter === modelData ? "white" : Style.textTertiary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: tab.projectStatusFilter = modelData }
                }
            }
        }


        Item { width: parent.width; height: 48; visible: financeController.loading
            Text { anchors.centerIn: parent; text: "Chargement…"; font.pixelSize: 13; color: Style.textTertiary } }

        // ── Empty state (Dons) ───────────────────────────────────────────────
        Column { width: parent.width; spacing: 16
            visible: !financeController.loading && tab.viewMode === "dons" && tab.filteredDons.length === 0
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

        // ── Empty state (Projets) ─────────────────────────────────────────────
        Column { width: parent.width; spacing: 16
            visible: !financeController.loading && tab.viewMode === "projets" && tab.filteredProjets.length === 0
            Item { width: 1; height: 24 }
            Rectangle { width: 56; height: 56; radius: 20; color: "#ECFDF5"
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "target"; iconSize: 24; iconColor: "#059669" } }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: tab.projectSearch !== "" || tab.projectStatusFilter !== "Tous"
                         ? "Aucun résultat pour cette recherche"
                         : "Aucun projet enregistré"
                   font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary }
            Item { width: 1; height: 24 }
        }


        // ── Table header (Dons) ──────────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 40
            visible: tab.viewMode === "dons" && tab.filteredDons.length > 0
            spacing: 12

            SectionLabel { Layout.fillWidth: true; text: "DONATEUR" }
            SectionLabel { Layout.preferredWidth: tab.wProjet; text: "PROJET"; horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wNature; text: "NATURE"; horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wDate; text: "DATE"; horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wMontant; text: "MONTANT"; horizontalAlignment: Text.AlignHCenter }
            Item { Layout.preferredWidth: tab.wActions }
        }
        Separator { width: parent.width; visible: tab.viewMode === "dons" && tab.filteredDons.length > 0 }

        // ── Table rows (Dons) ────────────────────────────────────────────────
        Column { width: parent.width; spacing: 0; visible: tab.viewMode === "dons"
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

                            Text {
                                Layout.preferredWidth: tab.wProjet
                                text: tab.projetName(modelData.projetId)
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: Style.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

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

                            Text {
                                Layout.preferredWidth: tab.wDate
                                text: tab.isoToFr(modelData.dateDon)
                                font.pixelSize: 11; font.weight: Font.Medium
                                color: Style.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                            }

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


        // ── Table header (Projets) ────────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 40
            visible: tab.viewMode === "projets" && tab.filteredProjets.length > 0
            spacing: 12
            SectionLabel { Layout.fillWidth: true; text: "PROJET" }
            SectionLabel { Layout.preferredWidth: tab.wDate; text: "PÉRIODE"; horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wStatus; text: "STATUT"; horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wMontantProj; text: "MONTANT (COLLECTÉ / OBJECTIF)"; horizontalAlignment: Text.AlignHCenter }
            Item { Layout.preferredWidth: tab.wActions }
        }
        Separator { width: parent.width; visible: tab.viewMode === "projets" && tab.filteredProjets.length > 0 }

        // ── Table rows (Projets) ──────────────────────────────────────────────
        Column { width: parent.width; spacing: 0; visible: tab.viewMode === "projets"
            Repeater {
                model: tab.filteredProjets
                delegate: Column {
                    width: parent.width
                    Rectangle {
                        width: parent.width; height: 68
                        color: pMa.containsMouse ? Style.bgPage : "transparent"
                        MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true; z: -1 }

                        RowLayout {
                            anchors.fill: parent; spacing: 12

                            // Nom + desc
                            Column {
                                Layout.fillWidth: true; spacing: 3
                                Text { text: modelData.nom
                                       font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                       elide: Text.ElideRight; width: parent.width }
                                Text { text: modelData.description || "—"
                                       font.pixelSize: 10; color: Style.textTertiary
                                       elide: Text.ElideRight; width: parent.width }
                            }

                            // Dates
                            Column {
                                Layout.preferredWidth: tab.wDate; spacing: 2
                                Text { text: tab.isoToFr(modelData.dateDebut)
                                       font.pixelSize: 11; color: Style.textSecondary; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                                Text { text: modelData.dateFin ? tab.isoToFr(modelData.dateFin) : "—"
                                       font.pixelSize: 9; color: Style.textTertiary; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                            }

                            // Statut
                            Item {
                                Layout.preferredWidth: tab.wStatus; implicitHeight: 24
                                property bool isFinished: modelData.statut === "Terminé" || modelData.statut === "Termine" || (modelData.totalDons >= modelData.objectifFinancier && modelData.objectifFinancier > 0)
                                Badge {
                                    anchors.centerIn: parent
                                    text: parent.isFinished ? "Terminé" : "En cours"
                                    variant: parent.isFinished ? "success" : "neutral"
                                }
                            }

                            // Montant
                            Column {
                                Layout.preferredWidth: tab.wMontantProj; spacing: 4
                                RowLayout {
                                    width: parent.width; spacing: 4
                                    Text { Layout.fillWidth: true; text: "COLLECTÉ"; font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.8; color: Style.textTertiary }
                                    Text { text: (modelData.totalDons || 0).toFixed(0) + " / " + modelData.objectifFinancier.toFixed(0) + " DT"
                                           font.pixelSize: 10; font.weight: Font.Black; color: Style.textSecondary }
                                }
                                Rectangle { width: parent.width; height: 6; radius: 3; color: Style.bgSecondary
                                    Rectangle {
                                        width: modelData.objectifFinancier > 0 
                                               ? Math.min(parent.width * (modelData.totalDons || 0) / modelData.objectifFinancier, parent.width) 
                                               : 0
                                        height: parent.height; radius: parent.radius; color: Style.successColor
                                    }
                                }
                            }

                            // Actions
                            RowLayout {
                                Layout.preferredWidth: tab.wActions; spacing: 4
                                IconButton {
                                    iconName: "edit"; iconSize: 16; hoverColor: Style.primary
                                    onClicked: {
                                        page.editingProject = modelData
                                        page.showEditProjectModal = true
                                    }
                                }
                                IconButton {
                                    iconName: "trash"; iconSize: 16; hoverColor: Style.errorColor
                                    onClicked: {
                                        page.deleteType = "projet"
                                        page.deleteItemId = modelData.id
                                        page.deleteItemName = modelData.nom
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
    }
}