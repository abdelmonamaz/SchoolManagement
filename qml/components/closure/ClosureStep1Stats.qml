import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Clôture Étape 1 : Vue d'ensemble ─────────────────────────────────────────
ScrollView {
    id: root
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    required property var stats
    required property var incomplete

    Column {
        width: root.width
        spacing: 16

        // Warning critical
        Rectangle {
            width: parent.width
            height: warnCol.implicitHeight + 32
            radius: 12; color: Style.warningBg
            border.color: Style.warningColor; border.width: 1

            Column {
                id: warnCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 10

                Row {
                    spacing: 10
                    Text { text: qsTr("⚠️"); font.pixelSize: 16 }
                    Text { text: qsTr("Attention : Action Critique"); font.pixelSize: 15; font.bold: true; color: Style.warningColor }
                }
                Text {
                    width: parent.width
                    text: qsTr("La clôture d'année scolaire est une opération <b>irréversible</b> qui va :")
                    textFormat: Text.RichText; font.pixelSize: 13; color: Style.warningColor; wrapMode: Text.WordWrap
                }
                Repeater {
                    model: [
                        qsTr("Archiver définitivement toutes les notes et bulletins de l'année %1").arg(root.stats ? root.stats.anneeActiveLibelle : ""),
                        qsTr("Verrouiller les modifications sur les données académiques de cette année"),
                        qsTr("Faire passer automatiquement les étudiants qui ont réussi au niveau supérieur"),
                        qsTr("Marquer les étudiants de niveau terminal comme diplômés")
                    ]
                    delegate: Row {
                        spacing: 8
                        Text { text: qsTr("•"); font.pixelSize: 13; color: Style.warningColor }
                        Text { width: warnCol.width - 16; text: modelData; font.pixelSize: 13; color: Style.warningColor; wrapMode: Text.WordWrap }
                    }
                }
            }
        }

        // Stat cards 2x2
        Grid {
            width: parent.width; columns: 2; spacing: 12

            Repeater {
                model: [
                    { label: qsTr("Étudiants Inscrits"), sub: qsTr("Année ") + (root.stats ? root.stats.anneeActiveLibelle : ""),
                      value: root.stats ? root.stats.studentsInscrits : 0, color: Style.successBg, accent: Style.successColor },
                    { label: qsTr("Taux de Réussite"), sub: qsTr("Global tous niveaux"),
                      value: (root.stats ? root.stats.tauxReussite : 0) + "%", color: Style.bgWhite, accent: Style.chart3 },
                    { label: qsTr("Diplômés"), sub: qsTr("Niveau terminal complété"),
                      value: root.stats ? root.stats.diplomes : 0, color: Style.background, accent: Style.chart3 },
                    { label: qsTr("Redoublants"), sub: qsTr("Tous niveaux confondus"),
                      value: root.stats ? root.stats.redoublants : 0, color: Style.errorBg, accent: Style.errorColor }
                ]
                delegate: Rectangle {
                    width: (root.width - 12) / 2; height: 90; radius: 12
                    color: modelData.color; border.color: Qt.rgba(0,0,0,0.05); border.width: 1
                    Row {
                        anchors { fill: parent; margins: 16 }
                        spacing: 12
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 4
                            Text { text: "" + modelData.value; font.pixelSize: 28; font.bold: true; color: modelData.accent }
                            Text { text: modelData.label; font.pixelSize: 13; font.bold: true; color: modelData.accent }
                            Text { text: modelData.sub; font.pixelSize: 11; color: Qt.darker(modelData.accent, 1.2) }
                        }
                    }
                }
            }
        }

        // Incomplete sessions warning
        Rectangle {
            width: parent.width
            visible: root.incomplete && root.incomplete.length > 0
            height: visible ? incomplCol.implicitHeight + 24 : 0
            radius: 12; color: Style.warningBg; border.color: Style.chart1; border.width: 1

            Column {
                id: incomplCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 6
                Row {
                    spacing: 8
                    Text { text: qsTr("⚠️"); font.pixelSize: 14 }
                    Text {
                        text: (root.incomplete ? root.incomplete.length : 0) + " séance(s) non validée(s)"
                        font.pixelSize: 13; font.bold: true; color: Style.warningColor
                    }
                }
                Text {
                    width: parent.width
                    text: qsTr("Ces séances passées n'ont pas d'enregistrement de présence. Vous pouvez continuer, elles seront archivées telles quelles.")
                    font.pixelSize: 12; color: Style.warningColor; wrapMode: Text.WordWrap
                }
            }
        }

        // Backup recommendation
        Rectangle {
            width: parent.width; height: backupRow.implicitHeight + 24
            radius: 12; color: Style.chart3; border.color: Style.chart3; border.width: 1
            Row {
                id: backupRow
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                spacing: 10
                Text { text: qsTr("🛡️"); font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    width: parent.width - 30
                    text: qsTr("Sauvegarde recommandée : Avant de procéder à la clôture, assurez-vous d'avoir effectué une sauvegarde complète de la base de données dans l'onglet \"Sauvegarde & Data\" des Paramètres.")
                    font.pixelSize: 12; color: Style.chart3; wrapMode: Text.WordWrap
                }
            }
        }
    }
}
