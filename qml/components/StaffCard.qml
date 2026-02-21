import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

Rectangle {
    id: root

    property var staffData
    signal editClicked()
    signal deleteClicked()
    signal payClicked()

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    implicitHeight: staffCardCol.implicitHeight + 48
    radius: 24
    color: Style.bgWhite
    border.color: staffCardMa.containsMouse ? Qt.rgba(0.24, 0.35, 0.27, 0.2) : Style.borderLight

    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }

    Column {
        id: staffCardCol
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        // Header avec Avatar et Actions
        RowLayout {
            width: parent.width
            spacing: 14

            Avatar {
                initials: staffData.nom.charAt(0)
                size: 56
                bgColor: Style.bgSecondary
                textColor: Style.primary
                textSize: 20
            }

            Column {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: staffData.nom + " " + (staffData.prenom || "")
                    font.pixelSize: 14
                    font.bold: true
                    color: Style.textPrimary
                    elide: Text.ElideRight
                    width: parent.width
                }

                Row {
                    spacing: 6

                    Rectangle {
                        implicitWidth: postText.implicitWidth + 12
                        height: 20
                        radius: 8
                        color: getPostBgColor(staffData.poste || "Enseignant")

                        Text {
                            id: postText
                            anchors.centerIn: parent
                            text: (staffData.poste || "ENSEIGNANT").toUpperCase()
                            font.pixelSize: 8
                            font.weight: Font.Black
                            color: getPostColor(staffData.poste || "Enseignant")
                            font.letterSpacing: 0.5
                        }
                    }

                    Badge {
                        text: (staffData.modePaie === "Heure" || !staffData.modePaie) ? "HORAIRE" : "FIXE"
                        variant: (staffData.modePaie === "Heure" || !staffData.modePaie) ? "info" : "success"
                    }
                }
            }

            Row {
                spacing: 8

                IconButton {
                    iconName: "edit"
                    iconSize: 14
                    hoverColor: Style.primary
                    onClicked: root.editClicked()
                }

                IconButton {
                    iconName: "delete"
                    iconSize: 14
                    hoverColor: Style.errorColor
                    onClicked: root.deleteClicked()
                }
            }
        }

        Separator { width: parent.width }

        // Informations de contact
        Row {
            width: parent.width
            spacing: 16

            Column {
                width: (parent.width - 16) / 2
                spacing: 6

                SectionLabel {
                    text: "TÉLÉPHONE"
                }

                Text {
                    text: staffData.telephone || "—"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Style.textSecondary
                }
            }

            Column {
                width: (parent.width - 16) / 2
                spacing: 6
                visible: staffData.specialite

                SectionLabel {
                    text: "SPÉCIALITÉ"
                }

                Text {
                    text: staffData.specialite || "—"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Style.textSecondary
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        Separator { width: parent.width }

        // Informations financières
        RowLayout {
            width: parent.width
            spacing: 12

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2

                Text {
                    text: "Base Rémunération"
                    font.pixelSize: 10
                    font.bold: true
                    color: Style.textTertiary
                }

                Text {
                    text: (staffData.valeurBase || staffData.prixHeureActuel || 25) + " DT"
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: Style.textPrimary
                }

                Text {
                    text: "/" + ((staffData.modePaie === "Heure" || !staffData.modePaie) ? "h" : "mois")
                    font.pixelSize: 10
                    color: Style.textTertiary
                    font.bold: true
                }
            }

            Column {
                Layout.alignment: Qt.AlignTop
                visible: staffData.modePaie === "Heure" || !staffData.modePaie
                spacing: 2

                Text {
                    text: "Heures Février"
                    font.pixelSize: 10
                    font.bold: true
                    color: Style.textTertiary
                }

                Text {
                    text: (staffData.heuresTravailes || 0) + "h"
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: Style.primary
                }
            }
        }

        Separator { width: parent.width }

        // Paiement Estimé et Simulation
        RowLayout {
            width: parent.width
            spacing: 16

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 6

                SectionLabel {
                    text: "PAIEMENT RÉEL"
                }

                Text {
                    property real dueAmount: staffData.sommeDue || 0
                    text: dueAmount.toFixed(2) + " DT"
                    font.pixelSize: 16
                    font.weight: Font.Black
                    color: Style.successColor
                }
            }

            Column {
                Layout.alignment: Qt.AlignTop
                spacing: 6

                SectionLabel {
                    text: "SOMME PAYÉE"
                }

                Text {
                    property real paidAmount: staffData.sommePaye || 0
                    property real dueAmount: staffData.sommeDue || 0
                    text: paidAmount.toFixed(2) + " DT"
                    font.pixelSize: 16
                    font.weight: Font.Black
                    color: paidAmount >= dueAmount ? Style.successColor : Style.errorColor
                }

                PrimaryButton {
                    text: "Payer"
                    iconName: "dollar-sign"
                    onClicked: root.payClicked()
                }
            }
        }
    }

    MouseArea {
        id: staffCardMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }

    function getPostColor(post) {
        switch(post) {
            case "Enseignant": return Style.primary
            case "Administration": return "#0EA5E9"
            case "Sécurité": return "#F97316"
            case "Entretien": return "#8B5CF6"
            default: return Style.primary
        }
    }

    function getPostBgColor(post) {
        switch(post) {
            case "Enseignant": return Style.primary + "20"
            case "Administration": return "#0EA5E920"
            case "Sécurité": return "#F9731620"
            case "Entretien": return "#8B5CF620"
            default: return Style.primary + "20"
        }
    }
}
