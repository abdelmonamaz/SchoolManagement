import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

// Popup de configuration de la génération des bulletins
// Signaux :
//   bulletinRequested(int eleveId, int classeId, bool allStudents)
ModalOverlay {
    id: root

    signal bulletinRequested(int eleveId, int classeId, bool allStudents)

    // État interne
    property int    selNiveauId:  -1
    property int    selClasseId:  -1
    property int    selEleveId:   -1
    property bool   allStudents:  true

    modalWidth: 560

    onOpened: {
        selNiveauId  = -1
        selClasseId  = -1
        selEleveId   = -1
        allStudents  = true
        if (cfgNiveauCombo)  cfgNiveauCombo.currentIndex  = -1
        if (cfgClasseCombo)  cfgClasseCombo.currentIndex  = -1
        if (cfgEleveCombo)   cfgEleveCombo.currentIndex   = -1
    }

    // Students in selected class
    readonly property var classStudents: {
        if (selClasseId < 0) return []
        var result = [], all = studentController.students
        for (var i = 0; i < all.length; i++)
            if (all[i].classeId === selClasseId) result.push(all[i])
        return result
    }

    Column {
        width: parent.width
        spacing: 20
        padding: 32
        bottomPadding: 28

        // ── Header ──────────────────────────────────────────────────────────
        RowLayout {
            width: parent.width - 64

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    width: 48; height: 48; radius: 16
                    color: Style.primaryBg
                    Text { anchors.centerIn: parent; text: "📄"; font.pixelSize: 22 }
                }

                Column {
                    spacing: 2
                    Text {
                        text: "Générer les Bulletins"
                        font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary
                    }
                    Text {
                        text: "Configuration et export des bulletins scolaires"
                        font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium
                    }
                }
            }

            IconButton { iconName: "close"; iconSize: 18; onClicked: root.visible = false }
        }

        Separator { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter }

        // ── Bandeau info ────────────────────────────────────────────────────
        Rectangle {
            width: parent.width - 64
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: infoCol.implicitHeight + 20
            radius: 12; color: Style.infoBg; border.color: Style.infoBorder

            Column {
                id: infoCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 4

                RowLayout {
                    spacing: 8
                    IconLabel { iconName: "info"; iconSize: 14; iconColor: Style.infoColor }
                    Text {
                        Layout.fillWidth: true
                        text: "Information"
                        font.pixelSize: 12; font.bold: true; color: Style.infoColor
                    }
                }
                Text {
                    width: parent.width
                    text: "Les bulletins seront générés au format PDF avec l'en-tête de l'école Ez-Zaytouna et incluront toutes les notes saisies pour la période sélectionnée."
                    font.pixelSize: 11; color: Style.infoColor
                    wrapMode: Text.WordWrap; lineHeight: 1.5
                }
            }
        }

        // ── CONFIGURATION ────────────────────────────────────────────────────
        Column {
            width: parent.width - 64
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            SectionLabel { text: "CONFIGURATION" }

            // Niveau + Classe — Row avec largeurs explicites pour garantir l'égalité
            Row {
                id: niveauClasseRow
                width: parent.width
                spacing: 16

                Column {
                    // Largeur exacte = moitié du parent moins l'espacement
                    width: (niveauClasseRow.width - niveauClasseRow.spacing) / 2
                    spacing: 6

                    SectionLabel { text: "NIVEAU" }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight

                        ComboBox {
                            id: cfgNiveauCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: schoolingController.niveaux
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: cfgNiveauCombo.currentIndex >= 0 ? cfgNiveauCombo.currentText : "Sélectionner..."
                                font.pixelSize: 13; font.bold: true
                                color: cfgNiveauCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                            }
                            onCurrentValueChanged: {
                                if (currentIndex < 0) return
                                root.selNiveauId = currentValue
                                schoolingController.loadClassesByNiveau(currentValue)
                                cfgClasseCombo.currentIndex = -1
                                cfgEleveCombo.currentIndex  = -1
                                root.selClasseId = -1
                                root.selEleveId  = -1
                            }
                        }
                    }
                }

                Column {
                    width: (niveauClasseRow.width - niveauClasseRow.spacing) / 2
                    spacing: 6

                    SectionLabel { text: "CLASSE" }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage
                        border.color: root.selNiveauId < 0 ? Style.bgTertiary : Style.borderLight
                        opacity: root.selNiveauId < 0 ? 0.55 : 1.0

                        ComboBox {
                            id: cfgClasseCombo
                            anchors.fill: parent; anchors.margins: 4
                            enabled: root.selNiveauId >= 0
                            model: schoolingController.classes
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: cfgClasseCombo.currentIndex >= 0 ? cfgClasseCombo.currentText
                                    : root.selNiveauId < 0 ? "Choisir un niveau d'abord" : "Sélectionner..."
                                font.pixelSize: 13; font.bold: true
                                color: cfgClasseCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                            }
                            onCurrentValueChanged: {
                                if (currentIndex < 0) return
                                root.selClasseId = currentValue
                                cfgEleveCombo.currentIndex = -1
                                root.selEleveId = -1
                            }
                        }
                    }
                }
            }

            // Générer pour
            Column {
                width: parent.width; spacing: 8
                SectionLabel { text: "GÉNÉRER POUR" }

                RowLayout {
                    width: parent.width; spacing: 12

                    // Tous les élèves
                    Rectangle {
                        Layout.fillWidth: true
                        height: 72; radius: 14
                        color: root.allStudents ? Style.primaryBg : Style.bgPage
                        border.color: root.allStudents ? Style.primary : Style.borderLight
                        border.width: root.allStudents ? 2 : 1
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8
                                IconLabel { iconName: "users"; iconSize: 16; iconColor: root.allStudents ? Style.primary : Style.textTertiary }
                                Text {
                                    text: "Tous les élèves"
                                    font.pixelSize: 13; font.bold: true
                                    color: root.allStudents ? Style.primary : Style.textPrimary
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.selClasseId >= 0
                                      ? "Générer " + root.classStudents.length + " bulletin" + (root.classStudents.length > 1 ? "s" : "") + " pour toute la classe"
                                      : "Sélectionner une classe"
                                font.pixelSize: 10; color: root.allStudents ? Style.primary : Style.textTertiary
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.allStudents = true }
                    }

                    // Un élève
                    Rectangle {
                        Layout.fillWidth: true
                        height: 72; radius: 14
                        color: !root.allStudents ? Style.primaryBg : Style.bgPage
                        border.color: !root.allStudents ? Style.primary : Style.borderLight
                        border.width: !root.allStudents ? 2 : 1
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8
                                IconLabel { iconName: "user"; iconSize: 16; iconColor: !root.allStudents ? Style.primary : Style.textTertiary }
                                Text {
                                    text: "Un élève"
                                    font.pixelSize: 13; font.bold: true
                                    color: !root.allStudents ? Style.primary : Style.textPrimary
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Sélectionner un élève spécifique"
                                font.pixelSize: 10; color: !root.allStudents ? Style.primary : Style.textTertiary
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.allStudents = false }
                    }
                }
            }

            // Sélection élève (visible si mode "Un élève")
            Column {
                width: parent.width; spacing: 6
                visible: !root.allStudents

                SectionLabel { text: "SÉLECTIONNER L'ÉLÈVE" }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage
                    border.color: root.selClasseId < 0 ? Style.bgTertiary : Style.borderLight
                    opacity: root.selClasseId < 0 ? 0.55 : 1.0

                    ComboBox {
                        id: cfgEleveCombo
                        anchors.fill: parent; anchors.margins: 4
                        enabled: root.selClasseId >= 0
                        model: root.classStudents
                        textRole: "prenom"
                        currentIndex: -1
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            leftPadding: 8
                            text: cfgEleveCombo.currentIndex >= 0
                                  ? root.classStudents[cfgEleveCombo.currentIndex].prenom + " " + root.classStudents[cfgEleveCombo.currentIndex].nom
                                  : root.selClasseId < 0 ? "Choisir une classe d'abord" : "Sélectionner un élève..."
                            font.pixelSize: 13; font.bold: true
                            color: cfgEleveCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        delegate: Rectangle {
                            width: cfgEleveCombo.width; height: 40
                            color: eleveItemMa.containsMouse ? Style.bgSecondary : "transparent"
                            Text {
                                anchors.fill: parent; leftPadding: 12
                                text: modelData.prenom + " " + modelData.nom
                                font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                verticalAlignment: Text.AlignVCenter
                            }
                            MouseArea {
                                id: eleveItemMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    cfgEleveCombo.currentIndex = index
                                    root.selEleveId = modelData.id
                                    cfgEleveCombo.popup.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Boutons ─────────────────────────────────────────────────────────
        RowLayout {
            width: parent.width - 64
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            readonly property bool formValid: root.selClasseId >= 0
                && (root.allStudents || root.selEleveId >= 0)

            Rectangle {
                Layout.fillWidth: true; height: 48; radius: 14
                color: cancelMa.containsMouse ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderLight
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "ANNULER"; font.pixelSize: 11; font.weight: Font.Black; color: Style.textTertiary }
                MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.visible = false }
            }

            Rectangle {
                Layout.fillWidth: true; height: 48; radius: 14
                color: parent.formValid
                       ? (confirmMa.containsMouse ? Style.primaryDark : Style.primary)
                       : Style.bgTertiary
                opacity: parent.formValid ? 1.0 : 0.5
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.centerIn: parent; spacing: 8
                    IconLabel { iconName: "printer"; iconSize: 14; iconColor: "white" }
                    Text { text: "GÉNÉRER LE BULLETIN"; font.pixelSize: 11; font.weight: Font.Black; color: "#FFFFFF" }
                }

                MouseArea {
                    id: confirmMa; anchors.fill: parent
                    enabled: parent.parent.formValid
                    hoverEnabled: true; cursorShape: parent.parent.formValid ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        root.bulletinRequested(
                            root.allStudents ? -1 : root.selEleveId,
                            root.selClasseId,
                            root.allStudents
                        )
                    }
                }
            }
        }
    }
}
