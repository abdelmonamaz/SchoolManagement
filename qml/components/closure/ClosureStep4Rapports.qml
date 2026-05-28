import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Clôture Étape 4 : Rapports ────────────────────────────────────────────────
ScrollView {
    id: root
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    required property var progressions

    readonly property int nbPromus: {
        var c = 0
        for (var i = 0; i < progressions.length; i++)
            if (progressions[i].resultat === "Réussi" && progressions[i].niveauSuivantId > 0) c++
        return c
    }
    readonly property int nbDiplomes: {
        var c = 0
        for (var i = 0; i < progressions.length; i++)
            if (progressions[i].resultat === "Réussi" && progressions[i].niveauSuivantId <= 0) c++
        return c
    }
    readonly property int nbRedoublants: {
        var c = 0
        for (var i = 0; i < progressions.length; i++)
            if (progressions[i].resultat === "Redoublant") c++
        return c
    }

    Column {
        width: root.width
        spacing: 16

        Text { text: qsTr("Résumé des actions"); font.pixelSize: 16; font.bold: true; color: Style.textPrimary }

        Grid {
            width: parent.width; columns: 3; spacing: 12

            Repeater {
                model: [
                    { label: qsTr("Promus"),      icon: "↑", value: root.nbPromus,      color: Style.successBg, accent: Style.successColor },
                    { label: qsTr("Redoublants"), icon: "↩", value: root.nbRedoublants, color: Style.errorBg,   accent: Style.errorColor },
                    { label: qsTr("Diplômés"),    icon: "🎓", value: root.nbDiplomes,   color: Style.background, accent: Style.chart3 }
                ]
                delegate: Rectangle {
                    width: (root.width - 24) / 3; height: 80; radius: 12
                    color: modelData.color; border.color: Qt.rgba(0,0,0,0.06); border.width: 1
                    Column {
                        anchors.centerIn: parent; spacing: 6
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "" + modelData.value; font.pixelSize: 26; font.bold: true; color: modelData.accent }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                            Text { text: modelData.icon; font.pixelSize: 13; color: modelData.accent }
                            Text { text: modelData.label; font.pixelSize: 12; font.bold: true; color: modelData.accent }
                        }
                    }
                }
            }
        }

        Text { text: qsTr("Après la clôture"); font.pixelSize: 14; font.bold: true; color: Style.textPrimary }

        Repeater {
            model: [
                qsTr("Une nouvelle année scolaire sera créée"),
                qsTr("Les %1 élèves promus seront inscrits au niveau suivant").arg(root.nbPromus),
                qsTr("Les %1 redoublants seront inscrits au même niveau").arg(root.nbRedoublants),
                qsTr("Les %1 diplômés ne recevront pas de nouvelle inscription").arg(root.nbDiplomes)
            ]
            delegate: Row {
                spacing: 10
                Rectangle { width: 6; height: 6; radius: 3; color: Style.primary; anchors.verticalCenter: parent.verticalCenter }
                Text { text: modelData; font.pixelSize: 13; color: Style.textSecondary; wrapMode: Text.WordWrap; width: root.width - 20 }
            }
        }
    }
}
