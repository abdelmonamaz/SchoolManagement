import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

ModalOverlay {
    id: root

    property string personnelName: ""
    property int personnelId: -1
    property var contrats: []

    signal editContratRequested(var contratData)
    signal deleteContratRequested(int contratId)

    modalWidth: 600
    modalRadius: 32

    function parseDate(ddmmyyyy) {
        if (!ddmmyyyy || ddmmyyyy === "") return null
        var parts = ddmmyyyy.split("/")
        if (parts.length !== 3) return null
        return new Date(parts[2], parseInt(parts[1]) - 1, parseInt(parts[0]))
    }

    function getContratStatus(dateDebut, dateFin) {
        var now = new Date()
        var start = parseDate(dateDebut)
        if (start && start > now) return "avenir"
        var end = parseDate(dateFin)
        if (end && now > end) return "termine"
        return "encours"
    }

    Column {
        width: parent.width
        spacing: 24
        padding: 40

        // Header
        RowLayout {
            width: parent.width - 80
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Rectangle {
                width: 56
                height: 56
                radius: 20
                color: Style.bgSecondary

                IconLabel {
                    anchors.centerIn: parent
                    iconName: "calendar"
                    iconSize: 28
                    iconColor: Style.primary
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Historique des contrats"
                    font.pixelSize: 22
                    font.weight: Font.Black
                    color: Style.textPrimary
                }

                Text {
                    text: root.personnelName.toUpperCase()
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Style.textTertiary
                    font.letterSpacing: 1
                }
            }
        }

        // Scrollable contrats list
        Flickable {
            width: parent.width - 80
            anchors.horizontalCenter: parent.horizontalCenter
            height: Math.min(contratsCol.height, 420)
            contentHeight: contratsCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: contratsCol.height > 420 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            }

            Column {
                id: contratsCol
                width: parent.width
                spacing: 12

                Repeater {
                    model: root.contrats

                    Rectangle {
                        required property var modelData
                        required property int index

                        property string contratStatus: root.getContratStatus(modelData.dateDebut, modelData.dateFin)

                        width: contratsCol.width
                        implicitHeight: contratItemCol.implicitHeight + 32
                        radius: 16
                        color: contratStatus === "encours" ? Style.primary + "08"
                             : contratStatus === "avenir" ? "#3B82F608"
                             : Style.bgPage
                        border.color: contratStatus === "encours" ? Style.primary + "30"
                                    : contratStatus === "avenir" ? "#3B82F630"
                                    : Style.borderLight

                        Column {
                            id: contratItemCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 10

                            // Status + Poste + Actions
                            RowLayout {
                                width: parent.width
                                spacing: 8

                                Rectangle {
                                    implicitWidth: statusItemText.implicitWidth + 12
                                    height: 20
                                    radius: 8
                                    color: contratStatus === "encours" ? Style.primary
                                         : contratStatus === "avenir" ? "#3B82F6"
                                         : Style.textTertiary + "20"

                                    Text {
                                        id: statusItemText
                                        anchors.centerIn: parent
                                        text: contratStatus === "encours" ? "EN COURS"
                                            : contratStatus === "avenir" ? "À VENIR"
                                            : "TERMINÉ"
                                        font.pixelSize: 8
                                        font.weight: Font.Black
                                        color: contratStatus === "termine" ? Style.textTertiary : Style.bgWhite
                                        font.letterSpacing: 0.5
                                    }
                                }

                                Text {
                                    text: modelData.poste || "Enseignant"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    color: Style.textPrimary
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: (modelData.modePaie === "Heure" ? "Horaire" : "Fixe")
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: Style.textTertiary
                                }

                                // Edit button
                                IconButton {
                                    iconName: "edit"
                                    iconSize: 12
                                    hoverColor: Style.primary
                                    onClicked: root.editContratRequested(modelData)
                                }

                                // Delete button
                                IconButton {
                                    iconName: "delete"
                                    iconSize: 12
                                    hoverColor: Style.errorColor
                                    onClicked: root.deleteContratRequested(modelData.contratId)
                                }
                            }

                            // Details
                            RowLayout {
                                width: parent.width
                                spacing: 16

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: "RÉMUNÉRATION"
                                        font.pixelSize: 8
                                        font.weight: Font.Black
                                        color: Style.textTertiary
                                        font.letterSpacing: 0.5
                                    }

                                    Text {
                                        text: (modelData.valeurBase || 25) + " DT" + (modelData.modePaie === "Heure" ? "/h" : "/mois")
                                        font.pixelSize: 14
                                        font.weight: Font.Black
                                        color: Style.textPrimary
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: "PÉRIODE"
                                        font.pixelSize: 8
                                        font.weight: Font.Black
                                        color: Style.textTertiary
                                        font.letterSpacing: 0.5
                                    }

                                    Text {
                                        text: (modelData.dateDebut || "—") + (modelData.dateFin ? " → " + modelData.dateFin : " → ...")
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: Style.textSecondary
                                    }
                                }
                            }

                            // Specialité si présente
                            Text {
                                visible: modelData.specialite && modelData.specialite !== ""
                                text: "Spécialité: " + (modelData.specialite || "")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Style.textTertiary
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    visible: root.contrats.length === 0
                    text: "Aucun contrat trouvé."
                    font.pixelSize: 13
                    color: Style.textTertiary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // Close button
        Rectangle {
            width: parent.width - 80
            anchors.horizontalCenter: parent.horizontalCenter
            height: 48
            radius: 16
            color: Style.bgPage

            Text {
                anchors.centerIn: parent
                text: "FERMER"
                font.pixelSize: 10
                font.weight: Font.Black
                color: Style.textTertiary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }
    }
}
