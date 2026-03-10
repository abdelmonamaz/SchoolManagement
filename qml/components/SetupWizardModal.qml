import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

// ═══════════════════════════════════════════════════════════════════
//  Assistant de Mise en Marche — 3 étapes
//  Étape 1 : Identité de l'Association + Exercice Comptable
//  Étape 2 : Catalogue des Niveaux
//  Étape 3 : Première Année Scolaire
// ═══════════════════════════════════════════════════════════════════
Popup {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 700
    modal: true
    padding: 0
    closePolicy: Popup.NoAutoClose

    property int currentStep: 1
    readonly property int totalSteps: 3

    // ── Step 2 : création ──
    property string newNiveauNom: ""
    property int    newNiveauParentId: 0

    // ── Step 2 : édition inline ──
    property int    editingNiveauId: -1
    property string editingNom: ""
    property int    editingParentId: 0

    // ── Step 3 : libellé auto-rempli ─────────────────────────────
    property bool   libelleAutoFill:  true
    property string libelleAutoValue: ""

    function updateLibelleAuto() {
        if (!libelleAutoFill) return
        if (!anneeDateDebutField.isValid || !anneeDateFinField.isValid) return
        var y1 = anneeDateDebutField.dateString.substring(0, 4)
        var y2 = anneeDateFinField.dateString.substring(0, 4)
        var auto = y1 + "-" + y2
        libelleAutoValue = auto
        anneeLibelleField.text = auto
    }

    // ── Step 3 : année scolaire ≤ 12 mois ────────────────────────
    readonly property bool anneeValid: {
        if (!anneeDateDebutField.isValid || !anneeDateFinField.isValid) return false
        var d1 = new Date(anneeDateDebutField.dateString)
        var d2 = new Date(anneeDateFinField.dateString)
        if (d2.getTime() <= d1.getTime()) return false
        var maxEnd = new Date(d1)
        maxEnd.setMonth(maxEnd.getMonth() + 12)
        return d2.getTime() < maxEnd.getTime()    // d2 doit être avant d1 + 12 mois
    }

    // ── Step 1 : mise à jour automatique des dates exercice ──────
    // Quand l'une change, l'autre est recalculée pour couvrir exactement 12 mois.
    property bool updatingDate: false   // guard anti-boucle

    function isoToLocalDate(iso) {
        var p = iso.split("-")
        return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
    }
    function localDateToIso(d) {
        var m = d.getMonth() + 1; var day = d.getDate()
        return d.getFullYear() + "-" + (m < 10 ? "0" + m : "" + m) + "-" + (day < 10 ? "0" + day : "" + day)
    }

    Overlay.modal: Rectangle { color: "#0F172ACC" }
    background: Rectangle { radius: 32; color: Style.bgWhite }

    onOpened: {
        setupController.loadNiveaux()
    }

    onCurrentStepChanged: {
        // En entrant en étape 3, réactiver l'auto-remplissage du libellé
        if (currentStep === 3) {
            libelleAutoFill  = true
            libelleAutoValue = ""
            updateLibelleAuto()
        }
    }

    // Dès que l'utilisateur modifie manuellement le libellé, désactiver l'auto-remplissage
    Connections {
        target: anneeLibelleField
        function onTextChanged() {
            if (anneeLibelleField.text !== root.libelleAutoValue)
                root.libelleAutoFill = false
        }
    }

    Connections {
        target: setupController
        function onSetupCompleted() { root.close() }
        function onOperationFailed(error) {
            console.warn("[SetupWizard] completeSetup failed:", error)
        }
    }

    contentItem: Column {
        width: root.width
        spacing: 0

        // ─── Header ───────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 108
            color: Style.sandBg
            radius: 32

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 48
                color: Style.sandBg
            }
            Separator { anchors.bottom: parent.bottom; width: parent.width }

            RowLayout {
                anchors.fill: parent; anchors.margins: 28; spacing: 16

                Column {
                    Layout.fillWidth: true; spacing: 5
                    Text {
                        text: root.currentStep === 1 ? "Bienvenue — Configuration initiale"
                            : root.currentStep === 2 ? "Catalogue des Niveaux"
                            : "Première Année Scolaire"
                        font.pixelSize: 20; font.weight: Font.Black; color: Style.primary
                    }
                    Text {
                        text: root.currentStep === 1 ? "ÉTAPE 1 / 3 — IDENTITÉ DE L'ASSOCIATION"
                            : root.currentStep === 2 ? "ÉTAPE 2 / 3 — CRÉEZ VOTRE CATALOGUE DE NIVEAUX"
                            : "ÉTAPE 3 / 3 — PARAMÈTRES DE L'ANNÉE EN COURS"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: Style.textTertiary; font.letterSpacing: 1
                    }
                }

                Row {
                    spacing: 8
                    Repeater {
                        model: root.totalSteps
                        Rectangle {
                            width: root.currentStep > index ? 32 : (root.currentStep === index + 1 ? 24 : 12)
                            height: 8; radius: 4
                            color: root.currentStep > index ? Style.successColor
                                 : root.currentStep === index + 1 ? Style.primary
                                 : Style.bgTertiary
                            Behavior on width { NumberAnimation { duration: 200 } }
                            Behavior on color  { ColorAnimation  { duration: 200 } }
                        }
                    }
                }
            }
        }

        // ─── Body ─────────────────────────────────────────────────
        Item {
            width: parent.width
            implicitHeight: Math.max(480, bodyStack.implicitHeight + 48)

            StackLayout {
                id: bodyStack
                anchors.fill: parent
                anchors.margins: 28
                currentIndex: root.currentStep - 1

                // ══════════════════════════════════════════
                //  ÉTAPE 1 : Association + Exercice
                // ══════════════════════════════════════════
                ColumnLayout {
                    spacing: 20

                    Rectangle {
                        Layout.fillWidth: true; height: 48; radius: 14
                        color: Style.primaryBg
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            IconLabel { iconName: "info"; iconColor: Style.primary }
                            Text {
                                Layout.fillWidth: true
                                text: "Ces informations identifient votre association dans les documents officiels."
                                font.pixelSize: 12; font.bold: true; color: Style.primary
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    FormField {
                        id: nomAssocField
                        Layout.fillWidth: true
                        label: "NOM DE L'ASSOCIATION"
                        placeholder: "ex: Ez-Zaytouna"
                        nextTabItem: adresseField.inputItem
                        Component.onCompleted: {
                            text = setupController.associationData.nomAssociation || ""
                        }
                    }

                    FormField {
                        id: adresseField
                        Layout.fillWidth: true
                        label: "ADRESSE"
                        placeholder: "ex: 12 Rue de la Mosquée, Tunis"
                        prevTabItem: nomAssocField.inputItem
                        nextTabItem: exDebutField.inputItem
                        Component.onCompleted: {
                            text = setupController.associationData.adresse || ""
                        }
                    }

                    // ── Exercice comptable ──
                    Text {
                        text: "EXERCICE COMPTABLE"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.primary; font.letterSpacing: 1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        DateField {
                            id: exDebutField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            label: "DATE DE DÉBUT"
                            nextTabItem: exFinField.inputItem
                            prevTabItem: adresseField.inputItem
                            onDateStringChanged: {
                                if (root.updatingDate || !isValid) return
                                root.updatingDate = true
                                var d = root.isoToLocalDate(dateString)
                                d.setMonth(d.getMonth() + 12)
                                d.setDate(d.getDate() - 1)
                                exFinField.setDate(root.localDateToIso(d))
                                root.updatingDate = false
                            }
                        }

                        DateField {
                            id: exFinField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            label: "DATE DE FIN"
                            prevTabItem: exDebutField.inputItem
                            onDateStringChanged: {
                                if (root.updatingDate || !isValid) return
                                root.updatingDate = true
                                var d = root.isoToLocalDate(dateString)
                                d.setDate(d.getDate() + 1)
                                d.setMonth(d.getMonth() - 12)
                                exDebutField.setDate(root.localDateToIso(d))
                                root.updatingDate = false
                            }
                        }
                    }

                    // ── Âge de passage adulte ──
                    Text {
                        text: "CATÉGORISATION"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.primary; font.letterSpacing: 1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: "Âge de passage Adulte :"
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                            Layout.alignment: Qt.AlignVCenter
                        }
                        TextField {
                            id: agePassageInput
                            Layout.preferredWidth: 72; height: 40
                            text: (setupController.associationData.agePassageAdulte || 12).toString()
                            font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                            horizontalAlignment: TextInput.AlignHCenter
                            selectByMouse: true
                            validator: IntValidator { bottom: 1; top: 99 }
                            background: Rectangle {
                                radius: 10; color: Style.bgPage; border.color: Style.borderLight
                                border.width: parent.activeFocus ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 120 } }
                            }
                        }
                        Text {
                            text: "ans"
                            font.pixelSize: 13; font.bold: true; color: Style.textSecondary
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // ══════════════════════════════════════════
                //  ÉTAPE 2 : Niveaux
                // ══════════════════════════════════════════
                ColumnLayout {
                    spacing: 16

                    // ── Barre d'ajout ──
                    Rectangle {
                        Layout.fillWidth: true; height: 60; radius: 14
                        color: Style.bgPage; border.color: Style.borderLight

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 10

                            Rectangle {
                                Layout.fillWidth: true; height: 40; radius: 10
                                color: "#FFFFFF"; border.color: Style.borderLight
                                HoverHandler { cursorShape: Qt.IBeamCursor }
                                TextInput {
                                    id: niveauNomInput
                                    anchors.fill: parent; anchors.margins: 10
                                    font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                    onTextChanged: root.newNiveauNom = text
                                    Keys.onReturnPressed: addNiveauBtn.click()
                                }
                                Text {
                                    anchors.fill: parent; anchors.margins: 10
                                    text: "Nom du niveau (ex: Niveau 1)"
                                    font.pixelSize: 13; font.bold: true
                                    color: Style.textTertiary
                                    visible: niveauNomInput.text === ""
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Rectangle {
                                width: 170; height: 40; radius: 10
                                color: "#FFFFFF"; border.color: Style.borderLight
                                ComboBox {
                                    id: parentCombo
                                    anchors.fill: parent; anchors.margins: 2
                                    model: {
                                        var items = [{"nom": "— Aucun parent —", "id": 0}]
                                        for (var i = 0; i < setupController.niveaux.length; i++)
                                            items.push(setupController.niveaux[i])
                                        return items
                                    }
                                    textRole: "nom"
                                    background: Rectangle { color: "transparent" }
                                    contentItem: Text {
                                        text: parentCombo.displayText
                                        font.pixelSize: 11; font.bold: true; color: Style.textSecondary
                                        verticalAlignment: Text.AlignVCenter; leftPadding: 8
                                        elide: Text.ElideRight
                                    }
                                    onCurrentIndexChanged: {
                                        root.newNiveauParentId = currentIndex > 0 ? model[currentIndex].id : 0
                                    }
                                }
                            }

                            Rectangle {
                                id: addNiveauBtn
                                width: 76; height: 40; radius: 10
                                color: root.newNiveauNom.trim() !== "" ? Style.primary : Style.bgTertiary
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "+ Ajouter"
                                    font.pixelSize: 11; font.weight: Font.Black; color: "#FFFFFF"
                                }
                                function click() {
                                    if (root.newNiveauNom.trim() === "") return
                                    setupController.createNiveau(root.newNiveauNom.trim(), root.newNiveauParentId)
                                    niveauNomInput.text = ""
                                    parentCombo.currentIndex = 0
                                    root.newNiveauNom = ""
                                    root.newNiveauParentId = 0
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.newNiveauNom.trim() !== ""
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: addNiveauBtn.click()
                                }
                            }
                        }
                    }

                    // ── Liste des niveaux ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 340; radius: 14
                        color: Style.bgPage; border.color: Style.borderLight
                        clip: true

                        Column {
                            anchors.centerIn: parent; spacing: 8
                            visible: setupController.niveaux.length === 0
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Aucun niveau créé"
                                font.pixelSize: 14; font.bold: true; color: Style.textTertiary
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Créez au moins un niveau pour continuer."
                                font.pixelSize: 12; color: Style.textTertiary
                            }
                        }

                        ListView {
                            anchors.fill: parent; anchors.margins: 8
                            model: setupController.niveaux
                            clip: true; spacing: 4
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                id: delegateRoot
                                width: ListView.view.width
                                // Hauteur dynamique : mode édition = 68, mode normal = 48
                                height: root.editingNiveauId === modelData.id ? 68 : 48
                                radius: 12
                                color: rowHover.containsMouse && root.editingNiveauId !== modelData.id
                                       ? Style.bgPage : "#FFFFFF"
                                border.color: root.editingNiveauId === modelData.id
                                              ? Style.primary : Style.borderLight
                                Behavior on height { NumberAnimation { duration: 150 } }
                                Behavior on color  { ColorAnimation  { duration: 100 } }
                                clip: true

                                // ─── MODE LECTURE ───────────────────────────
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14; anchors.rightMargin: 10
                                    spacing: 10
                                    visible: root.editingNiveauId !== modelData.id
                                    opacity: root.editingNiveauId !== modelData.id ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 100 } }

                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: modelData.parentLevelId > 0 ? Style.primary : Style.successColor
                                    }

                                    Column {
                                        Layout.fillWidth: true; spacing: 1
                                        Text {
                                            text: modelData.nom
                                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                        }
                                        Text {
                                            visible: modelData.parentLevelId > 0
                                            text: {
                                                if (modelData.parentLevelId <= 0) return ""
                                                for (var i = 0; i < setupController.niveaux.length; i++) {
                                                    if (setupController.niveaux[i].id === modelData.parentLevelId)
                                                        return "↳ Succède à : " + setupController.niveaux[i].nom
                                                }
                                                return "↳ Niveau parent"
                                            }
                                            font.pixelSize: 10; color: Style.textTertiary
                                        }
                                    }

                                    // Badge TERMINAL
                                    Rectangle {
                                        visible: {
                                            for (var i = 0; i < setupController.niveaux.length; i++) {
                                                if (setupController.niveaux[i].parentLevelId === modelData.id) return false
                                            }
                                            return true
                                        }
                                        height: 20; radius: 10
                                        width: termLbl.implicitWidth + 16
                                        color: Style.warningBg
                                        Text {
                                            id: termLbl
                                            anchors.centerIn: parent
                                            text: "TERMINAL"
                                            font.pixelSize: 9; font.weight: Font.Black
                                            color: Style.warningColor
                                        }
                                    }

                                    // Bouton Éditer
                                    IconButton {
                                        iconName: "edit"
                                        iconSize: 15
                                        onClicked: {
                                            // editingParentId doit être positionné AVANT editingNiveauId
                                            // car le changement de editingNiveauId déclenche onModelChanged
                                            // du combo, qui lit editingParentId pour resynchroniser l'index.
                                            root.editingParentId = modelData.parentLevelId
                                            root.editingNom      = modelData.nom
                                            editNomInput.text    = modelData.nom
                                            root.editingNiveauId = modelData.id  // déclenche onModelChanged
                                        }
                                    }

                                    // Bouton Supprimer
                                    IconButton {
                                        iconName: "delete"
                                        iconSize: 15
                                        hoverColor: Style.errorColor
                                        onClicked: setupController.deleteNiveau(modelData.id)
                                    }
                                }

                                // ─── MODE ÉDITION ────────────────────────────
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.margins: 10
                                    spacing: 8
                                    visible: root.editingNiveauId === modelData.id
                                    opacity: root.editingNiveauId === modelData.id ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 100 } }

                                    // Champ nom
                                    Rectangle {
                                        Layout.fillWidth: true; height: 36; radius: 8
                                        color: Style.bgPage; border.color: Style.primary
                                        HoverHandler { cursorShape: Qt.IBeamCursor }
                                        TextInput {
                                            id: editNomInput
                                            anchors.fill: parent; anchors.margins: 8
                                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                            text: root.editingNom
                                            onTextChanged: root.editingNom = text
                                            Keys.onReturnPressed: saveEditBtn.save()
                                            Keys.onEscapePressed: root.editingNiveauId = -1
                                        }
                                    }

                                    // Sélecteur parent (en édition)
                                    Rectangle {
                                        width: 160; height: 36; radius: 8
                                        color: Style.bgPage; border.color: Style.borderLight
                                        ComboBox {
                                            id: editParentCombo
                                            anchors.fill: parent; anchors.margins: 2
                                            model: {
                                                var items = [{"nom": "— Aucun parent —", "id": 0}]
                                                for (var i = 0; i < setupController.niveaux.length; i++) {
                                                    // Exclure le niveau en cours d'édition
                                                    if (setupController.niveaux[i].id !== root.editingNiveauId)
                                                        items.push(setupController.niveaux[i])
                                                }
                                                return items
                                            }
                                            textRole: "nom"
                                            background: Rectangle { color: "transparent" }
                                            contentItem: Text {
                                                text: editParentCombo.displayText
                                                font.pixelSize: 11; font.bold: true; color: Style.textSecondary
                                                verticalAlignment: Text.AlignVCenter; leftPadding: 6
                                                elide: Text.ElideRight
                                            }
                                            // Après reconstruction du modèle, resynchroniser l'index avec editingParentId
                                            onModelChanged: {
                                                var idx = 0
                                                for (var i = 1; i < model.length; i++) {
                                                    if (model[i].id === root.editingParentId) { idx = i; break }
                                                }
                                                currentIndex = idx
                                            }
                                            onCurrentIndexChanged: {
                                                root.editingParentId = currentIndex > 0 ? model[currentIndex].id : 0
                                            }
                                        }
                                    }

                                    // Bouton Sauvegarder
                                    Rectangle {
                                        id: saveEditBtn
                                        width: 36; height: 36; radius: 8
                                        color: root.editingNom.trim() !== "" ? Style.successColor : Style.bgTertiary
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            font.pixelSize: 16; font.bold: true; color: "#FFFFFF"
                                        }
                                        function save() {
                                            if (root.editingNom.trim() === "") return
                                            setupController.updateNiveau(
                                                root.editingNiveauId,
                                                root.editingNom.trim(),
                                                root.editingParentId)
                                            root.editingNiveauId = -1
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.editingNom.trim() !== ""
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: saveEditBtn.save()
                                        }
                                    }

                                    // Bouton Annuler
                                    Rectangle {
                                        width: 36; height: 36; radius: 8
                                        color: Style.bgPage; border.color: Style.borderLight
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            font.pixelSize: 13; font.bold: true; color: Style.textSecondary
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.editingNiveauId = -1
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true
                                    // Désactivé en mode édition pour laisser passer les clics vers TextInput et ComboBox
                                    enabled: root.editingNiveauId !== modelData.id
                                    onClicked: mouse.accepted = false
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // ══════════════════════════════════════════
                //  ÉTAPE 3 : Première année scolaire
                // ══════════════════════════════════════════
                ColumnLayout {
                    spacing: 20

                    Rectangle {
                        Layout.fillWidth: true; height: 48; radius: 14; color: Style.primaryBg
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            IconLabel { iconName: "info"; iconColor: Style.primary }
                            Text {
                                Layout.fillWidth: true
                                text: "Ces paramètres s'appliqueront à la première année scolaire."
                                font.pixelSize: 12; font.bold: true; color: Style.primary
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    FormField {
                        id: anneeLibelleField
                        Layout.fillWidth: true
                        label: "LIBELLÉ DE L'ANNÉE"
                        placeholder: "ex: 2025-2026"
                        Component.onCompleted: {
                            var d = new Date()
                            var y = d.getMonth() < 8 ? d.getFullYear() - 1 : d.getFullYear()
                            text = y + "-" + (y + 1)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        DateField {
                            id: anneeDateDebutField
                            Layout.fillWidth: true
                            label: "DATE DE DÉBUT"
                            onDateStringChanged: root.updateLibelleAuto()
                            Component.onCompleted: {
                                var y = new Date().getMonth() < 8
                                    ? new Date().getFullYear() - 1
                                    : new Date().getFullYear()
                                setDate(y + "-09-01")
                            }
                        }
                        DateField {
                            id: anneeDateFinField
                            Layout.fillWidth: true
                            label: "DATE DE FIN"
                            onDateStringChanged: root.updateLibelleAuto()
                            Component.onCompleted: {
                                var y = new Date().getMonth() < 8
                                    ? new Date().getFullYear()
                                    : new Date().getFullYear() + 1
                                setDate(y + "-06-30")
                            }
                        }
                    }

                    // Alerte si les dates sont invalides ou l'intervalle dépasse 12 mois
                    Rectangle {
                        Layout.fillWidth: true; height: 36; radius: 10
                        color: Style.errorBg
                        visible: anneeDateDebutField.isValid && anneeDateFinField.isValid && !root.anneeValid
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            IconLabel { iconName: "warning"; iconColor: Style.errorColor; iconSize: 14 }
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var d1 = new Date(anneeDateDebutField.dateString)
                                    var d2 = new Date(anneeDateFinField.dateString)
                                    if (d2.getTime() <= d1.getTime())
                                        return "La date de fin doit être postérieure à la date de début."
                                    return "L'année scolaire ne peut pas dépasser 12 mois."
                                }
                                font.pixelSize: 11; font.bold: true; color: Style.errorColor
                            }
                        }
                    }

                    // ── Tarifs mensuels ──
                    Text {
                        text: "TARIFS MENSUELS"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.primary; font.letterSpacing: 1
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 110; radius: 14
                        color: Style.bgPage; border.color: Style.borderLight
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 18; spacing: 0
                            ColumnLayout {
                                spacing: 4
                                SectionLabel { text: "TARIF JEUNE" }
                                RowLayout {
                                    spacing: 6
                                    TextField {
                                        id: tarifJeuneInput
                                        Layout.preferredWidth: 110; height: 48
                                        text: "150"
                                        font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary
                                        selectByMouse: true
                                        leftPadding: 12; rightPadding: 8; topPadding: 0; bottomPadding: 0
                                        verticalAlignment: TextInput.AlignVCenter
                                        validator: RegularExpressionValidator { regularExpression: /^\d{0,5}(\.\d{0,2})?$/ }
                                        background: Rectangle {
                                            radius: 10; color: "#FFFFFF"
                                            border.width: parent.activeFocus ? 2 : 1
                                            border.color: parent.activeFocus ? Style.primary : Style.borderLight
                                            Behavior on border.color { ColorAnimation { duration: 120 } }
                                        }
                                    }
                                    Text {
                                        text: "DT / mois"; font.pixelSize: 12; font.bold: true
                                        color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            ColumnLayout {
                                spacing: 4
                                SectionLabel { text: "TARIF ADULTE" }
                                RowLayout {
                                    spacing: 6
                                    TextField {
                                        id: tarifAdulteInput
                                        Layout.preferredWidth: 110; height: 48
                                        text: "250"
                                        font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary
                                        selectByMouse: true
                                        leftPadding: 12; rightPadding: 8; topPadding: 0; bottomPadding: 0
                                        verticalAlignment: TextInput.AlignVCenter
                                        validator: RegularExpressionValidator { regularExpression: /^\d{0,5}(\.\d{0,2})?$/ }
                                        background: Rectangle {
                                            radius: 10; color: "#FFFFFF"
                                            border.width: parent.activeFocus ? 2 : 1
                                            border.color: parent.activeFocus ? Style.primary : Style.borderLight
                                            Behavior on border.color { ColorAnimation { duration: 120 } }
                                        }
                                    }
                                    Text {
                                        text: "DT / mois"; font.pixelSize: 12; font.bold: true
                                        color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }
                    }

                    // ── Frais d'inscription ──
                    Text {
                        text: "FRAIS D'INSCRIPTION"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.primary; font.letterSpacing: 1
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 110; radius: 14
                        color: Style.bgPage; border.color: Style.borderLight
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 18; spacing: 0
                            ColumnLayout {
                                spacing: 4
                                SectionLabel { text: "FRAIS JEUNE" }
                                RowLayout {
                                    spacing: 6
                                    TextField {
                                        id: fraisJeuneInput
                                        Layout.preferredWidth: 110; height: 48
                                        text: "50"
                                        font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary
                                        selectByMouse: true
                                        leftPadding: 12; rightPadding: 8; topPadding: 0; bottomPadding: 0
                                        verticalAlignment: TextInput.AlignVCenter
                                        validator: RegularExpressionValidator { regularExpression: /^\d{0,5}(\.\d{0,2})?$/ }
                                        background: Rectangle {
                                            radius: 10; color: "#FFFFFF"
                                            border.width: parent.activeFocus ? 2 : 1
                                            border.color: parent.activeFocus ? Style.primary : Style.borderLight
                                            Behavior on border.color { ColorAnimation { duration: 120 } }
                                        }
                                    }
                                    Text {
                                        text: "DT"; font.pixelSize: 12; font.bold: true
                                        color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            ColumnLayout {
                                spacing: 4
                                SectionLabel { text: "FRAIS ADULTE" }
                                RowLayout {
                                    spacing: 6
                                    TextField {
                                        id: fraisAdulteInput
                                        Layout.preferredWidth: 110; height: 48
                                        text: "50"
                                        font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary
                                        selectByMouse: true
                                        leftPadding: 12; rightPadding: 8; topPadding: 0; bottomPadding: 0
                                        verticalAlignment: TextInput.AlignVCenter
                                        validator: RegularExpressionValidator { regularExpression: /^\d{0,5}(\.\d{0,2})?$/ }
                                        background: Rectangle {
                                            radius: 10; color: "#FFFFFF"
                                            border.width: parent.activeFocus ? 2 : 1
                                            border.color: parent.activeFocus ? Style.primary : Style.borderLight
                                            Behavior on border.color { ColorAnimation { duration: 120 } }
                                        }
                                    }
                                    Text {
                                        text: "DT"; font.pixelSize: 12; font.bold: true
                                        color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }

        // ─── Footer ───────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: 96
            color: Style.bgPage
            Separator { anchors.top: parent.top; width: parent.width }

            RowLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 16

                Rectangle {
                    Layout.fillWidth: true; height: 52; radius: 16
                    color: Style.bgWhite; border.color: Style.borderMedium
                    visible: root.currentStep > 1
                    Text {
                        anchors.centerIn: parent; text: "RETOUR"
                        font.pixelSize: 12; font.weight: Font.Black
                        color: Style.textSecondary; font.letterSpacing: 1
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentStep--
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 52; radius: 16

                    readonly property bool canProceed: {
                        if (root.currentStep === 1)
                            return nomAssocField.text.trim() !== ""
                                && exDebutField.isValid
                                && exFinField.isValid
                        if (root.currentStep === 2)
                            return setupController.niveaux.length > 0
                        // Étape 3 : libellé + dates valides + ≤ 12 mois
                        return anneeLibelleField.text.trim() !== ""
                            && root.anneeValid
                    }

                    color: canProceed ? Style.primary : Style.bgTertiary
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.currentStep < root.totalSteps ? "CONTINUER →" : "TERMINER LA CONFIGURATION"
                        font.pixelSize: 12; font.weight: Font.Black
                        color: "#FFFFFF"; font.letterSpacing: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.canProceed
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentStep === 1) {
                                setupController.saveAssociation({
                                    nomAssociation:   nomAssocField.text.trim(),
                                    adresse:          adresseField.text.trim(),
                                    exerciceDebut:    exDebutField.dateString,
                                    exerciceFin:      exFinField.dateString,
                                    agePassageAdulte: parseInt(agePassageInput.text) || 12
                                })
                                root.currentStep = 2
                            } else if (root.currentStep === 2) {
                                root.currentStep = 3
                            } else {
                                setupController.completeSetup({
                                    libelle:                 anneeLibelleField.text.trim(),
                                    dateDebut:               anneeDateDebutField.dateString,
                                    dateFin:                 anneeDateFinField.dateString,
                                    tarifJeune:              parseFloat(tarifJeuneInput.text)  || 0,
                                    tarifAdulte:             parseFloat(tarifAdulteInput.text) || 0,
                                    fraisInscriptionJeune:   parseFloat(fraisJeuneInput.text)  || 0,
                                    fraisInscriptionAdulte:  parseFloat(fraisAdulteInput.text) || 0
                                })
                                // La fermeture est gérée par Connections { onSetupCompleted: root.close() }
                            }
                        }
                    }
                }
            }
        }
    }
}
