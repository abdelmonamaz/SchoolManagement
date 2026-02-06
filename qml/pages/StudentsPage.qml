import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: studentsPage
    implicitHeight: mainLayout.implicitHeight

    property bool showDetail: false
    property int selectedIdx: -1
    property string filterLevel: "all"
    property bool showRegistrationModal: false

    ListModel {
        id: studentsModel
        ListElement { sid: "2025001"; name: "Amine Ben Salem"; level: "Niveau 3"; status: "Admis"; email: "amine.bs@gmail.com"; phone: "06 12 34 56 78" }
        ListElement { sid: "2025002"; name: "Sara Khalil"; level: "Niveau 3"; status: "Inscrit"; email: "sara.k@gmail.com"; phone: "06 98 76 54 32" }
        ListElement { sid: "2025003"; name: "Zaid Al-Harbi"; level: "Niveau 2"; status: "Non payé"; email: "zaid.h@gmail.com"; phone: "06 11 22 33 44" }
        ListElement { sid: "2025004"; name: "Layla Mansour"; level: "Niveau 1"; status: "Inscrit"; email: "layla.m@gmail.com"; phone: "06 55 44 33 22" }
        ListElement { sid: "2025005"; name: "Omar Al-Faruq"; level: "Niveau 5"; status: "Admis"; email: "omar.f@gmail.com"; phone: "06 00 11 22 33" }
    }

    ListModel {
        id: filteredStudents
    }

    function updateFilter() {
        filteredStudents.clear()
        for (var i = 0; i < studentsModel.count; i++) {
            var student = studentsModel.get(i)
            if (filterLevel === "all" || student.level === filterLevel) {
                filteredStudents.append(student)
            }
        }
    }

    Component.onCompleted: updateFilter()

    onFilterLevelChanged: updateFilter()

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
            sourceComponent: studentDetailComponent
        }

        // ─── List View ───
        ColumnLayout {
            visible: !showDetail
            Layout.fillWidth: true
            spacing: 28

            RowLayout {
                Layout.fillWidth: true
                PageHeader {
                    Layout.fillWidth: true
                    title: "Annuaire des Étudiants"
                    subtitle: "Gestion des dossiers individuels et du suivi."
                }
                PrimaryButton {
                    text: "Inscrire un Élève"
                    iconName: "plus"
                    onClicked: showRegistrationModal = true
                }
            }

            AppCard {
                Layout.fillWidth: true

                Column {
                    width: parent.width
                    spacing: 20

                    // Search & Filters
                    RowLayout {
                        width: parent.width
                        spacing: 12

                        SearchField {
                            Layout.fillWidth: true
                            placeholder: "Rechercher par nom, matricule..."
                        }

                        // Level Filter Buttons
                        Rectangle {
                            Layout.preferredWidth: implicitWidth
                            implicitWidth: levelFilterRow.implicitWidth + 8
                            height: 44
                            radius: 16
                            color: Style.bgSecondary

                            Row {
                                id: levelFilterRow
                                anchors.centerIn: parent
                                spacing: 4

                                Repeater {
                                    model: ["all", "Niveau 1", "Niveau 2", "Niveau 3", "Niveau 4", "Niveau 5"]

                                    Rectangle {
                                        width: filterText.implicitWidth + 24
                                        height: 36
                                        radius: 12
                                        color: filterLevel === modelData ? Style.primary : "transparent"

                                        Text {
                                            id: filterText
                                            anchors.centerIn: parent
                                            text: modelData === "all" ? "Tous" : modelData
                                            font.pixelSize: 10
                                            font.weight: Font.Black
                                            color: filterLevel === modelData ? "#FFFFFF" : Style.textTertiary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: filterLevel = modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Table Header
                    Separator { width: parent.width }

                    RowLayout {
                        width: parent.width
                        spacing: 0
                        Text { Layout.preferredWidth: 200; text: "ÉLÈVE"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                        Text { Layout.preferredWidth: 100; text: "MATRICULE"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                        Text { Layout.preferredWidth: 100; text: "NIVEAU"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                        Text { Layout.fillWidth: true; text: "CONTACT"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                        Text { Layout.preferredWidth: 80; text: "STATUT"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; }
                        Text { Layout.preferredWidth: 80; text: "ACTION"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; horizontalAlignment: Text.AlignRight }
                    }

                    // Table Rows
                    Column {
                        width: parent.width
                        spacing: 0

                        Repeater {
                            model: filteredStudents

                            delegate: Rectangle {
                                width: parent.width
                                height: 64
                                color: rowMa.containsMouse ? "#FAFBFC" : "transparent"
                                border.color: Style.borderLight
                                border.width: 0

                                Separator {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.topMargin: 1
                                    spacing: 0

                                    // Name
                                    RowLayout {
                                        Layout.preferredWidth: 200
                                        spacing: 10
                                        Avatar {
                                            initials: model.name.charAt(0)
                                            size: 38
                                        }
                                        Text { text: model.name; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    }

                                    // Matricule
                                    Text { Layout.preferredWidth: 100; text: model.sid; font.pixelSize: 12; font.weight: Font.Medium; color: Style.textSecondary }

                                    // Level
                                    Item {
                                        Layout.preferredWidth: 100
                                        implicitHeight: lvlBadge.height
                                        Badge { id: lvlBadge; text: model.level; variant: "info" }
                                    }

                                    // Contact
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: model.email; font.pixelSize: 12; font.weight: Font.Medium; color: Style.textPrimary }
                                        Text { text: model.phone; font.pixelSize: 9; font.weight: Font.Bold; color: Style.textTertiary }
                                    }

                                    // Status
                                    Item {
                                        Layout.preferredWidth: 80
                                        implicitHeight: stBadge.height
                                        Badge {
                                            id: stBadge
                                            text: model.status
                                            variant: model.status === "Admis" ? "success" : (model.status === "Non payé" ? "error" : "info")
                                        }
                                    }

                                    // Actions
                                    Row {
                                        Layout.preferredWidth: 80
                                        Layout.alignment: Qt.AlignRight
                                        spacing: 4
                                        IconButton { iconName: "eye"; iconSize: 16; onClicked: { selectedIdx = index; showDetail = true } }
                                        IconButton { iconName: "edit"; iconSize: 16 }
                                    }
                                }

                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onDoubleClicked: { selectedIdx = index; showDetail = true }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }

    // ─── Student Detail Component ───
    Component {
        id: studentDetailComponent

        ColumnLayout {
            spacing: 28

            // Back button
            Text {
                text: "← Retour à l'annuaire"
                font.pixelSize: 14; font.bold: true
                color: backMa.containsMouse ? Style.primary : Style.textSecondary

                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: showDetail = false
                }
            }

            // Student header card
            Rectangle {
                Layout.fillWidth: true
                height: 160
                radius: Style.radiusRound
                color: Style.bgWhite
                border.color: Style.borderLight

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 28

                    // Avatar
                    Avatar {
                        size: 100
                        initials: studentsModel.get(selectedIdx).name.charAt(0)
                        bgColor: Style.bgSecondary
                        textColor: Style.textSecondary
                        border.color: "#FFFFFF"
                        border.width: 4
                    }

                    // Info
                    Column {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            spacing: 12
                            Text { text: studentsModel.get(selectedIdx).name; font.pixelSize: 26; font.weight: Font.Black; color: Style.textPrimary }
                            Badge { text: studentsModel.get(selectedIdx).level; variant: "info" }
                        }

                        Text {
                            text: "MATRICULE: " + studentsModel.get(selectedIdx).sid
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: Style.textTertiary
                            font.letterSpacing: 2
                        }

                        RowLayout {
                            spacing: 20
                            Row {
                                spacing: 6
                                IconLabel { iconName: "mail"; iconSize: 14; iconColor: Style.primary }
                                Text { text: studentsModel.get(selectedIdx).email; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary }
                            }
                            Row {
                                spacing: 6
                                IconLabel { iconName: "phone"; iconSize: 14; iconColor: Style.primary }
                                Text { text: studentsModel.get(selectedIdx).phone; font.pixelSize: 13; font.weight: Font.Medium; color: Style.textSecondary }
                            }
                        }
                    }

                    Row {
                        spacing: 8
                        OutlineButton { text: "Modifier" }
                        PrimaryButton { text: "Bulletin PDF" }
                    }
                }
            }

            // Academic Grid
            RowLayout {
                Layout.fillWidth: true
                spacing: 24

                // Left: Academic tracking + Attendance
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    spacing: 24

                    AppCard {
                        Layout.fillWidth: true
                        title: "Suivi Académique"

                        Column {
                            width: parent.width
                            spacing: 0

                            // Table header
                            RowLayout {
                                width: parent.width
                                height: 40
                                Text { Layout.preferredWidth: 160; text: "MATIÈRE"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }
                                Text { Layout.fillWidth: true; text: "CONTRÔLE"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; horizontalAlignment: Text.AlignHCenter }
                                Text { Layout.fillWidth: true; text: "EXAMEN"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; horizontalAlignment: Text.AlignHCenter }
                                Text { Layout.fillWidth: true; text: "MOYENNE"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; horizontalAlignment: Text.AlignHCenter }
                                Text { Layout.preferredWidth: 80; text: "STATUT"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary; horizontalAlignment: Text.AlignRight }
                            }

                            Separator { width: parent.width }

                            Repeater {
                                model: ListModel {
                                    ListElement { subject: "Coran"; grade: "18.5"; exam: "17.0"; avg: "17.75"; status: "Validé" }
                                    ListElement { subject: "Arabe"; grade: "16.0"; exam: "15.5"; avg: "15.75"; status: "Validé" }
                                    ListElement { subject: "Fiqh"; grade: "14.5"; exam: "12.0"; avg: "13.25"; status: "Validé" }
                                    ListElement { subject: "Histoire Islamique"; grade: "12.0"; exam: "14.0"; avg: "13.0"; status: "Validé" }
                                }

                                delegate: Column {
                                    width: parent.width

                                    RowLayout {
                                        width: parent.width
                                        height: 52
                                        Text { Layout.preferredWidth: 160; text: model.subject; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                        Text { Layout.fillWidth: true; text: model.grade + "/20"; font.pixelSize: 13; font.weight: Font.DemiBold; color: Style.textSecondary; horizontalAlignment: Text.AlignHCenter }
                                        Text { Layout.fillWidth: true; text: model.exam + "/20"; font.pixelSize: 13; font.weight: Font.DemiBold; color: Style.textSecondary; horizontalAlignment: Text.AlignHCenter }
                                        Text { Layout.fillWidth: true; text: model.avg; font.pixelSize: 14; font.weight: Font.Black; color: Style.primary; horizontalAlignment: Text.AlignHCenter }
                                        Item {
                                            Layout.preferredWidth: 80
                                            implicitHeight: 20
                                            Badge { anchors.right: parent.right; text: model.status; variant: "success" }
                                        }
                                    }
                                    Separator { width: parent.width }
                                }
                            }
                        }
                    }

                    // Attendance
                    AppCard {
                        Layout.fillWidth: true
                        title: "Assiduité"
                        subtitle: "Présences et Retards"

                        Column {
                            width: parent.width
                            spacing: 20

                            RowLayout {
                                width: parent.width
                                spacing: 16

                                Repeater {
                                    model: [
                                        { label: "Présences", value: "98%", bg: Style.successBg, border_: Style.successBorder, color_: Style.successColor },
                                        { label: "Retards", value: "2", bg: Style.warningBg, border_: Style.warningBorder, color_: Style.warningColor },
                                        { label: "Absences", value: "1", bg: Style.errorBg, border_: Style.errorBorder, color_: Style.errorColor }
                                    ]

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 80
                                        radius: 16
                                        color: modelData.bg
                                        border.color: modelData.border_

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; font.pixelSize: 10; font.weight: Font.Bold; color: modelData.color_ }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; font.pixelSize: 24; font.weight: Font.Black; color: modelData.color_ }
                                        }
                                    }
                                }
                            }

                            // Calendar grid
                            GridLayout {
                                width: parent.width
                                columns: 7
                                columnSpacing: 6
                                rowSpacing: 6

                                Repeater {
                                    model: 31

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: width
                                        radius: 12
                                        color: index === 14 ? Style.errorBg :
                                               (index === 7 || index === 22) ? Style.warningBg : Style.successBg
                                        border.color: index === 14 ? Style.errorBorder :
                                                      (index === 7 || index === 22) ? Style.warningBorder : Style.successBorder

                                        Text {
                                            anchors.centerIn: parent
                                            text: (index + 1).toString()
                                            font.pixelSize: 12; font.bold: true
                                            color: index === 14 ? Style.errorColor :
                                                   (index === 7 || index === 22) ? Style.warningColor : Style.successColor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Right sidebar
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 24

                    AppCard {
                        Layout.fillWidth: true
                        title: "Infos Administratives"

                        Column {
                            width: parent.width
                            spacing: 20

                            Column {
                                width: parent.width; spacing: 4
                                SectionLabel { text: "PARENTS / TUTEUR" }
                                Text { text: "Mohamed Ben Salem"; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                Text { text: "+212 6 61 22 33 44"; font.pixelSize: 11; font.weight: Font.Medium; color: Style.textSecondary }
                            }

                            Column {
                                width: parent.width; spacing: 6
                                SectionLabel { text: "ÉTAT DES PAIEMENTS" }
                                Rectangle {
                                    width: parent.width; height: 40; radius: 12
                                    color: Style.successBg; border.color: Style.successBorder
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 10
                                        Text { Layout.fillWidth: true; text: "Frais payés"; font.pixelSize: 11; font.bold: true; color: Style.successColor }
                                        Text { text: "✓"; font.pixelSize: 16; color: Style.successColor }
                                    }
                                }
                            }

                            Column {
                                width: parent.width; spacing: 6
                                SectionLabel { text: "DOCUMENTS" }
                                Repeater {
                                    model: ["Acte de naissance.pdf", "Certificat Médical.pdf"]
                                    delegate: RowLayout {
                                        spacing: 8
                                        Rectangle { width: 6; height: 6; radius: 3; color: Style.primary }
                                        Text { text: modelData; font.pixelSize: 12; font.weight: Font.Medium; color: Style.textSecondary }
                                    }
                                }
                            }
                        }
                    }

                    AppCard {
                        Layout.fillWidth: true
                        title: "Historique Scolaire"

                        Column {
                            width: parent.width
                            spacing: 10

                            Repeater {
                                model: ListModel {
                                    ListElement { year: "2024-2025"; level: "Niveau 2"; result: "Admis"; avg: "16.42" }
                                    ListElement { year: "2023-2024"; level: "Niveau 1"; result: "Admis"; avg: "15.80" }
                                }

                                delegate: Rectangle {
                                    width: parent.width; height: 60; radius: 16
                                    color: "transparent"; border.color: Style.borderLight

                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 12
                                        Column {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: model.year; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary }
                                            Text { text: model.level; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                        }
                                        Badge { text: model.avg; variant: "success" }
                                    }

                                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Registration Modal ───
    ModalOverlay {
        show: showRegistrationModal
        modalWidth: Math.min(parent.width - 64, 800)
        onClose: showRegistrationModal = false

        // Modal Header
        Rectangle {
            width: parent.width
            height: 80
            color: "#FAFBFC"
            radius: 32

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 40
                color: "#FAFBFC"
            }

            Separator {
                anchors.bottom: parent.bottom
                width: parent.width
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Nouvelle Inscription"
                        font.pixelSize: 20
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "REMPLISSEZ LES INFORMATIONS DE L'ÉLÈVE"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.textTertiary
                        font.letterSpacing: 1
                    }
                }

                IconButton {
                    iconName: "close"
                    iconSize: 18
                    onClicked: showRegistrationModal = false
                }
            }
        }

        // Modal Body
        Item {
            width: parent.width
            implicitHeight: bodyCol.implicitHeight + 48

            Column {
                id: bodyCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 32

                // Section 1: Identité
                Column {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: Style.primary

                            Text {
                                anchors.centerIn: parent
                                text: "1"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: "#FFFFFF"
                            }
                        }

                        Text {
                            text: "IDENTITÉ DE L'ÉLÈVE"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: Style.textPrimary
                            font.letterSpacing: 1
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 16

                        FormField {
                            id: nameField
                            Layout.fillWidth: true
                            label: "NOM COMPLET"
                            placeholder: "ex: Ahmed Ben Moussa"
                        }

                        FormField {
                            id: birthDateField
                            Layout.fillWidth: true
                            label: "DATE DE NAISSANCE"
                            placeholder: "JJ/MM/AAAA"
                        }
                    }
                }

                // Section 2: Scolarité
                Column {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: Style.primary

                            Text {
                                anchors.centerIn: parent
                                text: "2"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: "#FFFFFF"
                            }
                        }

                        Text {
                            text: "INFORMATIONS ACADÉMIQUES"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: Style.textPrimary
                            font.letterSpacing: 1
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 16

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            SectionLabel {
                                text: "CATÉGORIE"
                            }

                            Rectangle {
                                width: parent.width
                                height: 44
                                radius: 12
                                color: Style.bgSecondary

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 4

                                    Repeater {
                                        model: ["Enfant", "Adulte"]

                                        Rectangle {
                                            width: (parent.width - 4) / 2
                                            height: parent.height
                                            radius: 10
                                            color: index === 0 ? Style.bgWhite : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.pixelSize: 10
                                                font.weight: Font.Black
                                                color: index === 0 ? Style.primary : Style.textTertiary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            SectionLabel {
                                text: "NIVEAU D'AFFECTATION"
                            }

                            Rectangle {
                                width: parent.width
                                height: 44
                                radius: 12
                                color: Style.bgPage
                                border.color: Style.borderLight

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Niveau 1"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Style.textPrimary
                                    }

                                    Text {
                                        text: "▾"
                                        font.pixelSize: 12
                                        color: Style.textTertiary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }
                }

                // Section 3: Contacts
                Column {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: Style.primary

                            Text {
                                anchors.centerIn: parent
                                text: "3"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: "#FFFFFF"
                            }
                        }

                        Text {
                            text: "CONTACTS & TUTEURS"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: Style.textPrimary
                            font.letterSpacing: 1
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 16

                        FormField {
                            id: parentField
                            Layout.fillWidth: true
                            label: "NOM DU TUTEUR / PARENT"
                            placeholder: "Nom du tuteur"
                        }

                        FormField {
                            id: phoneField
                            Layout.fillWidth: true
                            label: "TÉLÉPHONE DE CONTACT"
                            placeholder: "06 12 34 56 78"
                        }

                        FormField {
                            id: emailField
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            label: "EMAIL"
                            placeholder: "exemple@email.com"
                        }

                        FormField {
                            id: addressField
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            label: "ADRESSE DE RÉSIDENCE"
                            placeholder: "Adresse complète"
                        }
                    }
                }
            }
        }

        // Modal Footer
        Rectangle {
            width: parent.width
            height: 80
            color: "#FAFBFC"

            Separator {
                anchors.top: parent.top
                width: parent.width
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    height: 48
                    radius: 16
                    color: Style.bgPage
                    border.color: Style.borderLight

                    Text {
                        anchors.centerIn: parent
                        text: "ANNULER"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.textTertiary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showRegistrationModal = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    height: 48
                    radius: 16
                    color: Style.primary

                    Text {
                        anchors.centerIn: parent
                        text: "CONFIRMER L'INSCRIPTION"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: "#FFFFFF"
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            showRegistrationModal = false
                            nameField.text = ""
                            birthDateField.text = ""
                            parentField.text = ""
                            phoneField.text = ""
                            emailField.text = ""
                            addressField.text = ""
                        }
                    }
                }
            }
        }
    }
}
