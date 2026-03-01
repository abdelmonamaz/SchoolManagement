import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1 as Platform
import UI.Components

ModalOverlay {
    id: root
    
    property var student: null
    property var niveaux: []
    
    // Internal state for the current enrollment being edited
    property var enrollmentData: null
    property var anneeScolaireOptions: []
    property bool isPaid: false
    property string currentJustif: ""

    modalWidth: 560
    modalRadius: 24

    onClose: {
        root.show = false
        editErrorMsg.text = ""
        enrollmentData = null
    }

    onShowChanged: {
        if (!show) return
        editErrorMsg.text = ""
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

        if (enrollmentData) {
            var foundYear = false
            for (var j = 0; j < anneeScolaireOptions.length; j++) {
                if (anneeScolaireOptions[j] === enrollmentData.anneeScolaire) {
                    editYearCombo.currentIndex = j
                    foundYear = true
                    break
                }
            }
            if (!foundYear) {
                // Add it if it's an older/future year not in the default list
                anneeScolaireOptions.unshift(enrollmentData.anneeScolaire)
                editYearCombo.currentIndex = 0
            }

            for (var i = 0; i < root.niveaux.length; i++) {
                if (root.niveaux[i].id === enrollmentData.niveauId) {
                    editLevelCombo.currentIndex = i
                    break
                }
            }
            editResultField.text = enrollmentData.resultat || "En cours"
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
            Rectangle { width: 48; height: 48; radius: 20; color: Style.warningBg || "#FEF3C7"
                IconLabel { anchors.centerIn: parent; iconName: "edit"; iconSize: 22; iconColor: Style.warningColor || "#D97706" } }
            Column { Layout.fillWidth: true; spacing: 2
                Text { text: "Modifier l'Inscription"; font.pixelSize: 18; font.weight: Font.Black; color: Style.primary }
                Text { text: root.student ? root.student.prenom + " " + root.student.nom : ""
                       font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium
                       elide: Text.ElideRight; width: parent.width }
            }
            IconButton { iconName: "close"; iconSize: 18; onClicked: root.onClose() }
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
                        color: Style.bgPage; border.color: Style.borderLight
                        ComboBox {
                            id: editYearCombo; anchors.fill: parent; anchors.margins: 2
                            model: root.anneeScolaireOptions
                            background: Rectangle { color: "transparent" }
                            contentItem: Text {
                                text: editYearCombo.displayText; font.pixelSize: 13; font.bold: true
                                color: Style.textPrimary; verticalAlignment: Text.AlignVCenter; leftPadding: 8
                            }
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

            FormField { id: editResultField; width: parent.width; label: "RÉSULTAT" }
            
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
                                color: "#FFFFFF"
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
            
            RowLayout {
                width: parent.width; spacing: 16; Layout.topMargin: 10
                OutlineButton {
                    Layout.fillWidth: true; text: "Annuler"
                    onClicked: root.onClose()
                }
                PrimaryButton {
                    Layout.fillWidth: true; text: "Mettre à jour"
                    onClicked: {
                        studentController.updateEnrollment(root.enrollmentData.id, {
                            eleveId: root.student.id,
                            anneeScolaire: editYearCombo.currentText,
                            niveauId: root.niveaux[editLevelCombo.currentIndex].id,
                            resultat: editResultField.text,
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
