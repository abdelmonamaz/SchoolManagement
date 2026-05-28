import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import UI.Components

ModalOverlay {
    id: root

    required property var selectedItem
    required property int pageWidth

    property bool isEditing: false
    property bool showDeleteConfirm: false
    property var editData: null

    property bool itemIsEvent: selectedItem ? selectedItem.typeSeance === "Événement" : false
    property bool itemIsExam: selectedItem ? selectedItem.typeSeance === "Examen" : false

    // ── Gestion des semestres ─────────────────────────────────────
    readonly property bool hasSemestres: setupController.activeSemestres.length >= 2

    // Retourne le numéro de semestre correspondant à une date ISO (YYYY-MM-DD).
    function detectSemestreFromIso(isoDate) {
        if (!hasSemestres || !isoDate) return 0
        var sems = setupController.activeSemestres
        var d = isoDate.indexOf("T") >= 0 ? isoDate.split("T")[0] : isoDate
        for (var i = 0; i < sems.length; i++)
            if (d >= sems[i].dateDebut && d <= sems[i].dateFin) return sems[i].numero
        return sems.length > 0 ? sems[0].numero : 0
    }

    modalWidth: isEditing ? Math.min(pageWidth - 64, 580) : 420

    onShowChanged: {
        if (!show) {
            isEditing = false
            showDeleteConfirm = false
        }
    }

    Column {
        width: parent.width
        spacing: 0
        padding: 32

        // Header
        RowLayout {
            width: parent.width - 64
            spacing: 12

            Badge {
                text: root.selectedItem ? (root.selectedItem.typeSeance || "") : ""
                variant: {
                    if (!root.selectedItem) return "neutral"
                    if (root.selectedItem.typeSeance === "Examen") return "error"
                    if (root.selectedItem.typeSeance === "Événement") return "warning"
                    return "neutral"
                }
            }

            Item { Layout.fillWidth: true }

            IconButton {
                iconName: "close"; iconSize: 18
                onClicked: root.close()
            }
        }

        Item { width: 1; height: 16 }

        // ─── View Mode ───
        Column {
            width: parent.width - 64
            spacing: 20
            visible: !root.isEditing

            // Title: titre for exam/event, subject for cours
            Text {
                text: {
                    if (!root.selectedItem) return ""
                    if (root.itemIsExam || root.itemIsEvent)
                        return root.selectedItem.titre || root.selectedItem.subject || ""
                    return root.selectedItem.subject || ""
                }
                font.pixelSize: 24; font.weight: Font.Black; color: Style.textPrimary
                wrapMode: Text.WordWrap
                width: parent.width
            }

            // Subtitle: show subject for exams (matière under titre)
            Text {
                visible: root.itemIsExam && root.selectedItem && root.selectedItem.subject
                text: root.selectedItem ? (root.selectedItem.subject || "") : ""
                font.pixelSize: 14; font.weight: Font.Bold; color: Style.primary
            }

            Column {
                width: parent.width
                spacing: 14

                RowLayout {
                    width: parent.width; spacing: 12
                    Rectangle {
                        width: 32; height: 32; radius: 10; color: Style.bgPage
                        IconLabel { anchors.centerIn: parent; iconName: "calendar"; iconSize: 14; iconColor: Style.primary }
                    }
                    Text {
                        text: root.selectedItem ? ((root.selectedItem.day || "") + " • " + (root.selectedItem.time || "")) : ""
                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                    }
                }

                // Salle + Classe (hide classe for events)
                RowLayout {
                    width: parent.width; spacing: 12
                    visible: root.selectedItem && (root.selectedItem.room !== "—" || !root.itemIsEvent)
                    Rectangle {
                        width: 32; height: 32; radius: 10; color: Style.bgPage
                        IconLabel { anchors.centerIn: parent; iconName: "location"; iconSize: 14; iconColor: Style.primary }
                    }
                    Text {
                        text: {
                            if (!root.selectedItem) return ""
                            if (root.itemIsEvent)
                                return root.selectedItem.room || ""
                            return (root.selectedItem.room || "") + " • " + (root.selectedItem.className || "")
                        }
                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                    }
                }

                // Professeur (hide for events)
                RowLayout {
                    width: parent.width; spacing: 12
                    visible: !root.itemIsEvent
                    Rectangle {
                        width: 32; height: 32; radius: 10; color: Style.bgPage
                        IconLabel { anchors.centerIn: parent; iconName: "user"; iconSize: 14; iconColor: Style.primary }
                    }
                    Text {
                        text: root.selectedItem ? (root.selectedItem.professor || "") : ""
                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                    }
                }

                RowLayout {
                    width: parent.width; spacing: 12
                    Rectangle {
                        width: 32; height: 32; radius: 10; color: Style.bgPage
                        IconLabel { anchors.centerIn: parent; iconName: "clock"; iconSize: 14; iconColor: Style.primary }
                    }
                    Text {
                        text: root.selectedItem ? (root.selectedItem.dureeMinutes + " min") : ""
                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                    }
                }

                // Descriptif (événements uniquement)
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.itemIsEvent && root.selectedItem && root.selectedItem.descriptif

                    Separator { width: parent.width }

                    Text {
                        text: qsTr("DESCRIPTIF")
                        font.pixelSize: 9; font.weight: Font.Black; color: Style.textTertiary
                        font.letterSpacing: 1
                    }

                    Text {
                        text: root.selectedItem ? (root.selectedItem.descriptif || "") : ""
                        font.pixelSize: 13; color: Style.textSecondary
                        wrapMode: Text.WordWrap; width: parent.width
                    }
                }
            }

            Item { width: 1; height: 4 }

            RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: editModMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent; text: qsTr("MODIFIER")
                        font.pixelSize: 10; font.weight: Font.Black; color: Style.textSecondary
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: editModMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.selectedItem) {
                                root.editData = {
                                    "id": root.selectedItem.id,
                                    "titre": root.selectedItem.titre || "",
                                    "matiereId": root.selectedItem.matiereId || 0,
                                    "profId": root.selectedItem.profId || 0,
                                    "salleId": root.selectedItem.salleId || 0,
                                    "classeId": root.selectedItem.classeId || 0,
                                    "dateHeureDebut": root.selectedItem.dateHeureDebut,
                                    "dureeMinutes": root.selectedItem.dureeMinutes,
                                    "typeSeance": root.selectedItem.typeSeance,
                                    "descriptif": root.selectedItem.descriptif || ""
                                }
                                root.isEditing = true
                                root.showDeleteConfirm = false
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: root.showDeleteConfirm ? Style.errorColor
                         : delModMa.containsMouse ? Style.errorBg : Style.errorBg
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.showDeleteConfirm ? "CONFIRMER" : "SUPPRIMER"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: root.showDeleteConfirm ? Style.background : Style.errorColor
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: delModMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.showDeleteConfirm) {
                                if (root.selectedItem && root.selectedItem.id) {
                                    examsController.deleteExam(root.selectedItem.id)
                                    root.close()
                                }
                            } else {
                                root.showDeleteConfirm = true
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 36; radius: 10
                visible: root.showDeleteConfirm
                color: cancelDelMa.containsMouse ? Style.bgSecondary : Style.bgPage
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent; text: qsTr("ANNULER LA SUPPRESSION")
                    font.pixelSize: 9; font.weight: Font.Black; color: Style.textTertiary
                    font.letterSpacing: 0.5
                }

                MouseArea {
                    id: cancelDelMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showDeleteConfirm = false
                }
            }
        }

        // ─── Edit Mode ───
        Column {
            id: editModeCol
            width: parent.width - 64
            spacing: 16
            visible: root.isEditing

            property bool editIsEvent: root.editData ? root.editData.typeSeance === "Événement" : false
            property bool editIsExam:  root.editData ? root.editData.typeSeance === "Examen"    : false

            // Charger les classes du bon niveau quand on entre en mode édition
            Connections {
                target: root
                function onIsEditingChanged() {
                    if (!root.isEditing || !root.editData) return
                    var classes = schoolingController.allClasses
                    for (var c = 0; c < classes.length; c++) {
                        if (classes[c].id === root.editData.classeId) {
                            schoolingController.loadClassesByNiveau(classes[c].niveauId)
                            break
                        }
                    }
                }
            }

            // Resélectionner la classe dès que le modèle est rechargé
            Connections {
                target: schoolingController
                function onClassesChanged() {
                    if (!root.isEditing || !root.editData) return
                    for (var i = 0; i < editClasseCombo.count; i++) {
                        if (editClasseCombo.model[i].id === root.editData.classeId) {
                            editClasseCombo.currentIndex = i; break
                        }
                    }
                }
            }

            Text {
                text: qsTr("Modifier la Session")
                font.pixelSize: 20; font.weight: Font.Black; color: Style.textPrimary
            }

            // ── Informations en lecture seule ────────────────────────
            Column {
                width: parent.width; spacing: 10

                // Matière (cours / examen)
                Column {
                    width: parent.width; spacing: 4
                    visible: !editModeCol.editIsEvent
                    SectionLabel { text: qsTr("MATIÈRE") }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.bgTertiary
                        Text {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            text: root.selectedItem ? (root.selectedItem.subject || "—") : "—"
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textSecondary; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                        }
                    }
                }

                // Titre (examen / événement)
                Column {
                    width: parent.width; spacing: 4
                    visible: editModeCol.editIsExam || editModeCol.editIsEvent
                    SectionLabel { text: editModeCol.editIsExam ? qsTr("ÉPREUVE") : qsTr("NOM DE L'ÉVÈNEMENT") }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.bgTertiary
                        Text {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            text: root.editData ? (root.editData.titre || "—") : "—"
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textSecondary; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                        }
                    }
                }

                // Durée (lecture seule)
                Column {
                    width: parent.width; spacing: 4
                    SectionLabel { text: qsTr("DURÉE (MIN)") }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.bgTertiary
                        Text {
                            anchors { fill: parent; leftMargin: 12 }
                            text: root.editData ? root.editData.dureeMinutes.toString() : "—"
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textSecondary; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Separator { width: parent.width }

            // ── Champs éditables ─────────────────────────────────────
            GridLayout {
                id: editGrid
                width: parent.width
                columns: 2; columnSpacing: 14; rowSpacing: 14

                property bool editIsEvent: editModeCol.editIsEvent
                property bool editIsExam:  editModeCol.editIsExam

                // Heure
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    SectionLabel { text: qsTr("HEURE") }
                    Rectangle {
                        id: editTimeRect
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage
                        border.color: editTimeInput.isValidTime ? Style.borderLight : Style.errorColor
                        border.width: editTimeInput.isValidTime ? 1 : 1.5
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        TextInput {
                            id: editTimeInput
                            anchors.fill: parent; anchors.margins: 10
                            inputMask: "00:00"
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textPrimary; verticalAlignment: Text.AlignVCenter
                            KeyNavigation.tab: editClasseCombo

                            // Plage valide : heures 00-23, minutes 00-59
                            // displayText inclut le ":" du masque, text non.
                            readonly property bool isValidTime: {
                                var parts = displayText.split(":")
                                if (parts.length !== 2) return false
                                var h = parseInt(parts[0]); var m = parseInt(parts[1])
                                return h >= 0 && h <= 23 && m >= 0 && m <= 59
                            }

                            Component.onCompleted: {
                                if (root.editData && root.editData.dateHeureDebut) {
                                    var d = root.editData.dateHeureDebut
                                    if (typeof d === "string" && d.indexOf("T") >= 0)
                                        text = d.split("T")[1].substring(0, 5)
                                } else {
                                    text = "08:00"
                                }
                            }
                        }
                    }
                }

                // Classe (Cours & Examen)
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    visible: !editGrid.editIsEvent
                    SectionLabel { text: qsTr("CLASSE") }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editClasseCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: schoolingController.classes
                            textRole: "nom"; valueRole: "id"; currentIndex: -1
                            Component.onCompleted: {
                                if (root.editData) {
                                    for (var i = 0; i < count; i++)
                                        if (model[i].id === root.editData.classeId) { currentIndex = i; break }
                                }
                            }
                            onCurrentValueChanged: if (root.editData && currentIndex >= 0) root.editData.classeId = currentValue
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: editClasseCombo.currentIndex >= 0 ? editClasseCombo.displayText : qsTr("Sélectionner...")
                                font.pixelSize: 12; font.weight: Font.Bold
                                color: editClasseCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // Professeur (Cours & Examen)
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    visible: !editGrid.editIsEvent

                    SectionLabel { text: editGrid.editIsExam ? "PROFESSEUR (OPTIONNEL)" : "PROFESSEUR" }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editProfCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: staffController.enseignants
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            Component.onCompleted: {
                                if (root.editData) {
                                    for (var i = 0; i < count; i++) {
                                        if (model[i].id === root.editData.profId) { currentIndex = i; break }
                                    }
                                }
                            }
                            onCurrentValueChanged: if (root.editData && currentIndex >= 0) root.editData.profId = currentValue
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: editProfCombo.currentIndex >= 0 ? editProfCombo.displayText : "Sélectionner..."
                                font.pixelSize: 12; font.weight: Font.Bold
                                color: editProfCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                            }

                            popup: Popup {
                                y: editProfCombo.height - 1
                                width: editProfCombo.width
                                implicitHeight: Math.min(editProfPopupCol.implicitHeight + 2, 200)
                                padding: 1

                                contentItem: Flickable {
                                    clip: true
                                    contentHeight: editProfPopupCol.implicitHeight
                                    flickableDirection: Flickable.VerticalFlick

                                    Column {
                                        id: editProfPopupCol
                                        width: parent.width

                                        Rectangle {
                                            width: parent.width; height: 34
                                            color: editProfResetMa.containsMouse ? Style.bgSecondary : "transparent"
                                            visible: editGrid.editIsExam

                                            Text {
                                                anchors.fill: parent; leftPadding: 12
                                                text: qsTr("Sélectionner...")
                                                font.pixelSize: 12; font.italic: true; font.bold: true
                                                color: Style.textTertiary; verticalAlignment: Text.AlignVCenter
                                            }
                                            MouseArea {
                                                id: editProfResetMa
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { editProfCombo.currentIndex = -1; if (root.editData) root.editData.profId = 0; editProfCombo.popup.close() }
                                            }
                                        }

                                        Repeater {
                                            model: staffController.enseignants
                                            Rectangle {
                                                width: editProfPopupCol.width; height: 34
                                                color: editProfItemMa.containsMouse ? Style.bgSecondary : (editProfCombo.currentIndex === index ? Style.bgPage : "transparent")
                                                Text {
                                                    anchors.fill: parent; leftPadding: 12
                                                    text: modelData.nom || ""
                                                    font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                MouseArea {
                                                    id: editProfItemMa
                                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { editProfCombo.currentIndex = index; editProfCombo.popup.close() }
                                                }
                                            }
                                        }
                                    }
                                }

                                background: Rectangle { radius: 8; border.color: Style.borderLight; color: Style.background }
                            }
                        }
                    }
                }

                // Salle (tous)
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6

                    SectionLabel { text: editGrid.editIsEvent ? "SALLE (OPTIONNEL)" : "SALLE" }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editSalleCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: schoolingController.salles
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            Component.onCompleted: {
                                if (root.editData) {
                                    for (var i = 0; i < count; i++) {
                                        if (model[i].id === root.editData.salleId) { currentIndex = i; break }
                                    }
                                }
                            }
                            onCurrentValueChanged: if (root.editData && currentIndex >= 0) root.editData.salleId = currentValue
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: editSalleCombo.currentIndex >= 0 ? editSalleCombo.displayText : "Sélectionner..."
                                font.pixelSize: 12; font.weight: Font.Bold
                                color: editSalleCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                            }

                            popup: Popup {
                                y: editSalleCombo.height - 1
                                width: editSalleCombo.width
                                implicitHeight: Math.min(editSallePopupCol.implicitHeight + 2, 200)
                                padding: 1

                                contentItem: Flickable {
                                    clip: true
                                    contentHeight: editSallePopupCol.implicitHeight
                                    flickableDirection: Flickable.VerticalFlick

                                    Column {
                                        id: editSallePopupCol
                                        width: parent.width

                                        Rectangle {
                                            width: parent.width; height: 34
                                            color: editSalleResetMa.containsMouse ? Style.bgSecondary : "transparent"
                                            visible: editGrid.editIsEvent

                                            Text {
                                                anchors.fill: parent; leftPadding: 12
                                                text: qsTr("Sélectionner...")
                                                font.pixelSize: 12; font.italic: true; font.bold: true
                                                color: Style.textTertiary; verticalAlignment: Text.AlignVCenter
                                            }
                                            MouseArea {
                                                id: editSalleResetMa
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { editSalleCombo.currentIndex = -1; if (root.editData) root.editData.salleId = 0; editSalleCombo.popup.close() }
                                            }
                                        }

                                        Repeater {
                                            model: schoolingController.salles
                                            Rectangle {
                                                width: editSallePopupCol.width; height: 34
                                                color: editSalleItemMa.containsMouse ? Style.bgSecondary : (editSalleCombo.currentIndex === index ? Style.bgPage : "transparent")
                                                Text {
                                                    anchors.fill: parent; leftPadding: 12
                                                    text: modelData.nom || ""
                                                    font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                MouseArea {
                                                    id: editSalleItemMa
                                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { editSalleCombo.currentIndex = index; editSalleCombo.popup.close() }
                                                }
                                            }
                                        }
                                    }
                                }

                                background: Rectangle { radius: 8; border.color: Style.borderLight; color: Style.background }
                            }
                        }
                    }
                }

                // Descriptif événement (lecture seule)
                Column {
                    Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 6
                    visible: editGrid.editIsEvent && root.editData && root.editData.descriptif

                    SectionLabel { text: qsTr("DESCRIPTIF") }
                    Rectangle {
                        width: parent.width; height: 60; radius: 10
                        color: Style.bgPage; border.color: Style.bgTertiary
                        Text {
                            anchors { fill: parent; margins: 10 }
                            text: root.editData ? (root.editData.descriptif || "") : ""
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textSecondary
                            wrapMode: Text.WordWrap; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Item { width: 1; height: 4 }

            RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: cancelEditMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent; text: qsTr("ANNULER")
                        font.pixelSize: 10; font.weight: Font.Black; color: Style.textSecondary
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: cancelEditMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.isEditing = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12

                    property bool editValid: {
                        if (!root.editData) return false
                        if (!editTimeInput.isValidTime) return false
                        if (editGrid.editIsEvent) return editSalleCombo.currentIndex >= 0
                        if (editGrid.editIsExam)  return editClasseCombo.currentIndex >= 0 && editSalleCombo.currentIndex >= 0
                        // Cours
                        return editProfCombo.currentIndex >= 0 && editClasseCombo.currentIndex >= 0 && editSalleCombo.currentIndex >= 0
                    }

                    opacity: editValid ? 1.0 : 0.5
                    color: !editValid ? Style.bgTertiary : saveEditMa.containsMouse ? Style.primaryDark : Style.primary
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent; text: qsTr("ENREGISTRER")
                        font.pixelSize: 10; font.weight: Font.Black; color: Style.background
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: saveEditMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: parent.editValid ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: parent.editValid
                        onClicked: {
                            if (root.editData) {
                                var origDate = root.editData.dateHeureDebut
                                var datePart = origDate.split("T")[0]
                                var newTime = editTimeInput.displayText || "08:00"
                                root.editData.dateHeureDebut = datePart + "T" + newTime + ":00"
                                examsController.updateExam(root.editData.id, root.editData)
                                root.isEditing = false
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
