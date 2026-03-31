import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Étape 2 : Catalogue des niveaux ──────────────────────────────────────────
ColumnLayout {
    id: root
    spacing: 16

    readonly property bool canProceed: setupController.niveaux.length > 0

    // Inline edit state
    property int    editingId:       -1
    property string editingNom:      ""
    property int    editingParentId: 0

    // New niveau state
    property string newNom:      ""
    property int    newParentId: 0

    // ── Add bar ─────────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true; height: 60; radius: 14
        color: Style.bgPage; border.color: Style.borderLight

        RowLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 10

            Rectangle {
                Layout.fillWidth: true; height: 40; radius: 10
                color: Style.background; border.color: Style.borderLight
                HoverHandler { cursorShape: Qt.IBeamCursor }
                TextInput {
                    id: niveauInput
                    anchors.fill: parent; anchors.margins: 10
                    font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                    onTextChanged: root.newNom = text
                    Keys.onReturnPressed: addBtn.click()
                }
                Text {
                    anchors.fill: parent; anchors.margins: 10
                    text: qsTr("Nom du niveau (ex: Niveau 1)")
                    font.pixelSize: 13; font.bold: true; color: Style.textTertiary
                    visible: niveauInput.text === ""; verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                width: 170; height: 40; radius: 10
                color: Style.background; border.color: Style.borderLight
                ComboBox {
                    id: parentCombo
                    anchors.fill: parent; anchors.margins: 2
                    model: {
                        var items = [{"nom": qsTr("— Aucun parent —"), "id": 0}]
                        for (var i = 0; i < setupController.niveaux.length; i++)
                            items.push(setupController.niveaux[i])
                        return items
                    }
                    textRole: "nom"
                    background: Rectangle { color: "transparent" }
                    contentItem: Text {
                        text: parentCombo.displayText
                        font.pixelSize: 11; font.bold: true; color: Style.textSecondary
                        verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight
                    }
                    onCurrentIndexChanged: root.newParentId = currentIndex > 0 ? model[currentIndex].id : 0
                }
            }

            Rectangle {
                id: addBtn
                width: 76; height: 40; radius: 10
                color: root.newNom.trim() !== "" ? Style.primary : Style.bgTertiary
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent; text: qsTr("+ Ajouter")
                    font.pixelSize: 11; font.weight: Font.Black; color: Style.background
                }
                function click() {
                    if (root.newNom.trim() === "") return
                    setupController.createNiveau(root.newNom.trim(), root.newParentId)
                    niveauInput.text = ""; parentCombo.currentIndex = 0
                    root.newNom = ""; root.newParentId = 0
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: root.newNom.trim() !== ""
                    onClicked: addBtn.click()
                }
            }
        }
    }

    // ── Niveau list ─────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true; height: 340; radius: 14
        color: Style.bgPage; border.color: Style.borderLight; clip: true

        Column {
            anchors.centerIn: parent; spacing: 8
            visible: setupController.niveaux.length === 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Aucun niveau créé")
                font.pixelSize: 14; font.bold: true; color: Style.textTertiary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Créez au moins un niveau pour continuer.")
                font.pixelSize: 12; color: Style.textTertiary
            }
        }

        ListView {
            anchors.fill: parent; anchors.margins: 8
            model: setupController.niveaux; clip: true; spacing: 4
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: row
                width: ListView.view.width
                height: root.editingId === modelData.id ? 68 : 48
                radius: 12
                color: rowHover.containsMouse && root.editingId !== modelData.id
                       ? Style.bgPage : Style.background
                border.color: root.editingId === modelData.id ? Style.primary : Style.borderLight
                Behavior on height { NumberAnimation { duration: 150 } }
                Behavior on color  { ColorAnimation  { duration: 100 } }
                clip: true

                // ─── Read mode ──────────────────────────────────────────
                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                    spacing: 10
                    visible: root.editingId !== modelData.id
                    opacity: root.editingId !== modelData.id ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    Rectangle { width: 8; height: 8; radius: 4; color: modelData.parentLevelId > 0 ? Style.primary : Style.successColor }

                    Column {
                        Layout.fillWidth: true; spacing: 1
                        Text { text: modelData.nom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                        Text {
                            visible: modelData.parentLevelId > 0
                            text: {
                                for (var i = 0; i < setupController.niveaux.length; i++)
                                    if (setupController.niveaux[i].id === modelData.parentLevelId)
                                        return qsTr("↳ Succède à : ") + setupController.niveaux[i].nom
                                return ""
                            }
                            font.pixelSize: 10; color: Style.textTertiary
                        }
                    }

                    Rectangle {
                        visible: { for (var i = 0; i < setupController.niveaux.length; i++) if (setupController.niveaux[i].parentLevelId === modelData.id) return false; return true }
                        height: 20; radius: 10; width: tLbl.implicitWidth + 16; color: Style.warningBg
                        Text { id: tLbl; anchors.centerIn: parent; text: qsTr("TERMINAL"); font.pixelSize: 9; font.weight: Font.Black; color: Style.warningColor }
                    }

                    IconButton {
                        iconName: "edit"; iconSize: 15
                        onClicked: {
                            root.editingParentId = modelData.parentLevelId
                            root.editingNom      = modelData.nom
                            editInput.text       = modelData.nom
                            root.editingId       = modelData.id
                        }
                    }
                    IconButton {
                        iconName: "delete"; iconSize: 15; hoverColor: Style.errorColor
                        onClicked: setupController.deleteNiveau(modelData.id)
                    }
                }

                // ─── Edit mode ──────────────────────────────────────────
                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10; margins: 10 }
                    spacing: 8
                    visible: root.editingId === modelData.id
                    opacity: root.editingId === modelData.id ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    Rectangle {
                        Layout.fillWidth: true; height: 36; radius: 8
                        color: Style.bgPage; border.color: Style.primary
                        HoverHandler { cursorShape: Qt.IBeamCursor }
                        TextInput {
                            id: editInput
                            anchors.fill: parent; anchors.margins: 8
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                            onTextChanged: root.editingNom = text
                            Keys.onReturnPressed: saveBtn.save()
                            Keys.onEscapePressed: root.editingId = -1
                        }
                    }

                    Rectangle {
                        width: 160; height: 36; radius: 8
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editParentCombo
                            anchors.fill: parent; anchors.margins: 2
                            model: {
                                var items = [{"nom": qsTr("— Aucun parent —"), "id": 0}]
                                for (var i = 0; i < setupController.niveaux.length; i++)
                                    if (setupController.niveaux[i].id !== root.editingId)
                                        items.push(setupController.niveaux[i])
                                return items
                            }
                            textRole: "nom"
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                text: editParentCombo.displayText
                                font.pixelSize: 11; font.bold: true; color: Style.textSecondary
                                verticalAlignment: Text.AlignVCenter; leftPadding: 6; elide: Text.ElideRight
                            }
                            onModelChanged: {
                                var idx = 0
                                for (var i = 1; i < model.length; i++)
                                    if (model[i].id === root.editingParentId) { idx = i; break }
                                currentIndex = idx
                            }
                            onCurrentIndexChanged: root.editingParentId = currentIndex > 0 ? model[currentIndex].id : 0
                        }
                    }

                    Rectangle {
                        id: saveBtn
                        width: 36; height: 36; radius: 8
                        color: root.editingNom.trim() !== "" ? Style.successColor : Style.bgTertiary
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: qsTr("✓"); font.pixelSize: 16; font.bold: true; color: Style.background }
                        function save() {
                            if (root.editingNom.trim() === "") return
                            setupController.updateNiveau(root.editingId, root.editingNom.trim(), root.editingParentId)
                            root.editingId = -1
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            enabled: root.editingNom.trim() !== ""
                            onClicked: saveBtn.save()
                        }
                    }

                    Rectangle {
                        width: 36; height: 36; radius: 8
                        color: Style.bgPage; border.color: Style.borderLight
                        Text { anchors.centerIn: parent; text: qsTr("✕"); font.pixelSize: 13; font.bold: true; color: Style.textSecondary }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.editingId = -1 }
                    }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true
                    enabled: root.editingId !== modelData.id
                    onClicked: mouse.accepted = false
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
