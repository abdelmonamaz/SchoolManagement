import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
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
    property int deletingMatiereId: 0
    property bool showEditRoomModal: false
    property var editingRoom: ({id: 0, nom: "", capaciteChaises: 20, equipement: ""})
    property bool showDeleteRoomConfirm: false
    property int deletingRoomId: 0
    property bool showManageEquipmentsModal: false

    Component.onCompleted: {
        schoolingController.loadNiveaux()
        schoolingController.loadSalles()
        schoolingController.loadEquipements()
        studentController.loadStudents()
    }

    Connections {
        target: schoolingController
        function onNiveauxChanged() {
            if (selectedNiveauId < 0 && schoolingController.niveaux.length > 0)
                selectNiveau(schoolingController.niveaux[0].id)
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
        function onOperationFailed(err) { console.warn("SchoolingPage error:", err) }
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
                title: "Architecture Académique"
                subtitle: "Configuration des niveaux, des matières et de la logistique."
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
                            text: "NIVEAUX & MATIÈRES"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: activeTab === "levels" ? "#FFFFFF" : Style.textTertiary
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
                            text: "GESTION DES SALLES"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: activeTab === "rooms" ? "#FFFFFF" : Style.textTertiary
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
                        onNiveauEditRequested: (id, nom) => {
                            schoolPage.editingNiveau = {id: id, nom: nom}
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
                            onMatiereCreateRequested: (nom) => schoolingController.createMatiere(nom, selectedNiveauId)
                            onMatiereDeleteRequested: (id) => {
                                schoolPage.deletingMatiereId = id
                                schoolPage.showDeleteMatiereConfirm = true
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
        onEditRequested: (id, nom) => {
            schoolingController.updateNiveau(id, nom)
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
        deletingMatiereId: schoolPage.deletingMatiereId

        onDeleteRequested: (id) => {
            schoolingController.deleteMatiere(id)
            showDeleteMatiereConfirm = false
        }
        onCloseRequested: showDeleteMatiereConfirm = false
    }

    ClassModals {
        showCreate: showClassModal
        showEdit: showEditClassModal
        showDelete: showDeleteClassConfirm
        editingClass: schoolPage.editingClass
        deletingClasseId: schoolPage.deletingClasseId
        selectedNiveauNom: schoolPage.selectedNiveauNom()
        selectedNiveauId: schoolPage.selectedNiveauId

        onCreateRequested: (nom, niveauId) => {
            schoolingController.createClasse(nom, niveauId)
            showClassModal = false
        }
        onEditRequested: (id, nom, niveauId) => {
            schoolingController.updateClasse(id, nom, niveauId)
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
