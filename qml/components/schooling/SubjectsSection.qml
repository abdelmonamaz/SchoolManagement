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

    signal matiereCreateRequested(string nom, int semestreNumero, real coefficient)
    signal matiereDeleteRequested(int id)
    signal matiereEditRequested(int id)

    // Semester labels for the toggle buttons
    readonly property bool hasSemestres: setupController.activeSemestres.length >= 2

    Column {
        width: parent.width
        spacing: 18

        Flow {
            width: parent.width
            spacing: 12

            Repeater {
                model: root.matieres

                Rectangle {
                    id: subjectCard
                    implicitWidth: subjectRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: {
                        var n = modelData.semestreNumero
                        if (n === 1) return Style.primaryBg
                        if (n === 2) return Qt.rgba(0.1, 0.5, 0.9, 0.08)
                        return Style.bgPage
                    }
                    border.color: {
                        var n = modelData.semestreNumero
                        if (n === 1) return Style.primary
                        if (n === 2) return Style.infoColor
                        return subjectCardHover.hovered ? Style.borderMedium : Style.borderLight
                    }
                    border.width: modelData.semestreNumero > 0 ? 1.5 : 1

                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color        { ColorAnimation { duration: 150 } }

                    HoverHandler { id: subjectCardHover }

                    RowLayout {
                        id: subjectRow
                        anchors.centerIn: parent
                        spacing: 6

                        // Semester badge (S1 / S2)
                        Rectangle {
                            visible: root.hasSemestres
                            width: 22; height: 18; radius: 5
                            color: {
                                var n = modelData.semestreNumero
                                if (n === 1) return Style.primary
                                if (n === 2) return Style.infoColor
                                return Style.bgTertiary
                            }
                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var n = modelData.semestreNumero
                                    if (n === 1) return "S1"
                                    if (n === 2) return "S2"
                                    return "∞"
                                }
                                font.pixelSize: 8; font.weight: Font.Black
                                color: modelData.semestreNumero > 0 ? "white" : Style.textTertiary
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    var next = modelData.semestreNumero === 1 ? 2 : 1  // S1↔S2
                                    schoolingController.setMatiereSemestre(modelData.id, next)
                                }
                                ToolTip.visible: containsMouse
                                ToolTip.text: qsTr("Cliquer pour basculer entre S1 et S2")
                                ToolTip.delay: 500
                            }
                        }

                        // Coefficient badge (shown only if ≠ 1)
                        Rectangle {
                            visible: modelData.coefficient !== undefined && modelData.coefficient !== 1.0
                            width: coefBadgeText.implicitWidth + 8; height: 18; radius: 5
                            color: Style.bgSecondary
                            border.color: Style.borderLight
                            Text {
                                id: coefBadgeText
                                anchors.centerIn: parent
                                text: "×" + (modelData.coefficient || 1)
                                font.pixelSize: 8; font.weight: Font.Black
                                color: Style.textSecondary
                            }
                        }

                        Text {
                            text: modelData.nom
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }

                        IconButton {
                            iconName: "edit"
                            iconSize: 12
                            hoverColor: Style.primary
                            onClicked: root.matiereEditRequested(modelData.id)
                        }

                        IconButton {
                            iconName: "close"
                            iconSize: 12
                            hoverColor: Style.errorColor
                            onClicked: root.matiereDeleteRequested(modelData.id)
                        }
                    }
                }
            }
        }

        Separator { width: parent.width }

        RowLayout {
            width: parent.width
            spacing: 12

            // Semester selector (only shown when semestres are configured)
            // Semester selector S1 / S2
            Row {
                id: semestreSelector
                visible: root.hasSemestres
                spacing: 4
                property int newSemestre: 1

                Repeater {
                    model: [{ label: "S1", value: 1 }, { label: "S2", value: 2 }]
                    Rectangle {
                        readonly property bool active: semestreSelector.newSemestre === modelData.value
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
                            onClicked: semestreSelector.newSemestre = modelData.value
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 12
                color: Style.bgPage
                border.color: Style.borderLight

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14

                    IconLabel {
                        iconName: "book"
                        iconSize: 16
                        iconColor: Style.textTertiary
                    }

                    TextInput {
                        id: newSubjectInput
                        Layout.fillWidth: true
                        font.pixelSize: 13
                        font.bold: true
                        color: Style.textPrimary
                        cursorVisible: true

                        Text {
                            visible: !parent.text
                            text: qsTr("Nom de la nouvelle matière...")
                            font: parent.font
                            color: Style.textTertiary
                        }

                        HoverHandler { cursorShape: Qt.IBeamCursor }
                    }
                }
            }

            // Coefficient input for new matière
            Rectangle {
                width: 72; height: 44; radius: 12
                color: Style.bgPage
                border.color: newCoefInput.activeFocus ? Style.primary : Style.borderLight
                HoverHandler { cursorShape: Qt.IBeamCursor }
                TextInput {
                    id: newCoefInput
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 13; font.bold: true; color: Style.textPrimary
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

            PrimaryButton {
                text: qsTr("AJOUTER")
                iconName: "plus"
                onClicked: {
                    if (newSubjectInput.text.trim() !== "" && root.selectedNiveauId > 0) {
                        root.matiereCreateRequested(newSubjectInput.text.trim(), semestreSelector.newSemestre, parseFloat(newCoefInput.text) || 1.0)
                        newSubjectInput.text = ""
                        newCoefInput.text = "1"
                    }
                }
            }
        }
    }
}
