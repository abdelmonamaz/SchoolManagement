import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Clôture Étape 2 : Progressions par élève ──────────────────────────────────
Column {
    id: root
    spacing: 8

    required property var  progressions
    required property bool step2Valid
    required property int  nbDecides

    signal progressionChanged(int index, var updatedItem)

    // Summary bar
    Rectangle {
        width: parent.width; height: 40; radius: 10
        color: root.step2Valid ? Style.successBg : Style.warningBg
        border.color: root.step2Valid ? Style.successColor : Style.warningBorder; border.width: 1

        Row {
            anchors.centerIn: parent; spacing: 8
            Text { text: root.step2Valid ? "✅" : "⏳"; font.pixelSize: 14 }
            Text {
                text: qsTr("%1 / %2 résultats décidés").arg(root.nbDecides).arg(root.progressions.length)
                      + (root.step2Valid ? qsTr(" — Prêt à continuer") : qsTr(" — Décidez tous les résultats"))
                font.pixelSize: 13; font.bold: true
                color: root.step2Valid ? Style.zitouna : Style.warningColor
            }
        }
    }

    // List
    ListView {
        width: parent.width
        height: 360
        clip: true
        model: root.progressions
        spacing: 4
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            id: progDelegate
            required property var modelData
            required property int index
            width: ListView.view.width; height: 66; radius: 10; color: Style.bgWhite
            border.color: {
                var r = modelData.resultat
                if (r === "Réussi")     return Style.successColor
                if (r === "Redoublant") return Style.errorBorder
                return Style.borderLight
            }
            border.width: 1

            RowLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 12

                // Avatar
                Rectangle {
                    width: 38; height: 38; radius: 19
                    color: {
                        var r = modelData.resultat
                        if (r === "Réussi")     return Style.successBg
                        if (r === "Redoublant") return Style.errorBorder
                        return Style.bgPage
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.nom.charAt(0)
                        font.pixelSize: 15; font.bold: true
                        color: {
                            var r = modelData.resultat
                            if (r === "Réussi")     return Style.zitouna
                            if (r === "Redoublant") return Style.errorColor
                            return Style.textSecondary
                        }
                    }
                }

                // Name + niveau
                Column {
                    Layout.preferredWidth: 160; spacing: 2
                    Text { text: modelData.nom + " " + modelData.prenom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary; elide: Text.ElideRight; width: parent.width }
                    Text { text: modelData.niveauActuelNom; font.pixelSize: 11; color: Style.textSecondary; elide: Text.ElideRight; width: parent.width }
                }

                // Average grade badge
                Rectangle {
                    width: 56; height: 28; radius: 8
                    visible: modelData.moyenneAnnuelle !== undefined
                    color: {
                        var m = modelData.moyenneAnnuelle
                        if (m < 0) return Style.secondary
                        return m >= 10 ? Style.successBg : Style.errorBorder
                    }
                    border.color: {
                        var m = modelData.moyenneAnnuelle
                        if (m < 0) return Style.borderLight
                        return m >= 10 ? Style.successColor : Style.errorBorder
                    }
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: { var m = modelData.moyenneAnnuelle; return m < 0 ? "—" : m.toFixed(1) }
                        font.pixelSize: 12; font.bold: true
                        color: {
                            var m = modelData.moyenneAnnuelle
                            if (m < 0) return Style.textTertiary
                            return m >= 10 ? Style.successColor : Style.errorColor
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Réussi button
                Rectangle {
                    width: 80; height: 30; radius: 8
                    color: modelData.resultat === "Réussi" ? Style.successColor : Style.bgPage
                    border.color: modelData.resultat === "Réussi" ? Style.successColor : Style.borderMedium; border.width: 1
                    Text {
                        anchors.centerIn: parent; text: qsTr("Réussi"); font.pixelSize: 12; font.bold: true
                        color: modelData.resultat === "Réussi" ? "white" : Style.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var item = Object.assign({}, modelData)
                            item.resultat = "Réussi"
                            if (item.niveauxSuivants && item.niveauxSuivants.length > 0)
                                item.niveauSuivantId = item.niveauxSuivants[0].id
                            else
                                item.niveauSuivantId = 0
                            root.progressionChanged(index, item)
                        }
                    }
                }

                // Redoublant button
                Rectangle {
                    width: 90; height: 30; radius: 8
                    color: modelData.resultat === "Redoublant" ? Style.errorColor : Style.bgPage
                    border.color: modelData.resultat === "Redoublant" ? Style.errorColor : Style.borderMedium; border.width: 1
                    Text {
                        anchors.centerIn: parent; text: qsTr("Redoublant"); font.pixelSize: 12; font.bold: true
                        color: modelData.resultat === "Redoublant" ? "white" : Style.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var item = Object.assign({}, modelData)
                            item.resultat = "Redoublant"; item.niveauSuivantId = 0
                            root.progressionChanged(index, item)
                        }
                    }
                }

                // Next niveau display / selector
                Rectangle {
                    width: 160; height: 30; radius: 8
                    color: Style.bgPage; border.color: Style.borderLight; border.width: 1
                    visible: modelData.resultat !== "En cours"

                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            text: {
                                var r = modelData.resultat
                                if (r === "Redoublant") return "↩"
                                if (r === "Réussi") return (modelData.niveauSuivantId > 0) ? "→" : "🎓"
                                return ""
                            }
                            font.pixelSize: 13; color: Style.textSecondary
                        }
                        Text {
                            text: {
                                var r = modelData.resultat
                                if (r === "Redoublant") return modelData.niveauActuelNom
                                if (r === "Réussi") {
                                    if (modelData.niveauSuivantId <= 0) return "Diplômé"
                                    for (var i = 0; i < modelData.niveauxSuivants.length; i++) {
                                        if (modelData.niveauxSuivants[i].id === modelData.niveauSuivantId)
                                            return modelData.niveauxSuivants[i].nom
                                    }
                                }
                                return ""
                            }
                            font.pixelSize: 11; font.bold: true
                            color: {
                                var r = modelData.resultat
                                if (r === "Redoublant") return Style.errorColor
                                if (r === "Réussi" && modelData.niveauSuivantId <= 0) return Style.chart3
                                return Style.successColor
                            }
                            elide: Text.ElideRight
                            width: (modelData.resultat === "Réussi" && modelData.niveauxSuivants && modelData.niveauxSuivants.length > 1) ? 100 : 130
                        }
                    }

                    // Dropdown chevron if multiple choices
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.resultat === "Réussi" && modelData.niveauxSuivants && modelData.niveauxSuivants.length > 1
                        text: qsTr("▾"); font.pixelSize: 12; color: Style.textSecondary
                    }

                    // Click to cycle through next niveaux
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: (modelData.resultat === "Réussi" && modelData.niveauxSuivants && modelData.niveauxSuivants.length > 1)
                                     ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: modelData.resultat === "Réussi" && modelData.niveauxSuivants && modelData.niveauxSuivants.length > 1
                        onClicked: {
                            var item = Object.assign({}, modelData)
                            var suivants = item.niveauxSuivants
                            var curIdx = 0
                            for (var i = 0; i < suivants.length; i++) {
                                if (suivants[i].id === item.niveauSuivantId) { curIdx = i; break }
                            }
                            curIdx = (curIdx + 1) % suivants.length
                            item.niveauSuivantId = suivants[curIdx].id
                            root.progressionChanged(index, item)
                        }
                    }
                }
            }
        }
    }
}
