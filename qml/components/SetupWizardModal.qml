import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ═══════════════════════════════════════════════════════════════════
//  Assistant de Mise en Marche — 3 étapes
//  Étape 1 : Identité de l'Association + Exercice Comptable
//  Étape 2 : Catalogue des Niveaux
//  Étape 3 : Première Année Scolaire + Tarifs
// ═══════════════════════════════════════════════════════════════════
Popup {
    id: root
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 700
    height: Math.min(parent.height * 0.95, 820)
    modal: true
    padding: 0
    closePolicy: Popup.NoAutoClose

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int currentStep: 1
    readonly property int totalSteps: 3

    Overlay.modal: Rectangle { color: Qt.alpha(Style.foreground, 0.80) }
    background: Rectangle { radius: 32; color: Style.bgWhite }

    onOpened: {
        setupController.loadNiveaux()
    }

    onCurrentStepChanged: {
        if (currentStep === 3) {
            step3._autoFill = true
            step3._autoValue = ""
            step3._updateLibelleAuto()
        }
    }

    Connections {
        target: setupController
        function onSetupCompleted() { root.close() }
        function onOperationFailed(error) {
            console.warn("[SetupWizard] operation failed:", error)
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ─── Header ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 108
            color: Style.sandBg; radius: 32

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 48; color: Style.sandBg }
            Separator  { anchors.bottom: parent.bottom; width: parent.width }

            RowLayout {
                anchors.fill: parent; anchors.margins: 28; spacing: 16

                Column {
                    Layout.fillWidth: true; spacing: 5
                    Text {
                        text: root.currentStep === 1 ? qsTr("Bienvenue — Configuration initiale")
                            : root.currentStep === 2 ? qsTr("Catalogue des Niveaux")
                            : qsTr("Première Année Scolaire")
                        font.pixelSize: 20; font.weight: Font.Black; color: Style.primary
                    }
                    Text {
                        text: root.currentStep === 1 ? qsTr("ÉTAPE 1 / 3 — IDENTITÉ DE L'ASSOCIATION")
                            : root.currentStep === 2 ? qsTr("ÉTAPE 2 / 3 — CRÉEZ VOTRE CATALOGUE DE NIVEAUX")
                            : qsTr("ÉTAPE 3 / 3 — PARAMÈTRES DE L'ANNÉE EN COURS")
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: Style.textTertiary; font.letterSpacing: 1
                    }
                }

                Row {
                    spacing: 8
                    Repeater {
                        model: root.totalSteps
                        Rectangle {
                            width: root.currentStep > index ? 32 : (root.currentStep === index + 1 ? 24 : 12)
                            height: 8; radius: 4
                            color: root.currentStep > index   ? Style.successColor
                                 : root.currentStep === index + 1 ? Style.primary : Style.bgTertiary
                            Behavior on width { NumberAnimation { duration: 200 } }
                            Behavior on color  { ColorAnimation  { duration: 200 } }
                        }
                    }
                }
            }
        }

        // ─── Body (scrollable) ────────────────────────────────────
        Flickable {
            id: bodyFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: Math.max(
                (root.currentStep === 1 ? step1.implicitHeight :
                 root.currentStep === 2 ? step2.implicitHeight :
                                          step3.implicitHeight) + 56,
                height)
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            SetupStep1Association {
                id: step1
                x: 28; y: 28
                width: parent.width - 56
                visible: root.currentStep === 1
                height: visible ? implicitHeight : 0
            }
            SetupStep2Niveaux {
                id: step2
                x: 28; y: 28
                width: parent.width - 56
                visible: root.currentStep === 2
                height: visible ? implicitHeight : 0
            }
            SetupStep3AnneeScolaire {
                id: step3
                x: 28; y: 28
                width: parent.width - 56
                visible: root.currentStep === 3
                height: visible ? implicitHeight : 0
            }
        }

        // ─── Footer ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 96
            color: Style.bgPage
            Separator { anchors.top: parent.top; width: parent.width }

            RowLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 16

                // Back button
                Rectangle {
                    Layout.fillWidth: true; height: 52; radius: 16
                    color: Style.bgWhite; border.color: Style.borderMedium
                    visible: root.currentStep > 1
                    Text {
                        anchors.centerIn: parent; text: qsTr("RETOUR")
                        font.pixelSize: 12; font.weight: Font.Black
                        color: Style.textSecondary; font.letterSpacing: 1
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentStep--
                    }
                }

                // Continue / Finish button
                Rectangle {
                    Layout.fillWidth: true; height: 52; radius: 16

                    readonly property bool canProceed: {
                        if (root.currentStep === 1) return step1.canProceed
                        if (root.currentStep === 2) return step2.canProceed
                        return step3.canProceed
                    }

                    color: canProceed ? Style.primary : Style.bgTertiary
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.currentStep < root.totalSteps
                              ? qsTr("CONTINUER →") : qsTr("TERMINER LA CONFIGURATION")
                        font.pixelSize: 12; font.weight: Font.Black
                        color: Style.background; font.letterSpacing: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.canProceed
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.currentStep === 1) {
                                setupController.saveAssociation(step1.getData())
                                setupController.initDraftYear()
                                root.currentStep = 2
                            } else if (root.currentStep === 2) {
                                root.currentStep = 3
                            } else {
                                setupController.completeSetup(step3.getData())
                            }
                        }
                    }
                }
            }
        }
    }
}
