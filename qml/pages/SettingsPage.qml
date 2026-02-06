import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: settingsPage
    implicitHeight: mainLayout.implicitHeight

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        PageHeader {
            Layout.fillWidth: true
            title: "Paramètres du Système"
            subtitle: "Configurez l'environnement Ez-Zaytouna selon vos besoins."
        }

        // ─── Settings Cards Grid ───
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 20
            rowSpacing: 20

            Repeater {
                model: ListModel {
                    ListElement { sid: "profile"; label: "Profil Admin"; icon: "👤"; desc: "Gérez vos informations personnelles et votre avatar." }
                    ListElement { sid: "security"; label: "Sécurité & Accès"; icon: "🛡"; desc: "Double authentification et historique de connexion." }
                    ListElement { sid: "school"; label: "Établissement"; icon: "🏫"; desc: "Nom de l'école, logo, et année scolaire en cours." }
                    ListElement { sid: "rooms"; label: "Gestion des Salles"; icon: "📍"; desc: "Configurez les salles disponibles et leur capacité." }
                    ListElement { sid: "notif"; label: "Notifications"; icon: "🔔"; desc: "Paramètres des alertes SMS et Emails pour les parents." }
                    ListElement { sid: "backup"; label: "Sauvegarde & Data"; icon: "🗄"; desc: "Sauvegardes automatiques et export de la base." }
                }

                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 160
                    radius: Style.radiusRound
                    color: Style.bgWhite
                    border.color: setMa.containsMouse ? Style.primary : Style.borderLight
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 12

                        Rectangle {
                            width: 48; height: 48
                            radius: 16
                            color: setMa.containsMouse ? Style.primaryBg : Style.bgPage

                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: model.icon
                                font.pixelSize: 22
                            }
                        }

                        Text {
                            text: model.label
                            font.pixelSize: 14; font.bold: true
                            color: setMa.containsMouse ? Style.primary : Style.textPrimary
                        }

                        Text {
                            text: model.desc
                            font.pixelSize: 11; font.weight: Font.Medium
                            color: Style.textTertiary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: setMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        // ─── Configuration des Tarifs ───
        AppCard {
            Layout.fillWidth: true
            title: "Configuration des Tarifs (Mensualités)"
            subtitle: "Définissez les frais de scolarité par défaut pour la génération automatique."

            Column {
                width: parent.width
                spacing: 24

                // Grid with 2 tarif cards
                GridLayout {
                    width: parent.width
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 24

                    // Tarif Enfant
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: childCol.implicitHeight + 48
                        radius: 24
                        color: Style.chartBlueLight
                        border.color: "#BFDBFE"
                        border.width: 1

                        Column {
                            id: childCol
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 12

                            Text {
                                text: "TARIF ENFANT"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: Style.chartBlue
                                font.letterSpacing: 2
                            }

                            RowLayout {
                                width: parent.width
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 48
                                    radius: 12
                                    color: "#FFFFFF"
                                    border.color: "#BFDBFE"
                                    border.width: 1

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        text: "150"
                                        font.pixelSize: 16
                                        font.weight: Font.Black
                                        color: Style.chartBlue
                                        verticalAlignment: TextInput.AlignVCenter
                                    }
                                }

                                Text {
                                    text: "DT"
                                    font.pixelSize: 16
                                    font.weight: Font.Black
                                    color: Style.chartBlue
                                }
                            }
                        }
                    }

                    // Tarif Adulte
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: adultCol.implicitHeight + 48
                        radius: 24
                        color: "#FEF3C7"
                        border.color: "#FCD34D"
                        border.width: 1

                        Column {
                            id: adultCol
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 12

                            Text {
                                text: "TARIF ADULTE"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: "#D97706"
                                font.letterSpacing: 2
                            }

                            RowLayout {
                                width: parent.width
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 48
                                    radius: 12
                                    color: "#FFFFFF"
                                    border.color: "#FCD34D"
                                    border.width: 1

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        text: "250"
                                        font.pixelSize: 16
                                        font.weight: Font.Black
                                        color: "#D97706"
                                        verticalAlignment: TextInput.AlignVCenter
                                    }
                                }

                                Text {
                                    text: "DT"
                                    font.pixelSize: 16
                                    font.weight: Font.Black
                                    color: "#D97706"
                                }
                            }
                        }
                    }
                }

                // Info box
                Rectangle {
                    width: parent.width
                    implicitHeight: infoRow.implicitHeight + 32
                    radius: 16
                    color: Style.bgPage
                    border.color: Style.borderLight
                    border.width: 1

                    RowLayout {
                        id: infoRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        IconLabel {
                            iconName: "info"
                            iconSize: 18
                            iconColor: Style.textSecondary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "CES TARIFS SERONT APPLIQUÉS LORS DE LA GÉNÉRATION AUTOMATIQUE DU GRAND LIVRE MENSUEL DANS LE MENU FINANCE."
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Style.textSecondary
                            wrapMode: Text.WordWrap
                            lineHeight: 1.5
                        }
                    }
                }
            }
        }

        // ─── Bottom cards ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            // School Info Form
            AppCard {
                Layout.fillWidth: true
                title: "Informations de l'Établissement"

                Column {
                    width: parent.width
                    spacing: 20

                    RowLayout {
                        width: parent.width; spacing: 16

                        FormField {
                            Layout.fillWidth: true
                            label: "NOM DE L'ÉCOLE"
                            text: "Ez-Zaytouna"
                        }

                        FormField {
                            Layout.fillWidth: true
                            label: "TYPE"
                            text: "Primaire / Secondaire"
                        }
                    }

                    Column {
                        width: parent.width; spacing: 6
                        SectionLabel { text: "ADRESSE" }
                        Rectangle {
                            width: parent.width; height: 80; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                            TextEdit {
                                anchors.fill: parent; anchors.margins: 12
                                text: "123 Rue de la Science, Casablanca, Maroc"
                                font.pixelSize: 13; font.bold: true
                                color: Style.textPrimary
                                wrapMode: TextEdit.Wrap
                            }
                        }
                    }

                    PrimaryButton { text: "Enregistrer les modifications" }
                }
            }

            // System Status
            AppCard {
                Layout.fillWidth: true
                title: "État du Système"

                Column {
                    width: parent.width
                    spacing: 20

                    // Cloud status
                    Rectangle {
                        width: parent.width; height: 64; radius: 16
                        color: Style.successBg; border.color: Style.successBorder

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 14

                            Rectangle {
                                width: 40; height: 40; radius: 12
                                color: Style.successBorder

                                Text { anchors.centerIn: parent; text: "☁"; font.pixelSize: 18; color: Style.successColor }
                            }

                            Column {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Stockage Cloud"; font.pixelSize: 13; font.bold: true; color: Style.successColor }
                                Text { text: "CONNECTÉ & SYNCHRONISÉ"; font.pixelSize: 9; font.weight: Font.Bold; color: Style.successColor }
                            }

                            Text { text: "8.4 GB / 20 GB"; font.pixelSize: 13; font.weight: Font.Black; color: Style.successColor }
                        }
                    }

                    // Updates section
                    Column {
                        width: parent.width; spacing: 12
                        Text { text: "MISES À JOUR"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }

                        Column {
                            width: parent.width; spacing: 0

                            RowLayout {
                                width: parent.width; height: 52
                                Column { Layout.fillWidth: true; spacing: 2
                                    Text { text: "Version du Logiciel"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text { text: "Dernière vérification: Aujourd'hui 08:00"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }
                                }
                                Badge { text: "v2.4.8 (Stable)" }
                            }

                            Separator { width: parent.width }

                            RowLayout {
                                width: parent.width; height: 52
                                Column { Layout.fillWidth: true; spacing: 2
                                    Text { text: "Base de données"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text { text: "Prochaine sauvegarde: Demain 02:00"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }
                                }
                                Badge { text: "Optimisée"; variant: "success" }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }
}
