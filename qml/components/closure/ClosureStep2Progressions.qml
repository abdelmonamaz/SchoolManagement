import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Clôture Étape 2 : Progressions par élève ──────────────────────────────────
// Le composant gère son état en interne via un ListModel.
// Seuls `resultat` et `niveauSuivantId` sont mutables ; toutes les autres données
// statiques sont lues depuis `progressions[index]` (la prop initiale).
Column {
    id: root
    spacing: 8

    required property var progressions   // données initiales (lecture seule après chargement)

    // Exposés en lecture au parent
    readonly property int  nbDecides:  _nbDecides
    readonly property bool step2Valid: _step2Valid

    property int  _nbDecides:  0
    property bool _step2Valid: false

    // ── Modèle interne (uniquement les champs mutables) ──────────────────────
    ListModel { id: internalModel }

    onProgressionsChanged: {
        internalModel.clear()
        for (var i = 0; i < progressions.length; i++) {
            internalModel.append({
                resultat:        progressions[i].resultat,
                niveauSuivantId: progressions[i].niveauSuivantId
            })
        }
        _recalcValid()
    }

    function _recalcValid() {
        var c = 0
        for (var i = 0; i < internalModel.count; i++) {
            if (internalModel.get(i).resultat !== "En cours") c++
        }
        _nbDecides  = c
        _step2Valid = (internalModel.count > 0 && c === internalModel.count)
    }

    // Appelé par le parent pour obtenir le tableau final avant clôture
    function getProgressions() {
        var arr = []
        for (var i = 0; i < internalModel.count; i++) {
            var src = root.progressions[i]
            var m   = internalModel.get(i)
            arr.push({
                inscriptionId:   src.inscriptionId,
                eleveId:         src.eleveId,
                nom:             src.nom,
                prenom:          src.prenom,
                categorie:       src.categorie,
                niveauActuelId:  src.niveauActuelId,
                niveauActuelNom: src.niveauActuelNom,
                resultat:        m.resultat,
                niveauxSuivants: src.niveauxSuivants,
                niveauSuivantId: m.niveauSuivantId,
                moyenneAnnuelle: src.moyenneAnnuelle
            })
        }
        return arr
    }

    // ── Summary bar ───────────────────────────────────────────────────────────
    Rectangle {
        width: parent.width; height: 40; radius: 10
        color: root.step2Valid ? Style.successBg : Style.warningBg
        border.color: root.step2Valid ? Style.successColor : Style.warningBorder; border.width: 1

        Row {
            anchors.centerIn: parent; spacing: 8
            Text { text: root.step2Valid ? "✅" : "⏳"; font.pixelSize: 14 }
            Text {
                text: qsTr("%1 / %2 résultats décidés").arg(root.nbDecides).arg(internalModel.count)
                      + (root.step2Valid ? qsTr(" — Prêt à continuer") : qsTr(" — Décidez tous les résultats"))
                font.pixelSize: 13; font.bold: true
                color: root.step2Valid ? Style.zitouna : Style.warningColor
            }
        }
    }

    // ── Liste ─────────────────────────────────────────────────────────────────
    ListView {
        id: listView
        width: parent.width
        height: 360
        clip: true
        model: internalModel   // ListModel → setProperty() ne remet pas contentY à zéro
        spacing: 4
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            id: progDelegate
            required property int    index
            // Rôles mutables déclarés en `required property` → QML les met à jour
            // automatiquement à chaque internalModel.setProperty()
            required property string resultat
            required property int    niveauSuivantId

            // Données statiques depuis le tableau original (non stockées dans le ListModel)
            readonly property var    pOrig:           root.progressions[index] ?? {}
            readonly property string pNom:            pOrig.nom             ?? ""
            readonly property string pPrenom:         pOrig.prenom          ?? ""
            readonly property string pNiveauActuelNom:pOrig.niveauActuelNom  ?? ""
            readonly property double pMoyenne:        pOrig.moyenneAnnuelle  ?? -1.0
            readonly property var    pNiveauxSuivants:pOrig.niveauxSuivants  ?? []

            width: ListView.view.width; height: 66; radius: 10; color: Style.bgWhite
            border.color: {
                if (resultat === "Réussi")     return Style.successColor
                if (resultat === "Redoublant") return Style.errorBorder
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
                        if (progDelegate.resultat === "Réussi")     return Style.successBg
                        if (progDelegate.resultat === "Redoublant") return Style.errorBorder
                        return Style.bgPage
                    }
                    Text {
                        anchors.centerIn: parent
                        text: progDelegate.pNom.charAt(0)
                        font.pixelSize: 15; font.bold: true
                        color: {
                            if (progDelegate.resultat === "Réussi")     return Style.zitouna
                            if (progDelegate.resultat === "Redoublant") return Style.errorColor
                            return Style.textSecondary
                        }
                    }
                }

                // Nom + niveau actuel
                Column {
                    Layout.preferredWidth: 160; spacing: 2
                    Text { text: progDelegate.pNom + " " + progDelegate.pPrenom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary; elide: Text.ElideRight; width: parent.width }
                    Text { text: progDelegate.pNiveauActuelNom; font.pixelSize: 11; color: Style.textSecondary; elide: Text.ElideRight; width: parent.width }
                }

                // Badge moyenne
                Rectangle {
                    width: 56; height: 28; radius: 8
                    visible: progDelegate.pMoyenne !== undefined
                    color: {
                        var m = progDelegate.pMoyenne
                        if (m < 0) return Style.secondary
                        return m >= 10 ? Style.successBg : Style.errorBorder
                    }
                    border.color: {
                        var m = progDelegate.pMoyenne
                        if (m < 0) return Style.borderLight
                        return m >= 10 ? Style.successColor : Style.errorBorder
                    }
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: { var m = progDelegate.pMoyenne; return m < 0 ? "—" : m.toFixed(1) }
                        font.pixelSize: 12; font.bold: true
                        color: {
                            var m = progDelegate.pMoyenne
                            if (m < 0) return Style.textTertiary
                            return m >= 10 ? Style.successColor : Style.errorColor
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Bouton Réussi
                Rectangle {
                    width: 80; height: 30; radius: 8
                    color: progDelegate.resultat === "Réussi" ? Style.successColor : Style.bgPage
                    border.color: progDelegate.resultat === "Réussi" ? Style.successColor : Style.borderMedium; border.width: 1
                    Text {
                        anchors.centerIn: parent; text: qsTr("Réussi"); font.pixelSize: 12; font.bold: true
                        color: progDelegate.resultat === "Réussi" ? "white" : Style.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var suivants = progDelegate.pNiveauxSuivants
                            internalModel.setProperty(progDelegate.index, "resultat", "Réussi")
                            internalModel.setProperty(progDelegate.index, "niveauSuivantId",
                                (suivants && suivants.length > 0) ? suivants[0].id : 0)
                            root._recalcValid()
                        }
                    }
                }

                // Bouton Redoublant
                Rectangle {
                    width: 90; height: 30; radius: 8
                    color: progDelegate.resultat === "Redoublant" ? Style.errorColor : Style.bgPage
                    border.color: progDelegate.resultat === "Redoublant" ? Style.errorColor : Style.borderMedium; border.width: 1
                    Text {
                        anchors.centerIn: parent; text: qsTr("Redoublant"); font.pixelSize: 12; font.bold: true
                        color: progDelegate.resultat === "Redoublant" ? "white" : Style.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            internalModel.setProperty(progDelegate.index, "resultat", "Redoublant")
                            internalModel.setProperty(progDelegate.index, "niveauSuivantId", 0)
                            root._recalcValid()
                        }
                    }
                }

                // Affichage / sélecteur du niveau suivant
                Rectangle {
                    width: 160; height: 30; radius: 8
                    color: Style.bgPage; border.color: Style.borderLight; border.width: 1
                    visible: progDelegate.resultat !== "En cours"

                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            text: {
                                var r = progDelegate.resultat
                                if (r === "Redoublant") return "↩"
                                if (r === "Réussi") return (progDelegate.niveauSuivantId > 0) ? "→" : "🎓"
                                return ""
                            }
                            font.pixelSize: 13; color: Style.textSecondary
                        }
                        Text {
                            text: {
                                var r = progDelegate.resultat
                                if (r === "Redoublant") return progDelegate.pNiveauActuelNom
                                if (r === "Réussi") {
                                    if (progDelegate.niveauSuivantId <= 0) return "Diplômé"
                                    var suivants = progDelegate.pNiveauxSuivants
                                    for (var i = 0; i < suivants.length; i++) {
                                        if (suivants[i].id === progDelegate.niveauSuivantId)
                                            return suivants[i].nom
                                    }
                                }
                                return ""
                            }
                            font.pixelSize: 11; font.bold: true
                            color: {
                                var r = progDelegate.resultat
                                if (r === "Redoublant") return Style.errorColor
                                if (r === "Réussi" && progDelegate.niveauSuivantId <= 0) return Style.chart3
                                return Style.successColor
                            }
                            elide: Text.ElideRight
                            width: (progDelegate.resultat === "Réussi" && progDelegate.pNiveauxSuivants && progDelegate.pNiveauxSuivants.length > 1) ? 100 : 130
                        }
                    }

                    // Chevron si plusieurs choix
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: progDelegate.resultat === "Réussi" && progDelegate.pNiveauxSuivants && progDelegate.pNiveauxSuivants.length > 1
                        text: qsTr("▾"); font.pixelSize: 12; color: Style.textSecondary
                    }

                    // Clic pour cycler parmi les niveaux suivants
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: (progDelegate.resultat === "Réussi" && progDelegate.pNiveauxSuivants && progDelegate.pNiveauxSuivants.length > 1)
                                     ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: progDelegate.resultat === "Réussi" && progDelegate.pNiveauxSuivants && progDelegate.pNiveauxSuivants.length > 1
                        onClicked: {
                            var suivants = progDelegate.pNiveauxSuivants
                            var curIdx = 0
                            for (var i = 0; i < suivants.length; i++) {
                                if (suivants[i].id === progDelegate.niveauSuivantId) { curIdx = i; break }
                            }
                            curIdx = (curIdx + 1) % suivants.length
                            internalModel.setProperty(progDelegate.index, "niveauSuivantId", suivants[curIdx].id)
                        }
                    }
                }
            }
        }
    }
}
