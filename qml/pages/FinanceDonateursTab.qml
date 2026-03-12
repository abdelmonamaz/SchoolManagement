import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform as Platform
import UI.Components

AppCard {
    id: tab
    required property var page

    // ── State ─────────────────────────────────────────────────────────────────
    property string viewMode:     "donateurs" // "donateurs" | "projets"
    
    // Donateurs state
    property string filterType:   qsTr("Tous")   // "Tous" | "Physique" | "Morale"
    property string localSearch:  ""
    property int    currentPage:  0
    property int    pageSize:     10

    property var    editingDonateur: null
    property bool   showEditModal:   false
    property bool   showExportPopup: false

    // Projets state
    property string projectStatusFilter: "Tous" // "Tous" | "En cours" | "Terminé"

    // ── CSV file dialog ───────────────────────────────────────────────────────
    Platform.FileDialog {
        id: saveDialog
        title: qsTr("Enregistrer le fichier CSV")
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["Fichiers CSV (*.csv)", "Tous les fichiers (*)"]
        defaultSuffix: "csv"
        onAccepted: {
            var path = saveDialog.file.toString()
            path = path.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "")
            financeController.exportDonateursCSV(decodeURIComponent(path))
            tab.showExportPopup = false
        }
        onRejected: { tab.showExportPopup = false }
    }

    // ── Filtered + paginated list (Donateurs) ─────────────────────────────────
    readonly property var filteredDonateurs: {
        var list = financeController.donateurs
        var q    = tab.localSearch.toLowerCase()
        var result = []
        for (var i = 0; i < list.length; i++) {
            var d = list[i]
            var dtype = (d.typePersonne && d.typePersonne !== "") ? d.typePersonne : qsTr("Physique")
            if (tab.filterType !== "Tous" && dtype !== tab.filterType) continue
            if (q !== "") {
                var haystack = (d.nom + " " + d.cin + " " + d.raisonSociale +
                                " " + d.telephone + " " + d.adresse).toLowerCase()
                if (haystack.indexOf(q) < 0) continue
            }
            result.push(d)
        }
        return result
    }

    readonly property int pageCount: Math.max(1, Math.ceil(filteredDonateurs.length / pageSize))

    readonly property var pageItems: {
        var start = currentPage * pageSize
        return filteredDonateurs.slice(start, start + pageSize)
    }

    onFilterTypeChanged:  { currentPage = 0 }
    onLocalSearchChanged: { currentPage = 0 }

    // ── Filtered list (Projets) ───────────────────────────────────────────────
    readonly property var filteredProjets: {
        var list = financeController.projets
        var q = tab.localSearch.toLowerCase()
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

    // ── AppCard header ────────────────────────────────────────────────────────
    title:    tab.viewMode === "donateurs" ? "Liste des Donateurs" : "Projets de l'association"
    subtitle: tab.viewMode === "donateurs" ? filteredDonateurs.length + " donateur(s) enregistré(s)" : projetsStats.total + " projet(s) au total"

    headerAction: Component {
        Row {
            spacing: 8
            Rectangle {
                width: 110; height: 32; radius: 8
                color: tab.viewMode === "donateurs" ? Style.primary : Style.bgPage
                border.color: tab.viewMode === "donateurs" ? Style.primary : Style.borderLight
                Text {
                    anchors.centerIn: parent; text: qsTr("DONATEURS")
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: tab.viewMode === "donateurs" ? "white" : Style.textSecondary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { tab.viewMode = "donateurs"; tab.localSearch = "" }
                }
            }
            Rectangle {
                width: 110; height: 32; radius: 8
                color: tab.viewMode === "projets" ? Style.primary : Style.bgPage
                border.color: tab.viewMode === "projets" ? Style.primary : Style.borderLight
                Text {
                    anchors.centerIn: parent; text: qsTr("PROJETS")
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: tab.viewMode === "projets" ? "white" : Style.textSecondary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { tab.viewMode = "projets"; tab.localSearch = "" }
                }
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function isoToFr(d) {
        if (!d || d === "") return "—"
        var p = d.split("-"); if (p.length < 3) return d
        return p[2] + "/" + p[1] + "/" + p[0]
    }

    // ── Column widths ─────────────────────────────────────────────────────────
    readonly property int wTel:    120
    readonly property int wAction:  70
    readonly property int wDate:   100
    readonly property int wStatus: 100
    readonly property int wMontant: 180

    Column {
        width: parent.width; spacing: 16

        // ── Top bar: recherche + actions ───────────────────────────────────────
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
                        text: tab.localSearch
                        onTextChanged: tab.localSearch = text
                        Text {
                            visible: !localSearchField.text
                            text: tab.viewMode === "donateurs" ? "Rechercher un donateur…" : "Rechercher un projet…"
                            font: localSearchField.font; color: Style.textTertiary
                        }
                    }
                }
            }

            // Boutons d'action
            Rectangle {
                visible: tab.viewMode === "donateurs"
                height: 40; implicitWidth: exportRow.implicitWidth + 24; radius: 12
                color: exportMa.containsMouse ? Style.primary : Style.bgPage
                border.color: exportMa.containsMouse ? Style.primary : Style.borderLight
                RowLayout {
                    id: exportRow
                    anchors.centerIn: parent; spacing: 6
                    IconLabel { iconName: "download"; iconSize: 14
                                iconColor: exportMa.containsMouse ? "white" : Style.textTertiary }
                    Text { text: qsTr("Exporter CSV"); font.pixelSize: 11; font.weight: Font.Black
                           color: exportMa.containsMouse ? "white" : Style.textTertiary }
                }
                MouseArea { id: exportMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tab.showExportPopup = true }
            }

            Rectangle {
                visible: tab.viewMode === "projets"
                height: 40; implicitWidth: newProjRow.implicitWidth + 24; radius: 12
                color: newProjMa.containsMouse ? Style.primaryDark : Style.primary
                RowLayout {
                    id: newProjRow
                    anchors.centerIn: parent; spacing: 6
                    IconLabel { iconName: "plus"; iconSize: 14; iconColor: "white" }
                    Text { text: qsTr("Nouveau Projet"); font.pixelSize: 11; font.weight: Font.Black; color: "white" }
                }
                MouseArea { id: newProjMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { page.editingProject = null; page.showProjectModal = true } }
            }
        }

        // ── Filtres ───────────────────────────────────────────────────────────
        Row { spacing: 6; visible: tab.viewMode === "donateurs"
            Repeater {
                model: [qsTr("Tous"), qsTr("Physique"), qsTr("Morale")]
                delegate: Rectangle {
                    width: 90; height: 34; radius: 10
                    color: tab.filterType === modelData ? Style.primary : Style.bgPage
                    border.color: tab.filterType === modelData ? Style.primary : Style.borderLight
                    Text { anchors.centerIn: parent; text: modelData.toUpperCase()
                           font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                           color: tab.filterType === modelData ? "white" : Style.textTertiary }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: tab.filterType = modelData }
                }
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

        // ── Empty state (Donateurs) ───────────────────────────────────────────
        Column { width: parent.width; spacing: 16
            visible: tab.viewMode === "donateurs" && tab.filteredDonateurs.length === 0
            Item { width: 1; height: 24 }
            Rectangle { width: 56; height: 56; radius: 20; color: Style.warningBorder
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "users"; iconSize: 24; iconColor: Style.warningColor } }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: tab.localSearch !== "" || tab.filterType !== "Tous"
                         ? "Aucun résultat"
                         : "Aucun donateur enregistré"
                   font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary }
            Item { width: 1; height: 24 }
        }

        // ── Empty state (Projets) ─────────────────────────────────────────────
        Column { width: parent.width; spacing: 16
            visible: tab.viewMode === "projets" && tab.filteredProjets.length === 0
            Item { width: 1; height: 24 }
            Rectangle { width: 56; height: 56; radius: 20; color: Style.successBg
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "target"; iconSize: 24; iconColor: Style.successColor } }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: tab.localSearch !== "" || tab.projectStatusFilter !== "Tous"
                         ? "Aucun résultat pour cette recherche"
                         : "Aucun projet enregistré"
                   font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary }
            Item { width: 1; height: 24 }
        }

        // ── Table header (Donateurs) ──────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 40
            visible: tab.viewMode === "donateurs" && tab.filteredDonateurs.length > 0
            spacing: 12
            SectionLabel { Layout.fillWidth: true; text: qsTr("NOM / IDENTITÉ") }
            SectionLabel { Layout.preferredWidth: tab.wTel;    text: qsTr("TÉLÉPHONE"); horizontalAlignment: Text.AlignHCenter }
            Item { Layout.preferredWidth: tab.wAction }
        }
        Separator { width: parent.width; visible: tab.viewMode === "donateurs" && tab.filteredDonateurs.length > 0 }

        // ── Table rows (Donateurs) ────────────────────────────────────────────
        Column { width: parent.width; spacing: 0; visible: tab.viewMode === "donateurs"
            Repeater {
                model: tab.pageItems
                delegate: Column {
                    width: parent.width
                    Rectangle {
                        width: parent.width; height: 68
                        color: rMa.containsMouse ? Style.bgPage : "transparent"
                        MouseArea { id: rMa; anchors.fill: parent; hoverEnabled: true; z: -1 }

                        RowLayout {
                            anchors.fill: parent; spacing: 12

                            // Nom + identifiant (CIN ou MF selon le type)
                            Column {
                                Layout.fillWidth: true; spacing: 3
                                Text { text: modelData.nom
                                       font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                       elide: Text.ElideRight; width: parent.width }
                                Text {
                                    width: parent.width; elide: Text.ElideRight
                                    font.pixelSize: 10; color: Style.textTertiary
                                    text: {
                                        var t = (modelData.typePersonne && modelData.typePersonne !== "")
                                                ? modelData.typePersonne : "Physique"
                                        if (t === "Morale") {
                                            var mf = modelData.matriculeFiscal || ""
                                            return mf !== "" ? "MF : " + mf : (modelData.raisonSociale || "—")
                                        } else {
                                            var cin = modelData.cin || ""
                                            return cin !== "" ? "CIN : " + cin : "—"
                                        }
                                    }
                                }
                            }

                            // Téléphone
                            Text {
                                Layout.preferredWidth: tab.wTel
                                text: modelData.telephone || "—"
                                font.pixelSize: 11; color: Style.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // Action : éditer
                            Item {
                                Layout.preferredWidth: tab.wAction
                                IconButton {
                                    anchors.centerIn: parent
                                    iconName: "edit"; iconSize: 16; hoverColor: Style.primary
                                    onClicked: {
                                        tab.editingDonateur = modelData
                                        tab.showEditModal   = true
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
            SectionLabel { Layout.fillWidth: true; text: qsTr("PROJET") }
            SectionLabel { Layout.preferredWidth: tab.wDate; text: qsTr("PÉRIODE"); horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wStatus; text: qsTr("STATUT"); horizontalAlignment: Text.AlignHCenter }
            SectionLabel { Layout.preferredWidth: tab.wMontant; text: qsTr("MONTANT (COLLECTÉ / OBJECTIF)"); horizontalAlignment: Text.AlignHCenter }
            Item { Layout.preferredWidth: tab.wAction }
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
                                Layout.preferredWidth: tab.wMontant; spacing: 4
                                RowLayout {
                                    width: parent.width; spacing: 4
                                    Text { Layout.fillWidth: true; text: qsTr("COLLECTÉ"); font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 0.8; color: Style.textTertiary }
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
                                Layout.preferredWidth: tab.wAction; spacing: 4
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

        // ── Pagination (Donateurs) ────────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 44
            visible: tab.viewMode === "donateurs" && tab.pageCount > 1
            spacing: 8

            Item { Layout.fillWidth: true }

            Rectangle { width: 36; height: 36; radius: 10
                color: prevPgMa.containsMouse && tab.currentPage > 0 ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderLight
                Text { anchors.centerIn: parent; text: qsTr("‹"); font.pixelSize: 18; font.bold: true
                       color: tab.currentPage > 0 ? Style.textPrimary : Style.textTertiary }
                MouseArea { id: prevPgMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: tab.currentPage > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (tab.currentPage > 0) tab.currentPage-- }
            }

            Text { text: (tab.currentPage + 1) + " / " + tab.pageCount
                   font.pixelSize: 11; font.weight: Font.Black; color: Style.textPrimary }

            Rectangle { width: 36; height: 36; radius: 10
                color: nextPgMa.containsMouse && tab.currentPage < tab.pageCount - 1 ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderLight
                Text { anchors.centerIn: parent; text: qsTr("›"); font.pixelSize: 18; font.bold: true
                       color: tab.currentPage < tab.pageCount - 1 ? Style.textPrimary : Style.textTertiary }
                MouseArea { id: nextPgMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: tab.currentPage < tab.pageCount - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (tab.currentPage < tab.pageCount - 1) tab.currentPage++ }
            }

            Item { Layout.fillWidth: true }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // EXPORT POPUP (confirmation avant sélection du fichier)
    // ═════════════════════════════════════════════════════════════════════════
    ModalOverlay {
        show: tab.showExportPopup; modalWidth: 400; modalRadius: 28
        onClose: tab.showExportPopup = false

        Column { width: parent.width; spacing: 20; padding: 32; bottomPadding: 24
            RowLayout { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                Rectangle { width: 48; height: 48; radius: 20; color: Style.primaryBg
                    IconLabel { anchors.centerIn: parent; iconName: "download"; iconSize: 24; iconColor: Style.primary } }
                Column { Layout.fillWidth: true; spacing: 2
                    Text { text: qsTr("Exporter les Donateurs"); font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: tab.filteredDonateurs.length + " donateur(s) — format CSV"
                           font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
                }
                IconButton { iconName: "close"; iconSize: 18; onClicked: tab.showExportPopup = false }
            }
            Rectangle { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: expInfo.implicitHeight + 24; radius: 14
                color: Style.primaryBg; border.color: Style.borderLight
                Text { id: expInfo; anchors.fill: parent; anchors.margins: 14
                    text: qsTr("Cliquez sur <b>Confirmer</b> pour choisir l'emplacement d'enregistrement du fichier CSV.")
                    font.pixelSize: 12; color: Style.textSecondary; wrapMode: Text.WordWrap
                    textFormat: Text.RichText; lineHeight: 1.5 }
            }
            ModalButtons { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter
                cancelText: qsTr("Annuler"); confirmText: qsTr("Confirmer")
                onCancel:  tab.showExportPopup = false
                onConfirm: saveDialog.open()
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // EDIT DONATEUR MODAL
    // ═════════════════════════════════════════════════════════════════════════
    ModalOverlay {
        id: editModal
        show: tab.showEditModal; modalWidth: 520; modalRadius: 32
        onClose: _closeEdit()

        property string typePersonne: "Physique"

        function _populate(d) {
            if (!d) return
            editNomField.text = d.nom || ""
            editTelField.text = d.telephone || ""
            editAdrField.text = d.adresse || ""
            editModal.typePersonne = d.typePersonne || "Physique"
            editCinField.text = d.cin || ""
            editRsField.text  = d.raisonSociale || ""
            editMfField.text  = d.matriculeFiscal || ""
            editRlField.text  = d.representantLegal || ""
        }

        function _closeEdit() {
            tab.showEditModal = false
            tab.editingDonateur = null
        }

        onShowChanged: {
            if (show && tab.editingDonateur) _populate(tab.editingDonateur)
        }

        Column {
            width: parent.width; spacing: 0

            // Header
            Column {
                width: parent.width; padding: 32; bottomPadding: 20; spacing: 16
                RowLayout {
                    width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                    Rectangle { width: 48; height: 48; radius: 20; color: Style.primaryBg
                        IconLabel { anchors.centerIn: parent; iconName: "edit"; iconSize: 24; iconColor: Style.primary } }
                    Column { Layout.fillWidth: true; spacing: 2
                        Text { text: qsTr("Modifier le Donateur"); font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary }
                        Text { text: qsTr("Conforme Décret-loi 2011-88"); font.pixelSize: 10; color: Style.primary; font.weight: Font.Bold }
                    }
                    IconButton { iconName: "close"; iconSize: 18; onClicked: editModal._closeEdit() }
                }
                Separator { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter }
            }

            // Scrollable form
            Flickable {
                id: editFlick
                width: parent.width
                height: Math.min(contentHeight, 400)
                contentWidth: parent.width
                contentHeight: editFormCol.implicitHeight
                clip: true; flickableDirection: Flickable.VerticalFlick
                ScrollBar.vertical: ScrollBar {
                    policy: editFlick.contentHeight > editFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }

                Column {
                    id: editFormCol
                    width: parent.width - 64
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 4; bottomPadding: 16; spacing: 16

                    FormField { id: editNomField; width: parent.width
                                label: qsTr("NOM / DÉNOMINATION *")
                                placeholder: qsTr("Nom complet ou raison sociale")
                                fieldHeight: 44 }

                    Column { width: parent.width; spacing: 6
                        SectionLabel { text: qsTr("TYPE DE PERSONNE") }
                        Row { spacing: 6; width: parent.width
                            Repeater {
                                model: ["Physique", "Morale"]
                                delegate: Rectangle {
                                    width: (parent.width - 6) / 2; height: 36; radius: 10
                                    color: editModal.typePersonne === modelData ? Style.primary : Style.bgPage
                                    border.color: editModal.typePersonne === modelData ? Style.primary : Style.borderLight
                                    Text { anchors.centerIn: parent
                                           text: qsTr("PERSONNE ") + modelData.toUpperCase()
                                           font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                                           color: editModal.typePersonne === modelData ? "white" : Style.textTertiary }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: editModal.typePersonne = modelData }
                                }
                            }
                        }
                    }

                    FormField { id: editCinField; width: parent.width
                                visible: editModal.typePersonne === "Physique"
                                label: qsTr("N° CIN"); placeholder: qsTr("00000000"); fieldHeight: 44 }

                    Column { width: parent.width; spacing: 10
                             visible: editModal.typePersonne === "Morale"
                        FormField { id: editRsField; width: parent.width
                                    label: qsTr("RAISON SOCIALE"); placeholder: qsTr("Dénomination officielle"); fieldHeight: 44 }
                        FormField { id: editMfField; width: parent.width
                                    label: qsTr("MATRICULE FISCAL"); placeholder: qsTr("Ex: 1234567/A/M/000"); fieldHeight: 44 }
                        FormField { id: editRlField; width: parent.width
                                    label: qsTr("REPRÉSENTANT LÉGAL"); placeholder: qsTr("Nom du représentant"); fieldHeight: 44 }
                    }

                    RowLayout { width: parent.width; spacing: 8
                        FormField { id: editTelField; Layout.fillWidth: true
                                    label: qsTr("TÉLÉPHONE"); placeholder: qsTr("XX XXX XXX"); fieldHeight: 44 }
                        FormField { id: editAdrField; Layout.fillWidth: true
                                    label: qsTr("ADRESSE"); placeholder: qsTr("Adresse"); fieldHeight: 44 }
                    }
                }
            }

            // Buttons
            Column {
                width: parent.width; topPadding: 16; bottomPadding: 28
                ModalButtons {
                    width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter
                    cancelText: qsTr("Annuler"); confirmText: qsTr("Enregistrer les modifications")
                    onCancel: editModal._closeEdit()
                    onConfirm: {
                        if (editNomField.text.trim() === "") return
                        if (!tab.editingDonateur) return
                        financeController.updateDonateur(tab.editingDonateur.id, {
                            nom:               editNomField.text.trim(),
                            telephone:         editTelField.text.trim(),
                            adresse:           editAdrField.text.trim(),
                            typePersonne:      editModal.typePersonne,
                            cin:               editModal.typePersonne === "Physique" ? editCinField.text.trim() : "",
                            raisonSociale:     editModal.typePersonne === "Morale"   ? editRsField.text.trim()  : "",
                            matriculeFiscal:   editModal.typePersonne === "Morale"   ? editMfField.text.trim()  : "",
                            representantLegal: editModal.typePersonne === "Morale"   ? editRlField.text.trim()  : ""
                        })
                        editModal._closeEdit()
                    }
                }
            }
        }
    }
}
