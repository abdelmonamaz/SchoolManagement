import QtQuick
import QtQuick.Layouts
import UI.Components

// Épreuve picker shown in exam session form.
// Displays the list of defined épreuves for the selected matière,
// marking the ones already scheduled for the selected classe.
Column {
    id: root
    spacing: 8

    required property int    formMatiereId
    required property int    formClasseId
    required property string formTitre
    required property bool   showAllEpreuves

    signal titreSelected(string titre)
    signal showAllChanged(bool value)

    function isTitreScheduled(titre) {
        var titles = examsController.scheduledExamTitles
        for (var i = 0; i < titles.length; i++)
            if (titles[i] === titre) return true
        return false
    }

    // ── Section header ──────────────────────────────────────────────
    RowLayout {
        width: parent.width

        SectionLabel { Layout.fillWidth: true; text: qsTr("ÉPREUVE À PLANIFIER") }

        RowLayout {
            spacing: 6
            visible: root.formMatiereId >= 0 && root.formClasseId >= 0

            Rectangle {
                width: 16; height: 16; radius: 4
                color: root.showAllEpreuves ? Style.primary : "transparent"
                border.color: root.showAllEpreuves ? Style.primary : Style.borderMedium
                border.width: 1.5
                Text {
                    anchors.centerIn: parent; text: qsTr("✓")
                    font.pixelSize: 9; font.weight: Font.Bold; color: Style.background
                    visible: root.showAllEpreuves
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.showAllChanged(!root.showAllEpreuves)
                }
            }
            Text {
                text: qsTr("Inclure les épreuves déjà planifiées")
                font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary
            }
        }
    }

    // ── Placeholder (matière ou classe non sélectionnée) ────────────
    Rectangle {
        width: parent.width; height: 44; radius: 12
        color: Style.bgPage; border.color: Style.borderLight
        visible: root.formMatiereId < 0 || root.formClasseId < 0

        Text {
            anchors.centerIn: parent
            text: root.formMatiereId < 0 && root.formClasseId < 0
                  ? "Sélectionnez une classe et une matière pour voir les épreuves"
                  : root.formClasseId < 0
                  ? "Sélectionnez une classe pour voir les épreuves"
                  : "Sélectionnez une matière pour voir les épreuves"
            font.pixelSize: 11; font.italic: true; color: Style.textTertiary
            width: parent.width - 24; horizontalAlignment: Text.AlignHCenter
        }
    }

    // ── Épreuves (matière + classe sélectionnées) ────────────────────
    Column {
        width: parent.width; spacing: 8
        visible: root.formMatiereId >= 0 && root.formClasseId >= 0

        // No épreuves defined
        Rectangle {
            width: parent.width; height: 44; radius: 12
            color: Style.bgPage; border.color: Style.borderLight
            visible: schoolingController.matiereExamens.length === 0
            Text {
                anchors.centerIn: parent
                text: qsTr("Aucune épreuve définie pour cette matière")
                font.pixelSize: 11; font.italic: true; color: Style.textTertiary
                width: parent.width - 24; horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        // Épreuve tiles
        Flow {
            width: parent.width; spacing: 8
            visible: schoolingController.matiereExamens.length > 0

            Repeater {
                model: schoolingController.matiereExamens

                delegate: Item {
                    property bool isDone:     root.isTitreScheduled(modelData.titre)
                    property bool isSelected: root.formTitre === modelData.titre
                    visible: root.showAllEpreuves || !isDone
                    width:  visible ? epreuveRow.implicitWidth + 24 : 0
                    height: visible ? 40 : 0

                    Rectangle {
                        anchors.fill: parent; radius: 12
                        color: isSelected ? Style.primary
                             : isDone     ? Style.secondary
                             : epreuveMa.containsMouse ? Style.primaryBg : Style.bgPage
                        border.color: isSelected ? Style.primary
                                    : isDone     ? Style.borderLight
                                    : epreuveMa.containsMouse ? Style.primary : Style.borderLight
                        Behavior on color      { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: epreuveRow
                            anchors.centerIn: parent; spacing: 6
                            Text {
                                text: isDone ? "✓ " + modelData.titre : modelData.titre
                                font.pixelSize: 12; font.weight: Font.Bold
                                color: isSelected ? Style.background
                                     : isDone     ? Style.textTertiary
                                     : epreuveMa.containsMouse ? Style.primary : Style.textPrimary
                            }
                        }

                        MouseArea {
                            id: epreuveMa
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: isDone && !root.showAllEpreuves
                                         ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: root.titreSelected(modelData.titre)
                        }
                    }
                }
            }
        }
    }
}
