import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

AppCard {
    id: root
    title: qsTr("Matières enseignées : ") + selectedNiveauNom
    subtitle: qsTr("Ajoutez ou supprimez des cours pour ce niveau")

    required property var matieres
    required property string selectedNiveauNom
    required property int selectedNiveauId

    signal matiereCreateRequested(string nom, int semestreNumero, real coefficient, int nombreSeances, int dureeSeanceMinutes)
    signal matiereDeleteRequested(var ids)
    signal matiereEditRequested(var group)

    readonly property bool hasSemestres: setupController.activeSemestres.length >= 2

    // Regroupe les matières par nom (insensible à la casse) :
    // deux enregistrements portant le même nom → un seul groupe avec [S1, S2].
    readonly property var groupedMatieres: {
        var groups = {}
        var orderedKeys = []
        for (var i = 0; i < root.matieres.length; i++) {
            var m = root.matieres[i]
            var key = m.nom.toLowerCase().trim()
            if (!groups[key]) {
                groups[key] = {
                    nom: m.nom,
                    ids: [],
                    semestres: [],
                    coefficient: m.coefficient,
                    nombreSeances: m.nombreSeances,
                    dureeSeanceMinutes: m.dureeSeanceMinutes,
                    niveauId: m.niveauId,
                    primaryId: m.id
                }
                orderedKeys.push(key)
            }
            groups[key].ids.push(m.id)
            groups[key].semestres.push(m.semestreNumero)
        }
        var result = []
        for (var j = 0; j < orderedKeys.length; j++)
            result.push(groups[orderedKeys[j]])
        return result
    }

    Column {
        width: parent.width
        spacing: 18

        // ─── Cartes des matières ───
        Flow {
            width: parent.width
            spacing: 12

            Repeater {
                model: root.groupedMatieres

                Rectangle {
                    id: subjectCard

                    // Référence au groupe (évite la collision de nom avec les
                    // Repeater imbriqués qui redéfinissent « modelData »).
                    property var group: modelData

                    implicitWidth: subjectRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: {
                        var sems = subjectCard.group.semestres
                        if (sems.length >= 2) return Qt.rgba(0.15, 0.55, 0.25, 0.07)
                        if (sems[0] === 1) return Style.primaryBg
                        if (sems[0] === 2) return Qt.rgba(0.1, 0.5, 0.9, 0.08)
                        return Style.bgPage
                    }
                    border.color: {
                        var sems = subjectCard.group.semestres
                        if (sems.length >= 2) return Qt.rgba(0.15, 0.55, 0.25, 0.55)
                        if (sems[0] === 1) return Style.primary
                        if (sems[0] === 2) return Style.infoColor
                        return subjectCardHover.hovered ? Style.borderMedium : Style.borderLight
                    }
                    border.width: subjectCard.group.semestres.length > 0 ? 1.5 : 1

                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color        { ColorAnimation { duration: 150 } }

                    HoverHandler { id: subjectCardHover }

                    RowLayout {
                        id: subjectRow
                        anchors.centerIn: parent
                        spacing: 4

                        // Badges S1 / S2 (un badge par semestre du groupe)
                        Row {
                            spacing: 3
                            visible: root.hasSemestres

                            Repeater {
                                model: subjectCard.group.semestres

                                Rectangle {
                                    width: 22; height: 18; radius: 5
                                    color: modelData === 1 ? Style.primary
                                         : modelData === 2 ? Style.infoColor
                                         : Style.bgTertiary
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData === 1 ? "S1"
                                            : modelData === 2 ? "S2" : "∞"
                                        font.pixelSize: 8; font.weight: Font.Black
                                        color: modelData > 0 ? "white" : Style.textTertiary
                                    }
                                }
                            }
                        }

                        // Badge coefficient (affiché seulement si ≠ 1)
                        Rectangle {
                            visible: subjectCard.group.coefficient !== undefined && subjectCard.group.coefficient !== 1.0
                            width: coefBadgeText.implicitWidth + 8; height: 18; radius: 5
                            color: Style.bgSecondary
                            border.color: Style.borderLight
                            Text {
                                id: coefBadgeText
                                anchors.centerIn: parent
                                text: "×" + (subjectCard.group.coefficient || 1)
                                font.pixelSize: 8; font.weight: Font.Black
                                color: Style.textSecondary
                            }
                        }

                        Text {
                            text: subjectCard.group.nom
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }

                        IconButton {
                            iconName: "edit"
                            iconSize: 12
                            hoverColor: Style.primary
                            onClicked: root.matiereEditRequested(subjectCard.group)
                        }

                        IconButton {
                            iconName: "close"
                            iconSize: 12
                            hoverColor: Style.errorColor
                            onClicked: root.matiereDeleteRequested(subjectCard.group.ids)
                        }
                    }
                }
            }
        }

        Separator { width: parent.width }

        // ─── Formulaire d'ajout ───
        Column {
            width: parent.width
            spacing: 8

            // Ligne principale : sélecteur S1/S2 + nom + bouton
            RowLayout {
                width: parent.width
                spacing: 12

                // Sélecteur de semestre(s) — multi-sélection possible
                Row {
                    id: semestreSelector
                    visible: root.hasSemestres
                    spacing: 4
                    property var newSemestres: [1, 2]

                    Repeater {
                        model: [{ label: "S1", value: 1 }, { label: "S2", value: 2 }]

                        Rectangle {
                            readonly property bool active: semestreSelector.newSemestres.indexOf(modelData.value) >= 0
                            width: 40; height: 44; radius: 10
                            color: active ? (modelData.value === 1 ? Style.primaryBg : Qt.rgba(0.1, 0.5, 0.9, 0.08)) : Style.bgPage
                            border.color: active ? (modelData.value === 1 ? Style.primary : Style.infoColor) : Style.borderLight
                            border.width: active ? 1.5 : 1
                            Behavior on color        { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 12; font.weight: Font.Black
                                color: active ? (modelData.value === 1 ? Style.primary : Style.infoColor) : Style.textTertiary
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var arr = semestreSelector.newSemestres.slice()
                                    var idx = arr.indexOf(modelData.value)
                                    if (idx >= 0) {
                                        // Au moins un semestre doit rester sélectionné
                                        if (arr.length > 1) { arr.splice(idx, 1); semestreSelector.newSemestres = arr }
                                    } else {
                                        arr.push(modelData.value); arr.sort()
                                        semestreSelector.newSemestres = arr
                                    }
                                }
                            }
                        }
                    }
                }

                // Champ nom de la matière
                Rectangle {
                    Layout.fillWidth: true
                    height: 44; radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14

                        IconLabel { iconName: "book"; iconSize: 16; iconColor: Style.textTertiary }

                        TextInput {
                            id: newSubjectInput
                            Layout.fillWidth: true
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                            cursorVisible: true

                            Text {
                                visible: !parent.text
                                text: qsTr("Nom de la nouvelle matière...")
                                font: parent.font; color: Style.textTertiary
                            }
                            HoverHandler { cursorShape: Qt.IBeamCursor }
                        }
                    }
                }

                PrimaryButton {
                    text: qsTr("AJOUTER")
                    iconName: "plus"
                    onClicked: {
                        var nom = newSubjectInput.text.trim()
                        if (nom !== "" && root.selectedNiveauId > 0) {
                            var semestres = root.hasSemestres ? semestreSelector.newSemestres : [0]
                            var coef     = parseFloat(newCoefInput.text)   || 1.0
                            var seances  = parseInt(newSeancesInput.text)  || 0
                            var duree    = parseInt(newDureeInput.text)    || 60
                            for (var i = 0; i < semestres.length; i++)
                                root.matiereCreateRequested(nom, semestres[i], coef, seances, duree)
                            newSubjectInput.text  = ""
                            newCoefInput.text     = ""
                            newSeancesInput.text  = ""
                            newDureeInput.text    = ""
                        }
                    }
                }
            }

            // Ligne secondaire : Séances / Durée / Coefficient
            RowLayout {
                width: parent.width
                spacing: 12

                // Décalage pour aligner sous le champ nom
                // (largeur du sélecteur S1/S2 + spacing = 40+40+4+12 = 96)
                Item { width: root.hasSemestres ? 96 : 0; height: 1 }

                // Séances / an
                Rectangle {
                    Layout.preferredWidth: 100; height: 36; radius: 10
                    color: Style.bgPage
                    border.color: newSeancesInput.activeFocus ? Style.primary : Style.borderLight
                    HoverHandler { cursorShape: Qt.IBeamCursor }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 6
                        TextInput {
                            id: newSeancesInput
                            Layout.fillWidth: true
                            font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                            selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator { bottom: 0; top: 999 }
                            Text {
                                visible: !parent.text
                                text: qsTr("Séances")
                                font: parent.font; color: Style.textTertiary
                            }
                        }
                    }
                }

                // Durée (min)
                Rectangle {
                    Layout.preferredWidth: 100; height: 36; radius: 10
                    color: Style.bgPage
                    border.color: newDureeInput.activeFocus ? Style.primary : Style.borderLight
                    HoverHandler { cursorShape: Qt.IBeamCursor }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 6
                        TextInput {
                            id: newDureeInput
                            Layout.fillWidth: true
                            font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                            selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator { bottom: 1; top: 480 }
                            Text {
                                visible: !parent.text
                                text: qsTr("Durée (min)")
                                font: parent.font; color: Style.textTertiary
                            }
                        }
                    }
                }

                // Coefficient
                Rectangle {
                    Layout.preferredWidth: 88; height: 36; radius: 10
                    color: Style.bgPage
                    border.color: newCoefInput.activeFocus ? Style.primary : Style.borderLight
                    HoverHandler { cursorShape: Qt.IBeamCursor }
                    TextInput {
                        id: newCoefInput
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                        selectByMouse: true; inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: 0.1; top: 99.9; decimals: 2; notation: DoubleValidator.StandardNotation }
                        Text {
                            visible: !parent.text
                            text: qsTr("Coef.")
                            font: parent.font; color: Style.textTertiary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
