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
                        text: "DESCRIPTIF"
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
                        anchors.centerIn: parent; text: "MODIFIER"
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
                    anchors.centerIn: parent; text: "ANNULER LA SUPPRESSION"
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
            width: parent.width - 64
            spacing: 16
            visible: root.isEditing

            property bool editIsEvent: root.editData ? root.editData.typeSeance === "Événement" : false
            property bool editIsExam: root.editData ? root.editData.typeSeance === "Examen" : false

            Text {
                text: "Modifier la Session"
                font.pixelSize: 20; font.weight: Font.Black; color: Style.textPrimary
            }

            GridLayout {
                id: editGrid
                width: parent.width
                columns: 2
                columnSpacing: 14
                rowSpacing: 14

                property bool editIsEvent: root.editData ? root.editData.typeSeance === "Événement" : false
                property bool editIsExam: root.editData ? root.editData.typeSeance === "Examen" : false

                // Titre (Examen & Événement)
                Column {
                    Layout.fillWidth: true
                    Layout.columnSpan: editGrid.editIsEvent ? 2 : 1
                    Layout.preferredWidth: 1
                    spacing: 6
                    visible: editGrid.editIsExam || editGrid.editIsEvent

                    SectionLabel { text: editGrid.editIsExam ? "TITRE DE L'ÉPREUVE" : "NOM DE L'ÉVÈNEMENT" }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        TextInput {
                            id: editTitreInput
                            anchors.fill: parent; anchors.margins: 10
                            text: root.editData ? (root.editData.titre || "") : ""
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textPrimary; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Niveau (Cours & Examen) — permet de filtrer matières et classes
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    visible: !editGrid.editIsEvent

                    SectionLabel { text: "NIVEAU" }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editNiveauCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: schoolingController.niveaux
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            Component.onCompleted: {
                                // Trouver le niveau de la classe actuelle
                                if (root.editData) {
                                    var classes = schoolingController.allClasses
                                    for (var c = 0; c < classes.length; c++) {
                                        if (classes[c].id === root.editData.classeId) {
                                            var niveauId = classes[c].niveauId
                                            for (var n = 0; n < count; n++) {
                                                if (model[n].id === niveauId) { currentIndex = n; break }
                                            }
                                            break
                                        }
                                    }
                                }
                            }
                            onCurrentValueChanged: {
                                if (currentIndex >= 0) {
                                    schoolingController.loadMatieresByNiveau(currentValue)
                                    schoolingController.loadClassesByNiveau(currentValue)
                                }
                            }
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: editNiveauCombo.currentIndex >= 0 ? editNiveauCombo.displayText : "Sélectionner..."
                                font.pixelSize: 12; font.weight: Font.Bold
                                color: editNiveauCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // Matière (Cours & Examen)
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    visible: !editGrid.editIsEvent

                    SectionLabel { text: "MATIÈRE" }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editMatiereCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: schoolingController.matieres
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            Component.onCompleted: {
                                if (root.editData) {
                                    for (var i = 0; i < count; i++) {
                                        if (model[i].id === root.editData.matiereId) { currentIndex = i; break }
                                    }
                                }
                            }
                            onCurrentValueChanged: if (root.editData && currentIndex >= 0) root.editData.matiereId = currentValue
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: editMatiereCombo.currentIndex >= 0 ? editMatiereCombo.displayText : "Sélectionner..."
                                font.pixelSize: 12; font.weight: Font.Bold
                                color: editMatiereCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // Classe (Cours & Examen)
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    visible: !editGrid.editIsEvent

                    SectionLabel { text: "CLASSE" }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editClasseCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: schoolingController.classes
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            Component.onCompleted: {
                                if (root.editData) {
                                    for (var i = 0; i < count; i++) {
                                        if (model[i].id === root.editData.classeId) { currentIndex = i; break }
                                    }
                                }
                            }
                            onCurrentValueChanged: if (root.editData && currentIndex >= 0) root.editData.classeId = currentValue
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: editClasseCombo.currentIndex >= 0 ? editClasseCombo.displayText : "Sélectionner..."
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
                                                text: "Sélectionner..."
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
                                                text: "Sélectionner..."
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

                // Heure
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    SectionLabel { text: "HEURE" }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        TextInput {
                            id: editTimeInput
                            anchors.fill: parent; anchors.margins: 10
                            text: {
                                if (root.editData && root.editData.dateHeureDebut) {
                                    var d = root.editData.dateHeureDebut
                                    if (typeof d === "string" && d.indexOf("T") >= 0)
                                        return d.split("T")[1].substring(0, 5)
                                }
                                return "08:00"
                            }
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textPrimary; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Durée
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    SectionLabel { text: "DURÉE (MIN)" }
                    Rectangle {
                        width: parent.width; height: 40; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight
                        TextInput {
                            id: editDureeInput
                            anchors.fill: parent; anchors.margins: 10
                            text: root.editData ? root.editData.dureeMinutes.toString() : "60"
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textPrimary; verticalAlignment: Text.AlignVCenter
                            inputMethodHints: Qt.ImhDigitsOnly
                        }
                    }
                }

                // Descriptif (Événement uniquement)
                Column {
                    Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 6
                    visible: editGrid.editIsEvent

                    SectionLabel { text: "DESCRIPTIF (OPTIONNEL)" }
                    Rectangle {
                        width: parent.width; height: 70; radius: 10
                        color: Style.bgPage; border.color: Style.borderLight

                        Flickable {
                            anchors.fill: parent; anchors.margins: 10
                            contentWidth: width; contentHeight: editDescriptifInput.implicitHeight
                            clip: true; flickableDirection: Flickable.VerticalFlick

                            TextEdit {
                                id: editDescriptifInput
                                width: parent.width
                                text: root.editData ? (root.editData.descriptif || "") : ""
                                font.pixelSize: 12; font.weight: Font.Bold
                                color: Style.textPrimary
                                wrapMode: TextEdit.Wrap; selectByMouse: true

                                Text {
                                    visible: !editDescriptifInput.text
                                    text: "Description de l'évènement..."
                                    font: editDescriptifInput.font
                                    color: Style.textTertiary
                                }
                            }
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
                        anchors.centerIn: parent; text: "ANNULER"
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
                        if (editGrid.editIsEvent)
                            return editTitreInput.text.length > 0
                        if (editGrid.editIsExam)
                            return editTitreInput.text.length > 0 && editMatiereCombo.currentIndex >= 0 && editClasseCombo.currentIndex >= 0 && editSalleCombo.currentIndex >= 0
                        // Cours
                        return editMatiereCombo.currentIndex >= 0 && editProfCombo.currentIndex >= 0 && editClasseCombo.currentIndex >= 0 && editSalleCombo.currentIndex >= 0
                    }

                    opacity: editValid ? 1.0 : 0.5
                    color: !editValid ? Style.bgTertiary : saveEditMa.containsMouse ? Style.primaryDark : Style.primary
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent; text: "ENREGISTRER"
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
                                var newTime = editTimeInput.text || "08:00"
                                root.editData.dateHeureDebut = datePart + "T" + newTime + ":00"
                                root.editData.dureeMinutes = parseInt(editDureeInput.text) || 60
                                root.editData.titre = editTitreInput.text || ""
                                root.editData.descriptif = editDescriptifInput.text || ""

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
