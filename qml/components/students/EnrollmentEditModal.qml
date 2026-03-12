import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform as Platform
import UI.Components

ModalOverlay {
    id: root
    
    property var student: null
    property var niveaux: []
    // Internal state for the current enrollment being edited
    property var enrollmentData: null
    property bool isPaid: false
    property string currentJustif: ""

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
            for (var i = 0; i < root.niveaux.length; i++) {
                if (root.niveaux[i].id === enrollmentData.niveauId) {
                    editLevelCombo.currentIndex = i
                    break
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
        title: "Sélectionner un justificatif"
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
                Text { text: "Modifier l'Inscription"; font.pixelSize: 18; font.weight: Font.Black; color: Style.primary }
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

            RowLayout {
                width: parent.width; spacing: 16
                Column {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 6
                    SectionLabel { text: "ANNÉE SCOLAIRE" }
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
                    SectionLabel { text: "NIVEAU" }
                    Rectangle {
                        Layout.fillWidth: true; width: parent.width; height: 44; radius: 12
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editLevelCombo; anchors.fill: parent; anchors.margins: 2
                            model: root.niveaux; textRole: "nom"
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                text: editLevelCombo.displayText; font.pixelSize: 13; font.bold: true
                                color: Style.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: 8
                            }
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width; spacing: 16
                FormField { id: editFeeField; Layout.fillWidth: true; label: "FRAIS (DT)" }
                Column {
                    spacing: 6
                    SectionLabel { text: "STATUT DU PAIEMENT" }
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
                label: "DATE D'INSCRIPTION / PAIEMENT"
            }

            Column {
                width: parent.width; spacing: 6
                SectionLabel { text: "JUSTIFICATIF (PIÈCE JOINTE)" }
                RowLayout { width: parent.width; spacing: 8
                    Rectangle { Layout.fillWidth: true; height: 44; radius: 12
                                color: Style.bgPage; border.color: Style.borderLight
                        TextInput {
                            id: editJustifField
                            anchors.fill: parent; anchors.margins: 12
                            font.pixelSize: 12; font.bold: true; color: Style.textPrimary
                            clip: true; selectByMouse: true; readOnly: true
                            Text { visible: !editJustifField.text; text: "Aucun fichier sélectionné"
                                   font: editJustifField.font; color: Style.textTertiary }
                        }
                    }
                    Rectangle { Layout.preferredWidth: 44; height: 44; radius: 12
                        color: editBrowseHover.containsMouse ? Style.primary : Style.bgPage
                        border.color: editBrowseHover.containsMouse ? Style.primary : Style.borderLight
                        Text { anchors.centerIn: parent; text: "…"
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
                                niveauId: root.niveaux.length > 0 ? root.niveaux[editLevelCombo.currentIndex].id : 0,
                                resultat: "En cours",
                                fraisInscriptionPaye: root.isPaid,
                                montantInscription: parseFloat(editFeeField.text.replace(",", ".")) || 0
                            })
                        }
                        root.close()
                    }
                }
            }

            RowLayout {
                width: parent.width; spacing: 10

                OutlineButton {
                    Layout.fillWidth: true; text: "Annuler"
                    onClicked: root.close()
                }
                PrimaryButton {
                    Layout.fillWidth: true; text: "Mettre à jour"
                    onClicked: {
                        studentController.updateEnrollment(root.enrollmentData.id, {
                            eleveId: root.student.id,
                            anneeScolaire: root.enrollmentData.anneeScolaire,
                            annee_scolaire_id: root.enrollmentData.annee_scolaire_id || 0,
                            niveauId: root.niveaux[editLevelCombo.currentIndex].id,
                            resultat: root.enrollmentData ? root.enrollmentData.resultat : "En cours",
                            fraisInscriptionPaye: root.isPaid,
                            montantInscription: parseFloat(editFeeField.text.replace(",", ".")),
                            dateInscription: editDateField.dateString !== "" ? editDateField.dateString : Qt.formatDate(new Date(), "yyyy-MM-dd"),
                            justificatifPath: editJustifField.text.trim()
                        })
                    }
                }
            }
        }
    }
}
