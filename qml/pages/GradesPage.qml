import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: gradesPage
    implicitHeight: mainLayout.implicitHeight

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        // Header
        RowLayout {
            Layout.fillWidth: true

            PageHeader {
                Layout.fillWidth: true
                title: "Saisie des Notes"
                subtitle: "Saisissez et validez les résultats des épreuves."
            }

            Row {
                spacing: 8

                OutlineButton {
                    text: "Exporter CSV"
                    iconName: "download"
                }

                PrimaryButton {
                    text: "Générer les Bulletins"
                    iconName: "file"
                }
            }
        }

        // Filters
        AppCard {
            Layout.fillWidth: true

            RowLayout {
                width: parent.width
                spacing: 16

                Repeater {
                    model: [
                        { label: "ANNÉE", value: "2025 - 2026" },
                        { label: "NIVEAU", value: "Niveau 1" },
                        { label: "MATIÈRE", value: "Histoire Islamique" },
                        { label: "ÉPREUVE", value: "Partiel Trimestre 1" }
                    ]

                    delegate: Column {
                        Layout.fillWidth: true
                        spacing: 6

                        SectionLabel {
                            text: modelData.label
                        }

                        Rectangle {
                            width: parent.width
                            height: 44
                            radius: 12
                            color: Style.bgPage
                            border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.value
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Style.textPrimary
                                }

                                Text {
                                    text: "▾"
                                    font.pixelSize: 14
                                    color: Style.textTertiary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }
        }

        // Main content
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            // Grade entry table
            AppCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 3
                title: "Grille de Saisie"
                subtitle: "Épreuve: Histoire Islamique - Niveau 3"

                Column {
                    width: parent.width
                    spacing: 0

                    // Table header
                    RowLayout {
                        width: parent.width
                        height: 40

                        SectionLabel {
                            Layout.preferredWidth: 180
                            text: "ÉLÈVE"
                        }

                        SectionLabel {
                            Layout.preferredWidth: 100
                            text: "NOTE / 20"
                        }

                        SectionLabel {
                            Layout.fillWidth: true
                            text: "REMARQUES / OBSERVATIONS"
                        }

                        SectionLabel {
                            Layout.preferredWidth: 80
                            text: "STATUT"
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Separator { width: parent.width }

                    // Rows
                    Repeater {
                        model: ListModel {
                            ListElement {
                                sid: "2025001"
                                name: "Amine Ben Salem"
                                grade: ""
                                comment: ""
                                saved: false
                            }
                            ListElement {
                                sid: "2025002"
                                name: "Sara Khalil"
                                grade: "16"
                                comment: "Excellent travail"
                                saved: true
                            }
                            ListElement {
                                sid: "2025003"
                                name: "Zaid Al-Harbi"
                                grade: ""
                                comment: ""
                                saved: false
                            }
                            ListElement {
                                sid: "2025004"
                                name: "Layla Mansour"
                                grade: "14.5"
                                comment: "Bonne progression"
                                saved: true
                            }
                            ListElement {
                                sid: "2025005"
                                name: "Omar Al-Faruq"
                                grade: ""
                                comment: ""
                                saved: false
                            }
                        }

                        delegate: Column {
                            width: parent.width

                            RowLayout {
                                width: parent.width
                                height: 60

                                // Student name
                                RowLayout {
                                    Layout.preferredWidth: 180
                                    spacing: 10

                                    Avatar {
                                        initials: model.name.charAt(0)
                                        size: 32
                                        bgColor: Style.bgSecondary
                                        textColor: Style.primary
                                    }

                                    Column {
                                        spacing: 1

                                        Text {
                                            text: model.name
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Style.textPrimary
                                        }

                                        Text {
                                            text: model.sid
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: Style.textTertiary
                                        }
                                    }
                                }

                                // Grade input
                                Item {
                                    Layout.preferredWidth: 100
                                    implicitHeight: 36

                                    Rectangle {
                                        width: 72
                                        height: 36
                                        radius: 8
                                        color: Style.bgPage
                                        border.color: Style.borderMedium

                                        TextInput {
                                            anchors.centerIn: parent
                                            width: 50
                                            text: model.grade
                                            font.pixelSize: 14
                                            font.weight: Font.Black
                                            color: Style.primary
                                            horizontalAlignment: Text.AlignHCenter

                                            Text {
                                                visible: !parent.text
                                                anchors.centerIn: parent
                                                text: "--"
                                                font: parent.font
                                                color: Style.textTertiary
                                            }
                                        }
                                    }
                                }

                                // Comment
                                Item {
                                    Layout.fillWidth: true
                                    implicitHeight: 36

                                    TextInput {
                                        anchors.fill: parent
                                        anchors.topMargin: 8
                                        text: model.comment
                                        font.pixelSize: 13
                                        font.italic: true
                                        color: Style.textSecondary

                                        Text {
                                            visible: !parent.text
                                            text: "Saisir une observation..."
                                            font: parent.font
                                            color: Style.textTertiary
                                            opacity: 0.5
                                        }
                                    }
                                }

                                // Status
                                Row {
                                    Layout.preferredWidth: 80
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 4

                                    Text {
                                        text: model.saved ? "✓" : "⚠"
                                        font.pixelSize: 14
                                        color: model.saved ? Style.successColor : Style.textTertiary
                                    }

                                    Text {
                                        text: model.saved ? "SAISI" : "EN ATTENTE"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: model.saved ? Style.successColor : Style.textTertiary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Separator { width: parent.width }
                        }
                    }

                    // Footer
                    Item {
                        width: 1
                        height: 24
                    }

                    Separator { width: parent.width }

                    Item {
                        width: 1
                        height: 24
                    }

                    RowLayout {
                        width: parent.width

                        RowLayout {
                            spacing: 32

                            Column {
                                spacing: 2

                                SectionLabel {
                                    text: "MOYENNE DE CLASSE"
                                }

                                Text {
                                    text: "15.25"
                                    font.pixelSize: 24
                                    font.weight: Font.Black
                                    color: Style.primary
                                }
                            }

                            Column {
                                spacing: 2

                                SectionLabel {
                                    text: "SAISIE COMPLÉTÉE"
                                }

                                Text {
                                    text: "2 / 5"
                                    font.pixelSize: 24
                                    font.weight: Font.Black
                                    color: Style.textPrimary
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        PrimaryButton {
                            text: "Enregistrer les Notes"
                            iconName: "save"
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
                    title: "Guide de Saisie"

                    Column {
                        width: parent.width
                        spacing: 16

                        RowLayout {
                            spacing: 10

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Style.infoBg

                                Text {
                                    anchors.centerIn: parent
                                    text: "🔢"
                                    font.pixelSize: 14
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Utilisez le point (.) pour les décimales (ex: 15.5). La moyenne se recalcule en temps réel."
                                font.pixelSize: 11
                                color: Style.textSecondary
                                wrapMode: Text.WordWrap
                            }
                        }

                        Rectangle {
                            width: parent.width
                            implicitHeight: warnCol.implicitHeight + 24
                            radius: 16
                            color: Style.warningBg
                            border.color: Style.warningBorder

                            Column {
                                id: warnCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4

                                Text {
                                    text: "Attention"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Style.warningColor
                                }

                                Text {
                                    text: "Les bulletins ne peuvent être générés que si 100% des notes sont saisies pour cette épreuve."
                                    font.pixelSize: 10
                                    color: Style.warningColor
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                            }
                        }
                    }
                }

                AppCard {
                    Layout.fillWidth: true
                    title: "Progression de Saisie"

                    Column {
                        width: parent.width
                        spacing: 18

                        Repeater {
                            model: [
                                { subject: "Arabe", progress: 100 },
                                { subject: "Histoire Islamique", progress: 40 },
                                { subject: "Coran", progress: 0 }
                            ]

                            delegate: Column {
                                width: parent.width
                                spacing: 6

                                RowLayout {
                                    width: parent.width

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.subject
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Style.textPrimary
                                    }

                                    Text {
                                        text: modelData.progress + "%"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Style.textTertiary
                                    }
                                }

                                ProgressBar_ {
                                    width: parent.width
                                    value: modelData.progress / 100
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: 32
        }
    }
}
