import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

Item {
    id: gradesPage
    implicitHeight: mainLayout.implicitHeight

    // ── Sélection ──
    property int selNiveauId:  -1
    property int selClasseId:  -1
    property int selMatiereId: -1
    property int selSeanceId:  -1

    // ── Contexte pour le bulletin ──
    property string selNiveauNom:  ""
    property string selClasseNom:  ""
    property string selAnneeScolaire: {
        var d = new Date()
        var y = d.getMonth() >= 8 ? d.getFullYear() : d.getFullYear() - 1
        return y + "/" + (y + 1)
    }

    // ── État local des notes saisies (avant enregistrement) ──
    // participationId (string) → note saisie (string)
    property var pendingGrades:  ({})
    property int pendingVersion: 0   // incrément pour forcer la ré-évaluation des bindings

    function setPendingNote(partId, noteText) {
        var pg = pendingGrades
        if (noteText === "") { delete pg[String(partId)] }
        else { pg[String(partId)] = noteText }
        pendingGrades = pg
        pendingVersion++
    }

    // ── Helpers élèves ──
    function studentName(eleveId) {
        var s = studentController.students
        for (var i = 0; i < s.length; i++)
            if (s[i].id === eleveId) return s[i].prenom + " " + s[i].nom
        return "Élève #" + eleveId
    }
    function studentMatricule(eleveId) {
        var s = studentController.students
        for (var i = 0; i < s.length; i++)
            if (s[i].id === eleveId) return s[i].matricule || ("N°" + eleveId)
        return "N°" + eleveId
    }
    function studentInitials(eleveId) {
        var s = studentController.students
        for (var i = 0; i < s.length; i++)
            if (s[i].id === eleveId)
                return ((s[i].prenom || "?")[0] + (s[i].nom || "")[0]).toUpperCase()
        return "?"
    }

    // ── Propriétés calculées ──
    readonly property int totalCount: gradesController.grades.length

    readonly property int completionCount: {
        var _v = pendingVersion
        var cnt = 0
        var grades = gradesController.grades
        for (var i = 0; i < grades.length; i++) {
            var pid = String(grades[i].id)
            var noteStr = pendingGrades[pid] !== undefined
                        ? pendingGrades[pid]
                        : (grades[i].note !== null && grades[i].note !== undefined ? String(grades[i].note) : "")
            if (noteStr !== "") cnt++
        }
        return cnt
    }

    readonly property real liveAverage: {
        var _v = pendingVersion
        var sum = 0, cnt = 0
        var grades = gradesController.grades
        for (var i = 0; i < grades.length; i++) {
            var pid = String(grades[i].id)
            var noteStr = pendingGrades[pid] !== undefined
                        ? pendingGrades[pid]
                        : (grades[i].note !== null && grades[i].note !== undefined ? String(grades[i].note) : "")
            var v = parseFloat(noteStr)
            if (!isNaN(v) && v >= 0 && v <= 20) { sum += v; cnt++ }
        }
        return cnt > 0 ? Math.round(sum / cnt * 100) / 100 : 0
    }

    readonly property bool allEntered: totalCount > 0 && completionCount === totalCount

    readonly property bool hasPending: {
        var _v = pendingVersion
        for (var k in pendingGrades)
            if (Object.prototype.hasOwnProperty.call(pendingGrades, k)) return true
        return false
    }

    function buildSaveList() {
        var list = []
        var grades = gradesController.grades
        for (var i = 0; i < grades.length; i++) {
            var pid = String(grades[i].id)
            if (pendingGrades[pid] !== undefined) {
                var v = parseFloat(pendingGrades[pid])
                if (!isNaN(v) && v >= 0 && v <= 20)
                    list.push({participationId: grades[i].id, note: v})
            }
        }
        return list
    }

    // ── Cycle de vie ──
    Component.onCompleted: {
        schoolingController.loadNiveaux()
        studentController.loadStudents()
    }

    // Rechargement automatique quand la page redevient visible
    onVisibleChanged: {
        if (visible) {
            if (selClasseId >= 0 && selMatiereId >= 0)
                examsController.loadExamSeancesByClasseMatiere(selClasseId, selMatiereId)
            if (selSeanceId >= 0) {
                gradesController.loadGradesBySeance(selSeanceId)
                gradesController.loadClassAverage(selSeanceId)
            }
        }
    }

    Connections {
        target: gradesController
        function onOperationSucceeded(msg) {
            gradesPage.pendingGrades  = ({})
            gradesPage.pendingVersion++
            if (gradesPage.selSeanceId >= 0) {
                gradesController.loadGradesBySeance(gradesPage.selSeanceId)
                gradesController.loadClassAverage(gradesPage.selSeanceId)
            }
        }
        function onGradesChanged() {
            gradesPage.pendingGrades  = ({})
            gradesPage.pendingVersion++
        }
        function onBulletinDataLoaded(data) {
            var st = gradesPage._currentBulletinStudent
            if (!st) return

            // Retrouve le nom de la classe depuis le classeId du bulletin
            var classeNomBul = gradesPage.selClasseNom
            var classeIdBul  = gradesPage._bulletinClasseId
            if (classeIdBul >= 0) {
                var cls = schoolingController.classes
                for (var i = 0; i < cls.length; i++) {
                    if (cls[i].id === classeIdBul) { classeNomBul = cls[i].nom; break }
                }
            }

            // Retrouve le niveau depuis les données de la classe
            var niveauNomBul = gradesPage.selNiveauNom
            var niveaux = schoolingController.niveaux
            if (st.niveauId !== undefined && st.niveauId >= 0) {
                for (var j = 0; j < niveaux.length; j++) {
                    if (niveaux[j].id === st.niveauId) { niveauNomBul = niveaux[j].nom; break }
                }
            }

            bulletinPreviewPopup.bulletinData     = data
            bulletinPreviewPopup.studentName      = (st.prenom || "") + " " + (st.nom || "")
            bulletinPreviewPopup.studentMatricule = st.matricule || ("N°" + st.id)
            bulletinPreviewPopup.niveauNom        = niveauNomBul
            bulletinPreviewPopup.classeNom        = classeNomBul
            bulletinPreviewPopup.anneeScolaire    = gradesPage.selAnneeScolaire
            bulletinPreviewPopup.eleveId          = st.id
            bulletinPreviewPopup.open()
        }
    }

    // ── Layout principal ──
    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        // ── En-tête ──
        RowLayout {
            Layout.fillWidth: true

            PageHeader {
                Layout.fillWidth: true
                title: "Saisie des Notes"
                subtitle: "Saisissez et validez les résultats des épreuves par classe."
            }

            Row {
                spacing: 8

                OutlineButton {
                    text: "Exporter CSV"
                    iconName: "download"
                    enabled: selSeanceId >= 0 && gradesController.grades.length > 0
                    opacity: enabled ? 1.0 : 0.5
                }

                PrimaryButton {
                    text: "Générer les Bulletins"
                    iconName: "file"
                    enabled: selClasseId >= 0
                    opacity: enabled ? 1.0 : 0.45
                    onClicked: {
                        schoolingController.loadAllMatieres()
                        bulletinConfigPopup.open()
                    }
                }
            }
        }

        // ── Filtres (sélection de l'épreuve) ──
        AppCard {
            Layout.fillWidth: true

            RowLayout {
                width: parent.width
                spacing: 16

                // Niveau — largeur fixe (le plus court)
                Column {
                    Layout.preferredWidth: 130
                    spacing: 6
                    SectionLabel { text: "NIVEAU" }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight

                        ComboBox {
                            id: niveauCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: schoolingController.niveaux
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: niveauCombo.currentIndex >= 0 ? niveauCombo.currentText : "Sélectionner..."
                                font.pixelSize: 13; font.bold: true
                                color: niveauCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            onCurrentValueChanged: {
                                if (currentIndex < 0) return
                                gradesPage.selNiveauId  = currentValue
                                gradesPage.selNiveauNom = currentText
                                schoolingController.loadClassesByNiveau(currentValue)
                                schoolingController.loadMatieresByNiveau(currentValue)
                                classeCombo.currentIndex   = -1
                                matiereCombo.currentIndex  = -1
                                epreuveCombo.currentIndex  = -1
                                gradesPage.selClasseId  = -1
                                gradesPage.selClasseNom = ""
                                gradesPage.selMatiereId = -1
                                gradesPage.selSeanceId  = -1
                            }
                        }
                    }
                }

                // Classe — plus large
                Column {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 160
                    spacing: 6
                    SectionLabel { text: "CLASSE" }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage
                        border.color: gradesPage.selNiveauId < 0 ? Style.bgTertiary : Style.borderLight
                        opacity: gradesPage.selNiveauId < 0 ? 0.55 : 1.0

                        ComboBox {
                            id: classeCombo
                            anchors.fill: parent; anchors.margins: 4
                            enabled: gradesPage.selNiveauId >= 0
                            model: schoolingController.classes
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: classeCombo.currentIndex >= 0 ? classeCombo.currentText
                                    : gradesPage.selNiveauId < 0 ? "Choisir un niveau d'abord" : "Sélectionner..."
                                font.pixelSize: 13; font.bold: true
                                color: classeCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            onCurrentValueChanged: {
                                if (currentIndex < 0) return
                                gradesPage.selClasseId  = currentValue
                                gradesPage.selClasseNom = currentText
                                epreuveCombo.currentIndex = -1
                                gradesPage.selSeanceId = -1
                                if (gradesPage.selMatiereId >= 0)
                                    examsController.loadExamSeancesByClasseMatiere(currentValue, gradesPage.selMatiereId)
                            }
                        }
                    }
                }

                // Matière — plus large
                Column {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 160
                    spacing: 6
                    SectionLabel { text: "MATIÈRE" }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage
                        border.color: gradesPage.selNiveauId < 0 ? Style.bgTertiary : Style.borderLight
                        opacity: gradesPage.selNiveauId < 0 ? 0.55 : 1.0

                        ComboBox {
                            id: matiereCombo
                            anchors.fill: parent; anchors.margins: 4
                            enabled: gradesPage.selNiveauId >= 0
                            model: schoolingController.matieres
                            textRole: "nom"; valueRole: "id"
                            currentIndex: -1
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: matiereCombo.currentIndex >= 0 ? matiereCombo.currentText
                                    : gradesPage.selNiveauId < 0 ? "Choisir un niveau d'abord" : "Sélectionner..."
                                font.pixelSize: 13; font.bold: true
                                color: matiereCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            onCurrentValueChanged: {
                                if (currentIndex < 0) return
                                gradesPage.selMatiereId = currentValue
                                epreuveCombo.currentIndex = -1
                                gradesPage.selSeanceId = -1
                                if (gradesPage.selClasseId >= 0)
                                    examsController.loadExamSeancesByClasseMatiere(gradesPage.selClasseId, currentValue)
                            }
                        }
                    }
                }

                // Épreuve — prend le reste
                Column {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 180
                    spacing: 6
                    SectionLabel { text: "ÉPREUVE" }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage
                        border.color: (gradesPage.selClasseId < 0 || gradesPage.selMatiereId < 0)
                                    ? Style.bgTertiary : Style.borderLight
                        opacity: (gradesPage.selClasseId < 0 || gradesPage.selMatiereId < 0) ? 0.55 : 1.0

                        ComboBox {
                            id: epreuveCombo
                            anchors.fill: parent; anchors.margins: 4
                            enabled: gradesPage.selClasseId >= 0 && gradesPage.selMatiereId >= 0
                            model: examsController.examSeances
                            textRole: "label"; valueRole: "id"
                            currentIndex: -1
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                leftPadding: 8
                                text: epreuveCombo.currentIndex >= 0 ? epreuveCombo.currentText
                                    : (gradesPage.selClasseId < 0 || gradesPage.selMatiereId < 0)
                                    ? "Choisir classe et matière d'abord"
                                    : examsController.examSeances.length === 0
                                    ? "Aucune épreuve planifiée"
                                    : "Sélectionner une épreuve..."
                                font.pixelSize: 13; font.bold: true
                                color: epreuveCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            onCurrentValueChanged: {
                                if (currentIndex < 0) return
                                gradesPage.selSeanceId = currentValue
                                gradesController.loadGradesBySeance(currentValue)
                                gradesController.loadClassAverage(currentValue)
                            }
                        }
                    }
                }
            }
        }

        // ── État vide ──
        AppCard {
            Layout.fillWidth: true
            visible: gradesPage.selSeanceId < 0

            Column {
                width: parent.width
                spacing: 16

                Item { width: 1; height: 36 }

                Rectangle {
                    width: 64; height: 64; radius: 22
                    color: Style.primaryBg
                    anchors.horizontalCenter: parent.horizontalCenter
                    IconLabel { anchors.centerIn: parent; iconName: "file"; iconSize: 28; iconColor: Style.primary }
                }

                Text {
                    width: parent.width
                    text: "Sélectionnez un niveau, une classe, une matière et une épreuve\npour afficher la grille de saisie des notes."
                    font.pixelSize: 13; font.weight: Font.Medium
                    color: Style.textTertiary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap; lineHeight: 1.6
                }

                Item { width: 1; height: 36 }
            }
        }

        // ── Grille de saisie + barre latérale ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 24
            visible: gradesPage.selSeanceId >= 0

            // ── Grille ──
            AppCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 3

                title: "Grille de Saisie"
                subtitle: {
                    var mat = "", cls = ""
                    var m = schoolingController.matieres
                    for (var i = 0; i < m.length; i++) if (m[i].id === gradesPage.selMatiereId) { mat = m[i].nom; break }
                    var cl = schoolingController.classes
                    for (var j = 0; j < cl.length; j++) if (cl[j].id === gradesPage.selClasseId) { cls = cl[j].nom; break }
                    return (mat && cls) ? mat + "  ·  " + cls : "Saisie en cours"
                }

                Column {
                    width: parent.width
                    spacing: 0

                    // En-tête du tableau
                    RowLayout {
                        width: parent.width; height: 40; spacing: 0
                        SectionLabel { Layout.preferredWidth: 210; text: "ÉLÈVE" }
                        SectionLabel { Layout.preferredWidth: 120; text: "NOTE / 20" }
                        SectionLabel { Layout.fillWidth: true; text: "STATUT" }
                        SectionLabel { Layout.preferredWidth: 110; text: "ÉTAT"; horizontalAlignment: Text.AlignRight }
                    }

                    Separator { width: parent.width }

                    // Chargement
                    Item {
                        width: parent.width; height: 56
                        visible: gradesController.loading
                        Text {
                            anchors.centerIn: parent
                            text: "Chargement des participations..."
                            font.pixelSize: 13; font.italic: true; color: Style.textTertiary
                        }
                    }

                    // Aucun élève
                    Item {
                        width: parent.width; height: 56
                        visible: !gradesController.loading && gradesController.grades.length === 0
                        Text {
                            anchors.centerIn: parent
                            text: "Aucune participation enregistrée pour cette épreuve"
                            font.pixelSize: 13; font.italic: true; color: Style.textTertiary
                        }
                    }

                    // Lignes de notes
                    Repeater {
                        id: gradesRepeater
                        model: gradesController.grades

                        delegate: Column {
                            id: gradeRow
                            width: parent.width
                            property alias noteInputRef: noteInput

                            // Note courante pour cet élève (priorité : saisie locale > BDD)
                            property string currentNote: {
                                var _v = gradesPage.pendingVersion
                                var pid = String(modelData.id)
                                if (gradesPage.pendingGrades[pid] !== undefined)
                                    return String(gradesPage.pendingGrades[pid])
                                if (modelData.note !== null && modelData.note !== undefined)
                                    return String(modelData.note)
                                return ""
                            }
                            property bool isDirty: {
                                var _v = gradesPage.pendingVersion
                                return gradesPage.pendingGrades[String(modelData.id)] !== undefined
                            }
                            property bool hasNote: currentNote !== ""

                            RowLayout {
                                width: parent.width; height: 64; spacing: 0

                                // ── Élève (210 px) ──
                                Item {
                                    Layout.preferredWidth: 210
                                    Layout.fillHeight: true

                                    RowLayout {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        spacing: 10

                                        Avatar {
                                            initials: gradesPage.studentInitials(modelData.eleveId)
                                            size: 34
                                            bgColor: modelData.statut === "Absent" ? "#FEE2E2" : Style.bgSecondary
                                            textColor: modelData.statut === "Absent" ? Style.errorColor : Style.primary
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                width: parent.width
                                                text: gradesPage.studentName(modelData.eleveId)
                                                font.pixelSize: 12; font.bold: true
                                                color: Style.textPrimary
                                                horizontalAlignment: Text.AlignLeft
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                width: parent.width
                                                text: gradesPage.studentMatricule(modelData.eleveId)
                                                font.pixelSize: 9; font.weight: Font.Bold
                                                color: Style.textTertiary
                                                horizontalAlignment: Text.AlignLeft
                                            }
                                        }
                                    }
                                }

                                // ── Note / 20 (120 px) ──
                                Item {
                                    Layout.preferredWidth: 120
                                    Layout.fillHeight: true

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 88; height: 38; radius: 10
                                        color: noteInput.activeFocus ? Style.primaryBg : Style.bgPage
                                        border.color: noteInput.activeFocus ? Style.primary
                                                    : gradeRow.isDirty      ? Qt.rgba(0.24, 0.35, 0.27, 0.4)
                                                    : gradeRow.hasNote      ? Style.borderMedium
                                                    : Style.borderLight
                                        border.width: noteInput.activeFocus || gradeRow.isDirty ? 1.5 : 1
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                        Behavior on color       { ColorAnimation { duration: 120 } }

                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 6; spacing: 2

                                            TextInput {
                                                id: noteInput
                                                Layout.fillWidth: true
                                                text: gradeRow.currentNote
                                                font.pixelSize: 15; font.weight: Font.Black
                                                color: Style.primary
                                                horizontalAlignment: Text.AlignHCenter
                                                selectByMouse: true
                                                validator: DoubleValidator {
                                                    bottom: 0; top: 20; decimals: 2
                                                    notation: DoubleValidator.StandardNotation
                                                    locale: "C"
                                                }

                                                Text {
                                                    visible: !noteInput.text
                                                    anchors.centerIn: parent
                                                    text: "—"
                                                    font.pixelSize: 15; font.weight: Font.Black
                                                    color: Style.textTertiary
                                                }

                                                onTextEdited: gradesPage.setPendingNote(modelData.id, text)

                                                Keys.onTabPressed: {
                                                    var next = gradesRepeater.itemAt(index + 1)
                                                    if (next) next.noteInputRef.forceActiveFocus()
                                                    event.accepted = true
                                                }
                                                Keys.onBacktabPressed: {
                                                    var prev = gradesRepeater.itemAt(index - 1)
                                                    if (prev) prev.noteInputRef.forceActiveFocus()
                                                    event.accepted = true
                                                }
                                            }

                                            Text {
                                                text: "/20"
                                                font.pixelSize: 9; font.weight: Font.Black
                                                color: Style.textTertiary
                                            }
                                        }
                                    }
                                }

                                // ── Statut de présence (remplit le reste) ──
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Badge {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.statut || "Présent"
                                        variant: modelData.statut === "Absent" ? "error"
                                               : modelData.statut === "Retard" ? "warning"
                                               : "success"
                                    }
                                }

                                // ── Indicateur de saisie (110 px, ancré à droite) ──
                                Item {
                                    Layout.preferredWidth: 110
                                    Layout.fillHeight: true

                                    Row {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 5

                                        Text {
                                            text: gradeRow.isDirty  ? "✎"
                                                : gradeRow.hasNote  ? "✓"
                                                : "○"
                                            font.pixelSize: 14
                                            color: gradeRow.isDirty ? Style.primary
                                                 : gradeRow.hasNote ? Style.successColor
                                                 : Style.textTertiary
                                        }
                                        Text {
                                            text: gradeRow.isDirty ? "MODIFIÉ"
                                                : gradeRow.hasNote ? "SAISI"
                                                : "EN ATTENTE"
                                            font.pixelSize: 8; font.weight: Font.Black
                                            color: gradeRow.isDirty ? Style.primary
                                                 : gradeRow.hasNote ? Style.successColor
                                                 : Style.textTertiary
                                        }
                                    }
                                }
                            }

                            Separator { width: parent.width }
                        }
                    }

                    // Pied de tableau
                    Item { width: 1; height: 20 }
                    Separator { width: parent.width }
                    Item { width: 1; height: 20 }

                    RowLayout {
                        width: parent.width

                        RowLayout {
                            spacing: 40

                            Column {
                                spacing: 3
                                SectionLabel { text: "MOYENNE DE CLASSE" }
                                Text {
                                    text: gradesPage.completionCount > 0
                                          ? gradesPage.liveAverage.toFixed(2)
                                          : "—"
                                    font.pixelSize: 26; font.weight: Font.Black
                                    color: Style.primary
                                }
                            }

                            Column {
                                spacing: 3
                                SectionLabel { text: "NOTES SAISIES" }
                                Text {
                                    text: gradesPage.completionCount + " / " + gradesPage.totalCount
                                    font.pixelSize: 26; font.weight: Font.Black
                                    color: Style.textPrimary
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        PrimaryButton {
                            text: gradesPage.hasPending ? "Enregistrer les Notes" : "À jour"
                            iconName: "save"
                            enabled: gradesPage.hasPending
                            opacity: enabled ? 1.0 : 0.5
                            onClicked: {
                                var list = gradesPage.buildSaveList()
                                if (list.length > 0) gradesController.saveGrades(list)
                            }
                        }
                    }
                }
            }

            // ── Barre latérale ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 20

                // Guide de saisie
                AppCard {
                    Layout.fillWidth: true
                    title: "Guide de Saisie"

                    Column {
                        width: parent.width
                        spacing: 16

                        RowLayout {
                            width: parent.width
                            spacing: 10
                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: Style.infoBg
                                Text { anchors.centerIn: parent; text: "🔢"; font.pixelSize: 14 }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: "Utilisez le point (.) pour les décimales (ex: 15.5). La note doit être comprise entre 0 et 20."
                                font.pixelSize: 11; color: Style.textSecondary
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Bandeau dynamique : attention / prêt
                        Rectangle {
                            width: parent.width
                            implicitHeight: sideWarnCol.implicitHeight + 24
                            radius: 12
                            color: gradesPage.allEntered ? "#F0FDF4" : "#FEF3C7"
                            border.color: gradesPage.allEntered ? "#BBF7D0" : "#FCD34D"
                            Behavior on color { ColorAnimation { duration: 300 } }

                            Column {
                                id: sideWarnCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 4

                                Text {
                                    text: gradesPage.allEntered ? "Prêt pour les bulletins ✓" : "Attention"
                                    font.pixelSize: 11; font.bold: true
                                    color: gradesPage.allEntered ? "#166534" : "#92400E"
                                }
                                Text {
                                    width: parent.width
                                    text: gradesPage.allEntered
                                          ? "Toutes les notes sont saisies. Le bouton « Générer les Bulletins » est maintenant actif."
                                          : "Les bulletins ne peuvent être générés que si 100% des notes sont saisies pour cette épreuve."
                                    font.pixelSize: 10
                                    color: gradesPage.allEntered ? "#166534" : "#92400E"
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                // Progression
                AppCard {
                    Layout.fillWidth: true
                    title: "Progression de Saisie"

                    Column {
                        width: parent.width
                        spacing: 16

                        // Épreuve sélectionnée
                        Column {
                            width: parent.width
                            spacing: 8

                            RowLayout {
                                width: parent.width
                                Text {
                                    Layout.fillWidth: true
                                    text: epreuveCombo.currentIndex >= 0 ? epreuveCombo.currentText : "—"
                                    font.pixelSize: 11; font.bold: true
                                    color: Style.textPrimary
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: gradesPage.totalCount > 0
                                          ? Math.round(gradesPage.completionCount / gradesPage.totalCount * 100) + "%"
                                          : "0%"
                                    font.pixelSize: 11; font.bold: true
                                    color: gradesPage.allEntered ? Style.successColor : Style.textSecondary
                                }
                            }

                            ProgressBar_ {
                                width: parent.width
                                value: gradesPage.totalCount > 0
                                       ? gradesPage.completionCount / gradesPage.totalCount
                                       : 0
                            }

                            Text {
                                text: gradesPage.completionCount + " note(s) saisie(s) sur "
                                    + gradesPage.totalCount + " élève(s)"
                                font.pixelSize: 10; color: Style.textTertiary
                            }
                        }

                        // Stats rapides si au moins une note
                        Column {
                            width: parent.width
                            spacing: 8
                            visible: gradesPage.completionCount > 0

                            Separator { width: parent.width }

                            RowLayout {
                                width: parent.width

                                Column {
                                    spacing: 2
                                    SectionLabel { text: "MOYENNE" }
                                    Text {
                                        text: gradesPage.liveAverage.toFixed(2)
                                        font.pixelSize: 18; font.weight: Font.Black
                                        color: Style.primary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Column {
                                    spacing: 2
                                    SectionLabel { text: "SAISIES" }
                                    Text {
                                        text: gradesPage.completionCount
                                        font.pixelSize: 18; font.weight: Font.Black
                                        color: Style.textPrimary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }

    // ── Popups bulletin ──────────────────────────────────────────────────────
    BulletinConfigPopup {
        id: bulletinConfigPopup

        onBulletinRequested: function(eleveId, classeId, allStudents) {
            // Stocke les paramètres pour la preview
            gradesPage._bulletinAllStudents = allStudents
            gradesPage._bulletinClasseId    = classeId

            if (allStudents) {
                // Génère pour tous les élèves de la classe
                var students = studentController.students
                var classStudents = []
                for (var i = 0; i < students.length; i++)
                    if (students[i].classeId === classeId) classStudents.push(students[i])

                if (classStudents.length === 0) return
                gradesPage._bulletinQueue   = classStudents
                gradesPage._bulletinQueueIdx = 0
                // Lance le premier
                var s = classStudents[0]
                gradesPage._currentBulletinStudent = s
                gradesController.loadBulletinData(s.id, classeId)
            } else {
                // Un seul élève
                var st = studentController.students
                for (var j = 0; j < st.length; j++) {
                    if (st[j].id === eleveId) {
                        gradesPage._currentBulletinStudent = st[j]
                        break
                    }
                }
                gradesPage._bulletinQueue    = []
                gradesPage._bulletinQueueIdx = 0
                gradesController.loadBulletinData(eleveId, classeId)
            }
            bulletinConfigPopup.close()
        }
    }

    BulletinPreviewPopup {
        id: bulletinPreviewPopup
    }

    // Propriétés internes pour la gestion de file d'attente
    property var    _bulletinQueue:           []
    property int    _bulletinQueueIdx:        0
    property bool   _bulletinAllStudents:     false
    property int    _bulletinClasseId:        -1
    property var    _currentBulletinStudent:  null

}
