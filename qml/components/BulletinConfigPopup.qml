import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import UI.Components

// Popup de configuration de la génération des bulletins (export DOCX)
// Signal : bulletinRequested(eleveId, classeId, allStudents, semestre, anneeId, targetPath, president)
//   targetPath = chemin fichier → export élève unique
//   targetPath = chemin dossier → export par lot (noms auto dans le dossier)
ModalOverlay {
    id: root

    signal bulletinRequested(int eleveId, int classeId, bool allStudents, int semestre,
                             int anneeId, string targetPath, string president)

    // État interne
    property int    selAnneeId:      -1
    property int    selNiveauId:     -1
    property int    selClasseId:     -1
    property int    selEleveId:      -1
    property bool   allStudents:     true
    property int    selSemestreNum:  1
    property string presidentName:   ""

    function urlToPath(url) {
        var s = url.toString()
        if (s.startsWith("file:///")) {
            s = s.slice(8)
            if (!s.match(/^[A-Za-z]:/)) s = "/" + s
        }
        return decodeURIComponent(s)
    }

    modalWidth: 580

    readonly property var filteredNiveaux: {
        var all = selAnneeId >= 0 ? schoolingController.niveauxGlobal : schoolingController.niveaux
        var base = []
        for (var i = 0; i < all.length; i++) {
            if (selAnneeId >= 0 && all[i].anneeScolaireId !== selAnneeId) continue
            if (all[i].isFreestyle) continue
            base.push(all[i])
        }
        if (selAnneeId >= 0 && base.length === 0) {
            var fallback = []
            for (var j = 0; j < schoolingController.niveaux.length; j++) {
                if (!schoolingController.niveaux[j].isFreestyle) fallback.push(schoolingController.niveaux[j])
            }
            return fallback
        }
        return base
    }

    onOpened: {
        studentController.loadSchoolYears()
        schoolingController.loadNiveauxGlobal()

        selNiveauId   = -1
        selClasseId   = -1
        selEleveId    = -1
        allStudents   = true
        selSemestreNum = 1
        presidentName  = ""

        var years = studentController.schoolYears
        if (years.length > 0) {
            selAnneeId = years[0].id
            cfgAnneeCombo.currentIndex = 0
        } else {
            selAnneeId = -1
            if (cfgAnneeCombo) cfgAnneeCombo.currentIndex = -1
        }
        if (cfgNiveauCombo)  cfgNiveauCombo.currentIndex  = -1
        if (cfgClasseCombo)  cfgClasseCombo.currentIndex  = -1
        if (cfgEleveCombo)   cfgEleveCombo.currentIndex   = -1
        if (cfgSemCombo)     cfgSemCombo.currentIndex     = 0
    }

    readonly property var classStudents: studentController.studentsForBulletin

    Connections {
        target: studentController
        function onStudentsForBulletinChanged() {
            console.log("[BulletinConfig] studentsForBulletin:", studentController.studentsForBulletin.length)
        }
    }

    // ── Folder dialog (batch) ─────────────────────────────────────────────────
    FolderDialog {
        id: exportFolderDialog
        title: "Dossier d'export des bulletins DOCX"
        onAccepted: {
            root.bulletinRequested(-1, root.selClasseId, true,
                root.selSemestreNum, root.selAnneeId,
                root.urlToPath(exportFolderDialog.folder), root.presidentName)
        }
    }

    // ── File dialog (élève unique) ────────────────────────────────────────────
    FileDialog {
        id: singleSaveDialog
        fileMode: FileDialog.SaveFile
        title: "Enregistrer le bulletin DOCX"
        nameFilters: ["Fichiers Word (*.docx)", "Tous les fichiers (*)"]
        defaultSuffix: "docx"
        onAccepted: {
            root.bulletinRequested(root.selEleveId, root.selClasseId, false,
                root.selSemestreNum, root.selAnneeId,
                root.urlToPath(singleSaveDialog.file), root.presidentName)
        }
    }

    Column {
        width: parent.width
        spacing: 20
        padding: 32
        bottomPadding: 28

        // ── Header ───────────────────────────────────────────────────────────
        RowLayout {
            width: parent.width - 64

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    width: 48; height: 48; radius: 16
                    color: Style.primaryBg
                    Text { anchors.centerIn: parent; text: qsTr("📄"); font.pixelSize: 22 }
                }

                Column {
                    spacing: 2
                    Text {
                        text: qsTr("Générer les Bulletins")
                        font.pixelSize: 18; font.weight: Font.Black; color: Style.textPrimary
                    }
                    Text {
                        text: qsTr("Export DOCX — configuration et options")
                        font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium
                    }
                }
            }

            IconButton { iconName: "close"; iconSize: 18; onClicked: root.visible = false }
        }

        Separator { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter }

        // ── Champs de configuration ───────────────────────────────────────────
        Column {
            width: parent.width - 64
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            SectionLabel { text: qsTr("CONFIGURATION") }

            // Année scolaire
            Column {
                width: parent.width; spacing: 6
                SectionLabel { text: qsTr("ANNÉE SCOLAIRE") }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight

                    ComboBox {
                        id: cfgAnneeCombo
                        anchors.fill: parent; anchors.margins: 4
                        model: studentController.schoolYears
                        textRole: "libelle"; valueRole: "id"
                        currentIndex: 0
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            leftPadding: 8
                            text: cfgAnneeCombo.currentIndex >= 0 ? cfgAnneeCombo.currentText : "Sélectionner..."
                            font.pixelSize: 13; font.bold: true
                            color: cfgAnneeCombo.currentIndex >= 0 ? Style.textPrimary : Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCurrentValueChanged: {
                            if (currentIndex < 0) return
                            root.selAnneeId = currentValue
                            cfgNiveauCombo.currentIndex = -1
                            cfgClasseCombo.currentIndex = -1
                            if (cfgEleveCombo) cfgEleveCombo.currentIndex = -1
                            root.selNiveauId = -1; root.selClasseId = -1; root.selEleveId = -1
                        }
                    }
                }
            }

            // Semestre
            Column {
                width: parent.width; spacing: 6
                SectionLabel { text: qsTr("SEMESTRE") }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight

                    ComboBox {
                        id: cfgSemCombo
                        anchors.fill: parent; anchors.margins: 4
                        model: ListModel {
                            ListElement { label: "Semestre 1"; val: 1 }
                            ListElement { label: "Semestre 2 (annuel)"; val: 2 }
                        }
                        textRole: "label"
                        currentIndex: 0
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            leftPadding: 8
                            text: cfgSemCombo.currentIndex >= 0 ? cfgSemCombo.currentText : "Sélectionner..."
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                            verticalAlignment: Text.AlignVCenter
                        }
                        onCurrentIndexChanged: root.selSemestreNum = (currentIndex === 1) ? 2 : 1
                    }
                }
            }

            // Niveau + Classe
            Row {
                id: niveauClasseRow
                width: parent.width; spacing: 16

                Column {
                    width: (niveauClasseRow.width - 16) / 2; spacing: 6
                    SectionLabel { text: qsTr("NIVEAU") }
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight

                        ComboBox {
                            id: cfgNiveauCombo
                            anchors.fill: parent; anchors.margins: 4
                            model: root.filteredNiveaux
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
                                root.selClasseId = -1; root.selEleveId = -1
                            }
                        }
                    }
                }

                Column {
                    width: (niveauClasseRow.width - 16) / 2; spacing: 6
                    SectionLabel { text: qsTr("CLASSE") }
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
                                cfgEleveCombo.currentIndex = -1; root.selEleveId = -1
                                if (root.selAnneeId >= 0)
                                    studentController.loadStudentsForBulletin(currentValue, root.selAnneeId)
                            }
                        }
                    }
                }
            }

            // Générer pour
            Column {
                width: parent.width; spacing: 8
                SectionLabel { text: qsTr("GÉNÉRER POUR") }

                RowLayout {
                    width: parent.width; spacing: 12

                    Rectangle {
                        Layout.fillWidth: true; height: 72; radius: 14
                        color: root.allStudents ? Style.primaryBg : Style.bgPage
                        border.color: root.allStudents ? Style.primary : Style.borderLight
                        border.width: root.allStudents ? 2 : 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                                IconLabel { iconName: "users"; iconSize: 16; iconColor: root.allStudents ? Style.primary : Style.textTertiary }
                                Text { text: qsTr("Tous les élèves"); font.pixelSize: 13; font.bold: true; color: root.allStudents ? Style.primary : Style.textPrimary }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.selClasseId >= 0
                                      ? "Générer " + root.classStudents.length + " bulletin" + (root.classStudents.length > 1 ? "s" : "")
                                      : "Sélectionner une classe"
                                font.pixelSize: 10; color: root.allStudents ? Style.primary : Style.textTertiary
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.allStudents = true }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 72; radius: 14
                        color: !root.allStudents ? Style.primaryBg : Style.bgPage
                        border.color: !root.allStudents ? Style.primary : Style.borderLight
                        border.width: !root.allStudents ? 2 : 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                                IconLabel { iconName: "user"; iconSize: 16; iconColor: !root.allStudents ? Style.primary : Style.textTertiary }
                                Text { text: qsTr("Un élève"); font.pixelSize: 13; font.bold: true; color: !root.allStudents ? Style.primary : Style.textPrimary }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("Sélectionner un élève spécifique")
                                font.pixelSize: 10; color: !root.allStudents ? Style.primary : Style.textTertiary
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.allStudents = false }
                    }
                }
            }

            // Sélection élève (mode "Un élève")
            Column {
                width: parent.width; spacing: 6
                visible: !root.allStudents

                SectionLabel { text: qsTr("SÉLECTIONNER L'ÉLÈVE") }
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
                            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
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

            // Président de l'association
            Column {
                width: parent.width; spacing: 6
                SectionLabel { text: qsTr("PRÉSIDENT DE L'ASSOCIATION") }
                Rectangle {
                    width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight

                    Item {
                        anchors.fill: parent; anchors.margins: 12

                        Text {
                            anchors.fill: parent
                            text: qsTr("Nom du président…")
                            font.pixelSize: 13; color: Style.textTertiary
                            verticalAlignment: Text.AlignVCenter
                            visible: presidentInput.text === ""
                        }

                        TextInput {
                            id: presidentInput
                            anchors.fill: parent
                            text: root.presidentName
                            font.pixelSize: 13; color: Style.textPrimary
                            verticalAlignment: Text.AlignVCenter; clip: true
                            onTextChanged: root.presidentName = text
                        }
                    }
                }
            }
        }

        // ── Boutons ───────────────────────────────────────────────────────────
        RowLayout {
            width: parent.width - 64
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            readonly property bool formValid: root.selClasseId >= 0
                && (root.allStudents ? root.classStudents.length > 0 : root.selEleveId >= 0)

            Rectangle {
                Layout.fillWidth: true; height: 48; radius: 14
                color: cancelMa.containsMouse ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderLight
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: qsTr("ANNULER"); font.pixelSize: 11; font.weight: Font.Black; color: Style.textTertiary }
                MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.visible = false }
            }

            Rectangle {
                Layout.fillWidth: true; height: 48; radius: 14
                color: parent.formValid ? (confirmMa.containsMouse ? Style.primaryDark : Style.primary) : Style.bgTertiary
                opacity: parent.formValid ? 1.0 : 0.5
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.centerIn: parent; spacing: 8
                    IconLabel { iconName: "printer"; iconSize: 14; iconColor: "white" }
                    Text { text: qsTr("GÉNÉRER DOCX"); font.pixelSize: 11; font.weight: Font.Black; color: Style.background }
                }

                MouseArea {
                    id: confirmMa; anchors.fill: parent
                    enabled: parent.parent.formValid
                    hoverEnabled: true; cursorShape: parent.parent.formValid ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.allStudents) {
                            exportFolderDialog.open()
                        } else {
                            singleSaveDialog.open()
                        }
                    }
                }
            }
        }
    }
}
