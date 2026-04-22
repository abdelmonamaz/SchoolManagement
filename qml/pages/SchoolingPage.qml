import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.settings 1.0
import UI.Components

Item {
    id: schoolPage
    implicitHeight: mainLayout.implicitHeight

    property string activeTab: "levels"
    property int selectedNiveauId: -1
    property bool showRoomModal: false
    property bool showClassModal: false
    property bool showEditClassModal: false
    property var editingClass: ({id: 0, nom: ""})
    property var selectedEquipments: []
    property bool showClassStudentsPopup: false
    property int classPopupClasseId: 0
    property string classPopupClasseNom: ""
    property bool showDeleteClassConfirm: false
    property int deletingClasseId: 0
    property bool showNiveauModal: false
    property bool showEditNiveauModal: false
    property var editingNiveau: ({id: 0, nom: ""})
    property bool showDeleteNiveauConfirm: false
    property int deletingNiveauId: 0
    property bool showDeleteMatiereConfirm: false
    property var  deletingMatiereIds: []
    property bool showEditMatiereModal: false
    // Groupe de matière en cours d'édition (1 ou 2 enregistrements pour bi-semestre)
    property var  editingMatiereGroup: ({ nom: "", ids: [], semestres: [], niveauId: 0, coefficient: 1.0, nombreSeances: 0, dureeSeanceMinutes: 60 })
    property bool showEditRoomModal: false
    property var editingRoom: ({id: 0, nom: "", capaciteChaises: 20, equipement: ""})
    property bool showDeleteRoomConfirm: false
    property int deletingRoomId: 0
    property bool showManageEquipmentsModal: false

    Component.onCompleted: {
        console.log("[SchoolingPage] onCompleted — loadNiveaux")
        schoolingController.loadNiveaux()
        schoolingController.loadSalles()
        schoolingController.loadEquipements()
        studentController.loadStudents()
    }

    // Rechargement des matières du niveau courant quand on revient sur cette page
    // (un autre onglet, ex. SessionFormModal, peut avoir écrasé schoolingController.matieres)
    onVisibleChanged: {
        if (visible && selectedNiveauId > 0)
            schoolingController.loadMatieresByNiveau(selectedNiveauId)
    }

    Connections {
        target: schoolingController
        function onNiveauxChanged() {
            var ids = schoolingController.niveaux.map(function(n){ return n.id + "(" + n.nom + ")" })
            console.log("[SchoolingPage] onNiveauxChanged:", ids.join(", "),
                        "| selectedNiveauId=", selectedNiveauId)
            if (selectedNiveauId < 0 && schoolingController.niveaux.length > 0)
                selectNiveau(schoolingController.niveaux[0].id)
        }
        function onClassesChanged() {
            var ids = schoolingController.classes.map(function(c){ return c.id + "(" + c.nom + ",niv=" + c.niveauId + ")" })
            console.log("[SchoolingPage] onClassesChanged:", ids.join(", "))
        }
        function onOperationSucceeded(msg) {
            console.log("SchoolingPage:", msg)
            schoolingController.loadNiveaux()
            schoolingController.loadSalles()
            schoolingController.loadAllClasses()
            studentController.loadStudents()
            if (selectedNiveauId > 0) {
                schoolingController.loadClassesByNiveau(selectedNiveauId)
                schoolingController.loadMatieresByNiveau(selectedNiveauId)
            }
        }
        function onClasseCreated(classeId) {
            if (classModals && classModals.pendingStudentsToAssign && classModals.pendingStudentsToAssign.length > 0) {
                if (classModals.pendingIsHall)
                    studentController.assignMultipleStudentsToHallClasse(classModals.pendingStudentsToAssign, classeId)
                else
                    studentController.assignMultipleStudentsToClasse(classModals.pendingStudentsToAssign, classeId)
                classModals.pendingStudentsToAssign = []
                classModals.pendingIsHall = false
            }
        }
        function onOperationFailed(err) { console.warn("SchoolingPage error:", err) }
    }

    Connections {
        target: yearClosureController
        function onClosureSuccess(newYearLabel) {
            console.log("[SchoolingPage] onClosureSuccess:", newYearLabel, "— reset selectedNiveauId, reload niveaux")
            selectedNiveauId = -1
            schoolingController.loadNiveaux()
            schoolingController.loadSalles()
            schoolingController.loadEquipements()
            studentController.loadStudents()
        }
    }

    Connections {
        target: studentController
        function onStudentsChanged() {
            var cnt = 0
            var sts = studentController.students
            for (var i = 0; i < sts.length; i++)
                if (sts[i].classeId === classPopupClasseId) cnt++
            console.log("SchoolingPage studentsChanged: " + cnt + " élève(s) dans classe", classPopupClasseId)
        }
        function onOperationSucceeded(msg) { console.log("SchoolingPage studentController OK:", msg) }
        function onOperationFailed(err) { console.warn("SchoolingPage studentController ERREUR:", err) }
    }

    function selectNiveau(niveauId) {
        console.log("[SchoolingPage] selectNiveau:", niveauId)
        selectedNiveauId = niveauId
        schoolingController.loadClassesByNiveau(niveauId)
        schoolingController.loadMatieresByNiveau(niveauId)
    }

    function selectedNiveauNom() {
        var list = schoolingController.niveaux
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === selectedNiveauId) return list[i].nom
        }
        return ""
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true

            PageHeader {
                Layout.fillWidth: true
                title: qsTr("Architecture Académique")
                subtitle: qsTr("Configuration des niveaux, des matières et de la logistique.")
            }

            Rectangle {
                implicitWidth: tabRow.implicitWidth + 16
                height: 42
                radius: 16
                color: Style.bgSecondary
                border.color: Style.borderLight

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        width: levelsTabLabel.implicitWidth + 32
                        height: 34
                        radius: 12
                        color: activeTab === "levels" ? Style.primary : "transparent"

                        Text {
                            id: levelsTabLabel
                            anchors.centerIn: parent
                            text: qsTr("NIVEAUX & MATIÈRES")
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: activeTab === "levels" ? Style.background : Style.textTertiary
                            font.letterSpacing: 0.5
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = "levels"
                        }
                    }

                    Rectangle {
                        width: roomsTabLabel.implicitWidth + 32
                        height: 34
                        radius: 12
                        color: activeTab === "rooms" ? Style.primary : "transparent"

                        Text {
                            id: roomsTabLabel
                            anchors.centerIn: parent
                            text: qsTr("GESTION DES SALLES")
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: activeTab === "rooms" ? Style.background : Style.textTertiary
                            font.letterSpacing: 0.5
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = "rooms"
                        }
                    }
                }
            }
        }

        // ─── Levels Tab Content ───
        Loader {
            Layout.fillWidth: true
            active: activeTab === "levels"
            visible: active

            sourceComponent: Component {
                RowLayout {
                    spacing: 24

                    LevelSidebar {
                        Layout.alignment: Qt.AlignTop
                        niveaux: schoolingController.niveaux
                        selectedNiveauId: schoolPage.selectedNiveauId
                        onNiveauSelected: (niveauId) => schoolPage.selectNiveau(niveauId)
                        onNiveauEditRequested: (id, nom, isFreestyle) => {
                            schoolPage.editingNiveau = {id: id, nom: nom, isFreestyle: isFreestyle}
                            schoolPage.showEditNiveauModal = true
                        }
                        onNiveauDeleteRequested: (id) => {
                            schoolPage.deletingNiveauId = id
                            schoolPage.showDeleteNiveauConfirm = true
                        }
                        onNiveauAddRequested: schoolPage.showNiveauModal = true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 24

                        SubjectsSection {
                            Layout.fillWidth: true
                            matieres: schoolingController.matieres
                            selectedNiveauNom: schoolPage.selectedNiveauNom()
                            selectedNiveauId: schoolPage.selectedNiveauId
                            onMatiereCreateRequested: (nom, semestreNumero, coefficient, nombreSeances, dureeSeanceMinutes) =>
                                schoolingController.createMatiere(nom, selectedNiveauId, semestreNumero, coefficient, nombreSeances, dureeSeanceMinutes)
                            onMatiereDeleteRequested: (ids) => {
                                schoolPage.deletingMatiereIds = ids
                                schoolPage.showDeleteMatiereConfirm = true
                            }
                            onMatiereEditRequested: (group) => {
                                schoolPage.editingMatiereGroup = group
                                // Charge les examens du premier enregistrement du groupe
                                if (group.ids && group.ids.length > 0)
                                    schoolingController.loadMatiereExamens(group.ids[0])
                                schoolPage.showEditMatiereModal = true
                            }
                        }

                        ClassesSection {
                            Layout.fillWidth: true
                            classes: schoolingController.classes
                            students: studentController.students
                            selectedNiveauNom: schoolPage.selectedNiveauNom()
                            onClassCardClicked: (classeId, classeNom) => {
                                schoolPage.classPopupClasseId = classeId
                                schoolPage.classPopupClasseNom = classeNom
                                schoolPage.showClassStudentsPopup = true
                            }
                            onClassEditRequested: (id, nom) => {
                                schoolPage.editingClass = {id: id, nom: nom}
                                schoolPage.showEditClassModal = true
                            }
                            onClassDeleteRequested: (id) => {
                                schoolPage.deletingClasseId = id
                                schoolPage.showDeleteClassConfirm = true
                            }
                            onClassAddRequested: schoolPage.showClassModal = true
                        }
                    }
                }
            }
        }

        // ─── Rooms Tab Content ───
        Loader {
            Layout.fillWidth: true
            active: activeTab === "rooms"
            visible: active

            sourceComponent: Component {
                RoomsSection {
                    salles: schoolingController.salles
                    onRoomAddRequested: schoolPage.showRoomModal = true
                    onRoomEditRequested: (id, nom, capaciteChaises, equipement) => {
                        schoolPage.editingRoom = {
                            id: id,
                            nom: nom,
                            capaciteChaises: capaciteChaises,
                            equipement: equipement
                        }
                        schoolPage.showEditRoomModal = true
                    }
                    onRoomDeleteRequested: (id) => {
                        schoolPage.deletingRoomId = id
                        schoolPage.showDeleteRoomConfirm = true
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }

    // ─── All Modals ───
    NiveauModals {
        showCreate: showNiveauModal
        showEdit: showEditNiveauModal
        showDelete: showDeleteNiveauConfirm
        editingNiveau: schoolPage.editingNiveau
        deletingNiveauId: schoolPage.deletingNiveauId

        onCreateRequested: (nom) => {
            schoolingController.createNiveau(nom)
            showNiveauModal = false
        }
        onEditRequested: (id, nom, parentLevelId, isFreestyle) => {
            schoolingController.updateNiveau(id, nom, parentLevelId, isFreestyle)
            showEditNiveauModal = false
        }
        onDeleteRequested: (id) => {
            schoolingController.deleteNiveau(id)
            showDeleteNiveauConfirm = false
        }
        onCloseRequested: {
            showNiveauModal = false
            showEditNiveauModal = false
            showDeleteNiveauConfirm = false
        }
    }

    MatiereDeleteModal {
        show: showDeleteMatiereConfirm
        deletingMatiereIds: schoolPage.deletingMatiereIds

        onDeleteRequested: (ids) => {
            schoolingController.deleteMatieres(ids)
            showDeleteMatiereConfirm = false
        }
        onCloseRequested: showDeleteMatiereConfirm = false
    }

    MatiereEditModal {
        show:              showEditMatiereModal
        // ID principal = premier id du groupe (utilisé pour le chargement des examens)
        editingMatiereId:  schoolPage.editingMatiereGroup.ids && schoolPage.editingMatiereGroup.ids.length > 0
                               ? schoolPage.editingMatiereGroup.ids[0] : 0
        // Tous les IDs et semestres du groupe
        initialMatiereIds: schoolPage.editingMatiereGroup.ids    || []
        initialSemestres:  schoolPage.editingMatiereGroup.semestres || [1]
        editingNiveauId:   schoolPage.editingMatiereGroup.niveauId || schoolPage.selectedNiveauId
        initialNom:             schoolPage.editingMatiereGroup.nom             || ""
        initialNombreSeances:   schoolPage.editingMatiereGroup.nombreSeances   || 0
        initialDureeMinutes:    schoolPage.editingMatiereGroup.dureeSeanceMinutes > 0
                                    ? schoolPage.editingMatiereGroup.dureeSeanceMinutes : 60
        initialCoefficient:     schoolPage.editingMatiereGroup.coefficient > 0
                                    ? schoolPage.editingMatiereGroup.coefficient : 1.0

        onSaveRequested: (data) => {
            // data.allIds          : IDs initiaux du groupe
            // data.initialSemestres: semestres correspondants aux IDs initiaux
            // data.selectedSemestres: semestres souhaités après modification
            var allIds         = data.allIds         || []
            var initSems       = data.initialSemestres || []
            var selectedSems   = data.selectedSemestres || [1]

            // Construire une map semestreNumero → id existant
            var idBySem = {}
            for (var i = 0; i < allIds.length; i++)
                idBySem[initSems[i]] = allIds[i]

            var updateData = {
                nom:                data.nom,
                niveauId:           data.niveauId,
                nombreSeances:      data.nombreSeances,
                dureeSeanceMinutes: data.dureeSeanceMinutes,
                coefficient:        data.coefficient
            }

            // Semestres conservés → mettre à jour l'enregistrement existant
            for (var j = 0; j < initSems.length; j++) {
                var s = initSems[j]
                if (selectedSems.indexOf(s) >= 0)
                    schoolingController.updateMatiere(idBySem[s], updateData)
                else
                    // Semestre supprimé → supprimer l'enregistrement
                    schoolingController.deleteMatiere(idBySem[s])
            }

            // Nouveaux semestres → cloner depuis un enregistrement existant (copie les épreuves)
            var sourceId = allIds.length > 0 ? allIds[0] : -1
            for (var k = 0; k < selectedSems.length; k++) {
                var ns = selectedSems[k]
                if (initSems.indexOf(ns) < 0) {
                    if (sourceId >= 0)
                        schoolingController.cloneMatiereForSemestre(
                            sourceId, data.nom, data.niveauId, ns,
                            data.coefficient, data.nombreSeances, data.dureeSeanceMinutes)
                    else
                        schoolingController.createMatiere(
                            data.nom, data.niveauId, ns,
                            data.coefficient, data.nombreSeances, data.dureeSeanceMinutes)
                }
            }

            showEditMatiereModal = false
        }
        onCloseRequested: showEditMatiereModal = false
    }

    ClassModals {
        id: classModals
        showCreate: showClassModal
        showEdit: showEditClassModal
        showDelete: showDeleteClassConfirm
        editingClass: schoolPage.editingClass
        deletingClasseId: schoolPage.deletingClasseId
        selectedNiveauNom: schoolPage.selectedNiveauNom()
        selectedNiveauId: schoolPage.selectedNiveauId
        activeAnneeScolaire: setupController.activeTarifs ? (setupController.activeTarifs.libelle || "") : ""
        niveaux: schoolingController.niveaux

        property var pendingStudentsToAssign: []
        property bool pendingIsHall: false

        onCreateRequested: (nom, niveauId, studentIdsToAssign) => {
            pendingStudentsToAssign = studentIdsToAssign || []
            pendingIsHall = classModals.selectedNiveauIsFreestyle
            schoolingController.createClasse(nom, niveauId)
            showClassModal = false
        }
        onEditRequested: (id, nom, niveauId, studentIdsToAdd, studentIdsToRemove) => {
            schoolingController.updateClasse(id, nom, niveauId)

            var isHall = classModals.selectedNiveauIsFreestyle
            if (studentIdsToRemove && studentIdsToRemove.length > 0) {
                for (var j = 0; j < studentIdsToRemove.length; j++) {
                    if (isHall)
                        studentController.removeStudentFromHallClasse(studentIdsToRemove[j])
                    else
                        studentController.removeStudentFromClasse(studentIdsToRemove[j])
                }
            }
            if (studentIdsToAdd && studentIdsToAdd.length > 0) {
                if (isHall)
                    studentController.assignMultipleStudentsToHallClasse(studentIdsToAdd, id)
                else
                    studentController.assignMultipleStudentsToClasse(studentIdsToAdd, id)
            }

            showEditClassModal = false
        }
        onDeleteRequested: (id) => {
            studentController.unassignStudentsFromClasse(id)
            schoolingController.deleteClasse(id)
            showDeleteClassConfirm = false
        }
        onCloseRequested: {
            showClassModal = false
            showEditClassModal = false
            showDeleteClassConfirm = false
        }
    }

    ClassStudentsPopup {
        show: showClassStudentsPopup
        classeId: classPopupClasseId
        classeNom: classPopupClasseNom
        students: studentController.students

        onCloseRequested: showClassStudentsPopup = false
        onStudentViewRequested: (studentId) => {
            var win = schoolPage.ApplicationWindow.window
            if (win) {
                win.pendingStudentId = studentId
                win.currentPage = "students"
            }
        }
        onStudentRemoveRequested: (studentId) => {
            studentController.removeStudentFromClasse(studentId)
        }
    }

    RoomModals {
        showCreate: showRoomModal
        showEdit: showEditRoomModal
        showDelete: showDeleteRoomConfirm
        editingRoom: schoolPage.editingRoom
        deletingRoomId: schoolPage.deletingRoomId
        availableEquipments: schoolingController.equipements
        selectedEquipments: schoolPage.selectedEquipments

        onCreateRequested: (data) => {
            schoolingController.createSalle(data)
            showRoomModal = false
        }
        onEditRequested: (id, data) => {
            schoolingController.updateSalle(id, data)
            showEditRoomModal = false
        }
        onDeleteRequested: (id) => {
            schoolingController.deleteSalle(id)
            showDeleteRoomConfirm = false
        }
        onCloseRequested: {
            showRoomModal = false
            showEditRoomModal = false
            showDeleteRoomConfirm = false
        }
        onManageEquipmentsRequested: showManageEquipmentsModal = true
    }

    ManageEquipmentsModal {
        show: showManageEquipmentsModal
        availableEquipments: schoolingController.equipements

        onEquipmentAdded: (name) => {
            schoolingController.createEquipement(name)
        }
        onEquipmentDeleted: (index) => {
            var equip = schoolingController.equipements[index]
            if (equip && equip.id) {
                schoolingController.deleteEquipement(equip.id)
            }
        }
        onCloseRequested: showManageEquipmentsModal = false
    }
}
