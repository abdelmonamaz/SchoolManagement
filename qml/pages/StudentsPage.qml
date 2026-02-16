import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

Item {
    id: studentsPage
    implicitHeight: mainLayout.implicitHeight

    property bool showDetail: false
    property int selectedIdx: -1
    property string filterLevel: "all"
    property bool showRegistrationModal: false
    property bool showEditModal: false
    property int deletingStudentId: -1
    property bool showDeleteStudentConfirm: false

    Component.onCompleted: {
        studentController.loadStudents()
        schoolingController.loadNiveaux()
        schoolingController.loadAllClasses()
        // Vérification immédiate si les élèves sont déjà chargés (navigation depuis SchoolingPage)
        checkPendingStudent()
    }

    Connections {
        target: studentController
        function onOperationSucceeded(msg) {
            console.log("Success:", msg)
            showRegistrationModal = false
            showEditModal = false
            studentController.loadStudents()
        }
        function onOperationFailed(err) {
            console.log("Error:", err)
        }
        // Après chaque rechargement de la liste, re-sélectionner l'élève courant
        function onStudentsChanged() {
            if (showDetail && selectedIdx >= 0)
                studentController.selectStudent(selectedIdx)
            // Navigation depuis SchoolingPage (bouton Visualiser) — fallback si pas encore traité
            checkPendingStudent()
        }
    }

    function checkPendingStudent() {
        var win = studentsPage.ApplicationWindow.window
        if (win && win.pendingStudentId > 0) {
            var targetId = win.pendingStudentId
            win.pendingStudentId = 0
            var sts = studentController.students
            for (var i = 0; i < sts.length; i++) {
                if (sts[i].id === targetId) {
                    studentController.selectStudent(i)
                    studentsPage.selectedIdx = i
                    studentsPage.showDetail = true
                    break
                }
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        // ─── Detail View ───
        Loader {
            id: detailLoader
            Layout.fillWidth: true
            active: showDetail && selectedIdx >= 0
            visible: active

            sourceComponent: Component {
                StudentDetailView {
                    student: studentController.selectedStudent
                    niveaux: schoolingController.niveaux
                    classes: schoolingController.allClasses

                    onBackRequested: studentsPage.showDetail = false
                    onEditRequested: studentsPage.showEditModal = true
                    onDeleteRequested: {
                        studentsPage.deletingStudentId = studentController.selectedStudent.id
                        studentsPage.showDeleteStudentConfirm = true
                    }
                }
            }
        }

        // ─── List View ───
        Loader {
            Layout.fillWidth: true
            active: !showDetail
            visible: active

            sourceComponent: Component {
                StudentListView {
                    students: studentController.students
                    niveaux: schoolingController.niveaux
                    classes: schoolingController.classes
                    filterLevel: studentsPage.filterLevel

                    onStudentViewClicked: (index) => {
                        studentController.selectStudent(index)
                        studentsPage.selectedIdx = index
                        studentsPage.showDetail = true
                    }
                    onStudentEditClicked: (index) => {
                        studentController.selectStudent(index)
                        studentsPage.selectedIdx = index
                        studentsPage.showEditModal = true
                    }
                    onStudentDeleteClicked: (studentId) => {
                        studentsPage.deletingStudentId = studentId
                        studentsPage.showDeleteStudentConfirm = true
                    }
                    onRegistrationRequested: studentsPage.showRegistrationModal = true
                    onSearchRequested: (text) => studentController.searchStudents(text)
                    onFilterByClass: (classeId) => studentController.loadStudentsByClasse(classeId)
                    onLoadAllRequested: studentController.loadStudents()
                    onNiveauFilterChanged: (niveauId) => {
                        if (niveauId === 0)
                            schoolingController.loadAllClasses()
                        else
                            schoolingController.loadClassesByNiveau(niveauId)
                    }
                }
            }
        }
    }

    // ─── Registration Modal ───
    StudentRegistrationModal {
        visible: showRegistrationModal
        niveaux: schoolingController.niveaux
        classes: schoolingController.classes

        onCreateRequested: (data) => {
            studentController.createStudent(data)
            showRegistrationModal = false
        }
        onCloseRequested: showRegistrationModal = false
        onNiveauSelected: (niveauId) => schoolingController.loadClassesByNiveau(niveauId)
    }

    // ─── Edit Modal ───
    StudentEditModal {
        visible: showEditModal
        student: studentController.selectedStudent
        niveaux: schoolingController.niveaux
        allClasses: schoolingController.allClasses

        onUpdateRequested: (studentId, data) => {
            studentController.updateStudent(studentId, data)
            showEditModal = false
        }
        onCloseRequested: showEditModal = false
    }

    // ─── Delete Confirmation ───
    StudentDeleteModal {
        show: showDeleteStudentConfirm
        deletingStudentId: studentsPage.deletingStudentId

        onDeleteRequested: (studentId) => {
            studentController.deleteStudent(studentId)
            showDeleteStudentConfirm = false
            showDetail = false
        }
        onCloseRequested: showDeleteStudentConfirm = false
    }
}
