import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform as Platform
import UI.Components

Item {
    id: settingsPage
    implicitHeight: mainLayout.implicitHeight

    // ── Helpers exercice comptable ─────────────────────────────────────────
    property bool updatingDate: false
    property bool tarifsSaved: false
    property bool associationSaved: false
    property int loadedAgePassage: setupController.associationData.agePassageAdulte || 12

    function isoToLocalDate(iso) {
        var p = iso.split("-")
        return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
    }
    function localDateToIso(d) {
        var m = d.getMonth() + 1; var day = d.getDate()
        return d.getFullYear() + "-" + (m < 10 ? "0" + m : "" + m)
               + "-" + (day < 10 ? "0" + day : "" + day)
    }

    function _doSaveAssociation(agePassage) {
        associationSaved = true
        loadedAgePassage = agePassage
        var langue = langueCombo.currentValue || "français"
        setupController.saveAssociation({
            nomAssociation:   nomEcoleField.text.trim(),
            adresse:          adresseEdit.text.trim(),
            exerciceDebut:    exDebutField.isValid ? exDebutField.dateString
                                                   : (setupController.associationData.exerciceDebut || "01-01"),
            exerciceFin:      exFinField.isValid   ? exFinField.dateString
                                                   : (setupController.associationData.exerciceFin   || "12-31"),
            agePassageAdulte: agePassage,
            langue:           langue
        })
        appController.applyLanguage(langue)
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        PageHeader {
            Layout.fillWidth: true
            Layout.bottomMargin: 28
            title: qsTr("Paramètres du Système")
            subtitle: qsTr("Configurez l'environnement Ez-Zaytouna selon vos besoins.")
        }

        // ─── Cards ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            // ── Left column ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
            // ─── Configuration des Tarifs ───
            AppCard {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            title: qsTr("Configuration des Tarifs")
            subtitle: qsTr("Tarifs mensuels et frais d'inscription de l'année scolaire active.")

            Column {
                width: parent.width
                spacing: 24

                // ── Mensualités ──
                Text {
                    text: qsTr("MENSUALITÉS")
                    font.pixelSize: 10; font.weight: Font.Black
                    color: Style.textTertiary; font.letterSpacing: 1
                }

                GridLayout {
                    width: parent.width
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 0

                    // Tarif Jeune (mensuel)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: childCol.implicitHeight + 48
                        radius: 24
                        color: Style.chartBlueLight
                        border.color: Style.chart3; border.width: 1

                        Column {
                            id: childCol
                            anchors.fill: parent; anchors.margins: 24
                            spacing: 12

                            Text {
                                text: qsTr("TARIF JEUNE (mensuel)")
                                font.pixelSize: 10; font.weight: Font.Black
                                color: Style.chartBlue; font.letterSpacing: 2
                            }

                            RowLayout {
                                width: parent.width; spacing: 8

                                TextField {
                                    id: tarifJeuneInput
                                    Layout.fillWidth: true
                                    height: 48
                                    text: (setupController.activeTarifs.tarifJeune || 150).toString()
                                    font.pixelSize: 16; font.weight: Font.Black; color: Style.chartBlue
                                    selectByMouse: true
                                    leftPadding: 16; rightPadding: 8
                                    topPadding: 0; bottomPadding: 0
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextEdited: settingsPage.tarifsSaved = false
                                    validator: RegularExpressionValidator {
                                        regularExpression: /^\d{0,5}(\.\d{0,2})?$/
                                    }
                                    background: Rectangle {
                                        radius: 12; color: Style.background
                                        border.width: parent.activeFocus ? 2 : 1
                                        border.color: parent.activeFocus ? Style.primary
                                                    : parent.hovered ? Style.chart3 : Style.chart3
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text { text: qsTr("DT/mois"); font.pixelSize: 13; font.weight: Font.Black; color: Style.chartBlue }
                            }
                        }
                    }

                    // Tarif Adulte (mensuel)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: adultCol.implicitHeight + 48
                        radius: 24
                        color: Style.warningBorder; border.color: Style.warningBorder; border.width: 1

                        Column {
                            id: adultCol
                            anchors.fill: parent; anchors.margins: 24
                            spacing: 12

                            Text {
                                text: qsTr("TARIF ADULTE (mensuel)")
                                font.pixelSize: 10; font.weight: Font.Black
                                color: Style.warningColor; font.letterSpacing: 2
                            }

                            RowLayout {
                                width: parent.width; spacing: 8

                                TextField {
                                    id: tarifAdulteInput
                                    Layout.fillWidth: true
                                    height: 48
                                    text: (setupController.activeTarifs.tarifAdulte || 250).toString()
                                    font.pixelSize: 16; font.weight: Font.Black; color: Style.warningColor
                                    selectByMouse: true
                                    leftPadding: 16; rightPadding: 8
                                    topPadding: 0; bottomPadding: 0
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextEdited: settingsPage.tarifsSaved = false
                                    validator: RegularExpressionValidator {
                                        regularExpression: /^\d{0,5}(\.\d{0,2})?$/
                                    }
                                    background: Rectangle {
                                        radius: 12; color: Style.background
                                        border.width: parent.activeFocus ? 2 : 1
                                        border.color: parent.activeFocus ? Style.primary
                                                    : parent.hovered ? Style.warningBorder : Style.warningBorder
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text { text: qsTr("DT/mois"); font.pixelSize: 13; font.weight: Font.Black; color: Style.warningColor }
                            }
                        }
                    }
                }

                // ── Frais d'inscription ──
                Text {
                    text: qsTr("FRAIS D'INSCRIPTION (unique)")
                    font.pixelSize: 10; font.weight: Font.Black
                    color: Style.textTertiary; font.letterSpacing: 1
                }

                GridLayout {
                    width: parent.width
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 0

                    // Frais Jeune
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: fraisJCol.implicitHeight + 48
                        radius: 24
                        color: Style.successBg; border.color: Style.successBorder; border.width: 1

                        Column {
                            id: fraisJCol
                            anchors.fill: parent; anchors.margins: 24
                            spacing: 12

                            Text {
                                text: qsTr("FRAIS JEUNE")
                                font.pixelSize: 10; font.weight: Font.Black
                                color: Style.successColor; font.letterSpacing: 2
                            }

                            RowLayout {
                                width: parent.width; spacing: 8

                                TextField {
                                    id: fraisJeuneInput
                                    Layout.fillWidth: true
                                    height: 48
                                    text: (setupController.activeTarifs.fraisInscriptionJeune || 50).toString()
                                    font.pixelSize: 16; font.weight: Font.Black; color: Style.successColor
                                    selectByMouse: true
                                    leftPadding: 16; rightPadding: 8
                                    topPadding: 0; bottomPadding: 0
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextEdited: settingsPage.tarifsSaved = false
                                    validator: RegularExpressionValidator {
                                        regularExpression: /^\d{0,5}(\.\d{0,2})?$/
                                    }
                                    background: Rectangle {
                                        radius: 12; color: Style.background
                                        border.width: parent.activeFocus ? 2 : 1
                                        border.color: parent.activeFocus ? Style.primary
                                                    : parent.hovered ? Style.successColor : Style.successBorder
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text { text: qsTr("DT"); font.pixelSize: 13; font.weight: Font.Black; color: Style.successColor }
                            }
                        }
                    }

                    // Frais Adulte
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: fraisACol.implicitHeight + 48
                        radius: 24
                        color: Style.background; border.color: Style.border; border.width: 1

                        Column {
                            id: fraisACol
                            anchors.fill: parent; anchors.margins: 24
                            spacing: 12

                            Text {
                                text: qsTr("FRAIS ADULTE")
                                font.pixelSize: 10; font.weight: Font.Black
                                color: Style.chart3; font.letterSpacing: 2
                            }

                            RowLayout {
                                width: parent.width; spacing: 8

                                TextField {
                                    id: fraisAdulteInput
                                    Layout.fillWidth: true
                                    height: 48
                                    text: (setupController.activeTarifs.fraisInscriptionAdulte || 50).toString()
                                    font.pixelSize: 16; font.weight: Font.Black; color: Style.chart3
                                    selectByMouse: true
                                    leftPadding: 16; rightPadding: 8
                                    topPadding: 0; bottomPadding: 0
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextEdited: settingsPage.tarifsSaved = false
                                    validator: RegularExpressionValidator {
                                        regularExpression: /^\d{0,5}(\.\d{0,2})?$/
                                    }
                                    background: Rectangle {
                                        radius: 12; color: Style.background
                                        border.width: parent.activeFocus ? 2 : 1
                                        border.color: parent.activeFocus ? Style.primary
                                                    : parent.hovered ? Style.chart3 : Style.border
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text { text: qsTr("DT"); font.pixelSize: 13; font.weight: Font.Black; color: Style.chart3 }
                            }
                        }
                    }
                }

                // Info + bouton Enregistrer
                RowLayout {
                    width: parent.width; spacing: 16

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: infoRow.implicitHeight + 24
                        radius: 16; color: Style.bgPage
                        border.color: Style.borderLight; border.width: 1

                        RowLayout {
                            id: infoRow
                            anchors.fill: parent; anchors.margins: 14; spacing: 10

                            IconLabel { iconName: "info"; iconSize: 16; iconColor: Style.textSecondary }

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Ces tarifs s'appliquent lors de la génération du grand livre mensuel et sont pré-remplis à l'inscription.")
                                font.pixelSize: 10; font.weight: Font.Bold
                                color: Style.textSecondary; wrapMode: Text.WordWrap; lineHeight: 1.5
                            }
                        }
                    }

                    PrimaryButton {
                        text: qsTr("Enregistrer les tarifs")
                        enabled: !settingsPage.tarifsSaved
                        onClicked: {
                            settingsPage.tarifsSaved = true
                            setupController.updateTarifs({
                                tarifJeune:             parseFloat(tarifJeuneInput.text)  || 0,
                                tarifAdulte:            parseFloat(tarifAdulteInput.text) || 0,
                                fraisInscriptionJeune:  parseFloat(fraisJeuneInput.text)  || 0,
                                fraisInscriptionAdulte: parseFloat(fraisAdulteInput.text) || 0
                            })
                        }
                    }
                }
            }
            } // end tarifs AppCard

            // School Info Form
            AppCard {
                Layout.fillWidth: true
                title: qsTr("Informations de l'Établissement")

                Column {
                    width: parent.width
                    spacing: 20

                    FormField {
                        id: nomEcoleField
                        width: parent.width
                        label: qsTr("NOM DE L'ASSOCIATION")
                        placeholder: qsTr("ex: Ez-Zaytouna")
                        text: setupController.associationData.nomAssociation || ""
                        onTextChanged: settingsPage.associationSaved = false
                    }

                    Column {
                        width: parent.width; spacing: 6
                        SectionLabel { text: qsTr("ADRESSE") }
                        Rectangle {
                            width: parent.width; height: 80; radius: 12
                            color: Style.bgPage; border.color: Style.borderLight
                            TextEdit {
                                id: adresseEdit
                                anchors.fill: parent; anchors.margins: 12
                                text: setupController.associationData.adresse || ""
                                font.pixelSize: 13; font.bold: true
                                color: Style.textPrimary
                                wrapMode: TextEdit.Wrap
                                onTextChanged: settingsPage.associationSaved = false
                            }
                        }
                    }

                    // ── Langue de l'application ──
                    Column {
                        width: parent.width; spacing: 6
                        SectionLabel { text: qsTr("LANGUE DE L'APPLICATION") }
                        Rectangle {
                            width: parent.width; height: 40; radius: 10
                            color: Style.bgPage; border.color: Style.borderLight
                            ComboBox {
                                id: langueCombo
                                anchors.fill: parent; anchors.margins: 2
                                model: ["français", "anglais", "arabe"]
                                background: Rectangle { color: "transparent" }
                                contentItem: Text {
                                    text: langueCombo.displayText
                                    font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                    verticalAlignment: Text.AlignVCenter; leftPadding: 8
                                }
                                Component.onCompleted: {
                                    var l = setupController.associationData.langue || "français"
                                    currentIndex = indexOfValue(l) !== -1 ? indexOfValue(l) : 0
                                }
                                onCurrentIndexChanged: settingsPage.associationSaved = false
                            }
                        }
                    }

                    // ── Exercice comptable ──
                    Text {
                        text: qsTr("EXERCICE COMPTABLE")
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.primary; font.letterSpacing: 1
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 16

                        DateField {
                            id: exDebutField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            label: qsTr("DATE DE DÉBUT")
                            Component.onCompleted: {
                                var v = setupController.associationData.exerciceDebut || ""
                                if (v) setDate(v)
                            }
                            onDateStringChanged: {
                                if (!settingsPage.updatingDate && isValid)
                                    settingsPage.associationSaved = false
                                if (settingsPage.updatingDate || !isValid) return
                                settingsPage.updatingDate = true
                                var d = settingsPage.isoToLocalDate(dateString)
                                d.setMonth(d.getMonth() + 12)
                                d.setDate(d.getDate() - 1)
                                exFinField.setDate(settingsPage.localDateToIso(d))
                                settingsPage.updatingDate = false
                            }
                        }

                        DateField {
                            id: exFinField
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            label: qsTr("DATE DE FIN")
                            Component.onCompleted: {
                                var v = setupController.associationData.exerciceFin || ""
                                if (v) setDate(v)
                            }
                            onDateStringChanged: {
                                if (!settingsPage.updatingDate && isValid)
                                    settingsPage.associationSaved = false
                                if (settingsPage.updatingDate || !isValid) return
                                settingsPage.updatingDate = true
                                var d = settingsPage.isoToLocalDate(dateString)
                                d.setDate(d.getDate() + 1)
                                d.setMonth(d.getMonth() - 12)
                                exDebutField.setDate(settingsPage.localDateToIso(d))
                                settingsPage.updatingDate = false
                            }
                        }
                    }

                    // ── Âge de passage adulte ──
                    Text {
                        text: qsTr("CATÉGORISATION")
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.primary; font.letterSpacing: 1
                    }

                    RowLayout {
                        width: parent.width; spacing: 12
                        Text {
                            text: qsTr("Âge de passage Adulte :")
                            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                            Layout.alignment: Qt.AlignVCenter
                        }
                        TextField {
                            id: agePassageField
                            Layout.preferredWidth: 72; height: 40
                            text: (setupController.associationData.agePassageAdulte || 12).toString()
                            font.pixelSize: 14; font.bold: true; color: Style.textPrimary
                            horizontalAlignment: TextInput.AlignHCenter
                            selectByMouse: true
                            validator: IntValidator { bottom: 1; top: 99 }
                            onTextEdited: settingsPage.associationSaved = false
                            background: Rectangle {
                                radius: 10; color: Style.bgPage; border.color: Style.borderLight
                                border.width: parent.activeFocus ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 120 } }
                            }
                        }
                        Text {
                            text: qsTr("ans")
                            font.pixelSize: 13; font.bold: true; color: Style.textSecondary
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Item { Layout.fillWidth: true }
                    }

                    PrimaryButton {
                        text: qsTr("Enregistrer les modifications")
                        enabled: !settingsPage.associationSaved
                        onClicked: {
                            var newAge = parseInt(agePassageField.text) || 12
                            if (newAge !== settingsPage.loadedAgePassage) {
                                confirmAgePopup.pendingAge = newAge
                                confirmAgePopup.open()
                            } else {
                                settingsPage._doSaveAssociation(newAge)
                            }
                        }
                    }
                }
            }

            } // end left ColumnLayout

            // ── Right column ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 10

            // ─── Sauvegarde & Restauration ───
            AppCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: qsTr("Sauvegarde & Restauration")
                subtitle: qsTr("Gérez les sauvegardes de votre base de données.")

                Column {
                    width: parent.width
                    spacing: 20

                    // ── Sauvegarde automatique ──
                    Text {
                        text: qsTr("SAUVEGARDE AUTOMATIQUE")
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.textTertiary; font.letterSpacing: 1
                    }

                    // Toggle activation
                    Rectangle {
                        width: parent.width
                        height: 52; radius: 14
                        color: backupController.autoBackupEnabled ? Style.primaryBg : Style.bgPage
                        border.color: backupController.autoBackupEnabled ? Style.primary : Style.borderLight
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 12

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                verticalAlignment: Text.AlignVCenter
                                text: qsTr("Activer la sauvegarde automatique")
                                font.pixelSize: 13; font.bold: true
                                color: backupController.autoBackupEnabled ? Style.primary : Style.textPrimary
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: 44; height: 24; radius: 12
                                color: backupController.autoBackupEnabled ? Style.primary : Style.borderMedium
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    x: backupController.autoBackupEnabled ? parent.width - width - 3 : 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 18; height: 18; radius: 9
                                    color: "white"
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: backupController.autoBackupEnabled = !backupController.autoBackupEnabled
                        }
                    }

                    // Frequency + folder (only visible when enabled)
                    Column {
                        width: parent.width; spacing: 16
                        visible: backupController.autoBackupEnabled
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        // Frequency selector
                        Column {
                            width: parent.width; spacing: 6

                            SectionLabel { text: qsTr("FRÉQUENCE") }

                            RowLayout {
                                width: parent.width; spacing: 8

                                Repeater {
                                    model: [
                                        { label: qsTr("Quotidien"),  days: 1  },
                                        { label: qsTr("Hebdo"),      days: 7  },
                                        { label: qsTr("Mensuel"),    days: 30 }
                                    ]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true; height: 40; radius: 10
                                        property bool sel: backupController.autoBackupInterval === modelData.days
                                        color: sel ? Style.primary : Style.bgPage
                                        border.color: sel ? Style.primary : Style.borderLight
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.pixelSize: 12; font.bold: true
                                            color: sel ? Style.background : Style.textSecondary
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: backupController.autoBackupInterval = modelData.days
                                        }
                                    }
                                }
                            }
                        }

                        // Last auto-backup info
                        Text {
                            visible: backupController.lastAutoBackupDate.length > 0
                            text: qsTr("Dernière sauvegarde auto : ") + backupController.lastAutoBackupDate
                            font.pixelSize: 10; font.weight: Font.Bold
                            color: Style.textTertiary
                        }

                        // Destination folder
                        Column {
                            width: parent.width; spacing: 6

                            SectionLabel { text: qsTr("DOSSIER DE DESTINATION") }

                            RowLayout {
                                width: parent.width; spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true; height: 44
                                    radius: 12; color: Style.bgPage
                                    border.color: Style.borderLight; border.width: 1
                                    clip: true

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left; anchors.leftMargin: 14
                                        anchors.right: parent.right; anchors.rightMargin: 14
                                        text: backupController.autoBackupPath.length > 0
                                              ? backupController.autoBackupPath
                                              : qsTr("Aucun dossier sélectionné")
                                        font.pixelSize: 12; font.bold: true
                                        color: backupController.autoBackupPath.length > 0
                                               ? Style.textPrimary : Style.textTertiary
                                        elide: Text.ElideLeft
                                    }
                                }

                                OutlineButton {
                                    text: qsTr("Parcourir")
                                    onClicked: folderDialog.open()
                                }
                            }
                        }
                    }

                    PrimaryButton {
                        width: parent.width
                        text: qsTr("Sauvegarder maintenant")
                        onClicked: saveFileDialog.open()
                    }

                    // ── Séparateur ──
                    Rectangle {
                        width: parent.width; height: 1
                        color: Style.borderLight
                    }

                    // ── Restauration ──
                    Text {
                        text: qsTr("RESTAURATION")
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.textTertiary; font.letterSpacing: 1
                    }

                    Rectangle {
                        width: parent.width
                        implicitHeight: warnRow.implicitHeight + 24
                        radius: 14; color: Style.warningBorder
                        border.color: Style.warningBorder; border.width: 1

                        RowLayout {
                            id: warnRow
                            anchors.fill: parent; anchors.margins: 14; spacing: 10

                            Text { text: qsTr("⚠"); font.pixelSize: 16 }

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Charger une base de données remplacera toutes les données actuelles. L'application devra redémarrer.")
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: Style.warningColor; wrapMode: Text.WordWrap; lineHeight: 1.4
                            }
                        }
                    }

                    Rectangle {
                        id: loadDbButton
                        width: parent.width; height: 42; radius: 10
                        property bool loading: false
                        color: loadDbMa.containsMouse ? Style.warningColor : Style.warningColor
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.centerIn: parent; spacing: 8
                            Text {
                                text: loadDbButton.loading ? "⏳" : "📂"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: loadDbButton.loading ? qsTr("Chargement en cours…") : qsTr("Charger une base de données")
                                font.pixelSize: 12; font.bold: true; color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: loadDbMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !loadDbButton.loading
                            onClicked: {
                                loadDbButton.loading = true
                                loadFileDialog.open()
                            }
                        }
                    }

                    // Toast / feedback
                    Rectangle {
                        id: feedbackBar
                        width: parent.width
                        height: feedbackText.implicitHeight + 16
                        radius: 10
                        visible: feedbackText.text.length > 0
                        color: feedbackIsError ? Style.errorBorder : Style.successBg
                        border.color: feedbackIsError ? Style.errorBorder : Style.successBorder

                        property bool feedbackIsError: false

                        Text {
                            id: feedbackText
                            anchors.fill: parent; anchors.margins: 10
                            font.pixelSize: 11; font.weight: Font.Bold
                            wrapMode: Text.WordWrap; lineHeight: 1.4
                            color: feedbackBar.feedbackIsError ? Style.errorColor : Style.successColor
                        }

                        Timer {
                            id: feedbackTimer
                            interval: 4000
                            onTriggered: feedbackText.text = ""
                        }
                    }
                }
            }

            } // end right ColumnLayout
        } // end RowLayout

        Item { Layout.preferredHeight: 20 }

        // ── Clôture d'Année Scolaire ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 88
            radius: 20
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Style.errorBg }
                GradientStop { position: 1.0; color: Style.errorBg }
            }
            border.color: Style.errorBorder; border.width: 1

            RowLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 16

                // Lock icon
                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: Style.errorColor
                    Text { anchors.centerIn: parent; text: qsTr("🔒"); font.pixelSize: 22 }
                }

                // Text
                Column {
                    Layout.fillWidth: true; spacing: 4
                    Text {
                        text: qsTr("Clôture d'Année Scolaire")
                        font.pixelSize: 16; font.bold: true; color: Style.errorColor
                    }
                    Text {
                        text: qsTr("Archivez l'année ") + (setupController.activeTarifs.libelle || qsTr("en cours"))
                              + qsTr(", faites passer les étudiants au niveau supérieur et générez les rapports finaux.")
                        font.pixelSize: 12; color: Style.errorColor
                        wrapMode: Text.WordWrap; width: parent.width
                    }
                    Row {
                        spacing: 16
                        Row {
                            spacing: 5
                            Rectangle { width: 7; height: 7; radius: 4; color: Style.errorColor; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: qsTr("ACTION IRRÉVERSIBLE"); font.pixelSize: 10; font.bold: true; color: Style.errorColor; font.letterSpacing: 0.5 }
                        }
                        Text {
                            text: qsTr("Année en cours : ") + (setupController.activeTarifs.libelle || "-")
                            font.pixelSize: 11; font.bold: true; color: Style.errorColor
                        }
                    }
                }

                // Button
                Rectangle {
                    width: 180; height: 44; radius: 12
                    color: Style.errorColor

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent; spacing: 8
                        Text {
                            text: qsTr("🔒"); font.pixelSize: 14; color: "white"
                            height: 20; verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: qsTr("DÉMARRER LA CLÔTURE")
                            font.pixelSize: 11; font.bold: true; color: "white"; font.letterSpacing: 0.5
                            height: 20; verticalAlignment: Text.AlignVCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onEntered: parent.color = Style.errorColor
                        onExited:  parent.color = Style.errorColor
                        onClicked: {
                            yearClosureController.loadStats()
                            yearClosureController.loadStudentProgressions()
                            yearClosureModal.open()
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }

    // ── Clôture modal ──────────────────────────────────────────────────────
    YearClosureModal { id: yearClosureModal }

    // ── Dialogs sauvegarde / restauration ─────────────────────────────────
    Platform.FolderDialog {
        id: folderDialog
        title: qsTr("Choisir le dossier de sauvegarde automatique")
        onAccepted: backupController.autoBackupPath = folder.toString()
    }

    Platform.FileDialog {
        id: saveFileDialog
        title: qsTr("Enregistrer une copie de la base de données")
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["Archive ZIP (*.zip)", "Tous les fichiers (*)"]
        defaultSuffix: "zip"
        onAccepted: {
            var ok = backupController.copyDatabaseTo(file.toString())
            // feedback handled by backupSuccess / backupError signals
        }
    }

    Platform.FileDialog {
        id: loadFileDialog
        title: qsTr("Charger une base de données")
        fileMode: Platform.FileDialog.OpenFile
        nameFilters: ["Archive ZIP (*.zip)", "Base de données (*.db)", "Tous les fichiers (*)"]
        onAccepted: backupController.loadDatabase(file.toString())
        onRejected: loadDbButton.loading = false
    }

    // BackupController signal handlers
    Connections {
        target: backupController

        function onBackupSuccess(path) {
            feedbackBar.feedbackIsError = false
            feedbackText.text = qsTr("Sauvegarde créée avec succès :\n") + path
            feedbackTimer.restart()
        }
        function onBackupError(message) {
            feedbackBar.feedbackIsError = true
            feedbackText.text = message
            feedbackTimer.restart()
        }
        function onRestoreReady() {
            loadDbButton.loading = false
            restartPopup.open()
        }
        function onRestoreError(message) {
            loadDbButton.loading = false
            feedbackBar.feedbackIsError = true
            feedbackText.text = message
            feedbackTimer.restart()
        }
    }

    // ── Popup: redémarrage requis après restauration ────────────────────
    Popup {
        id: restartPopup
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 480; padding: 0
        modal: true
        closePolicy: Popup.NoAutoClose
        Overlay.modal: Rectangle { color: Qt.alpha(Style.foreground, 0.60) }
        background: Rectangle { radius: 20; color: Style.bgWhite; border.color: Style.borderLight; border.width: 1 }

        contentItem: Column {
            width: restartPopup.width
            padding: 28; spacing: 20

            Text {
                text: qsTr("Redémarrage requis")
                font.pixelSize: 17; font.weight: Font.Black; color: Style.textPrimary
                width: restartPopup.width - 56
            }

            Text {
                text: qsTr("La nouvelle base de données sera appliquée au prochain démarrage.\nFermez l'application et relancez-la pour prendre en compte les nouvelles données.")
                font.pixelSize: 13; color: Style.textSecondary
                width: restartPopup.width - 56
                wrapMode: Text.WordWrap; lineHeight: 1.5
            }

            RowLayout {
                width: restartPopup.width - 56; spacing: 12

                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderMedium; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Plus tard")
                        font.pixelSize: 12; font.bold: true; color: Style.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: restartPopup.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: Style.primary
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Quitter l'application")
                        font.pixelSize: 12; font.bold: true; color: Style.background
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }
        }
    }

    // ── Popup confirmation recalcul catégories ──────────────────────────
    Popup {
        id: confirmAgePopup
        property int pendingAge: 12
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 540; padding: 0
        modal: true
        closePolicy: Popup.CloseOnEscape
        Overlay.modal: Rectangle { color: Qt.alpha(Style.foreground, 0.60) }
        background: Rectangle { radius: 20; color: Style.bgWhite; border.color: Style.borderLight; border.width: 1 }

        contentItem: Column {
            width: confirmAgePopup.width
            padding: 28; spacing: 20

            Text {
                text: qsTr("Recalculer les catégories ?")
                font.pixelSize: 17; font.weight: Font.Black; color: Style.textPrimary
                width: confirmAgePopup.width - 56
            }
            Text {
                text: qsTr("L'âge de passage adulte a changé à <b>") + confirmAgePopup.pendingAge + qsTr(" ans</b>.\nVoulez-vous recalculer la catégorie (Jeune / Adulte) des élèves existants ?")
                font.pixelSize: 13; color: Style.textSecondary
                width: confirmAgePopup.width - 56
                wrapMode: Text.WordWrap; lineHeight: 1.5
                textFormat: Text.RichText
            }
            RowLayout {
                width: confirmAgePopup.width - 56; spacing: 12

                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: Style.bgPage; border.color: Style.borderMedium; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Non, nouveaux élèves seulement")
                        font.pixelSize: 12; font.bold: true; color: Style.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            confirmAgePopup.close()
                            settingsPage._doSaveAssociation(confirmAgePopup.pendingAge)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: Style.primary
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Oui, recalculer tout")
                        font.pixelSize: 12; font.bold: true; color: Style.background
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            confirmAgePopup.close()
                            setupController.recalculeCategories(confirmAgePopup.pendingAge)
                            settingsPage._doSaveAssociation(confirmAgePopup.pendingAge)
                        }
                    }
                }
            }
        }
    }
}
