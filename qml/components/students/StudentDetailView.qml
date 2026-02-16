import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

ColumnLayout {
    id: root
    spacing: 28

    required property var student
    required property var niveaux
    required property var classes

    signal backRequested()
    signal editRequested()
    signal deleteRequested()

    // Back button
    Text {
        text: "← Retour à l'annuaire"
        font.pixelSize: 14; font.bold: true
        color: backMa.containsMouse ? Style.primary : Style.textSecondary

        MouseArea {
            id: backMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.backRequested()
        }
    }

    // Student header card
    Rectangle {
        Layout.fillWidth: true
        height: 160
        radius: Style.radiusRound
        color: Style.bgWhite
        border.color: Style.borderLight

        RowLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 28

            // Avatar
            Avatar {
                size: 100
                initials: root.student.nom ? root.student.nom.charAt(0) : ""
                bgColor: Style.bgSecondary
                textColor: Style.textSecondary
                border.color: "#FFFFFF"
                border.width: 4
            }

            // Info
            Column {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    spacing: 12
                    Text { text: (root.student.nom || "") + " " + (root.student.prenom || ""); font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary }
                    Badge { text: root.student.categorie || ""; variant: "info" }
                }

                Text {
                    text: "MATRICULE: " + (root.student.id || "")
                    font.pixelSize: 12; font.weight: Font.Bold
                    color: Style.textTertiary
                    font.letterSpacing: 2
                }

                RowLayout {
                    spacing: 20
                    Row {
                        spacing: 6
                        IconLabel { iconName: "phone"; iconSize: 14; iconColor: Style.primary }
                        Text { text: root.student.telephone || ""; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary }
                    }
                    Row {
                        spacing: 6
                        IconLabel { iconName: "mail"; iconSize: 14; iconColor: Style.primary }
                        Text { text: root.student.adresse || ""; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary }
                    }
                }
            }

            Row {
                spacing: 8
                OutlineButton {
                    text: "Modifier"
                    onClicked: root.editRequested()
                }
                PrimaryButton { text: "Bulletin PDF" }
            }
        }
    }

    // Info Cards
    RowLayout {
        Layout.fillWidth: true
        spacing: 24

        // Left column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 2
            spacing: 24

            AppCard {
                Layout.fillWidth: true
                title: "Informations Personnelles"

                Column {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        width: parent.width
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "NOM" }
                            Text { text: root.student.nom || ""; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "PRÉNOM" }
                            Text { text: root.student.prenom || ""; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                    }

                    Separator { width: parent.width }

                    RowLayout {
                        width: parent.width
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "DATE DE NAISSANCE" }
                            Text {
                                text: {
                                    var d = root.student.dateNaissance || ""
                                    if (d.length === 10)
                                        return d.substring(8,10) + "/" + d.substring(5,7) + "/" + d.substring(0,4)
                                    return "—"
                                }
                                font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                            }
                        }
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "CATÉGORIE" }
                            Text { text: root.student.categorie || ""; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                    }

                    Separator { width: parent.width }

                    RowLayout {
                        width: parent.width
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "TÉLÉPHONE" }
                            Text { text: root.student.telephone || ""; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "ADRESSE" }
                            Text { text: root.student.adresse || ""; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                    }
                }
            }
        }

        // Right sidebar
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 24

            AppCard {
                Layout.fillWidth: true
                title: "Infos Administratives"

                Column {
                    width: parent.width
                    spacing: 20

                    Column {
                        width: parent.width; spacing: 4
                        SectionLabel { text: "MATRICULE" }
                        Text { text: root.student.id ? root.student.id.toString() : ""; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                    }

                    Separator { width: parent.width }

                    Column {
                        width: parent.width; spacing: 4
                        SectionLabel { text: "NIVEAU" }
                        Text {
                            text: {
                                var cid = root.student.classeId || 0
                                if (cid === 0) return "Aucune classe"
                                for (var i = 0; i < root.classes.length; i++) {
                                    if (root.classes[i].id === cid) {
                                        var nid = root.classes[i].niveauId
                                        for (var j = 0; j < root.niveaux.length; j++) {
                                            if (root.niveaux[j].id === nid)
                                                return root.niveaux[j].nom
                                        }
                                    }
                                }
                                return "—"
                            }
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                        }
                    }

                    Separator { width: parent.width }

                    Column {
                        width: parent.width; spacing: 4
                        SectionLabel { text: "CLASSE" }
                        Text {
                            text: {
                                var cid = root.student.classeId || 0
                                if (cid === 0) return "Non assigné"
                                for (var i = 0; i < root.classes.length; i++) {
                                    if (root.classes[i].id === cid)
                                        return root.classes[i].nom
                                }
                                return "—"
                            }
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                        }
                    }
                }
            }

            AppCard {
                Layout.fillWidth: true
                title: "Actions rapides"

                Column {
                    width: parent.width
                    spacing: 12

                    PrimaryButton {
                        width: parent.width
                        text: "Modifier le dossier"
                        iconName: "edit"
                        onClicked: root.editRequested()
                    }

                    OutlineButton {
                        width: parent.width
                        text: "Supprimer l'élève"
                        color: Style.errorColor
                        onClicked: root.deleteRequested()
                    }
                }
            }
        }
    }
}
