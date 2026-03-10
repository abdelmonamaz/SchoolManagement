import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1
import UI.Components

ColumnLayout {
    id: root
    spacing: 28

    required property var student
    required property var niveaux
    required property var classes

    signal backRequested()
    signal editRequested()
    signal deleteRequested()

    // ── Internal state ───────────────────────────────────────────────────────
    property bool _bulletinPending: false
    property bool _csvPending:      false

    // Temp storage for async CSV file dialog
    property var    _csvData:         ({})
    property string _csvStudentName:  ""
    property string _csvNiveauNom:    ""
    property string _csvClasseNom:    ""
    property string _csvAnnee:        ""

    function urlToPath(fileUrl) {
        var s = fileUrl.toString()
        if (s.startsWith("file:///")) return s.substring(8)
        if (s.startsWith("file://"))  return s.substring(7)
        return s
    }

    FileDialog {
        id: csvSaveDialog
        fileMode: FileDialog.SaveFile
        title: "Enregistrer le bulletin CSV"
        nameFilters: ["Fichiers CSV (*.csv)", "Tous les fichiers (*)"]
        defaultSuffix: "csv"
        onAccepted: {
            var path = root.urlToPath(file)
            var result = gradesController.exportBulletinCsv(
                root._csvData, root._csvStudentName,
                root._csvNiveauNom, root._csvClasseNom, root._csvAnnee, path
            )
            if (result.length > 0) Qt.openUrlExternally("file:///" + result)
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    // Look up niveau name from all niveaux (including historical years)
    function niveauNomById(niveauId) {
        var all = schoolingController.niveauxGlobal
        for (var i = 0; i < all.length; i++)
            if (all[i].id === niveauId) return all[i].nom
        // Fallback to active-year niveaux
        for (var j = 0; j < root.niveaux.length; j++)
            if (root.niveaux[j].id === niveauId) return root.niveaux[j].nom
        return niveauId > 0 ? "Niveau " + niveauId : "—"
    }

    // Most recent enrollment (by annee_scolaire_id)
    readonly property var currentEnrollment: {
        var enr = studentController.selectedStudentEnrollments
        if (!enr || enr.length === 0) return null
        var best = null
        for (var i = 0; i < enr.length; i++) {
            if (!best || enr[i].annee_scolaire_id > best.annee_scolaire_id)
                best = enr[i]
        }
        return best
    }

    readonly property string statusLabel: {
        if (!root.currentEnrollment) return "Jamais inscrit"
        var res = root.currentEnrollment.resultat || "En cours"
        if (res === "En cours")   return "Inscrit — En cours"
        if (res === "Réussi")     return "Réussi"
        if (res === "Redoublant") return "Redoublant"
        return res
    }

    readonly property string statusNiveauNom: {
        if (!root.currentEnrollment) return ""
        return root.niveauNomById(root.currentEnrollment.niveauId)
    }

    readonly property string statusAnneeScolaire: {
        if (!root.currentEnrollment) return ""
        return root.currentEnrollment.anneeScolaire || ""
    }

    // ── Connections ──────────────────────────────────────────────────────────

    Connections {
        target: studentController
        function onOperationFailed(err) {
            if (newEnrollmentPopup.opened) newErrorMsg.text = err;
        }
        function onOperationSucceeded(msg) {
            if (msg === "Nouvelle année inscrite") newEnrollmentPopup.close();
            if (msg === "Inscription mise à jour") editEnrollmentModal.show = false;
        }
    }

    Connections {
        target: gradesController

        function onBulletinDataLoaded(data) {
            if (root._bulletinPending) {
                root._bulletinPending = false

                var e = root.currentEnrollment
                var classeNomBul = ""
                if (e && e.classeId > 0) {
                    var cls = schoolingController.allClasses
                    for (var i = 0; i < cls.length; i++) {
                        if (cls[i].id === e.classeId) { classeNomBul = cls[i].nom; break }
                    }
                }

                // Enrich matière names
                var dataCopy = JSON.parse(JSON.stringify(data))
                var allM = schoolingController.allMatieres
                var mats = dataCopy.matieres || []
                for (var k = 0; k < mats.length; k++) {
                    for (var m = 0; m < allM.length; m++) {
                        if (allM[m].id === mats[k].matiereId) { mats[k].nom = allM[m].nom; break }
                    }
                }
                dataCopy.matieres = mats

                bulletinPreview.bulletinData     = dataCopy
                bulletinPreview.studentName      = (root.student.prenom || "") + " " + (root.student.nom || "")
                bulletinPreview.studentMatricule = root.student.matricule || ("N°" + root.student.id)
                bulletinPreview.niveauNom        = root.statusNiveauNom
                bulletinPreview.classeNom        = classeNomBul
                bulletinPreview.anneeScolaire    = root.statusAnneeScolaire
                bulletinPreview.eleveId          = root.student.id
                bulletinPreview.open()

            } else if (root._csvPending) {
                root._csvPending = false

                var data2 = JSON.parse(JSON.stringify(data))
                var allM2 = schoolingController.allMatieres
                var mats2 = data2.matieres || []
                for (var p = 0; p < mats2.length; p++) {
                    for (var q = 0; q < allM2.length; q++) {
                        if (allM2[q].id === mats2[p].matiereId) { mats2[p].nom = allM2[q].nom; break }
                    }
                }
                data2.matieres = mats2

                var classeNomCsv = ""
                var e2 = root.currentEnrollment
                if (e2 && e2.classeId > 0) {
                    var cls2 = schoolingController.allClasses
                    for (var r = 0; r < cls2.length; r++) {
                        if (cls2[r].id === e2.classeId) { classeNomCsv = cls2[r].nom; break }
                    }
                }

                // Store data and open file dialog
                root._csvData        = data2
                root._csvStudentName = (root.student.prenom || "") + " " + (root.student.nom || "")
                root._csvNiveauNom   = root.statusNiveauNom
                root._csvClasseNom   = classeNomCsv
                root._csvAnnee       = root.statusAnneeScolaire
                csvSaveDialog.open()
            }
        }
    }

    // ── Modals ───────────────────────────────────────────────────────────────

    EnrollmentEditModal {
        id: editEnrollmentModal
        student: root.student
        niveaux: root.niveaux
    }

    BulletinPreviewPopup {
        id: bulletinPreview
    }

    // ── Back button ──────────────────────────────────────────────────────────
    Text {
        text: "← Retour à l'annuaire"
        font.pixelSize: 14; font.bold: true
        color: backMa.containsMouse ? Style.primary : Style.textSecondary

        MouseArea {
            id: backMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.backRequested()
        }
    }

    // ─── Student Header Card ───
    Rectangle {
        Layout.fillWidth: true
        height: 180; radius: 32
        color: Style.bgWhite; border.color: Style.borderLight

        Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: 10; radius: 32; color: Style.primary
            Rectangle { anchors.left: parent.horizontalCenter; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 5; color: Style.primary }
        }

        RowLayout {
            anchors.fill: parent; anchors.margins: 28; spacing: 28

            Avatar {
                size: 110
                initials: root.student.nom ? root.student.nom.charAt(0) : ""
                bgColor: Style.sandBg
                textColor: Style.primary
                border.color: "#FFFFFF"; border.width: 4
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                RowLayout {
                    spacing: 12
                    Text { text: (root.student.prenom || "") + " " + (root.student.nom || ""); font.pixelSize: 28; font.weight: Font.Black; color: Style.textPrimary }
                    Badge {
                        text: root.student.sexe === "F" ? "FÉMININ" : "MASCULIN"
                        customTextColor: "#FFFFFF"
                        customBgColor: root.student.sexe === "F" ? "#DB2777" : Style.primary
                        customBorderColor: root.student.sexe === "F" ? "#BE185D" : Style.primaryDark
                    }
                }
                Text { text: "ID: " + (root.student.id || ""); font.pixelSize: 12; font.weight: Font.Bold; color: Style.textTertiary; font.letterSpacing: 2 }

                RowLayout {
                    Layout.topMargin: 10; spacing: 24
                    Row {
                        spacing: 6
                        IconLabel { iconName: "phone"; iconSize: 14; iconColor: Style.primary }
                        Text { text: root.student.telephone || "—"; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary }
                    }
                    Row {
                        spacing: 6
                        IconLabel { iconName: "pin"; iconSize: 14; iconColor: Style.primary }
                        Text { text: root.student.adresse || "—"; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary }
                    }
                }
            }

            Column {
                spacing: 10
                PrimaryButton {
                    text: "Bulletin Annuel"
                    iconName: "print"
                    enabled: root.currentEnrollment !== null && root.currentEnrollment.classeId > 0
                    onClicked: {
                        var e = root.currentEnrollment
                        if (!e || e.classeId <= 0) return
                        schoolingController.loadAllMatieres()
                        root._bulletinPending = true
                        root._csvPending = false
                        gradesController.loadBulletinData(root.student.id, e.classeId,
                            e.annee_scolaire_id || -1)
                    }
                }
                PrimaryButton {
                    text: "Exporter CSV"
                    iconName: "download"
                    enabled: root.currentEnrollment !== null && root.currentEnrollment.classeId > 0
                    onClicked: {
                        var e = root.currentEnrollment
                        if (!e || e.classeId <= 0) return
                        schoolingController.loadAllMatieres()
                        root._csvPending = true
                        root._bulletinPending = false
                        gradesController.loadBulletinData(root.student.id, e.classeId,
                            e.annee_scolaire_id || -1)
                    }
                }
                OutlineButton {
                    text: "Supprimer"
                    baseColor: Style.errorColor
                    hoverColor: "#BE185D"
                    textColor: "#FFFFFF"
                    onClicked: root.deleteRequested()
                }
            }
        }
    }

    // ─── Profile Content ───
    RowLayout {
        Layout.fillWidth: true; spacing: 24

        // Left: Identity & Info
        ColumnLayout {
            Layout.fillWidth: true; Layout.preferredWidth: 3; spacing: 24

            AppCard {
                Layout.fillWidth: true
                title: "Identité de l'Étudiant"

                ColumnLayout {
                    width: parent.width; spacing: 20

                    RowLayout {
                        Layout.fillWidth: true; spacing: 16
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "DATE DE NAISSANCE" }
                            Text { text: root.student.dateNaissance || "—"; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "CATÉGORIE" }
                            Text { text: root.student.categorie || "—"; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 16
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "PARENT / TUTEUR" }
                            Text { text: root.student.nomParent || "—"; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "CONTACT PARENT" }
                            Text { text: root.student.telParent || "—"; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 16
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "CIN ÉLÈVE" }
                            Text { text: root.student.cinEleve || "—"; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                        Column {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 4
                            SectionLabel { text: "CIN PARENT" }
                            Text { text: root.student.cinParent || "—"; font.pixelSize: 14; font.bold: true; color: Style.textPrimary }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    Column {
                        Layout.fillWidth: true; spacing: 4
                        SectionLabel { text: "COMMENTAIRES ET NOTES" }
                        Text {
                            Layout.fillWidth: true; text: root.student.commentaire || "Aucun commentaire.";
                            font.pixelSize: 13; color: Style.textSecondary; wrapMode: Text.Wrap
                        }
                    }

                    PrimaryButton {
                        Layout.topMargin: 10
                        text: "Modifier les informations"
                        onClicked: root.editRequested()
                    }
                }
            }

            // Enrollment History
            AppCard {
                Layout.fillWidth: true
                title: "Historique des Inscriptions"

                ColumnLayout {
                    width: parent.width; spacing: 16

                    // Table Header
                    RowLayout {
                        Layout.fillWidth: true; spacing: 24
                        Text { Layout.preferredWidth: 120; text: "ANNÉE"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 1 }
                        Text { Layout.fillWidth: true; text: "NIVEAU"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 1 }
                        Text { Layout.preferredWidth: 120; text: "RÉSULTAT"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 1 }
                        Text { Layout.preferredWidth: 80; text: "STATUT"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 1 }
                        Text { Layout.preferredWidth: 80; text: "ACTIONS"; font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary; font.letterSpacing: 1; horizontalAlignment: Text.AlignRight }
                    }

                    Separator { Layout.fillWidth: true }

                    // Table Rows
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Repeater {
                            model: studentController.selectedStudentEnrollments
                            delegate: Rectangle {
                                Layout.fillWidth: true; height: 48; color: "transparent"
                                border.color: Style.borderLight; border.width: 0
                                Separator { anchors.bottom: parent.bottom; width: parent.width }
                                RowLayout {
                                    anchors.fill: parent; spacing: 24
                                    Text { Layout.preferredWidth: 120; text: modelData.anneeScolaire; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.niveauNomById(modelData.niveauId)
                                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                    }
                                    Text { text: modelData.resultat; Layout.preferredWidth: 120; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary }
                                    Badge {
                                        Layout.preferredWidth: 80;
                                        text: modelData.fraisInscriptionPaye ? "PAYÉ" : "IMPAYÉ"
                                        variant: modelData.fraisInscriptionPaye ? "success" : "error"
                                    }
                                    Row {
                                        Layout.preferredWidth: 80
                                        Layout.alignment: Qt.AlignRight
                                        spacing: 4
                                        IconButton {
                                            iconName: "edit"; iconSize: 16
                                            onClicked: {
                                                editEnrollmentModal.enrollmentData = modelData
                                                editEnrollmentModal.show = true
                                            }
                                        }
                                        IconButton {
                                            iconName: "delete"; iconSize: 16; hoverColor: Style.errorColor
                                            onClicked: studentController.deleteEnrollment(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    PrimaryButton {
                        Layout.topMargin: 10
                        text: "Inscrire pour une nouvelle année"
                        iconName: "plus"
                        onClicked: newEnrollmentPopup.open()
                    }
                }
            }
        }

        // Right: Stats / Quick Info
        ColumnLayout {
            Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignTop; spacing: 24

            AppCard {
                Layout.fillWidth: true
                title: "Statut Actuel"
                Column {
                    spacing: 16
                    width: parent.width

                    // Status badge
                    Rectangle {
                        width: parent.width; height: 64; radius: 12
                        color: {
                            var s = root.statusLabel
                            if (s === "Jamais inscrit")      return Style.bgTertiary
                            if (s.indexOf("En cours") >= 0)  return Style.primaryBg
                            if (s === "Réussi")              return "#F0FFF4"
                            if (s === "Redoublant")           return "#FFF7ED"
                            return Style.bgPage
                        }

                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.statusLabel
                                font.pixelSize: 13; font.weight: Font.Black
                                color: {
                                    var s = root.statusLabel
                                    if (s === "Jamais inscrit")      return Style.textTertiary
                                    if (s.indexOf("En cours") >= 0)  return Style.primary
                                    if (s === "Réussi")              return "#166534"
                                    if (s === "Redoublant")           return "#9A3412"
                                    return Style.textPrimary
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.statusNiveauNom
                                visible: root.statusNiveauNom.length > 0
                                font.pixelSize: 11; color: Style.textTertiary; font.weight: Font.Medium
                            }
                        }
                    }

                    // Current year
                    Column {
                        width: parent.width; spacing: 4
                        visible: root.currentEnrollment !== null
                        SectionLabel { text: "ANNÉE SCOLAIRE" }
                        Text {
                            text: root.statusAnneeScolaire || "—"
                            font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                        }
                    }

                    // Total inscriptions
                    Column {
                        width: parent.width; spacing: 4
                        SectionLabel { text: "INSCRIPTIONS TOTALES" }
                        Text {
                            text: studentController.selectedStudentEnrollments.length + " année(s)"
                            font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                        }
                    }
                }
            }
        }
    }

    // New Enrollment Popup
    Popup {
        id: newEnrollmentPopup
        parent: Overlay.overlay; anchors.centerIn: parent
        width: 500; height: 480; modal: true; padding: 0
        background: Rectangle { radius: 24; color: Style.bgWhite }

        property var anneeScolaireOptions: []
        property bool isPaid: false

        onOpened: {
            newErrorMsg.text = ""
            var date = new Date()
            var year = date.getFullYear()
            var baseYear = date.getMonth() < 8 ? year - 1 : year
            anneeScolaireOptions = [
                (baseYear - 2) + "-" + (baseYear - 1),
                (baseYear - 1) + "-" + baseYear,
                baseYear + "-" + (baseYear + 1),
                (baseYear + 1) + "-" + (baseYear + 2),
                (baseYear + 2) + "-" + (baseYear + 3)
            ]
            newYearCombo.currentIndex = 2
            isPaid = false
        }

        contentItem: ColumnLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 20
            Text { text: "Nouvelle Inscription"; font.pixelSize: 18; font.weight: Font.Black; color: Style.primary }

            Text {
                id: newErrorMsg
                visible: text !== ""
                color: Style.errorColor
                font.pixelSize: 13
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            Column {
                Layout.fillWidth: true; spacing: 6
                SectionLabel { text: "ANNÉE SCOLAIRE" }
                Rectangle {
                    Layout.fillWidth: true; width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight
                    ComboBox {
                        id: newYearCombo; anchors.fill: parent; anchors.margins: 2
                        model: newEnrollmentPopup.anneeScolaireOptions
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: newYearCombo.displayText; font.pixelSize: 13; font.bold: true
                            color: Style.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: 8
                        }
                    }
                }
            }

            Column {
                Layout.fillWidth: true; spacing: 6
                SectionLabel { text: "NIVEAU" }
                Rectangle {
                    Layout.fillWidth: true; width: parent.width; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderLight
                    ComboBox {
                        id: levelCombo; anchors.fill: parent; anchors.margins: 2
                        model: root.niveaux; textRole: "nom"
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: levelCombo.displayText; font.pixelSize: 13; font.bold: true
                            color: Style.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: 8
                        }
                    }
                }
            }

            RowLayout {
                spacing: 16
                FormField { id: feeField; Layout.fillWidth: true; label: "FRAIS (DT)"; text: "50.0" }
                Column {
                    spacing: 6
                    SectionLabel { text: "STATUT DU PAIEMENT" }
                    Row {
                        spacing: 12
                        Rectangle {
                            width: 50; height: 26; radius: 13
                            color: newEnrollmentPopup.isPaid ? Style.successColor : Style.bgTertiary
                            Rectangle {
                                x: newEnrollmentPopup.isPaid ? 26 : 2; y: 2; width: 22; height: 22; radius: 11
                                color: "#FFFFFF"
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: newEnrollmentPopup.isPaid = !newEnrollmentPopup.isPaid }
                        }
                        Text {
                            text: newEnrollmentPopup.isPaid ? "PAYÉ" : "NON PAYÉ"
                            font.pixelSize: 12; font.weight: Font.Black
                            color: newEnrollmentPopup.isPaid ? Style.successColor : Style.textTertiary
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 16
                OutlineButton {
                    Layout.fillWidth: true; text: "Annuler"
                    onClicked: newEnrollmentPopup.close()
                }
                PrimaryButton {
                    Layout.fillWidth: true; text: "Valider l'inscription"
                    onClicked: {
                        studentController.enrollStudent({
                            eleveId: root.student.id,
                            anneeScolaire: newYearCombo.currentText,
                            niveauId: root.niveaux[levelCombo.currentIndex].id,
                            resultat: "En cours",
                            fraisInscriptionPaye: newEnrollmentPopup.isPaid,
                            montantInscription: parseFloat(feeField.text),
                            dateInscription: Qt.formatDate(new Date(), "yyyy-MM-dd"),
                            justificatifPath: ""
                        })
                    }
                }
            }
        }
    }
}
