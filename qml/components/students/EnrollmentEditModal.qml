import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform as Platform
import UI.Components

ModalOverlay {
    id: root
    
    property var student: null
    property var niveaux: []
    property var classes: []
    // Internal state for the current enrollment being edited
    property var enrollmentData: null
    property bool isPaid: false
    property bool hallOnly: false
    property int  hallClasseId: 0
    property string currentJustif: ""

    // Filtered helpers
    readonly property var normalNiveaux: {
        var items = []
        for (var i = 0; i < niveaux.length; i++)
            if (!niveaux[i].isFreestyle) items.push(niveaux[i])
        return items
    }
    readonly property var hallClasses: {
        var freestyleIds = []
        for (var i = 0; i < niveaux.length; i++)
            if (niveaux[i].isFreestyle) freestyleIds.push(niveaux[i].id)
        var items = [{"nom": qsTr("— Aucune —"), "id": 0}]
        for (var j = 0; j < classes.length; j++)
            if (freestyleIds.indexOf(classes[j].niveauId) !== -1) items.push(classes[j])
        return items
    }

    modalWidth: 560
    modalRadius: 24

    onClose: {
        root.show = false
        editErrorMsg.text = ""
    }

    onShowChanged: {
        if (!show) return
        editErrorMsg.text = ""

        if (enrollmentData) {
            root.hallOnly     = enrollmentData.hallOnly     || false
            root.hallClasseId = enrollmentData.hallClasseId || 0

            if (!root.hallOnly) {
                // Trouver l'index dans le modèle filtré (normalNiveaux)
                var idx = 0
                for (var i = 0; i < root.normalNiveaux.length; i++) {
                    if (root.normalNiveaux[i].id === enrollmentData.niveauId) { idx = i; break }
                }
                editLevelCombo.currentIndex = idx
            } else {
                // Trouver la classe Hall dans hallClasses
                for (var j = 1; j < root.hallClasses.length; j++) {
                    if (root.hallClasses[j].id === root.hallClasseId) {
                        hallClasseEditCombo.currentIndex = j; break
                    }
                }
            }

            editFeeField.text = enrollmentData.montantInscription.toString()
            isPaid = enrollmentData.fraisInscriptionPaye
            currentJustif = enrollmentData.justificatifPath || ""
            editJustifField.text = currentJustif

            if (enrollmentData.dateInscription) {
                editDateField.setDate(enrollmentData.dateInscription)
            } else {
                editDateField.setDate(Qt.formatDate(new Date(), "yyyy-MM-dd"))
            }
        }
    }

    Platform.FileDialog {
        id: editFileDialog
        title: qsTr("Sélectionner un justificatif")
        fileMode: Platform.FileDialog.OpenFile
        nameFilters: ["Documents (*.pdf *.jpg *.jpeg *.png *.doc *.docx)", "Tous les fichiers (*)"]
        onAccepted: {
            var path = editFileDialog.file.toString()
            path = path.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "")
            editJustifField.text = decodeURIComponent(path)
        }
    }

    Column {
        width: parent.width; spacing: 20; padding: 32; bottomPadding: 24

        RowLayout {
            width: parent.width - 64; spacing: 14
            Rectangle { width: 48; height: 48; radius: 20; color: Style.warningBg || Style.warningBorder
                IconLabel { anchors.centerIn: parent; iconName: "edit"; iconSize: 22; iconColor: Style.warningColor || Style.warningColor } }
            Column { Layout.fillWidth: true; spacing: 2
                Text { text: qsTr("Modifier l'Inscription"); font.pixelSize: 18; font.weight: Font.Black; color: Style.primary }
                Text { text: root.student ? root.student.prenom + " " + root.student.nom : ""
                       font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium
                       elide: Text.ElideRight; width: parent.width }
            }
            IconButton { iconName: "close"; iconSize: 18; onClicked: root.close() }
        }

        Separator { width: parent.width - 64; anchors.horizontalCenter: parent.horizontalCenter }

        Text {
            id: editErrorMsg
            visible: text !== ""
            color: Style.errorColor
            font.pixelSize: 13
            width: parent.width - 64
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.Wrap
        }

        Column {
            width: parent.width - 64; spacing: 16
            anchors.horizontalCenter: parent.horizontalCenter

            // ── Checkbox Seulement Hall ─────────────────────────────
            Rectangle {
                width: parent.width; height: 44; radius: 12
                color: root.hallOnly ? Style.primaryBg : Style.bgPage
                border.color: root.hallOnly ? Style.primary : Style.borderLight
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14; anchors.rightMargin: 14
                    spacing: 10
                    Rectangle {
                        width: 18; height: 18; radius: 4
                        color: root.hallOnly ? Style.primary : "transparent"
                        border.color: root.hallOnly ? Style.primary : Style.borderMedium
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 11; font.bold: true; color: Style.background; visible: root.hallOnly }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Seulement Hall Ezzaytouna")
                        font.pixelSize: 13; font.bold: true
                        color: root.hallOnly ? Style.primary : Style.textPrimary
                        verticalAlignment: Text.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        visible: root.hallOnly
                        text: qsTr("Frais = 0 · Gratuit")
                        font.pixelSize: 11; font.bold: true; color: Style.primary; opacity: 0.8
                    }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.hallOnly = !root.hallOnly
                        if (root.hallOnly) {
                            editFeeField.text = "0"
                            root.isPaid = true
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width; spacing: 16
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    SectionLabel { text: qsTr("ANNÉE SCOLAIRE") }
                    Rectangle {
                        Layout.fillWidth: true; width: parent.width; height: 44; radius: 12
                        color: Style.bgSecondary; border.color: Style.borderLight
                        Text {
                            anchors.fill: parent; anchors.leftMargin: 12
                            text: (root.enrollmentData && root.enrollmentData.anneeScolaire)
                                  ? root.enrollmentData.anneeScolaire
                                  : (setupController.activeTarifs ? setupController.activeTarifs.libelle : "")
                            font.pixelSize: 13; font.bold: true
                            color: Style.textSecondary; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    visible: !root.hallOnly
                    SectionLabel { text: qsTr("NIVEAU") }
                    Rectangle {
                        Layout.fillWidth: true; width: parent.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editLevelCombo; anchors.fill: parent; anchors.margins: 2
                            model: root.normalNiveaux; textRole: "nom"
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                text: editLevelCombo.displayText; font.pixelSize: 13; font.bold: true
                                color: Style.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: 8
                            }
                        }
                    }
                }
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    visible: root.hallOnly
                    SectionLabel { text: qsTr("CLASSE HALL (optionnel)") }
                    Rectangle {
                        Layout.fillWidth: true; width: parent.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: hallClasseEditCombo; anchors.fill: parent; anchors.margins: 2
                            model: root.hallClasses; textRole: "nom"
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                text: hallClasseEditCombo.displayText; font.pixelSize: 13; font.bold: true
                                color: Style.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: 8
                            }
                            onCurrentIndexChanged: root.hallClasseId = currentIndex > 0 ? model[currentIndex].id : 0
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width; spacing: 16
                FormField { id: editFeeField; Layout.fillWidth: true; label: qsTr("FRAIS (DT)") }
                Column {
                    spacing: 6
                    SectionLabel { text: qsTr("STATUT DU PAIEMENT") }
                    Row {
                        spacing: 12
                        Rectangle {
                            width: 50; height: 26; radius: 13
                            color: root.isPaid ? Style.successColor : Style.bgTertiary
                            Rectangle {
                                x: root.isPaid ? 26 : 2; y: 2; width: 22; height: 22; radius: 11
                                color: Style.background
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.isPaid = !root.isPaid }
                        }
                        Text { 
                            text: root.isPaid ? "PAYÉ" : "NON PAYÉ"
                            font.pixelSize: 12; font.weight: Font.Black
                            color: root.isPaid ? Style.successColor : Style.textTertiary
                        }
                    }
                }
            }

            DateField {
                id: editDateField
                width: parent.width
                label: qsTr("DATE D'INSCRIPTION / PAIEMENT")
            }

            Column {
                width: parent.width; spacing: 6
                SectionLabel { text: qsTr("JUSTIFICATIF (PIÈCE JOINTE)") }
                RowLayout { width: parent.width; spacing: 8
                    Rectangle { Layout.fillWidth: true; height: 44; radius: 12
                                color: Style.bgPage; border.color: Style.borderLight
                        TextInput {
                            id: editJustifField
                            anchors.fill: parent; anchors.margins: 12
                            font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                            clip: true; selectByMouse: true; readOnly: true
                            Text { visible: !editJustifField.text; text: qsTr("Aucun fichier sélectionné")
                                   font: editJustifField.font; color: Style.textTertiary }
                        }
                    }
                    Rectangle { Layout.preferredWidth: 44; height: 44; radius: 12
                        color: editBrowseHover.containsMouse ? Style.primary : Style.bgPage
                        border.color: editBrowseHover.containsMouse ? Style.primary : Style.borderLight
                        Text { anchors.centerIn: parent; text: qsTr("…")
                               font.pixelSize: 16; font.bold: true
                               color: editBrowseHover.containsMouse ? "white" : Style.textTertiary }
                        MouseArea { id: editBrowseHover; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: editFileDialog.open() }
                    }
                }
            }
            
            // Désinscrire / Inscrire — full width
            Rectangle {
                width: parent.width; height: 44; radius: 12
                readonly property bool isEnrolled: root.student && root.student.inscritAnneeActive
                color: actionMa.containsMouse
                       ? (isEnrolled ? Style.errorColor : Style.successColor)
                       : "transparent"
                border.color: isEnrolled ? Style.errorColor : Style.successColor; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: parent.isEnrolled ? "Désinscrire" : "Inscrire"
                    font.pixelSize: 13; font.weight: Font.Bold
                    color: actionMa.containsMouse ? Style.background
                           : (parent.isEnrolled ? Style.errorColor : Style.successColor)
                }
                MouseArea {
                    id: actionMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (parent.isEnrolled) {
                            if (root.enrollmentData)
                                studentController.deleteEnrollment(root.enrollmentData.id)
                        } else {
                            studentController.enrollStudent({
                                eleveId: root.student.id,
                                anneeScolaire: setupController.activeTarifs ? setupController.activeTarifs.libelle : "",
                                annee_scolaire_id: setupController.activeTarifs ? setupController.activeTarifs.id : 0,
                                niveauId: (!root.hallOnly && root.normalNiveaux.length > 0) ? root.normalNiveaux[editLevelCombo.currentIndex].id : 0,
                                resultat: "En cours",
                                fraisInscriptionPaye: root.isPaid,
                                montantInscription: parseFloat(editFeeField.text.replace(",", ".")) || 0,
                                hallOnly: root.hallOnly,
                                hallClasseId: root.hallClasseId
                            })
                        }
                        root.close()
                    }
                }
            }

            RowLayout {
                width: parent.width; spacing: 10

                OutlineButton {
                    Layout.fillWidth: true; text: qsTr("Annuler")
                    onClicked: root.close()
                }
                PrimaryButton {
                    Layout.fillWidth: true; text: qsTr("Mettre à jour")
                    onClicked: {
                        studentController.updateEnrollment(root.enrollmentData.id, {
                            eleveId: root.student.id,
                            anneeScolaire: root.enrollmentData.anneeScolaire,
                            annee_scolaire_id: root.enrollmentData.annee_scolaire_id || 0,
                            niveauId: (!root.hallOnly && root.normalNiveaux.length > 0) ? root.normalNiveaux[editLevelCombo.currentIndex].id : 0,
                            resultat: root.enrollmentData ? root.enrollmentData.resultat : "En cours",
                            fraisInscriptionPaye: root.isPaid,
                            montantInscription: parseFloat(editFeeField.text.replace(",", ".")),
                            dateInscription: editDateField.dateString !== "" ? editDateField.dateString : Qt.formatDate(new Date(), "yyyy-MM-dd"),
                            justificatifPath: editJustifField.text.trim(),
                            hallOnly: root.hallOnly,
                            hallClasseId: root.hallClasseId
                        })
                    }
                }
            }
        }
    }
}
