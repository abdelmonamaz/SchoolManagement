import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

ModalOverlay {
    id: root

    property bool isEditing: false

    // Form data properties
    property string nomText: ""
    property string telephoneText: ""
    property string specialtyText: ""
    property string baseValueText: "25"
    property string selectedPost: "Enseignant"
    property string selectedPaymentMode: "Heure"
    property string selectedStatus: "active"

    signal confirmed(var formData)
    signal cancelled()

    modalWidth: 640
    onClose: cancelled()

    function reset() {
        nomText = ""
        telephoneText = ""
        specialtyText = ""
        baseValueText = "25"
        selectedPost = "Enseignant"
        selectedPaymentMode = "Heure"
        selectedStatus = "active"
    }

    function populate(data) {
        nomText = data.nom
        telephoneText = data.telephone
        specialtyText = data.specialite || ""
        baseValueText = String(data.valeurBase || data.prixHeureActuel || 25)
        selectedPost = data.poste || "Enseignant"
        selectedPaymentMode = data.modePaie || "Heure"
        selectedStatus = data.statut === "Actif" ? "active" : "on_leave"
    }

    Column {
        width: parent.width
        spacing: 0
        padding: 40

        Text {
            text: isEditing ? "Modifier le contrat" : "Nouveau membre du personnel"
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

            // Nom Complet
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 6

                SectionLabel {
                    text: "NOM COMPLET"
                }

                FormField {
                    id: fieldNom
                    width: parent.width
                    placeholder: "Nom complet..."
                    text: root.nomText
                    onTextChanged: root.nomText = text
                    nextTabItem: fieldTelephone.inputItem
                }
            }

            // Type de Poste
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6

                SectionLabel {
                    text: "TYPE DE POSTE"
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

            // Téléphone
            Column {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2 - 8
                spacing: 6

                SectionLabel {
                    text: "TÉLÉPHONE"
                }

                FormField {
                    id: fieldTelephone
                    width: parent.width
                    placeholder: "XX XXX XXX"
                    text: root.telephoneText
                    onTextChanged: root.telephoneText = text
                    prevTabItem: fieldNom.inputItem
                    nextTabItem: fieldSpecialty.visible ? fieldSpecialty.inputItem : fieldBaseValue.inputItem

                    validator: RegularExpressionValidator {
                        regularExpression: /^\d{0,2}\s?\d{0,3}\s?\d{0,3}$/
                    }
                }
            }

            // Spécialité (si Enseignant)
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 6
                visible: root.selectedPost === "Enseignant"

                SectionLabel {
                    text: "SPÉCIALITÉ"
                }

                FormField {
                    id: fieldSpecialty
                    width: parent.width
                    placeholder: "ex: Fiqh & Hadith"
                    text: root.specialtyText
                    onTextChanged: root.specialtyText = text
                    prevTabItem: fieldTelephone.inputItem
                    nextTabItem: fieldBaseValue.inputItem
                }
            }

            // Separator
            Separator {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.topMargin: 12
                Layout.bottomMargin: 12
            }

            // Section Paramètres de Rémunération
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 20

                RowLayout {
                    width: parent.width
                    spacing: 8

                    IconLabel {
                        iconName: "dollar-sign"
                        iconSize: 16
                        iconColor: Style.primary
                    }

                    Text {
                        text: "PARAMÈTRES DE RÉMUNÉRATION"
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
                            text: "MODE DE PAIEMENT"
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
                                    color: root.selectedPaymentMode === "Heure" ? Style.bgWhite : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "À L'HEURE"
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        color: root.selectedPaymentMode === "Heure" ? Style.textPrimary : Style.textTertiary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedPaymentMode = "Heure"
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
                                        text: "SALAIRE FIXE"
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
                            text: root.selectedPaymentMode === "Heure" ? "TAUX HORAIRE (DT/H)" : "SALAIRE MENSUEL (DT)"
                        }

                        FormField {
                            id: fieldBaseValue
                            width: parent.width
                            text: root.baseValueText
                            onTextChanged: root.baseValueText = text
                            prevTabItem: fieldSpecialty.visible ? fieldSpecialty.inputItem : fieldTelephone.inputItem

                            validator: RegularExpressionValidator {
                                regularExpression: /^\d*\.?\d{0,2}$/
                            }
                        }
                    }

                }
            }

            // Separator
            Separator {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.topMargin: 12
                Layout.bottomMargin: 12
            }

            // Statut Actuel
            Column {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                spacing: 6

                SectionLabel {
                    text: "STATUT ACTUEL"
                }

                Row {
                    width: parent.width
                    spacing: 16

                    Rectangle {
                        width: (parent.width - 16) / 2
                        height: 48
                        radius: 12
                        color: root.selectedStatus === "active" ? Style.primary : Style.bgPage
                        border.color: root.selectedStatus === "active" ? Style.primary : Style.borderLight

                        Text {
                            anchors.centerIn: parent
                            text: "ACTIF"
                            font.pixelSize: 12
                            font.weight: Font.Black
                            color: root.selectedStatus === "active" ? Style.bgWhite : Style.textTertiary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedStatus = "active"
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 16) / 2
                        height: 48
                        radius: 12
                        color: root.selectedStatus === "on_leave" ? Style.warningColor : Style.bgPage
                        border.color: root.selectedStatus === "on_leave" ? Style.warningColor : Style.borderLight

                        Text {
                            anchors.centerIn: parent
                            text: "EN CONGÉ"
                            font.pixelSize: 12
                            font.weight: Font.Black
                            color: root.selectedStatus === "on_leave" ? Style.bgWhite : Style.textTertiary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedStatus = "on_leave"
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
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
            confirmText: "ENREGISTRER LE CONTRAT"
            onCancel: root.cancelled()
            onConfirm: {
                root.confirmed({
                    nom: root.nomText,
                    telephone: root.telephoneText,
                    poste: root.selectedPost,
                    specialite: root.specialtyText,
                    modePaie: root.selectedPaymentMode,
                    valeurBase: parseFloat(root.baseValueText) || 25.0,
                    statut: root.selectedStatus === "active" ? "Actif" : "En congé"
                })
            }
        }
    }
}
