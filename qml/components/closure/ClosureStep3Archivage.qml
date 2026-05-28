import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Clôture Étape 3 : Archivage ──────────────────────────────────────────────
ScrollView {
    id: root
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    required property var incomplete

    readonly property var arch: yearClosureController.archivageStats

    Column {
        width: root.width
        spacing: 16

        Text { text: qsTr("Bilan des séances"); font.pixelSize: 14; font.bold: true; color: Style.textPrimary }

        Grid {
            width: parent.width; columns: 3; spacing: 10
            Repeater {
                model: [
                    { label: qsTr("Cours prévus"),  value: root.arch ? root.arch.coursTotal   : 0, accent: Style.bgWhite,      bg: Style.chart3 },
                    { label: qsTr("Cours validés"), value: root.arch ? root.arch.coursValides : 0, accent: Style.successColor, bg: Style.successBg },
                    { label: qsTr("Examens"),        value: root.arch ? root.arch.examensTotal : 0, accent: Style.chart3,       bg: Style.background }
                ]
                delegate: Rectangle {
                    width: (root.width - 20) / 3; height: 64; radius: 10; color: modelData.bg
                    border.color: Qt.rgba(0,0,0,0.05); border.width: 1
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "" + modelData.value; font.pixelSize: 22; font.bold: true; color: modelData.accent }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; font.pixelSize: 11; color: modelData.accent }
                    }
                }
            }
        }

        // Global presence rate
        Rectangle {
            width: parent.width; height: presRow.implicitHeight + 20; radius: 10
            color: Style.background; border.color: Style.borderLight; border.width: 1
            Row {
                id: presRow
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 14 }
                spacing: 12
                Text { text: qsTr("📊"); font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                Text { text: qsTr("Taux de présence global :"); font.pixelSize: 13; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: (root.arch ? root.arch.tauxPresenceGlobal : 0) + " %"
                    font.pixelSize: 15; font.bold: true
                    color: {
                        var r = root.arch ? root.arch.tauxPresenceGlobal : 0
                        return r >= 75 ? Style.successColor : r >= 50 ? Style.warningColor : Style.errorColor
                    }
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: qsTr("| Notes examens saisies : ") + (root.arch ? root.arch.examensAvecNotes : 0) + "/" + (root.arch ? root.arch.examensTotal : 0)
                    font.pixelSize: 12; color: Style.textTertiary; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Per-matière breakdown
        Text {
            text: qsTr("Détail par matière"); font.pixelSize: 14; font.bold: true; color: Style.textPrimary
            visible: root.arch && root.arch.matieres && root.arch.matieres.length > 0
        }

        Repeater {
            model: root.arch ? root.arch.matieres : []
            delegate: Rectangle {
                width: root.width; height: matCol.implicitHeight + 20; radius: 12
                color: Style.bgWhite; border.color: Style.borderLight; border.width: 1

                Column {
                    id: matCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 8

                    Row {
                        width: parent.width; spacing: 8
                        Text { text: qsTr("📚"); font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.nom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: qsTr("·"); font.pixelSize: 13; color: Style.textTertiary; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.niveauNom; font.pixelSize: 11; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1 }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Présence : ") + modelData.presenceRate + "%"
                            font.pixelSize: 11; font.bold: true
                            color: modelData.presenceRate >= 75 ? Style.successColor : modelData.presenceRate >= 50 ? Style.warningColor : Style.errorColor
                        }
                    }

                    Row {
                        spacing: 8
                        Text { text: qsTr("Cours : ") + modelData.coursValides + "/" + modelData.coursTotal + " validés"; font.pixelSize: 11; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                        Rectangle {
                            width: 120; height: 6; radius: 3; color: Style.bgTertiary; anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                width: modelData.coursTotal > 0 ? parent.width * modelData.coursValides / modelData.coursTotal : 0
                                height: parent.height; radius: parent.radius; color: Style.successColor
                            }
                        }
                    }

                    Repeater {
                        model: modelData.examens
                        delegate: Row {
                            spacing: 6
                            Text { text: modelData.notesEntrees ? "✅" : "⚠️"; font.pixelSize: 11 }
                            Text {
                                text: modelData.titre + " (" + modelData.date + ") — "
                                      + (modelData.notesEntrees
                                         ? qsTr("Notes saisies (%1/%2)").arg(modelData.notesSaisies).arg(modelData.totalPart)
                                         : modelData.totalPart > 0
                                           ? qsTr("Notes incomplètes (%1/%2)").arg(modelData.notesSaisies).arg(modelData.totalPart)
                                           : qsTr("Aucune participation enregistrée"))
                                font.pixelSize: 11
                                color: modelData.notesEntrees ? Style.successColor : Style.warningColor
                            }
                        }
                    }
                }
            }
        }

        // Incomplete sessions
        Rectangle {
            width: parent.width
            visible: root.incomplete && root.incomplete.length > 0
            height: visible ? incompl3Col.implicitHeight + 24 : 0
            radius: 12; color: Style.warningBg; border.color: Style.chart1; border.width: 1

            Column {
                id: incompl3Col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 8
                Row {
                    spacing: 8
                    Text { text: qsTr("⚠️"); font.pixelSize: 14 }
                    Text {
                        text: qsTr("%1 séance(s) sans enregistrement de présence").arg(root.incomplete ? root.incomplete.length : 0)
                        font.pixelSize: 13; font.bold: true; color: Style.warningColor
                    }
                }
                Repeater {
                    model: root.incomplete
                    delegate: Row {
                        spacing: 8
                        Text { text: qsTr("•"); font.pixelSize: 12; color: Style.warningColor }
                        Text { text: qsTr("[") + modelData.type + "] " + modelData.titre + " — " + modelData.date; font.pixelSize: 12; color: Style.warningColor }
                    }
                }
            }
        }
    }
}
