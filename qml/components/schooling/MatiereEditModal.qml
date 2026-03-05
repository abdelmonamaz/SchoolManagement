import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

ModalOverlay {
    id: root
    modalWidth: 520
    modalColor: "#FAFBFC"

    required property bool show
    required property int  editingMatiereId

    // Champs pré-remplis depuis l'extérieur
    property string initialNom:              ""
    property int    initialNombreSeances:    0
    property int    initialDureeMinutes:     60
    property int    editingNiveauId:         0

    // État confirmation
    property bool   showConfirm:     false
    property var    pendingSaveData: null

    signal saveRequested(var data)
    signal closeRequested()

    visible: show

    onVisibleChanged: {
        if (visible) {
            nomInput.text           = initialNom
            nbSeancesInput.text     = initialNombreSeances > 0 ? String(initialNombreSeances) : ""
            dureeInput.text         = initialDureeMinutes  > 0 ? String(initialDureeMinutes)  : ""
            newExamenCombo.editText = ""
            newExamenCombo.currentIndex = -1
            showConfirm             = false
            pendingSaveData         = null
        }
    }

    // ─── Header ───
    // NOTE : implicitHeight (pas height) pour que ModalOverlay calcule la bonne hauteur totale
    Item {
        width: parent.width
        implicitHeight: 72
        Separator { anchors.bottom: parent.bottom; width: parent.width }

        RowLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 12

            Column {
                Layout.fillWidth: true; spacing: 2
                Text { text: "Modifier la matière"; font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                Text { text: "Séances, durée et évaluations"; font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
            }

            IconButton { iconName: "close"; onClicked: root.closeRequested() }
        }
    }

    // ─── Corps (fond blanc) ───
    Rectangle {
        width: parent.width
        implicitHeight: bodyCol.implicitHeight + 64
        color: Style.bgWhite

        Column {
            id: bodyCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
            spacing: 24

            // Nom
            Column {
                width: parent.width; spacing: 6
                Text { text: "NOM DE LA MATIÈRE"; font.pixelSize: 9; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 0.8 }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage
                    border.color: nomInput.activeFocus ? Style.primary : Style.borderLight
                    HoverHandler { cursorShape: Qt.IBeamCursor }
                    TextInput {
                        id: nomInput
                        anchors.fill: parent; anchors.margins: 12
                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                        selectByMouse: true
                        Text { visible: !parent.text; text: "Nom de la matière..."; font: parent.font; color: Style.textTertiary }
                    }
                }
            }

            // Nombre de séances + Durée (côte à côte)
            RowLayout {
                width: parent.width; spacing: 16

                Column {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: "SÉANCES / AN"; font.pixelSize: 9; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 0.8 }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage
                        border.color: nbSeancesInput.activeFocus ? Style.primary : Style.borderLight
                        HoverHandler { cursorShape: Qt.IBeamCursor }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8
                            TextInput {
                                id: nbSeancesInput
                                Layout.fillWidth: true
                                font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 0; top: 999 }
                                Text { visible: !parent.text; text: "0"; font: parent.font; color: Style.textTertiary }
                            }
                            Column {
                                spacing: 2
                                Rectangle {
                                    width: 24; height: 18; radius: 6; color: nbUpMa.containsMouse ? Style.bgSecondary : Style.bgPage
                                    Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: 8; color: Style.textSecondary }
                                    MouseArea { id: nbUpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { var v = parseInt(nbSeancesInput.text) || 0; nbSeancesInput.text = String(v + 1) } }
                                }
                                Rectangle {
                                    width: 24; height: 18; radius: 6; color: nbDownMa.containsMouse ? Style.bgSecondary : Style.bgPage
                                    Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: 8; color: Style.textSecondary }
                                    MouseArea { id: nbDownMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { var v = parseInt(nbSeancesInput.text) || 0; if (v > 0) nbSeancesInput.text = String(v - 1) } }
                                }
                            }
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: "DURÉE (MIN)"; font.pixelSize: 9; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 0.8 }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage
                        border.color: dureeInput.activeFocus ? Style.primary : Style.borderLight
                        HoverHandler { cursorShape: Qt.IBeamCursor }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8
                            TextInput {
                                id: dureeInput
                                Layout.fillWidth: true
                                font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator { bottom: 1; top: 480 }
                                Text { visible: !parent.text; text: "60"; font: parent.font; color: Style.textTertiary }
                            }
                            Column {
                                spacing: 2
                                Rectangle {
                                    width: 24; height: 18; radius: 6; color: durUpMa.containsMouse ? Style.bgSecondary : Style.bgPage
                                    Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: 8; color: Style.textSecondary }
                                    MouseArea { id: durUpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { var v = parseInt(dureeInput.text) || 60; dureeInput.text = String(v + 5) } }
                                }
                                Rectangle {
                                    width: 24; height: 18; radius: 6; color: durDownMa.containsMouse ? Style.bgSecondary : Style.bgPage
                                    Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: 8; color: Style.textSecondary }
                                    MouseArea { id: durDownMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { var v = parseInt(dureeInput.text) || 60; if (v > 5) dureeInput.text = String(v - 5) } }
                                }
                            }
                        }
                    }
                }
            }

            // Séparateur + titre Évaluations
            Column {
                width: parent.width; spacing: 12

                Separator { width: parent.width }

                RowLayout {
                    width: parent.width
                    Text { Layout.fillWidth: true; text: "ÉVALUATIONS"; font.pixelSize: 9; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 0.8 }
                    Text {
                        text: schoolingController.matiereExamens.length + " définie" + (schoolingController.matiereExamens.length > 1 ? "s" : "")
                        font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary
                    }
                }

                // Liste des évaluations existantes
                ListView {
                    id: examenList
                    width: parent.width
                    height: Math.min(contentHeight, 300)
                    clip: true; spacing: 6
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    model: schoolingController.matiereExamens

                    delegate: Rectangle {
                        width: examenList.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight

                        property bool editing: false

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8; spacing: 8

                            TextInput {
                                id: examenTitleInput
                                Layout.fillWidth: true
                                text: modelData.titre
                                font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                readOnly: !parent.parent.editing
                                selectByMouse: true
                                HoverHandler { cursorShape: parent.parent.editing ? Qt.IBeamCursor : Qt.ArrowCursor }
                            }

                            // Bouton Éditer / Confirmer
                            Rectangle {
                                width: 30; height: 30; radius: 9
                                color: editConfirmMa.containsMouse
                                       ? (parent.parent.editing ? Style.successColor : Style.primaryBg)
                                       : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.parent.editing ? "✓" : "✎"
                                    font.pixelSize: parent.parent.editing ? 14 : 13
                                    color: editConfirmMa.containsMouse
                                           ? (parent.parent.editing ? "#FFFFFF" : Style.primary)
                                           : Style.textTertiary
                                }
                                MouseArea {
                                    id: editConfirmMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.parent.parent.editing) {
                                            var newTitle = examenTitleInput.text.trim()
                                            if (newTitle && newTitle !== modelData.titre) {
                                                schoolingController.updateMatiereExamen(modelData.id, newTitle)
                                                schoolingController.loadMatiereExamens(root.editingMatiereId)
                                            }
                                            parent.parent.parent.editing = false
                                        } else {
                                            parent.parent.parent.editing = true
                                            examenTitleInput.forceActiveFocus()
                                        }
                                    }
                                }
                            }

                            // Bouton Supprimer
                            Rectangle {
                                width: 30; height: 30; radius: 9
                                color: delExMa.containsMouse ? "#FEE2E2" : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; font.bold: true; color: delExMa.containsMouse ? Style.errorColor : Style.textTertiary }
                                MouseArea {
                                    id: delExMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        schoolingController.deleteMatiereExamen(modelData.id)
                                        schoolingController.loadMatiereExamens(root.editingMatiereId)
                                    }
                                }
                            }
                        }
                    }

                    // État vide
                    Text {
                        anchors.centerIn: parent
                        visible: examenList.count === 0
                        text: "Aucune évaluation définie"
                        font.pixelSize: 12; font.italic: true; color: Style.textTertiary
                    }
                }

                // Champ ajout nouvel examen
                RowLayout {
                    width: parent.width; spacing: 12

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: 12
                        color: Style.bgPage
                        border.color: newExamenCombo.activeFocus ? Style.primary : Style.borderLight
                        
                        ComboBox {
                            id: newExamenCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: schoolingController.typeExamens
                            textRole: "titre"
                            valueRole: "id"
                            editable: true
                            currentIndex: -1
                            
                            background: Rectangle { color: "transparent" }
                            contentItem: TextInput {
                                leftPadding: 8; rightPadding: 8
                                verticalAlignment: Text.AlignVCenter
                                text: newExamenCombo.editText
                                font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                selectByMouse: true
                                Keys.onReturnPressed: addExamenBtn.doAdd()
                                Text { 
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    visible: !parent.text
                                    text: "Choisir ou saisir..."
                                    font: parent.font; color: Style.textTertiary 
                                }
                            }
                            
                            Component.onCompleted: schoolingController.loadTypeExamens()
                        }
                    }

                    Rectangle {
                        id: addExamenBtn
                        width: 44; height: 44; radius: 12
                        color: addExMa.containsMouse ? Style.primary : Style.primaryBg
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 20; font.bold: true; color: addExMa.containsMouse ? "#FFFFFF" : Style.primary }

                        function doAdd() {
                            var t = newExamenCombo.editText.trim()
                            if (t && root.editingMatiereId > 0) {
                                schoolingController.createTypeAndMatiereExamen(root.editingMatiereId, t)
                                newExamenCombo.editText = ""
                                newExamenCombo.currentIndex = -1
                            }
                        }

                        MouseArea {
                            id: addExMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: addExamenBtn.doAdd()
                        }
                    }
                    
                    Rectangle {
                        width: 44; height: 44; radius: 12
                        color: gearMa.containsMouse ? Style.bgSecondary : Style.bgPage
                        border.color: Style.borderLight
                        IconLabel { anchors.centerIn: parent; iconName: "settings"; iconSize: 18; iconColor: Style.textSecondary }
                        MouseArea {
                            id: gearMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: typeExamenModal.show = true
                        }
                    }
                }
            }
        }
    }
    
    TypeExamenModal {
        id: typeExamenModal
    }

    // ─── Footer ───
    // implicitHeight dynamique : normal (80) ou confirmation (116)
    Item {
        width: parent.width
        implicitHeight: root.showConfirm ? 116 : 80

        Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Separator { anchors.top: parent.top; width: parent.width }

        // ── Mode normal : ANNULER / ENREGISTRER ──
        RowLayout {
            id: normalFooter
            visible: !root.showConfirm
            opacity: root.showConfirm ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 18; leftMargin: 20; rightMargin: 20 }
            height: 44; spacing: 16

            Rectangle {
                Layout.fillWidth: true; Layout.preferredWidth: 1
                height: 44; radius: 14; color: Style.bgWhite; border.color: Style.borderLight
                Text { anchors.centerIn: parent; text: "ANNULER"; font.pixelSize: 11; font.weight: Font.Black; color: Style.textTertiary }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredWidth: 1
                height: 44; radius: 14; color: Style.primary
                Text { anchors.centerIn: parent; text: "ENREGISTRER"; font.pixelSize: 11; font.weight: Font.Black; color: "#FFFFFF"; font.letterSpacing: 0.5 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var nom = nomInput.text.trim()
                        if (!nom) return
                        root.pendingSaveData = {
                            id:                  root.editingMatiereId,
                            nom:                 nom,
                            niveauId:            root.editingNiveauId,
                            nombreSeances:       parseInt(nbSeancesInput.text) || 0,
                            dureeSeanceMinutes:  parseInt(dureeInput.text)     || 60
                        }
                        root.showConfirm = true
                    }
                }
            }
        }

        // ── Mode confirmation ──
        Column {
            id: confirmFooter
            visible: root.showConfirm
            opacity: root.showConfirm ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 16; leftMargin: 20; rightMargin: 20 }
            spacing: 10

            // Message
            Rectangle {
                width: parent.width; height: 32; radius: 10
                color: "#FFF7ED"
                border.color: "#FED7AA"

                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: "⚠"; font.pixelSize: 14; color: "#F97316" }
                    Text {
                        text: "Confirmer les modifications de la matière ?"
                        font.pixelSize: 12; font.weight: Font.Bold; color: "#92400E"
                    }
                }
            }

            // Boutons NON / OUI
            RowLayout {
                width: parent.width; spacing: 12

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 40; radius: 12
                    color: cancelConfirmMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "NON"; font.pixelSize: 11; font.weight: Font.Black; color: Style.textTertiary }
                    MouseArea { id: cancelConfirmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.showConfirm = false }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 40; radius: 12
                    color: okConfirmMa.containsMouse ? "#16A34A" : Style.successColor
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "OUI, ENREGISTRER"; font.pixelSize: 11; font.weight: Font.Black; color: "#FFFFFF" }
                    MouseArea {
                        id: okConfirmMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.saveRequested(root.pendingSaveData)
                            root.showConfirm = false
                        }
                    }
                }
            }
        }
    }
}
