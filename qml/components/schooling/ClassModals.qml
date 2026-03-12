import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

Item {
    id: root
    anchors.fill: parent

    required property bool showCreate
    required property bool showEdit
    required property bool showDelete
    required property var editingClass
    required property int deletingClasseId
    required property string selectedNiveauNom
    required property int selectedNiveauId
    required property string activeAnneeScolaire

    // Students passed from parent to see existing assignments
    property var allStudents: studentController.students
    property var unassignedStudentsList: studentController.unassignedStudents

    signal createRequested(string nom, int niveauId, var studentIdsToAssign)
    signal editRequested(int id, string nom, int niveauId, var studentIdsToAssign, var studentIdsToRemove)
    signal deleteRequested(int id)
    signal closeRequested()

    // Internal state for managing assigned students in the modal
    property var currentAssignedStudents: [] // List of {id, nom, prenom, sexe, categorie}
    property var initiallyAssignedIds: []
    property var selectedSexe: "all"
    property var selectedCategorie: "all"
    property string selectedAnneeScolaire: root.activeAnneeScolaire
    property string searchText: ""
    property string qteText: "15"
    property string localClassNameText: ""
    property var pendingEditData: null
    property bool showEditConfirm: false

    function initEditState() {
        currentAssignedStudents = []
        initiallyAssignedIds = []
        if (root.showEdit && root.editingClass && root.editingClass.id > 0) {
            for (var i = 0; i < root.allStudents.length; i++) {
                if (root.allStudents[i].classeId === root.editingClass.id) {
                    currentAssignedStudents.push(root.allStudents[i])
                    initiallyAssignedIds.push(root.allStudents[i].id)
                }
            }
        }
        currentAssignedStudentsChanged()
    }

    function resetFilters() {
        selectedSexe = "all"
        selectedCategorie = "all"
        selectedAnneeScolaire = root.activeAnneeScolaire
        searchText = ""
        qteText = "15"
    }

    onShowCreateChanged: {
        if (showCreate) {
            resetFilters()
            currentAssignedStudents = []
            initiallyAssignedIds = []
            localClassNameText = ""
        }
    }

    onShowEditChanged: {
        if (showEdit) {
            console.log("[ClassModals] onShowEdit: editingClass=" + JSON.stringify(root.editingClass)
                + " selectedNiveauId=" + root.selectedNiveauId)
            resetFilters()
            initEditState()
            localClassNameText = root.editingClass.nom
        }
    }

    function reloadUnassigned() {
        console.log("[ClassModals] reloadUnassigned: selectedNiveauId=" + root.selectedNiveauId
            + " sexe=" + selectedSexe + " categorie=" + selectedCategorie)
        studentController.loadUnassignedStudents(root.selectedNiveauId, selectedSexe, selectedCategorie)
    }

    // Assign multiple randomly
    function autoFill(count) {
        var available = []
        // Filter out those already in currentAssignedStudents
        for (var i = 0; i < unassignedStudentsList.length; i++) {
            var st = unassignedStudentsList[i]
            var alreadyAdded = false
            for (var j = 0; j < currentAssignedStudents.length; j++) {
                if (currentAssignedStudents[j].id === st.id) {
                    alreadyAdded = true; break;
                }
            }
            if (!alreadyAdded) available.push(st)
        }

        // Shuffle
        for (var k = available.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1));
            var temp = available[k];
            available[k] = available[j];
            available[j] = temp;
        }

        var toAdd = Math.min(count, available.length)
        var newAssigned = currentAssignedStudents.slice()
        for (var n = 0; n < toAdd; n++) {
            newAssigned.push(available[n])
        }
        currentAssignedStudents = newAssigned
        currentAssignedStudentsChanged() // Force UI update
    }

    function removeStudentFromSelection(studentId) {
        var newAssigned = []
        for (var i = 0; i < currentAssignedStudents.length; i++) {
            if (currentAssignedStudents[i].id !== studentId) {
                newAssigned.push(currentAssignedStudents[i])
            }
        }
        currentAssignedStudents = newAssigned
        currentAssignedStudentsChanged()
    }

    function addStudentToSelection(studentObj) {
        // check if already added
        for (var i = 0; i < currentAssignedStudents.length; i++) {
            if (currentAssignedStudents[i].id === studentObj.id) return;
        }
        var newAssigned = currentAssignedStudents.slice()
        newAssigned.push(studentObj)
        currentAssignedStudents = newAssigned
        currentAssignedStudentsChanged()
    }

    Component {
        id: classModalContent
        
        Item {
            anchors.fill: parent
            
            // Left panel: Class info
            Item {
                width: 280
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16
                    
                    Text {
                        text: (root.showCreate ? "Nouveau Groupe" : "Modifier le Groupe")
                        font.pixelSize: 20
                        font.weight: Font.Black
                        color: Style.textPrimary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: qsTr("Niveau : ") + root.selectedNiveauNom
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Style.primary
                    }

                    FormField {
                        id: localClassNameField
                        Layout.fillWidth: true
                        label: qsTr("NOM DU GROUPE")
                        placeholder: qsTr("ex: A, Matin...")
                        text: root.localClassNameText
                        onTextChanged: root.localClassNameText = text
                    }
                    
                    Separator { Layout.fillWidth: true; anchors.leftMargin: -12; anchors.rightMargin: -12 }
                    
                    Text { text: qsTr("FILTRAGE"); font.pixelSize: 10; font.weight: Font.Black; color: Style.primary; font.letterSpacing: 1 }

                    Column {
                        Layout.fillWidth: true; spacing: 4
                        SectionLabel { text: qsTr("ANNÉE SCOLAIRE") }
                        Rectangle {
                            width: parent.width; height: 40; radius: 10
                            color: Style.bgSecondary; border.color: Style.borderLight
                            Text {
                                anchors.fill: parent; anchors.leftMargin: 12
                                text: root.activeAnneeScolaire || "—"
                                font.pixelSize: 13; font.bold: true
                                color: Style.textSecondary
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: qsTr("SEXE") }
                            Rectangle {
                                width: parent.width; height: 40; radius: 10
                                color: Style.bgPage; border.color: Style.borderLight
                                ComboBox {
                                    id: sexeCombo; anchors.fill: parent; anchors.margins: 2
                                    model: ["Mixte", "Garçons", "Filles"];
                                    currentIndex: root.selectedSexe === "M" ? 1 : (root.selectedSexe === "F" ? 2 : 0)
                                    background: Rectangle { color: "transparent" }
                                    contentItem: Text {
                                        text: sexeCombo.displayText; font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                        verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight
                                    }
                                    onActivated: { 
                                        root.selectedSexe = (currentIndex === 0) ? "all" : (currentIndex === 1 ? "M" : "F")
                                        root.reloadUnassigned()
                                    }
                                }
                            }
                        }
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: qsTr("CATÉGORIE") }
                            Rectangle {
                                width: parent.width; height: 40; radius: 10
                                color: Style.bgPage; border.color: Style.borderLight
                                ComboBox {
                                    id: catCombo; anchors.fill: parent; anchors.margins: 2
                                    model: ["Toutes", "Jeune", "Adulte"];
                                    currentIndex: root.selectedCategorie === "Jeune" ? 1 : (root.selectedCategorie === "Adulte" ? 2 : 0)
                                    background: Rectangle { color: "transparent" }
                                    contentItem: Text {
                                        text: catCombo.displayText; font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                        verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight
                                    }
                                    onActivated: { 
                                        root.selectedCategorie = (currentIndex === 0) ? "all" : (currentIndex === 1 ? "Jeune" : "Adulte")
                                        root.reloadUnassigned()
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: qsTr("QTÉ") }
                            Rectangle {
                                width: parent.width; height: 40; radius: 10
                                color: Style.bgPage; border.color: Style.borderLight
                                TextInput {
                                    id: qteInput; anchors.fill: parent; anchors.margins: 4
                                    text: root.qteText; font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                    onTextChanged: root.qteText = text
                                }
                            }
                        }
                        PrimaryButton {
                            Layout.alignment: Qt.AlignBottom
                            Layout.fillWidth: true; Layout.preferredWidth: 2; Layout.preferredHeight: 40
                            text: qsTr("Auto Remplissage")
                            onClicked: {
                                var qte = parseInt(qteInput.text) || 0
                                if (qte > 0) root.autoFill(qte)
                            }
                        }
                    }
                    
                    Text {
                        text: root.unassignedStudentsList.length + " élèves non assignés disponibles."
                        font.pixelSize: 11; color: Style.textSecondary; Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }

                    Item { height: 1; width: 1; Layout.fillHeight: true } // Spacer
                    
                    Text {
                        text: qsTr("Total inscrits : ") + currentAssignedStudents.length
                        font.pixelSize: 14
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 280
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Style.borderLight
            }
            
            // Right panel: Student Assignment
            Item {
                anchors.left: parent.left
                anchors.leftMargin: 281
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 20
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Affectation des Étudiants")
                            font.pixelSize: 18
                            font.weight: Font.Black
                            color: Style.textPrimary
                            Layout.fillWidth: true
                        }
                        IconButton { iconName: "close"; iconSize: 18; onClicked: root.closeRequested() }
                    }
                    
                    // Search & Manual add
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        SearchField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholder: qsTr("Chercher un élève non assigné...")
                            text: root.searchText
                            onTextChanged: root.searchText = text
                        }
                    }

                    // Matching search results (dropdown overlay-like, but inline for simplicity)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.min(150, searchRepeater.count * 40 + 8)
                        visible: root.searchText.trim().length > 0 && searchRepeater.count > 0
                        color: Style.bgPage; radius: 12; border.color: Style.borderLight
                        clip: true
                        
                        Flickable {
                            anchors.fill: parent; anchors.margins: 4
                            contentHeight: searchCol.height
                            Column {
                                id: searchCol; width: parent.width
                                Repeater {
                                    id: searchRepeater
                                    model: {
                                        var query = root.searchText.trim().toLowerCase()
                                        var res = []
                                        if (query === "") return res
                                        for (var i = 0; i < root.unassignedStudentsList.length; i++) {
                                            var st = root.unassignedStudentsList[i]
                                            var nomComplet = (st.prenom + " " + st.nom).toLowerCase()
                                            if (nomComplet.indexOf(query) !== -1 || st.id.toString().indexOf(query) !== -1) {
                                                // Check if already assigned
                                                var added = false
                                                for (var j = 0; j < root.currentAssignedStudents.length; j++) {
                                                    if (root.currentAssignedStudents[j].id === st.id) { added = true; break; }
                                                }
                                                if (!added) res.push(st)
                                            }
                                        }
                                        return res
                                    }
                                    delegate: Rectangle {
                                        width: parent.width; height: 40; radius: 8
                                        color: smHover.containsMouse ? Style.bgSecondary : "transparent"
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                                            Text { text: modelData.prenom + " " + modelData.nom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
                                            Text { text: modelData.id; font.pixelSize: 11; color: Style.textTertiary; Layout.alignment: Qt.AlignVCenter }
                                            IconLabel { iconName: "plus"; iconSize: 14; iconColor: Style.primary; Layout.alignment: Qt.AlignVCenter }
                                        }
                                        MouseArea {
                                            id: smHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { root.addStudentToSelection(modelData); root.searchText = "" }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Assigned students list
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: Style.bgPage; radius: 16; border.color: Style.borderLight
                        
                        Flickable {
                            anchors.fill: parent; anchors.margins: 8; clip: true
                            contentHeight: assignedCol.height
                            Column {
                                id: assignedCol; width: parent.width; spacing: 4
                                Repeater {
                                    model: root.currentAssignedStudents
                                    delegate: Rectangle {
                                        width: parent.width; height: 44; radius: 12
                                        color: Style.bgWhite; border.color: Style.borderLight
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                                            Avatar { initials: modelData.nom.charAt(0); size: 24; Layout.alignment: Qt.AlignVCenter }
                                            Text { text: modelData.prenom + " " + modelData.nom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
                                            Badge { text: modelData.sexe === "F" ? "F" : "M"; customBgColor: modelData.sexe === "F" ? Style.errorColor : Style.primary; customTextColor: Style.background; customBorderColor: "transparent"; Layout.alignment: Qt.AlignVCenter }
                                            Badge { text: modelData.categorie; variant: "neutral"; Layout.alignment: Qt.AlignVCenter }
                                            IconButton {
                                                iconName: "close"; iconSize: 14; hoverColor: Style.errorColor; Layout.alignment: Qt.AlignVCenter
                                                onClicked: root.removeStudentFromSelection(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            visible: root.currentAssignedStudents.length === 0
                            text: qsTr("Aucun élève affecté au groupe.")
                            font.pixelSize: 13; color: Style.textTertiary; font.italic: true
                        }
                    }

                    // Actions
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Item { Layout.fillWidth: true }
                        OutlineButton { text: qsTr("ANNULER"); onClicked: root.closeRequested() }
                        PrimaryButton {
                            text: root.showCreate ? "CRÉER LE GROUPE" : "ENREGISTRER"
                            onClicked: {
                                var currentIds = []
                                for (var i = 0; i < currentAssignedStudents.length; i++) {
                                    currentIds.push(currentAssignedStudents[i].id)
                                }
                                
                                if (root.showCreate) {
                                    if (root.localClassNameText.trim() !== "" && root.selectedNiveauId > 0) {
                                        root.createRequested(root.localClassNameText.trim(), root.selectedNiveauId, currentIds)
                                    }
                                } else {
                                    if (root.localClassNameText.trim() !== "" && root.editingClass.id > 0) {
                                        var idsToRemove = []
                                        for (var j = 0; j < initiallyAssignedIds.length; j++) {
                                            if (currentIds.indexOf(initiallyAssignedIds[j]) === -1) {
                                                idsToRemove.push(initiallyAssignedIds[j])
                                            }
                                        }
                                        var idsToAdd = []
                                        for (var k = 0; k < currentIds.length; k++) {
                                            if (initiallyAssignedIds.indexOf(currentIds[k]) === -1) {
                                                idsToAdd.push(currentIds[k])
                                            }
                                        }
                                        
                                        var hasChanges = (root.localClassNameText.trim() !== root.editingClass.nom) || (idsToRemove.length > 0) || (idsToAdd.length > 0)
                                        
                                        if (hasChanges) {
                                            root.pendingEditData = {
                                                id: root.editingClass.id,
                                                nom: root.localClassNameText.trim(),
                                                niveauId: root.selectedNiveauId,
                                                idsToAdd: idsToAdd,
                                                idsToRemove: idsToRemove
                                            }
                                            root.showEditConfirm = true
                                        } else {
                                            root.closeRequested()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Modal wrapper for Create & Edit
    Popup {
        id: fullModal
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 800
        height: 600
        modal: true
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: root.showCreate || root.showEdit

        onOpened: root.reloadUnassigned()
        onClosed: root.closeRequested()
        
        background: Rectangle {
            radius: 24
            color: Style.bgWhite
            clip: true
        }

        contentItem: Loader {
            sourceComponent: classModalContent
        }
    }

    // ─── Confirmation Modification Classe ───
    ModalOverlay {
        id: editConfirmPopup
        show: root.showEditConfirm
        modalWidth: 460
        onClose: root.showEditConfirm = false
        
        Column {
            width: parent.width
            spacing: 24
            padding: 32

            Text {
                text: qsTr("Confirmer les modifications")
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Text {
                width: parent.width - 64
                text: qsTr("Vous avez modifié les informations de ce groupe. Voulez-vous enregistrer ces changements ?")
                font.pixelSize: 14
                color: Style.textSecondary
                wrapMode: Text.WordWrap
                lineHeight: 1.4
            }

            ModalButtons {
                width: parent.width - 64
                cancelText: qsTr("ANNULER")
                confirmText: qsTr("CONFIRMER")
                confirmColor: Style.primary
                onCancel: root.showEditConfirm = false
                onConfirm: {
                    if (root.pendingEditData) {
                        root.editRequested(
                            root.pendingEditData.id,
                            root.pendingEditData.nom,
                            root.pendingEditData.niveauId,
                            root.pendingEditData.idsToAdd,
                            root.pendingEditData.idsToRemove
                        )
                        root.pendingEditData = null
                    }
                    root.showEditConfirm = false
                }
            }
        }
    }

    // ─── Confirmation Suppression Classe ───
    Popup {
        id: deleteClassConfirmPopup
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 420
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: root.showDelete

        onVisibleChanged: {
            if (!visible) root.closeRequested()
        }

        background: Rectangle {
            radius: 20
            color: Style.bgWhite
            border.color: Style.borderLight
        }

        Column {
            width: parent.width
            spacing: 20
            padding: 28

            Text {
                text: qsTr("Supprimer la classe ?")
                font.pixelSize: 18
                font.weight: Font.Black
                color: Style.textPrimary
            }

            Text {
                width: parent.width - 56
                text: qsTr("Les élèves de cette classe seront retirés de la classe mais resteront dans la base de données.")
                font.pixelSize: 13
                color: Style.textSecondary
                wrapMode: Text.WordWrap
            }

            RowLayout {
                width: parent.width - 56
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("ANNULER")
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: Style.textSecondary
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: Style.errorColor

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("SUPPRIMER")
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: Style.background
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.deletingClasseId > 0) {
                                root.deleteRequested(root.deletingClasseId)
                            }
                        }
                    }
                }
            }
        }
    }
}
