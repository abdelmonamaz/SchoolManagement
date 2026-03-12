import QtQuick
import QtQuick.Layouts
import UI.Components

Rectangle {
    id: root

    property var staffData
    property string moisLabel: ""
    property bool isShowAllMode: staffData.showAllMode || false
    signal editIdentityClicked()
    signal editContratClicked()
    signal newContratClicked()
    signal deleteClicked()
    signal payClicked()
    signal viewHistoryClicked()

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

                Flow {
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        implicitWidth: postText.implicitWidth + 12
                        height: 20
                        radius: 8
                        visible: staffData.poste && staffData.poste !== ""
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
                        visible: staffData.modePaie && staffData.modePaie !== ""
                        text: (staffData.modePaie === "Heure" || !staffData.modePaie) ? "HORAIRE" : "FIXE"
                        variant: (staffData.modePaie === "Heure" || !staffData.modePaie) ? "info" : "success"
                    }

                    // Badge historique contrats
                    Rectangle {
                        visible: (staffData.nbContrats || 0) > 1
                        implicitWidth: contratCountText.implicitWidth + 12
                        height: 20
                        radius: 8
                        color: Style.primary + "15"

                        Text {
                            id: contratCountText
                            anchors.centerIn: parent
                            text: (staffData.nbContrats || 1) + " CONTRATS"
                            font.pixelSize: 8
                            font.weight: Font.Black
                            color: Style.primary
                            font.letterSpacing: 0.5
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.viewHistoryClicked()
                        }
                    }
                }
            }

            Row {
                spacing: 8

                // Menu d'édition avec deux options
                IconButton {
                    iconName: "edit"
                    iconSize: 14
                    hoverColor: Style.primary
                    onClicked: editMenu.visible = !editMenu.visible
                }

                IconButton {
                    iconName: "delete"
                    iconSize: 14
                    hoverColor: Style.errorColor
                    onClicked: root.deleteClicked()
                }
            }
        }

        // Menu contextuel d'édition
        Rectangle {
            id: editMenu
            visible: false
            width: parent.width
            implicitHeight: editMenuCol.implicitHeight + 8
            radius: 12
            color: Style.bgPage
            border.color: Style.borderLight

            Column {
                id: editMenuCol
                anchors.fill: parent
                anchors.margins: 4

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: editIdentityMa.containsMouse ? Style.bgSecondary : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        spacing: 8

                        IconLabel {
                            iconName: "edit"
                            iconSize: 12
                            iconColor: Style.textSecondary
                        }

                        Text {
                            text: qsTr("Modifier l'identité")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Style.textPrimary
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: editIdentityMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            editMenu.visible = false
                            root.editIdentityClicked()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    visible: staffData.contratId > 0
                    color: editContratMa.containsMouse ? Style.bgSecondary : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        spacing: 8

                        IconLabel {
                            iconName: "edit"
                            iconSize: 12
                            iconColor: Style.warningColor
                        }

                        Text {
                            text: qsTr("Modifier le contrat")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Style.warningColor
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: editContratMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            editMenu.visible = false
                            root.editContratClicked()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: newContratMa.containsMouse ? Style.bgSecondary : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        spacing: 8

                        IconLabel {
                            iconName: "plus"
                            iconSize: 12
                            iconColor: Style.primary
                        }

                        Text {
                            text: qsTr("Nouveau contrat")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Style.primary
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: newContratMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            editMenu.visible = false
                            root.newContratClicked()
                        }
                    }
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

                SectionLabel { text: qsTr("TÉLÉPHONE") }

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

                SectionLabel { text: qsTr("CIN") }

                Text {
                    text: staffData.cin || "—"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Style.textSecondary
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        Separator {
            width: parent.width
            visible: !isShowAllMode
        }

        // Informations financières
        RowLayout {
            width: parent.width
            spacing: 12
            visible: !isShowAllMode

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2

                Text {
                    text: qsTr("Base Rémunération")
                    font.pixelSize: 10
                    font.bold: true
                    color: Style.textTertiary
                }

                Text {
                    text: (staffData.valeurBase || 25) + " DT"
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: Style.textPrimary
                }

                Text {
                    text: qsTr("/") + (staffData.modePaie === "Heure" ? "h"
                               : staffData.modePaie === "Jour"  ? "jour"
                               : "mois")
                    font.pixelSize: 10
                    color: Style.textTertiary
                    font.bold: true
                }
            }

            Column {
                Layout.alignment: Qt.AlignTop
                visible: staffData.modePaie === "Heure" || staffData.modePaie === "Jour" || !staffData.modePaie
                spacing: 2

                Text {
                    text: staffData.modePaie === "Jour"
                        ? "Jours " + (root.moisLabel || "")
                        : "Heures " + (root.moisLabel || "")
                    font.pixelSize: 10
                    font.bold: true
                    color: Style.textTertiary
                }

                Text {
                    text: staffData.modePaie === "Jour"
                        ? (staffData.joursTravailes || 0) + "j"
                        : (staffData.heuresTravailes || 0) + "h"
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: Style.primary
                }
            }
        }

        // Date du contrat
        Row {
            width: parent.width
            spacing: 8
            visible: !isShowAllMode

            Text {
                text: qsTr("Contrat depuis:")
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Style.textTertiary
            }

            Text {
                text: staffData.dateDebut || "—"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Style.textSecondary
            }
        }

        Separator {
            width: parent.width
            visible: !isShowAllMode
        }

        // Somme due et Somme payée
        RowLayout {
            width: parent.width
            spacing: 16
            visible: !isShowAllMode

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 6

                SectionLabel {
                    text: qsTr("SOMME DUE")
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
                    text: qsTr("SOMME PAYÉE")
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
                    text: qsTr("Payer")
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
            case "Administration": return Style.chart2
            case "Sécurité": return Style.chart1
            case "Entretien": return Style.chart3
            default: return Style.primary
        }
    }

    function getPostBgColor(post) {
        switch(post) {
            case "Enseignant": return Style.primary + "20"
            case "Administration": return Qt.alpha(Style.chart2, 0.13)
            case "Sécurité": return Qt.alpha(Style.chart1, 0.13)
            case "Entretien": return Qt.alpha(Style.chart3, 0.13)
            default: return Style.primary + "20"
        }
    }
}
