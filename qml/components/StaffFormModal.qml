import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

ModalOverlay {
    id: root

    // "full" = new member + first contract
    // "identity" = edit name/tel/sexe only
    // "contract" = new contract for existing member
    // "editContract" = edit existing contract
    property string editMode: "full"

    // Identity data
    property string nomText: ""
    property string telephoneText: ""
    property string cinText: ""
    property string selectedSexe: "M"

    // Contract data
    property string specialtyText: ""
    property string baseValueText: "25"
    property string selectedPost: "Enseignant"
    property string selectedPaymentMode: "Heure"
    property string dateDebutText: ""
    property string dateFinText: ""
    property int joursTravailValue: 31   // bitmask Lun-Dim, bit0=Lun..bit6=Dim

    onSelectedPostChanged: {
        if (selectedPost === "Enseignant" && selectedPaymentMode === "Jour")
            selectedPaymentMode = "Heure"
        else if (selectedPost !== "Enseignant" && selectedPaymentMode === "Heure")
            selectedPaymentMode = "Jour"
    }

    // Context
    property int personnelId: -1
    property int contratId: -1

    signal confirmed(var formData)
    signal cancelled()

    modalWidth: 640
    onClose: cancelled()

    function reset() {
        nomText = ""
        telephoneText = ""
        cinText = ""
        selectedSexe = "M"
        specialtyText = ""
        baseValueText = "25"
        selectedPost = "Enseignant"
        selectedPaymentMode = "Heure"
        joursTravailValue = 31
        dateDebutText = Qt.formatDate(new Date(), "yyyy-MM-dd")
        dateFinText = ""
        personnelId = -1
        contratId = -1
        editMode = "full"
    }

    function populateIdentity(data) {
        nomText = data.nom || ""
        telephoneText = data.telephone || ""
        cinText = data.cin || ""
        selectedSexe = data.sexe || "M"
        personnelId = data.id || -1
        editMode = "identity"
    }

    function populateNewContrat(data) {
        personnelId = data.id || -1
        selectedPost = data.poste || "Enseignant"
        specialtyText = ""
        selectedPaymentMode = data.modePaie || (data.poste === "Enseignant" ? "Heure" : "Jour")
        joursTravailValue = data.joursTravail || 31
        baseValueText = String(data.valeurBase || 25)
        dateDebutText = Qt.formatDate(new Date(), "yyyy-MM-dd")
        dateFinText = ""
        editMode = "contract"
    }

    function populateEditContrat(data) {
        personnelId = data.id || -1
        contratId = data.contratId || -1
        selectedPost = data.poste || "Enseignant"
        specialtyText = data.specialite || ""
        selectedPaymentMode = data.modePaie || "Heure"
        joursTravailValue = data.joursTravail || 31
        baseValueText = String(data.valeurBase || 25)
        dateDebutText = data.dateDebutISO || ""
        dateFinText = data.dateFinISO || ""
        editMode = "editContract"
    }

    // Helper: convert dd/MM/yyyy to yyyy-MM-dd
    function ddmmyyyyToIso(str) {
        if (!str || str.length < 10) return ""
        var parts = str.split("/")
        if (parts.length !== 3) return ""
        return parts[2] + "-" + parts[1] + "-" + parts[0]
    }

    // Helper: format ISO date for display
    function isoToDisplay(isoStr) {
        if (!isoStr) return "Choisir..."
        var d = new Date(isoStr)
        if (isNaN(d.getTime())) return "Choisir..."
        var dd = d.getDate().toString()
        if (dd.length < 2) dd = "0" + dd
        var mm = (d.getMonth() + 1).toString()
        if (mm.length < 2) mm = "0" + mm
        return dd + "/" + mm + "/" + d.getFullYear()
    }

    Column {
        width: parent.width
        spacing: 0
        padding: 40

        Text {
            text: {
                if (editMode === "identity") return "Modifier l'identité"
                if (editMode === "contract") return "Nouveau contrat"
                if (editMode === "editContract") return "Modifier le contrat"
                return "Nouveau membre du personnel"
            }
            font.pixelSize: 24
            font.weight: Font.Black
            color: Style.textPrimary
            bottomPadding: 32
        }

        GridLayout {
            width: parent.width - 80
            columns: 2
            columnSpacing: 16
            rowSpacing: 18

            // === IDENTITY SECTION ===

            // Nom Complet
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 6
                visible: editMode === "full" || editMode === "identity"

                SectionLabel {
                    text: qsTr("NOM COMPLET")
                }

                FormField {
                    id: fieldNom
                    width: parent.width
                    placeholder: qsTr("Nom complet...")
                    text: root.nomText
                    onTextChanged: root.nomText = text
                    nextTabItem: fieldTelephone.inputItem
                }
            }

            // Téléphone
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6
                visible: editMode === "full" || editMode === "identity"

                SectionLabel { text: qsTr("TÉLÉPHONE") }

                FormField {
                    id: fieldTelephone
                    width: parent.width
                    placeholder: qsTr("XX XXX XXX")
                    text: root.telephoneText
                    onTextChanged: root.telephoneText = text
                    prevTabItem: fieldNom.inputItem
                    nextTabItem: fieldCin.inputItem

                    validator: RegularExpressionValidator {
                        regularExpression: /^\d{0,2}\s?\d{0,3}\s?\d{0,3}$/
                    }
                }
            }

            // CIN
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6
                visible: editMode === "full" || editMode === "identity"

                SectionLabel { text: qsTr("CIN") }

                FormField {
                    id: fieldCin
                    width: parent.width
                    placeholder: qsTr("Numéro CIN...")
                    text: root.cinText
                    onTextChanged: root.cinText = text
                    prevTabItem: fieldTelephone.inputItem
                }
            }

            // Sexe
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6
                visible: editMode === "full" || editMode === "identity"

                SectionLabel {
                    text: qsTr("SEXE")
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 12
                    color: Style.bgPage

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: (parent.parent.width - 8) / 2
                            height: 36
                            radius: 8
                            color: root.selectedSexe === "M" ? Style.bgWhite : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("HOMME")
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: root.selectedSexe === "M" ? Style.textPrimary : Style.textTertiary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedSexe = "M"
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            width: (parent.parent.width - 8) / 2
                            height: 36
                            radius: 8
                            color: root.selectedSexe === "F" ? Style.bgWhite : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("FEMME")
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: root.selectedSexe === "F" ? Style.textPrimary : Style.textTertiary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedSexe = "F"
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }

            // Separator between identity and contract sections
            Separator {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                visible: editMode === "full"
            }

            // === CONTRACT SECTION ===

            // Type de Poste
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6
                visible: editMode === "full" || editMode === "contract" || editMode === "editContract"

                SectionLabel {
                    text: qsTr("TYPE DE POSTE")
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    ComboBox {
                        anchors.fill: parent
                        anchors.margins: 4
                        model: ["Enseignant", "Administration", "Sécurité", "Entretien"]
                        currentIndex: {
                            switch(root.selectedPost) {
                                case "Enseignant": return 0
                                case "Administration": return 1
                                case "Sécurité": return 2
                                case "Entretien": return 3
                                default: return 0
                            }
                        }
                        onCurrentTextChanged: root.selectedPost = currentText
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: parent.displayText
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                    }
                }
            }

            // Spécialité (si Enseignant)
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6
                visible: (editMode === "full" || editMode === "contract" || editMode === "editContract") && root.selectedPost === "Enseignant"

                SectionLabel {
                    text: qsTr("SPÉCIALITÉ")
                }

                FormField {
                    id: fieldSpecialty
                    width: parent.width
                    placeholder: qsTr("ex: Fiqh & Hadith")
                    text: root.specialtyText
                    onTextChanged: root.specialtyText = text
                }
            }

            // Date de début (DatePickerPopup)
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6
                visible: editMode === "full" || editMode === "contract" || editMode === "editContract"

                SectionLabel {
                    text: qsTr("DATE DE DÉBUT")
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 12
                    color: Style.bgPage
                    border.color: dateDebutMa.containsMouse ? Style.primary : Style.borderLight

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        IconLabel {
                            iconName: "calendar"
                            iconSize: 14
                            iconColor: Style.primary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.isoToDisplay(root.dateDebutText)
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: root.dateDebutText ? Style.textPrimary : Style.textTertiary
                        }
                    }

                    MouseArea {
                        id: dateDebutMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.dateDebutText) {
                                dateDebutPicker.selectedDate = new Date(root.dateDebutText)
                            } else {
                                dateDebutPicker.selectedDate = new Date()
                            }
                            dateDebutPicker.open()
                        }
                    }
                }
            }

            // Date de fin (DatePickerPopup)
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6
                visible: editMode === "full" || editMode === "contract" || editMode === "editContract"

                SectionLabel {
                    text: qsTr("DATE DE FIN (OPTIONNEL)")
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 12
                    color: Style.bgPage
                    border.color: dateFinMa.containsMouse ? Style.primary : Style.borderLight

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        IconLabel {
                            iconName: "calendar"
                            iconSize: 14
                            iconColor: root.dateFinText ? Style.primary : Style.textTertiary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.dateFinText ? root.isoToDisplay(root.dateFinText) : "Indéterminée"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: root.dateFinText ? Style.textPrimary : Style.textTertiary
                        }

                        // Clear button
                        Rectangle {
                            visible: root.dateFinText !== ""
                            width: 24
                            height: 24
                            radius: 8
                            color: clearFinMa.containsMouse ? Style.errorBg : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("x")
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Style.textTertiary
                            }

                            MouseArea {
                                id: clearFinMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dateFinText = ""
                            }
                        }
                    }

                    MouseArea {
                        id: dateFinMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.dateFinText) {
                                dateFinPicker.selectedDate = new Date(root.dateFinText)
                            } else {
                                dateFinPicker.selectedDate = new Date()
                            }
                            dateFinPicker.open()
                        }
                        z: -1
                    }
                }
            }

            // Separator
            Separator {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                visible: editMode === "full" || editMode === "contract" || editMode === "editContract"
            }

            // Section Paramètres de Rémunération
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 20
                visible: editMode === "full" || editMode === "contract" || editMode === "editContract"

                RowLayout {
                    width: parent.width
                    spacing: 8

                    IconLabel {
                        iconName: "dollar-sign"
                        iconSize: 16
                        iconColor: Style.primary
                    }

                    Text {
                        text: qsTr("PARAMÈTRES DE RÉMUNÉRATION")
                        font.pixelSize: 12
                        font.weight: Font.Black
                        color: Style.textPrimary
                        font.letterSpacing: 1
                    }
                }

                GridLayout {
                    width: parent.width
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 18

                    // Mode de Paiement
                    Column {
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width / 2 - 8
                        spacing: 6

                        SectionLabel {
                            text: qsTr("MODE DE PAIEMENT")
                        }

                        Rectangle {
                            width: parent.width
                            height: 44
                            radius: 12
                            color: Style.bgPage

                            Row {
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: (parent.parent.width - 8) / 2
                                    height: 36
                                    radius: 8
                                    readonly property bool isFirstModeActive:
                                        root.selectedPost === "Enseignant"
                                            ? root.selectedPaymentMode === "Heure"
                                            : root.selectedPaymentMode === "Jour"
                                    color: isFirstModeActive ? Style.bgWhite : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.selectedPost === "Enseignant" ? "À L'HEURE" : "À LA JOURNÉE"
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        color: parent.isFirstModeActive ? Style.textPrimary : Style.textTertiary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedPaymentMode =
                                            root.selectedPost === "Enseignant" ? "Heure" : "Jour"
                                    }

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }

                                Rectangle {
                                    width: (parent.parent.width - 8) / 2
                                    height: 36
                                    radius: 8
                                    color: root.selectedPaymentMode === "Fixe" ? Style.bgWhite : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: qsTr("SALAIRE FIXE")
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        color: root.selectedPaymentMode === "Fixe" ? Style.textPrimary : Style.textTertiary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedPaymentMode = "Fixe"
                                    }

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }
                            }
                        }
                    }

                    // Valeur de Base
                    Column {
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width / 2 - 8
                        spacing: 6

                        SectionLabel {
                            text: root.selectedPaymentMode === "Heure" ? "TAUX HORAIRE (DT/H)"
                                : root.selectedPaymentMode === "Jour"  ? "TAUX JOURNALIER (DT/JOUR)"
                                : "SALAIRE MENSUEL (DT)"
                        }

                        FormField {
                            id: fieldBaseValue
                            width: parent.width
                            text: root.baseValueText
                            onTextChanged: root.baseValueText = text

                            validator: RegularExpressionValidator {
                                regularExpression: /^\d*\.?\d{0,2}$/
                            }
                        }
                    }

                    // Sélecteur de jours de travail (visible uniquement en mode "Jour")
                    Column {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        spacing: 8
                        visible: root.selectedPaymentMode === "Jour"

                        SectionLabel { text: qsTr("JOURS DE TRAVAIL") }

                        Row {
                            spacing: 6
                            Repeater {
                                model: ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
                                delegate: Rectangle {
                                    width: 50; height: 44; radius: 10
                                    property int bit: 1 << index
                                    property bool active: (root.joursTravailValue & bit) !== 0
                                    color: active ? Style.primary : Style.bgPage
                                    border.color: active ? Style.primary : Style.borderLight
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 10; font.weight: Font.Black
                                        color: active ? "white" : Style.textTertiary
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.joursTravailValue ^= bit
                                    }
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: 1
            height: 28
        }

        ModalButtons {
            width: parent.width - 80
            confirmText: {
                if (editMode === "identity") return "ENREGISTRER"
                if (editMode === "contract") return "CRÉER LE CONTRAT"
                if (editMode === "editContract") return "ENREGISTRER LE CONTRAT"
                return "ENREGISTRER LE CONTRAT"
            }
            onCancel: root.cancelled()
            onConfirm: {
                if (editMode === "identity") {
                    root.confirmed({
                        mode: "identity",
                        personnelId: root.personnelId,
                        nom: root.nomText,
                        telephone: root.telephoneText,
                        sexe: root.selectedSexe,
                        cin: root.cinText
                    })
                } else if (editMode === "contract") {
                    root.confirmed({
                        mode: "contract",
                        personnelId: root.personnelId,
                        poste: root.selectedPost,
                        specialite: root.specialtyText,
                        modePaie: root.selectedPaymentMode,
                        valeurBase: parseFloat(root.baseValueText) || 25.0,
                        joursTravail: root.joursTravailValue,
                        dateDebut: root.dateDebutText,
                        dateFin: root.dateFinText
                    })
                } else if (editMode === "editContract") {
                    root.confirmed({
                        mode: "editContract",
                        contratId: root.contratId,
                        personnelId: root.personnelId,
                        poste: root.selectedPost,
                        specialite: root.specialtyText,
                        modePaie: root.selectedPaymentMode,
                        valeurBase: parseFloat(root.baseValueText) || 25.0,
                        joursTravail: root.joursTravailValue,
                        dateDebut: root.dateDebutText,
                        dateFin: root.dateFinText
                    })
                } else {
                    root.confirmed({
                        mode: "full",
                        nom: root.nomText,
                        telephone: root.telephoneText,
                        sexe: root.selectedSexe,
                        cin: root.cinText,
                        poste: root.selectedPost,
                        specialite: root.specialtyText,
                        modePaie: root.selectedPaymentMode,
                        valeurBase: parseFloat(root.baseValueText) || 25.0,
                        joursTravail: root.joursTravailValue,
                        dateDebut: root.dateDebutText,
                        dateFin: root.dateFinText
                    })
                }
            }
        }
    }

    // Date Pickers
    DatePickerPopup {
        id: dateDebutPicker
        onConfirmed: function(isoDate) {
            root.dateDebutText = root.ddmmyyyyToIso(isoDate)
        }
    }

    DatePickerPopup {
        id: dateFinPicker
        onConfirmed: function(isoDate) {
            root.dateFinText = root.ddmmyyyyToIso(isoDate)
        }
    }
}
