import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

Popup {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 650
    modal: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    required property var niveaux
    required property var classes

    property int currentStep: 1
    property string selectedSexe: "M"
    property int selectedNiveauId: 0
    property string selectedAnneeScolaire: ""
    property double inscriptionFee: 50.0
    property bool isPaid: false

    // Renvoie le frais d'inscription selon la catégorie (depuis les paramètres)
    function defaultFeeForCategorie(cat) {
        var t = setupController.activeTarifs
        if (cat === "Adulte") return t.fraisInscriptionAdulte || 50.0
        return t.fraisInscriptionJeune || 50.0
    }

    signal createRequested(var data)
    signal closeRequested()

    // Met à jour le frais automatiquement quand la catégorie de l'élève change
    Connections {
        target: birthDateField
        function onCategorieChanged() {
            if (birthDateField.categorie !== "")
                root.inscriptionFee = root.defaultFeeForCategorie(birthDateField.categorie)
        }
    }

    onOpened: {
        // Utiliser l'année scolaire active depuis les paramètres
        selectedAnneeScolaire = setupController.activeTarifs.libelle || ""
        // Pré-remplir avec le frais Jeune par défaut
        root.inscriptionFee = root.defaultFeeForCategorie("Jeune")
        nameField.inputItem.forceActiveFocus()
    }

    onClosed: {
        root.closeRequested()
        currentStep = 1
    }

    background: Rectangle {
        radius: 32
        color: Style.bgWhite
    }

    Overlay.modal: Rectangle {
        color: Qt.alpha(Style.foreground, 0.60)
    }

    contentItem: Column {
        width: root.width
        spacing: 0

        // ─── Modal Header ───
        Rectangle {
            width: parent.width
            height: 100
            color: Style.sandBg
            radius: 32

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 50
                color: Style.sandBg
            }

            Separator {
                anchors.bottom: parent.bottom
                width: parent.width
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: currentStep === 1 ? "Inscription : Étape 1" : "Inscription : Étape 2"
                        font.pixelSize: 20
                        font.weight: Font.Black
                        color: Style.primary
                    }

                    Text {
                        text: currentStep === 1 ? "IDENTITÉ DE L'ÉLÈVE (DONNÉES PERMANENTES)" : "NOUVELLE INSCRIPTION (CONTRAT ANNUEL)"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.textTertiary
                        font.letterSpacing: 1
                    }
                }

                // Step indicators
                Row {
                    spacing: 8
                    Rectangle {
                        width: 32; height: 8; radius: 4
                        color: currentStep >= 1 ? Style.primary : Style.bgTertiary
                    }
                    Rectangle {
                        width: 32; height: 8; radius: 4
                        color: currentStep >= 2 ? Style.primary : Style.bgTertiary
                    }
                }

                IconButton {
                    iconName: "close"
                    iconSize: 18
                    onClicked: root.closeRequested()
                }
            }
        }

        // ─── Modal Body ───
        Item {
            width: parent.width
            implicitHeight: Math.max(500, bodyStack.implicitHeight + 48)

            StackLayout {
                id: bodyStack
                anchors.fill: parent
                anchors.margins: 24
                currentIndex: root.currentStep - 1

                // Step 1: Student Identity
                ColumnLayout {
                    spacing: 24

                    RowLayout {
                        spacing: 16
                        FormField {
                            id: nameField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "NOM"
                            placeholder: "ex: Ben Moussa"
                            nextTabItem: prenomField.inputItem
                        }
                        FormField {
                            id: prenomField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "PRÉNOM"
                            placeholder: "ex: Ahmed"
                            nextTabItem: birthDateField.inputItem
                            prevTabItem: nameField.inputItem
                        }
                    }

                    RowLayout {
                        spacing: 16
                        Column {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            spacing: 8
                            SectionLabel { text: "SEXE" }
                            Row {
                                spacing: 16
                                Row {
                                    spacing: 8
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        border.color: root.selectedSexe === "M" ? Style.primary : Style.borderMedium
                                        border.width: root.selectedSexe === "M" ? 6 : 2
                                        Behavior on border.width { NumberAnimation { duration: 100 } }
                                        MouseArea { anchors.fill: parent; onClicked: root.selectedSexe = "M" }
                                    }
                                    Text { text: "Masculin"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                }
                                Row {
                                    spacing: 8
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        border.color: root.selectedSexe === "F" ? Style.primary : Style.borderMedium
                                        border.width: root.selectedSexe === "F" ? 6 : 2
                                        Behavior on border.width { NumberAnimation { duration: 100 } }
                                        MouseArea { anchors.fill: parent; onClicked: root.selectedSexe = "F" }
                                    }
                                    Text { text: "Féminin"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: birthDateField.implicitHeight
                            DateField {
                                id: birthDateField
                                width: 240
                                label: "DATE DE NAISSANCE"
                                nextTabItem: phoneField.inputItem
                                prevTabItem: prenomField.inputItem
                                agePassage: setupController.associationData.agePassageAdulte || 12
                            }
                        }
                    }

                    RowLayout {
                        spacing: 16
                        FormField {
                            id: phoneField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "TÉLÉPHONE"
                            placeholder: "XX XXX XXX"
                            nextTabItem: addressField.inputItem
                            prevTabItem: birthDateField.inputItem
                            validator: RegularExpressionValidator {
                                regularExpression: /^\d{0,2}\s?\d{0,3}\s?\d{0,3}$/
                            }
                        }
                        FormField {
                            id: addressField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "ADRESSE"
                            placeholder: "Adresse complète"
                            nextTabItem: parentNameField.inputItem
                            prevTabItem: phoneField.inputItem
                        }
                    }

                    RowLayout {
                        spacing: 16
                        FormField {
                            id: parentNameField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "NOM DU PARENT / TUTEUR"
                            placeholder: "ex: Mohamed Ben Moussa"
                            nextTabItem: parentPhoneField.inputItem
                            prevTabItem: addressField.inputItem
                        }
                        FormField {
                            id: parentPhoneField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "TÉLÉPHONE PARENT"
                            placeholder: "XX XXX XXX"
                            nextTabItem: cinEleveField.inputItem
                            prevTabItem: parentNameField.inputItem
                            validator: RegularExpressionValidator {
                                regularExpression: /^\d{0,2}\s?\d{0,3}\s?\d{0,3}$/
                            }
                        }
                    }

                    RowLayout {
                        spacing: 16
                        FormField {
                            id: cinEleveField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "CIN ÉLÈVE (optionnel)"
                            placeholder: "ex: 12345678"
                            nextTabItem: cinParentField.inputItem
                            prevTabItem: parentPhoneField.inputItem
                        }
                        FormField {
                            id: cinParentField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            label: "CIN PARENT (optionnel)"
                            placeholder: "ex: 12345678"
                            prevTabItem: cinEleveField.inputItem
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        SectionLabel { text: "COMMENTAIRE / NOTES" }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 80
                            radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                            TextArea {
                                id: commentField
                                anchors.fill: parent; anchors.margins: 12
                                font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                wrapMode: TextEdit.Wrap
                                placeholderText: "Informations complémentaires..."
                                background: null
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Step 2: Academic Enrollment
                ColumnLayout {
                    spacing: 32

                    Rectangle {
                        Layout.fillWidth: true
                        height: 60; radius: 16
                        color: Style.primaryBg
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                            IconLabel { iconName: "info"; iconColor: Style.primary }
                            Text {
                                text: "Nouvelle Inscription pour l'année scolaire " + root.selectedAnneeScolaire
                                font.pixelSize: 14; font.weight: Font.Bold; color: Style.primary
                            }
                        }
                    }

                    RowLayout {
                        spacing: 24
                        Column {
                            Layout.fillWidth: true; spacing: 8
                            SectionLabel { text: "ANNÉE SCOLAIRE" }
                            Rectangle {
                                width: parent.width; height: 44; radius: 12
                                color: Style.primaryBg; border.color: Style.primary; border.width: 1
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: 12; spacing: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.selectedAnneeScolaire || "—"
                                        font.pixelSize: 14; font.weight: Font.Black; color: Style.primary
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "· Année active"
                                        font.pixelSize: 10; font.weight: Font.Bold; color: Style.primary; opacity: 0.7
                                    }
                                }
                            }
                        }

                        Column {
                            Layout.fillWidth: true; spacing: 8
                            SectionLabel { text: "NIVEAU" }
                            Rectangle {
                                width: parent.width; height: 44; radius: 12
                                color: Style.bgPage; border.color: Style.borderLight
                                ComboBox {
                                    id: niveauCombo
                                    anchors.fill: parent; anchors.margins: 2
                                    model: root.niveaux; textRole: "nom"
                                    
                                    background: Rectangle { color: "transparent" }
                                    contentItem: Text {
                                        text: niveauCombo.displayText
                                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                        verticalAlignment: Text.AlignVCenter; leftPadding: 8
                                    }

                                    onCurrentIndexChanged: {
                                        if (currentIndex >= 0 && currentIndex < root.niveaux.length) {
                                            root.selectedNiveauId = root.niveaux[currentIndex].id
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Financial Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Text { text: "SECTION FINANCIÈRE"; font.pixelSize: 10; font.weight: Font.Black; color: Style.primary; font.letterSpacing: 1 }
                        
                        Rectangle {
                            Layout.fillWidth: true; height: 100; radius: 20
                            color: Style.bgPage; border.color: Style.borderLight
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 20; spacing: 20
                                Column {
                                    Layout.fillWidth: true; spacing: 4
                                    SectionLabel { text: "FRAIS D'INSCRIPTION" }
                                    Row {
                                        spacing: 8
                                        TextInput {
                                            id: feeInput
                                            text: root.inscriptionFee.toString()
                                            font.pixelSize: 24; font.weight: Font.Black; color: Style.textPrimary
                                            onTextChanged: root.inscriptionFee = parseFloat(text) || 0
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^\d{0,4}(\.\d{0,3})?$/
                                            }
                                        }
                                        Text { text: "DT"; font.pixelSize: 14; font.weight: Font.Bold; color: Style.textTertiary; anchors.baseline: feeInput.baseline }
                                    }
                                }
                                
                                Column {
                                    spacing: 8
                                    SectionLabel { text: "STATUT DU PAIEMENT" }
                                    Row {
                                        spacing: 12
                                        Rectangle {
                                            width: 50; height: 26; radius: 13
                                            color: root.isPaid ? Style.successColor : Style.bgTertiary
                                            Rectangle {
                                                x: root.isPaid ? 26 : 2; y: 2; width: 22; height: 22; radius: 11
                                                color: Style.background
                                                Behavior on x { NumberAnimation { duration: 150 } }
                                            }
                                            MouseArea { anchors.fill: parent; onClicked: root.isPaid = !root.isPaid }
                                        }
                                        Text { 
                                            text: root.isPaid ? "PAYÉ" : "NON PAYÉ"
                                            font.pixelSize: 12; font.weight: Font.Black
                                            color: root.isPaid ? Style.successColor : Style.textTertiary
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }

        // ─── Modal Footer ───
        Rectangle {
            width: parent.width
            height: 100
            color: Style.bgPage

            Separator {
                anchors.top: parent.top
                width: parent.width
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // Cancel / Back button
                Rectangle {
                    Layout.fillWidth: true
                    height: 52; radius: 16
                    color: Style.bgWhite; border.color: Style.borderMedium
                    Text {
                        anchors.centerIn: parent
                        text: root.currentStep === 1 ? "ANNULER" : "RETOUR"
                        font.pixelSize: 12; font.weight: Font.Black; color: Style.textSecondary
                        font.letterSpacing: 1
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.currentStep === 1) root.closeRequested()
                            else root.currentStep = 1
                        }
                    }
                }

                // Next / Confirm button
                Rectangle {
                    Layout.fillWidth: true
                    height: 52; radius: 16
                    readonly property bool canNext: nameField.text.trim() !== "" && prenomField.text.trim() !== "" && birthDateField.isValid
                    readonly property bool canConfirm: canNext && root.selectedNiveauId !== 0
                    
                    color: (root.currentStep === 1 ? canNext : canConfirm) ? Style.primary : Style.bgTertiary
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.currentStep === 1 ? "CONTINUER" : "CONFIRMER L'INSCRIPTION"
                        font.pixelSize: 12; font.weight: Font.Black; color: Style.background
                        font.letterSpacing: 1
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.currentStep === 1 ? parent.canNext : parent.canConfirm
                        onClicked: {
                            if (root.currentStep === 1) {
                                root.currentStep = 2
                            } else {
                                root.createRequested({
                                    // Identity
                                    nom: nameField.text,
                                    prenom: prenomField.text,
                                    sexe: root.selectedSexe,
                                    telephone: phoneField.text,
                                    adresse: addressField.text,
                                    dateNaissance: birthDateField.dateString,
                                    nomParent: parentNameField.text,
                                    telParent: parentPhoneField.text,
                                    commentaire: commentField.text,
                                    categorie: birthDateField.categorie,
                                    cinEleve: cinEleveField.text,
                                    cinParent: cinParentField.text,

                                    // Enrollment
                                    anneeScolaire: root.selectedAnneeScolaire,
                                    niveauId: root.selectedNiveauId,
                                    fraisInscriptionPaye: root.isPaid,
                                    montantInscription: root.inscriptionFee
                                })
                                // Reset
                                nameField.text = ""
                                prenomField.text = ""
                                phoneField.text = ""
                                addressField.text = ""
                                parentNameField.text = ""
                                parentPhoneField.text = ""
                                cinEleveField.text = ""
                                cinParentField.text = ""
                                commentField.text = ""
                                birthDateField.clear()
                                root.currentStep = 1
                            }
                        }
                    }
                }
            }
        }
    }
}
