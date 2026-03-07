import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
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
        setupController.saveAssociation({
            nomAssociation:   nomEcoleField.text.trim(),
            adresse:          adresseEdit.text.trim(),
            exerciceDebut:    exDebutField.isValid ? exDebutField.dateString
                                                   : (setupController.associationData.exerciceDebut || "01-01"),
            exerciceFin:      exFinField.isValid   ? exFinField.dateString
                                                   : (setupController.associationData.exerciceFin   || "12-31"),
            agePassageAdulte: agePassage
        })
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        PageHeader {
            Layout.fillWidth: true
            title: "Paramètres du Système"
            subtitle: "Configurez l'environnement Ez-Zaytouna selon vos besoins."
        }

        // ─── Settings Cards Grid ───
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 20
            rowSpacing: 20

            Repeater {
                model: ListModel {
                    ListElement { sid: "profile"; label: "Profil Admin"; icon: "👤"; desc: "Gérez vos informations personnelles et votre avatar." }
                    ListElement { sid: "security"; label: "Sécurité & Accès"; icon: "🛡"; desc: "Double authentification et historique de connexion." }
                    ListElement { sid: "school"; label: "Établissement"; icon: "🏫"; desc: "Nom de l'école, logo, et année scolaire en cours." }
                    ListElement { sid: "rooms"; label: "Gestion des Salles"; icon: "📍"; desc: "Configurez les salles disponibles et leur capacité." }
                    ListElement { sid: "notif"; label: "Notifications"; icon: "🔔"; desc: "Paramètres des alertes SMS et Emails pour les parents." }
                    ListElement { sid: "backup"; label: "Sauvegarde & Data"; icon: "🗄"; desc: "Sauvegardes automatiques et export de la base." }
                }

                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 160
                    radius: Style.radiusRound
                    color: Style.bgWhite
                    border.color: setMa.containsMouse ? Style.primary : Style.borderLight
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 12

                        Rectangle {
                            width: 48; height: 48
                            radius: 16
                            color: setMa.containsMouse ? Style.primaryBg : Style.bgPage

                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: model.icon
                                font.pixelSize: 22
                            }
                        }

                        Text {
                            text: model.label
                            font.pixelSize: 14; font.bold: true
                            color: setMa.containsMouse ? Style.primary : Style.textPrimary
                        }

                        Text {
                            text: model.desc
                            font.pixelSize: 11; font.weight: Font.Medium
                            color: Style.textTertiary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: setMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        // ─── Configuration des Tarifs ───
        AppCard {
            Layout.fillWidth: true
            title: "Configuration des Tarifs"
            subtitle: "Tarifs mensuels et frais d'inscription de l'année scolaire active."

            Column {
                width: parent.width
                spacing: 24

                // ── Mensualités ──
                Text {
                    text: "MENSUALITÉS"
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
                        border.color: "#BFDBFE"; border.width: 1

                        Column {
                            id: childCol
                            anchors.fill: parent; anchors.margins: 24
                            spacing: 12

                            Text {
                                text: "TARIF JEUNE (mensuel)"
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
                                        radius: 12; color: "#FFFFFF"
                                        border.width: parent.activeFocus ? 2 : 1
                                        border.color: parent.activeFocus ? Style.primary
                                                    : parent.hovered ? "#93C5FD" : "#BFDBFE"
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text { text: "DT/mois"; font.pixelSize: 13; font.weight: Font.Black; color: Style.chartBlue }
                            }
                        }
                    }

                    // Tarif Adulte (mensuel)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: adultCol.implicitHeight + 48
                        radius: 24
                        color: "#FEF3C7"; border.color: "#FCD34D"; border.width: 1

                        Column {
                            id: adultCol
                            anchors.fill: parent; anchors.margins: 24
                            spacing: 12

                            Text {
                                text: "TARIF ADULTE (mensuel)"
                                font.pixelSize: 10; font.weight: Font.Black
                                color: "#D97706"; font.letterSpacing: 2
                            }

                            RowLayout {
                                width: parent.width; spacing: 8

                                TextField {
                                    id: tarifAdulteInput
                                    Layout.fillWidth: true
                                    height: 48
                                    text: (setupController.activeTarifs.tarifAdulte || 250).toString()
                                    font.pixelSize: 16; font.weight: Font.Black; color: "#D97706"
                                    selectByMouse: true
                                    leftPadding: 16; rightPadding: 8
                                    topPadding: 0; bottomPadding: 0
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextEdited: settingsPage.tarifsSaved = false
                                    validator: RegularExpressionValidator {
                                        regularExpression: /^\d{0,5}(\.\d{0,2})?$/
                                    }
                                    background: Rectangle {
                                        radius: 12; color: "#FFFFFF"
                                        border.width: parent.activeFocus ? 2 : 1
                                        border.color: parent.activeFocus ? Style.primary
                                                    : parent.hovered ? "#FDE68A" : "#FCD34D"
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text { text: "DT/mois"; font.pixelSize: 13; font.weight: Font.Black; color: "#D97706" }
                            }
                        }
                    }
                }

                // ── Frais d'inscription ──
                Text {
                    text: "FRAIS D'INSCRIPTION (unique)"
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
                                text: "FRAIS JEUNE"
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
                                        radius: 12; color: "#FFFFFF"
                                        border.width: parent.activeFocus ? 2 : 1
                                        border.color: parent.activeFocus ? Style.primary
                                                    : parent.hovered ? Style.successColor : Style.successBorder
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text { text: "DT"; font.pixelSize: 13; font.weight: Font.Black; color: Style.successColor }
                            }
                        }
                    }

                    // Frais Adulte
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: fraisACol.implicitHeight + 48
                        radius: 24
                        color: "#FDF4FF"; border.color: "#E9D5FF"; border.width: 1

                        Column {
                            id: fraisACol
                            anchors.fill: parent; anchors.margins: 24
                            spacing: 12

                            Text {
                                text: "FRAIS ADULTE"
                                font.pixelSize: 10; font.weight: Font.Black
                                color: "#7C3AED"; font.letterSpacing: 2
                            }

                            RowLayout {
                                width: parent.width; spacing: 8

                                TextField {
                                    id: fraisAdulteInput
                                    Layout.fillWidth: true
                                    height: 48
                                    text: (setupController.activeTarifs.fraisInscriptionAdulte || 50).toString()
                                    font.pixelSize: 16; font.weight: Font.Black; color: "#7C3AED"
                                    selectByMouse: true
                                    leftPadding: 16; rightPadding: 8
                                    topPadding: 0; bottomPadding: 0
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextEdited: settingsPage.tarifsSaved = false
                                    validator: RegularExpressionValidator {
                                        regularExpression: /^\d{0,5}(\.\d{0,2})?$/
                                    }
                                    background: Rectangle {
                                        radius: 12; color: "#FFFFFF"
                                        border.width: parent.activeFocus ? 2 : 1
                                        border.color: parent.activeFocus ? Style.primary
                                                    : parent.hovered ? "#C4B5FD" : "#E9D5FF"
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text { text: "DT"; font.pixelSize: 13; font.weight: Font.Black; color: "#7C3AED" }
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
                                text: "Ces tarifs s'appliquent lors de la génération du grand livre mensuel et sont pré-remplis à l'inscription."
                                font.pixelSize: 10; font.weight: Font.Bold
                                color: Style.textSecondary; wrapMode: Text.WordWrap; lineHeight: 1.5
                            }
                        }
                    }

                    PrimaryButton {
                        text: "Enregistrer les tarifs"
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
        }

        // ─── Bottom cards ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            // School Info Form
            AppCard {
                Layout.fillWidth: true
                title: "Informations de l'Établissement"

                Column {
                    width: parent.width
                    spacing: 20

                    FormField {
                        id: nomEcoleField
                        width: parent.width
                        label: "NOM DE L'ASSOCIATION"
                        placeholder: "ex: Ez-Zaytouna"
                        text: setupController.associationData.nomAssociation || ""
                        onTextChanged: settingsPage.associationSaved = false
                    }

                    Column {
                        width: parent.width; spacing: 6
                        SectionLabel { text: "ADRESSE" }
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

                    // ── Exercice comptable ──
                    Text {
                        text: "EXERCICE COMPTABLE"
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
                            label: "DATE DE DÉBUT"
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
                            label: "DATE DE FIN"
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
                        text: "CATÉGORISATION"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.primary; font.letterSpacing: 1
                    }

                    RowLayout {
                        width: parent.width; spacing: 12
                        Text {
                            text: "Âge de passage Adulte :"
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
                            text: "ans"
                            font.pixelSize: 13; font.bold: true; color: Style.textSecondary
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Item { Layout.fillWidth: true }
                    }

                    PrimaryButton {
                        text: "Enregistrer les modifications"
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

            // System Status
            AppCard {
                Layout.fillWidth: true
                title: "État du Système"

                Column {
                    width: parent.width
                    spacing: 20

                    // Cloud status
                    Rectangle {
                        width: parent.width; height: 64; radius: 16
                        color: Style.successBg; border.color: Style.successBorder

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 14

                            Rectangle {
                                width: 40; height: 40; radius: 12
                                color: Style.successBorder

                                Text { anchors.centerIn: parent; text: "☁"; font.pixelSize: 18; color: Style.successColor }
                            }

                            Column {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Stockage Cloud"; font.pixelSize: 13; font.bold: true; color: Style.successColor }
                                Text { text: "CONNECTÉ & SYNCHRONISÉ"; font.pixelSize: 9; font.weight: Font.Bold; color: Style.successColor }
                            }

                            Text { text: "8.4 GB / 20 GB"; font.pixelSize: 13; font.weight: Font.Black; color: Style.successColor }
                        }
                    }

                    // Updates section
                    Column {
                        width: parent.width; spacing: 12
                        Text { text: "MISES À JOUR"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }

                        Column {
                            width: parent.width; spacing: 0

                            RowLayout {
                                width: parent.width; height: 52
                                Column { Layout.fillWidth: true; spacing: 2
                                    Text { text: "Version du Logiciel"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text { text: "Dernière vérification: Aujourd'hui 08:00"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }
                                }
                                Badge { text: "v2.4.8 (Stable)" }
                            }

                            Separator { width: parent.width }

                            RowLayout {
                                width: parent.width; height: 52
                                Column { Layout.fillWidth: true; spacing: 2
                                    Text { text: "Base de données"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text { text: "Prochaine sauvegarde: Demain 02:00"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }
                                }
                                Badge { text: "Optimisée"; variant: "success" }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
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
        Overlay.modal: Rectangle { color: "#0F172A99" }
        background: Rectangle { radius: 20; color: Style.bgWhite; border.color: Style.borderLight; border.width: 1 }

        contentItem: Column {
            width: confirmAgePopup.width
            padding: 28; spacing: 20

            Text {
                text: "Recalculer les catégories ?"
                font.pixelSize: 17; font.weight: Font.Black; color: Style.textPrimary
                width: confirmAgePopup.width - 56
            }
            Text {
                text: "L'âge de passage adulte a changé à <b>" + confirmAgePopup.pendingAge + " ans</b>.\nVoulez-vous recalculer la catégorie (Jeune / Adulte) des élèves existants ?"
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
                        text: "Non, nouveaux élèves seulement"
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
                        text: "Oui, recalculer tout"
                        font.pixelSize: 12; font.bold: true; color: "#FFFFFF"
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
