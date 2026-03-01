import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1 as Platform
import UI.Components

AppCard {
    id: tab
    required property var page

    // ── State ─────────────────────────────────────────────────────────────────
    property string filterType:   "Tous"   // "Tous" | "Physique" | "Morale"
    property string localSearch:  ""
    property int    currentPage:  0
    property int    pageSize:     10

    property var    editingDonateur: null
    property bool   showEditModal:   false
    property bool   showExportPopup: false

    // ── CSV file dialog ───────────────────────────────────────────────────────
    Platform.FileDialog {
        id: saveDialog
        title: "Enregistrer le fichier CSV"
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

    // ── Filtered + paginated list ─────────────────────────────────────────────
    readonly property var filteredDonateurs: {
        var list = financeController.donateurs
        var q    = tab.localSearch.toLowerCase()
        var result = []
        for (var i = 0; i < list.length; i++) {
            var d = list[i]
            var dtype = (d.typePersonne && d.typePersonne !== "") ? d.typePersonne : "Physique"
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

    // ── AppCard header ────────────────────────────────────────────────────────
    title:    "Liste des Donateurs"
    subtitle: filteredDonateurs.length + " donateur(s) enregistré(s)"

    // ── Column widths ─────────────────────────────────────────────────────────
    readonly property int wTel:    120
    readonly property int wAction:  50

    Column {
        width: parent.width; spacing: 16

        // ── Top bar: recherche + export ───────────────────────────────────────
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
                        onTextChanged: tab.localSearch = text
                        Text {
                            visible: !localSearchField.text
                            text: "Rechercher un donateur…"
                            font: localSearchField.font; color: Style.textTertiary
                        }
                    }
                }
            }

            // Bouton export CSV
            Rectangle {
                height: 40; implicitWidth: exportRow.implicitWidth + 24; radius: 12
                color: exportMa.containsMouse ? Style.primary : Style.bgPage
                border.color: exportMa.containsMouse ? Style.primary : Style.borderLight
                RowLayout {
                    id: exportRow
                    anchors.centerIn: parent; spacing: 6
                    IconLabel { iconName: "download"; iconSize: 14
                                iconColor: exportMa.containsMouse ? "white" : Style.textTertiary }
                    Text { text: "Exporter CSV"; font.pixelSize: 11; font.weight: Font.Black
                           color: exportMa.containsMouse ? "white" : Style.textTertiary }
                }
                MouseArea { id: exportMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tab.showExportPopup = true }
            }
        }

        // ── Filtre Tous / Physique / Morale ───────────────────────────────────
        Row { spacing: 6
            Repeater {
                model: ["Tous", "Physique", "Morale"]
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

        // ── Empty state ───────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 16
            visible: tab.filteredDonateurs.length === 0
            Item { width: 1; height: 24 }
            Rectangle { width: 56; height: 56; radius: 20; color: "#FEF3C7"
                        anchors.horizontalCenter: parent.horizontalCenter
                IconLabel { anchors.centerIn: parent; iconName: "users"; iconSize: 24; iconColor: "#D97706" } }
            Text { anchors.horizontalCenter: parent.horizontalCenter
                   text: tab.localSearch !== "" || tab.filterType !== "Tous"
                         ? "Aucun résultat"
                         : "Aucun donateur enregistré"
                   font.pixelSize: 13; font.weight: Font.Medium; color: Style.textTertiary }
            Item { width: 1; height: 24 }
        }

        // ── Table header ──────────────────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 40
            visible: tab.filteredDonateurs.length > 0
            spacing: 12
            SectionLabel { Layout.fillWidth: true; text: "NOM / IDENTITÉ" }
            SectionLabel { Layout.preferredWidth: tab.wTel;    text: "TÉLÉPHONE"; horizontalAlignment: Text.AlignHCenter }
            Item { Layout.preferredWidth: tab.wAction }
        }
        Separator { width: parent.width; visible: tab.filteredDonateurs.length > 0 }

        // ── Table rows ────────────────────────────────────────────────────────
        Column { width: parent.width; spacing: 0
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

        // ── Pagination ────────────────────────────────────────────────────────
        RowLayout {
            width: parent.width; height: 44
            visible: tab.pageCount > 1
            spacing: 8

            Item { Layout.fillWidth: true }

            Rectangle { width: 36; height: 36; radius: 10
                color: prevPgMa.containsMouse && tab.currentPage > 0 ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderLight
                Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 18; font.bold: true
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
                Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 18; font.bold: true
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
                    Text { text: "Exporter les Donateurs"; font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: tab.filteredDonateurs.length + " donateur(s) — format CSV"
                           font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
                }
                IconButton { iconName: "close"; iconSize: 18; onClicked: tab.showExportPopup = false }
            }
            Rectangle { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: expInfo.implicitHeight + 24; radius: 14
                color: Style.primaryBg; border.color: Style.borderLight
                Text { id: expInfo; anchors.fill: parent; anchors.margins: 14
                    text: "Cliquez sur <b>Confirmer</b> pour choisir l'emplacement d'enregistrement du fichier CSV."
                    font.pixelSize: 12; color: Style.textSecondary; wrapMode: Text.WordWrap
                    textFormat: Text.RichText; lineHeight: 1.5 }
            }
            ModalButtons { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"; confirmText: "Confirmer"
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
                        Text { text: "Modifier le Donateur"; font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary }
                        Text { text: "Conforme Décret-loi 2011-88"; font.pixelSize: 10; color: Style.primary; font.weight: Font.Bold }
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
                                label: "NOM / DÉNOMINATION *"
                                placeholder: "Nom complet ou raison sociale"
                                fieldHeight: 44 }

                    Column { width: parent.width; spacing: 6
                        SectionLabel { text: "TYPE DE PERSONNE" }
                        Row { spacing: 6; width: parent.width
                            Repeater {
                                model: ["Physique", "Morale"]
                                delegate: Rectangle {
                                    width: (parent.width - 6) / 2; height: 36; radius: 10
                                    color: editModal.typePersonne === modelData ? Style.primary : Style.bgPage
                                    border.color: editModal.typePersonne === modelData ? Style.primary : Style.borderLight
                                    Text { anchors.centerIn: parent
                                           text: "PERSONNE " + modelData.toUpperCase()
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
                                label: "N° CIN"; placeholder: "00000000"; fieldHeight: 44 }

                    Column { width: parent.width; spacing: 10
                             visible: editModal.typePersonne === "Morale"
                        FormField { id: editRsField; width: parent.width
                                    label: "RAISON SOCIALE"; placeholder: "Dénomination officielle"; fieldHeight: 44 }
                        FormField { id: editMfField; width: parent.width
                                    label: "MATRICULE FISCAL"; placeholder: "Ex: 1234567/A/M/000"; fieldHeight: 44 }
                        FormField { id: editRlField; width: parent.width
                                    label: "REPRÉSENTANT LÉGAL"; placeholder: "Nom du représentant"; fieldHeight: 44 }
                    }

                    RowLayout { width: parent.width; spacing: 8
                        FormField { id: editTelField; Layout.fillWidth: true
                                    label: "TÉLÉPHONE"; placeholder: "XX XXX XXX"; fieldHeight: 44 }
                        FormField { id: editAdrField; Layout.fillWidth: true
                                    label: "ADRESSE"; placeholder: "Adresse"; fieldHeight: 44 }
                    }
                }
            }

            // Buttons
            Column {
                width: parent.width; topPadding: 16; bottomPadding: 28
                ModalButtons {
                    width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter
                    cancelText: "Annuler"; confirmText: "Enregistrer les modifications"
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
