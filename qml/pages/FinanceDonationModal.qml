import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform as Platform
import UI.Components

// ── FinanceDonationModal ────────────────────────────────────────────────────
// Formulaire conforme au Décret-loi 2011-88 (dons aux associations tunisiennes).
// Gère : Personne Physique / Morale, Don Numéraire / En Nature, justificatif.
// Modes : création (editMode=false) et édition (editMode=true).
ModalOverlay {
    id: root
    required property var page

    // ── Mode édition ─────────────────────────────────────────────────────────
    property bool editMode: false

    show: editMode ? page.showEditDonModal : page.showDonationModal
    modalWidth: 540; modalRadius: 32
    onClose: _close()

    // ── Internal state ──────────────────────────────────────────────────────
    property bool   useExisting:  true       // true = existing donor; false = new donor
    property string typePersonne: "Physique" // "Physique" | "Morale"
    property string natureDon:    "Numéraire"// "Numéraire" | "Nature"
    property string modePaiement: "Espèces"  // "Espèces" | "Virement" | "Chèque"
    property string etatMateriel: "Neuf"     // "Neuf" | "Occasion"

    // ── File dialog ─────────────────────────────────────────────────────────
    Platform.FileDialog {
        id: fileDialog
        title: "Sélectionner un justificatif"
        fileMode: Platform.FileDialog.OpenFile
        nameFilters: ["Documents (*.pdf *.jpg *.jpeg *.png *.doc *.docx)", "Tous les fichiers (*)"]
        onAccepted: {
            var path = fileDialog.file.toString()
            path = path.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "")
            donJustifField.text = decodeURIComponent(path)
        }
    }

    // ── Pre-fill for edit mode ───────────────────────────────────────────────
    function _populate(don) {
        if (!don) return
        root.natureDon    = don.natureDon    || "Numéraire"
        root.modePaiement = don.modePaiement || "Espèces"
        root.etatMateriel = don.etatMateriel || "Neuf"
        root.useExisting  = true

        // Sélectionner le donateur dans le combo
        var list = financeController.donateurs
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === don.donateurId) {
                donDonateurCombo.currentIndex = i
                break
            }
        }

        // Projet
        var plist = donProjetCombo.model
        for (var j = 0; j < plist.length; j++) {
            if (plist[j].id === (don.projetId || -1)) {
                donProjetCombo.currentIndex = j
                break
            }
        }

        // Montants
        if (root.natureDon === "Nature") {
            donValeurField.text = don.valeurEstimee > 0 ? don.valeurEstimee.toFixed(2) : ""
            donDescField.text   = don.descriptionMateriel || ""
        } else {
            donMontantField.text = don.montant > 0 ? don.montant.toFixed(2) : ""
        }

        donJustifField.text = don.justificatifPath || ""
        if (don.dateDon && don.dateDon !== "") donDateField.setDate(don.dateDon)
        else donDateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
    }

    // ── Reset ───────────────────────────────────────────────────────────────
    function _close() {
        if (editMode) page.showEditDonModal  = false
        else          page.showDonationModal = false
        donDonateurCombo.currentIndex = -1
        newNomField.text = ""; newTelField.text = ""; newAdrField.text = ""
        newCinField.text = ""; newRsField.text = ""; newMfField.text = ""
        newRlField.text = ""; donMontantField.text = ""; donValeurField.text = ""
        donDescField.text = ""; donJustifField.text = ""
        donDateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
        root.useExisting = true; root.typePersonne = "Physique"
        root.natureDon = "Numéraire"; root.modePaiement = "Espèces"
        root.etatMateriel = "Neuf"
    }

    onShowChanged: {
        if (show) {
            if (editMode && page.editingDon) _populate(page.editingDon)
            else donDateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
        }
    }

    // ── Layout ──────────────────────────────────────────────────────────────
    Column {
        width: parent.width; spacing: 0

        // ── Fixed header ─────────────────────────────────────────────────
        Column {
            width: parent.width; padding: 36; bottomPadding: 20; spacing: 16
            RowLayout {
                width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                Rectangle { width: 48; height: 48; radius: 20; color: editMode ? Style.primaryBg : "#FEF3C7"
                    IconLabel { anchors.centerIn: parent
                                iconName: editMode ? "edit" : "heart"; iconSize: 24
                                iconColor: editMode ? Style.primary : "#D97706" } }
                Column { Layout.fillWidth: true; spacing: 2
                    Text { text: editMode ? "Modifier le Don" : "Nouveau Don"
                           font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: "Conforme Décret-loi 2011-88"
                           font.pixelSize: 10; color: editMode ? Style.primary : "#D97706"; font.weight: Font.Bold }
                }
                IconButton { iconName: "close"; iconSize: 18; onClicked: _close() }
            }
            Separator { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter }
        }

        // ── Scrollable form ───────────────────────────────────────────────
        Flickable {
            id: formFlick
            width: parent.width
            height: Math.min(contentHeight, 440)
            contentWidth: parent.width
            contentHeight: formCol.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: ScrollBar {
                policy: formFlick.contentHeight > formFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            }

            Column {
                id: formCol
                width: parent.width; topPadding: 4; bottomPadding: 16; spacing: 20

                // ══════════════════════════════════════
                // SECTION DONATEUR
                // ══════════════════════════════════════
                Column {
                    width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                    SectionLabel { text: "DONATEUR" }

                    // Toggle Existant / Nouveau (masqué en mode édition)
                    Row { spacing: 6; width: parent.width; visible: !root.editMode
                        Repeater {
                            model: [
                                { label: "DONATEUR EXISTANT", val: true  },
                                { label: "NOUVEAU DONATEUR",  val: false }
                            ]
                            delegate: Rectangle {
                                width: (parent.width - 6) / 2; height: 36; radius: 10
                                color: root.useExisting === modelData.val ? Style.primary : Style.bgPage
                                border.color: root.useExisting === modelData.val ? Style.primary : Style.borderLight
                                Text { anchors.centerIn: parent; text: modelData.label
                                       font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                                       color: root.useExisting === modelData.val ? "white" : Style.textTertiary }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.useExisting = modelData.val }
                            }
                        }
                    }

                    // ── Existant : ComboBox ────────────────────────────────
                    Column { width: parent.width; spacing: 6; visible: root.useExisting
                        Rectangle { width: parent.width; height: 44; radius: 12
                                    color: Style.bgPage; border.color: Style.borderLight
                            ComboBox { id: donDonateurCombo
                                anchors.fill: parent; anchors.margins: 4
                                model: financeController.donateurs; textRole: "nom"; currentIndex: -1
                                background: Rectangle { color: "transparent" }
                                contentItem: Text { leftPadding: 8
                                    text: donDonateurCombo.currentIndex >= 0 ? donDonateurCombo.currentText
                                        : financeController.donateurs.length === 0 ? "Aucun donateur — créer ci-dessous"
                                        : "Sélectionner un donateur existant…"
                                    font.pixelSize: 13; font.bold: true; verticalAlignment: Text.AlignVCenter
                                    color: donDonateurCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary }
                            }
                        }
                    }

                    // ── Nouveau ────────────────────────────────────────────
                    Column { width: parent.width; spacing: 10; visible: !root.useExisting && !root.editMode

                        FormField { id: newNomField; width: parent.width
                                    label: "NOM / DÉNOMINATION *"; placeholder: "Nom complet ou raison sociale"; fieldHeight: 44 }

                        Column { width: parent.width; spacing: 6
                            SectionLabel { text: "TYPE DE PERSONNE" }
                            Row { spacing: 6; width: parent.width
                                Repeater {
                                    model: ["Physique", "Morale"]
                                    delegate: Rectangle {
                                        width: (parent.width - 6) / 2; height: 36; radius: 10
                                        color: root.typePersonne === modelData ? Style.primary : Style.bgPage
                                        border.color: root.typePersonne === modelData ? Style.primary : Style.borderLight
                                        Text { anchors.centerIn: parent
                                               text: "PERSONNE " + modelData.toUpperCase()
                                               font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                                               color: root.typePersonne === modelData ? "white" : Style.textTertiary }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.typePersonne = modelData }
                                    }
                                }
                            }
                        }

                        FormField { id: newCinField; width: parent.width; visible: root.typePersonne === "Physique"
                                    label: "N° CIN"; placeholder: "00000000"; fieldHeight: 44 }

                        Column { width: parent.width; spacing: 8; visible: root.typePersonne === "Morale"
                            FormField { id: newRsField; width: parent.width
                                        label: "RAISON SOCIALE"; placeholder: "Dénomination officielle"; fieldHeight: 44 }
                            FormField { id: newMfField; width: parent.width
                                        label: "MATRICULE FISCAL"; placeholder: "Ex: 1234567/A/M/000"; fieldHeight: 44 }
                            FormField { id: newRlField; width: parent.width
                                        label: "REPRÉSENTANT LÉGAL"; placeholder: "Nom du représentant"; fieldHeight: 44 }
                        }

                        RowLayout { width: parent.width; spacing: 8
                            FormField {
                                id: newTelField
                                Layout.fillWidth: true
                                label: "TÉLÉPHONE (FACULTATIF)"
                                placeholder: "XX XXX XXX"
                                fieldHeight: 44
                                validator: RegularExpressionValidator {
                                    regularExpression: /^\d{0,2}\s?\d{0,3}\s?\d{0,3}$/
                                }
                            }
                            FormField { id: newAdrField; Layout.fillWidth: true
                                        label: "ADRESSE (FACULTATIF)"; placeholder: "Adresse"; fieldHeight: 44 }
                        }
                    }
                }

                Separator { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter }

                // ══════════════════════════════════════
                // SECTION DON
                // ══════════════════════════════════════
                Column {
                    width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                    SectionLabel { text: "DÉTAILS DU DON" }

                    // Projet
                    Column { width: parent.width; spacing: 6
                        SectionLabel { text: "PROJET / AFFECTATION" }
                        Rectangle { width: parent.width; height: 44; radius: 12
                                    color: Style.bgPage; border.color: Style.borderLight
                            ComboBox { id: donProjetCombo
                                anchors.fill: parent; anchors.margins: 4
                                model: {
                                    var items = [{"nom": "Général (sans affectation)", "id": -1}]
                                    var p = financeController.projets
                                    for (var i = 0; i < p.length; i++) items.push(p[i])
                                    return items
                                }
                                textRole: "nom"; valueRole: "id"; currentIndex: 0
                                background: Rectangle { color: "transparent" }
                                contentItem: Text { leftPadding: 8; text: donProjetCombo.currentText
                                                    font.pixelSize: 13; font.bold: true
                                                    verticalAlignment: Text.AlignVCenter; color: Style.textPrimary }
                            }
                        }
                    }

                    // Nature du don toggle
                    Column { width: parent.width; spacing: 6
                        SectionLabel { text: "NATURE DU DON" }
                        Row { spacing: 6; width: parent.width
                            Repeater {
                                model: [
                                    { label: "NUMÉRAIRE",  val: "Numéraire" },
                                    { label: "EN NATURE",  val: "Nature"    }
                                ]
                                delegate: Rectangle {
                                    width: (parent.width - 6) / 2; height: 36; radius: 10
                                    color: root.natureDon === modelData.val ? Style.primary : Style.bgPage
                                    border.color: root.natureDon === modelData.val ? Style.primary : Style.borderLight
                                    Text { anchors.centerIn: parent; text: modelData.label
                                           font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                                           color: root.natureDon === modelData.val ? "white" : Style.textTertiary }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: root.natureDon = modelData.val }
                                }
                            }
                        }
                    }

                    // ── Numéraire ──────────────────────────────────────────
                    Column { width: parent.width; spacing: 8; visible: root.natureDon === "Numéraire"
                        FormField { id: donMontantField; width: parent.width
                                    label: "MONTANT (DT) *"; placeholder: "0.00"; fieldHeight: 44 }

                        Column { width: parent.width; spacing: 6
                            SectionLabel { text: "MODE DE PAIEMENT" }
                            Row { spacing: 6; width: parent.width
                                Repeater {
                                    model: ["Espèces", "Virement", "Chèque"]
                                    delegate: Rectangle {
                                        width: (parent.width - 12) / 3; height: 36; radius: 10
                                        color: root.modePaiement === modelData ? Style.primary : Style.bgPage
                                        border.color: root.modePaiement === modelData ? Style.primary : Style.borderLight
                                        Text { anchors.centerIn: parent; text: modelData.toUpperCase()
                                               font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                                               color: root.modePaiement === modelData ? "white" : Style.textTertiary }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.modePaiement = modelData }
                                    }
                                }
                            }
                        }
                    }

                    // ── En Nature ──────────────────────────────────────────
                    Column { width: parent.width; spacing: 8; visible: root.natureDon === "Nature"
                        FormField { id: donDescField; width: parent.width
                                    label: "DESCRIPTION DU BIEN *"
                                    placeholder: "Ex: Ordinateurs portables, mobilier…"; fieldHeight: 44 }
                        FormField { id: donValeurField; width: parent.width
                                    label: "VALEUR ESTIMÉE (DT) *"; placeholder: "0.00"; fieldHeight: 44 }

                        Column { width: parent.width; spacing: 6
                            SectionLabel { text: "ÉTAT DU BIEN" }
                            Row { spacing: 6; width: parent.width
                                Repeater {
                                    model: ["Neuf", "Occasion"]
                                    delegate: Rectangle {
                                        width: (parent.width - 6) / 2; height: 36; radius: 10
                                        color: root.etatMateriel === modelData ? Style.primary : Style.bgPage
                                        border.color: root.etatMateriel === modelData ? Style.primary : Style.borderLight
                                        Text { anchors.centerIn: parent; text: modelData.toUpperCase()
                                               font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 0.4
                                               color: root.etatMateriel === modelData ? "white" : Style.textTertiary }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.etatMateriel = modelData }
                                    }
                                }
                            }
                        }
                    }

                    // ── Date du don ────────────────────────────────────────
                    DateField {
                        id: donDateField
                        width: parent.width
                        label: "DATE DU DON"
                    }

                    // ── Justificatif ───────────────────────────────────────
                    Column { width: parent.width; spacing: 6
                        SectionLabel { text: "JUSTIFICATIF (PIÈCE JOINTE)" }
                        RowLayout { width: parent.width; spacing: 8
                            Rectangle { Layout.fillWidth: true; height: 44; radius: 12
                                        color: Style.bgPage; border.color: Style.borderLight
                                TextInput {
                                    id: donJustifField
                                    anchors.fill: parent; anchors.margins: 12
                                    font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                                    clip: true; selectByMouse: true; readOnly: true
                                    Text { visible: !donJustifField.text; text: "Aucun fichier sélectionné"
                                           font: donJustifField.font; color: Style.textTertiary }
                                }
                            }
                            Rectangle { Layout.preferredWidth: 44; height: 44; radius: 12
                                color: browseHover.containsMouse ? Style.primary : Style.bgPage
                                border.color: browseHover.containsMouse ? Style.primary : Style.borderLight
                                Text { anchors.centerIn: parent; text: "…"
                                       font.pixelSize: 16; font.bold: true
                                       color: browseHover.containsMouse ? "white" : Style.textTertiary }
                                MouseArea { id: browseHover; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: fileDialog.open() }
                            }
                        }
                    }
                }
            }
        }

        // ── Fixed buttons ─────────────────────────────────────────────────
        Column {
            width: parent.width; topPadding: 16; bottomPadding: 28; spacing: 0
            ModalButtons {
                width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: editMode ? "Enregistrer les modifications" : "Enregistrer le don"
                onCancel: _close()
                onConfirm: {
                    // ── Validation ──────────────────────────────────────
                    if (root.useExisting && donDonateurCombo.currentIndex < 0) return
                    if (!root.useExisting && newNomField.text.trim() === "") return

                    var montant = 0.0
                    var valeur  = 0.0
                    if (root.natureDon === "Nature") {
                        valeur = parseFloat(donValeurField.text.replace(",", "."))
                        if (isNaN(valeur) || valeur <= 0) return
                    } else {
                        montant = parseFloat(donMontantField.text.replace(",", "."))
                        if (isNaN(montant) || montant <= 0) return
                    }

                    // ── Build payload ──────────────────────────────────
                    var projetId = donProjetCombo.currentIndex >= 0 ? donProjetCombo.currentValue : -1
                    var dateDon  = donDateField.dateString !== ""
                                   ? donDateField.dateString
                                   : Qt.formatDate(new Date(), "yyyy-MM-dd")

                    var donPayload = {
                        projetId:            projetId,
                        montant:             montant,
                        dateDon:             dateDon,
                        natureDon:           root.natureDon,
                        modePaiement:        root.natureDon === "Nature" ? "" : root.modePaiement,
                        descriptionMateriel: root.natureDon === "Nature" ? donDescField.text.trim() : "",
                        valeurEstimee:       valeur,
                        etatMateriel:        root.natureDon === "Nature" ? root.etatMateriel : "",
                        justificatifPath:    donJustifField.text.trim()
                    }

                    if (root.editMode) {
                        // Édition : on conserve le donateurId existant
                        donPayload.donateurId = financeController.donateurs[donDonateurCombo.currentIndex].id
                        financeController.updateDon(page.editingDon.id, donPayload)
                        _close()
                    } else if (root.useExisting) {
                        donPayload.donateurId = financeController.donateurs[donDonateurCombo.currentIndex].id
                        financeController.recordDon(donPayload)
                        _close()
                    } else {
                        page.pendingDon    = donPayload
                        page.pendingDonNom = newNomField.text.trim()
                        financeController.createDonateur({
                            nom:               page.pendingDonNom,
                            telephone:         newTelField.text.trim(),
                            adresse:           newAdrField.text.trim(),
                            typePersonne:      root.typePersonne,
                            cin:               root.typePersonne === "Physique" ? newCinField.text.trim() : "",
                            raisonSociale:     root.typePersonne === "Morale"   ? newRsField.text.trim()  : "",
                            matriculeFiscal:   root.typePersonne === "Morale"   ? newMfField.text.trim()  : "",
                            representantLegal: root.typePersonne === "Morale"   ? newRlField.text.trim()  : ""
                        })
                        _close()
                    }
                }
            }
        }
    }
}
