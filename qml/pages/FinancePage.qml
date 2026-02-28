import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: financePage
    implicitHeight: mainLayout.implicitHeight

    property string activeTab: "schooling"
    property int    selectedMonthIndex: 1     // 0 = Janvier … 11 = Décembre
    property int    selectedYear:       2026
    property string searchTerm: ""

    readonly property var    monthNames: ["Janvier","Février","Mars","Avril","Mai","Juin",
                                          "Juillet","Août","Septembre","Octobre","Novembre","Décembre"]
    readonly property string selectedMonth: monthNames[selectedMonthIndex]

    function navigateMonth(delta) {
        var idx = selectedMonthIndex + delta
        if (idx < 0)  { idx = 11; selectedYear-- }
        if (idx > 11) { idx = 0;  selectedYear++ }
        selectedMonthIndex = idx
    }

    // Modals
    property bool showSchoolingModal: false
    property bool showDonationModal: false
    property bool showExpenseModal: false
    property bool showAutoModal: false
    property bool showDeleteModal: false
    property string deleteType: ""
    property string deleteItemName: ""

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 32

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            PageHeader {
                Layout.fillWidth: true
                title: "Finance & Trésorerie"
                subtitle: "Gestion mensuelle des flux financiers."
            }

            // ── Navigateur mois/année (même style que le calendrier de plannification) ──
            Row {
                spacing: 4

                // ◀ Mois précédent
                Rectangle {
                    width: 32; height: 36; radius: 10
                    color: prevMonthMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 18; font.bold: true; color: Style.textSecondary }
                    MouseArea {
                        id: prevMonthMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: financePage.navigateMonth(-1)
                    }
                }

                // Pill mois + année (cliquable → MonthYearSelector)
                Rectangle {
                    id: pillRect
                    implicitWidth: monthPillRow.implicitWidth + 20
                    height: 36; radius: 10
                    color: monthPicker.show ? Style.bgPage : Style.bgWhite
                    border.color: monthPicker.show ? Style.primary : Style.borderLight
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        id: monthPillRow
                        anchors.centerIn: parent; spacing: 6
                        IconLabel { iconName: "calendar"; iconSize: 14; iconColor: Style.primary }
                        Text {
                            text: financePage.selectedMonth + " " + financePage.selectedYear
                            font.pixelSize: 10; font.weight: Font.Black
                            color: Style.textPrimary; font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var pos = pillRect.mapToItem(financePage, 0, pillRect.height + 4)
                            monthPicker.x = Math.min(pos.x, financePage.width - monthPicker.width)
                            monthPicker.y = pos.y
                            monthPicker.selectedMonth = financePage.selectedMonthIndex + 1
                            monthPicker.selectedYear = financePage.selectedYear
                            monthPicker.show = !monthPicker.show
                        }
                    }
                }

                // ▶ Mois suivant
                Rectangle {
                    width: 32; height: 36; radius: 10
                    color: nextMonthMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 18; font.bold: true; color: Style.textSecondary }
                    MouseArea {
                        id: nextMonthMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: financePage.navigateMonth(1)
                    }
                }
            }
        }

        // ─── Tabs ───
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Style.borderLight
            }

            RowLayout {
                anchors.fill: parent
                spacing: 32

                Repeater {
                    model: [
                        { id: "schooling", label: "Scolarité", icon: "wallet" },
                        { id: "donations", label: "Dons & Waqf", icon: "heart" },
                        { id: "expenses", label: "Dépenses", icon: "receipt" },
                        { id: "journal", label: "Journal Unifié", icon: "history" }
                    ]

                    delegate: Item {
                        Layout.fillHeight: true
                        implicitWidth: tabContent.implicitWidth

                        RowLayout {
                            id: tabContent
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            IconLabel {
                                iconName: modelData.icon
                                iconSize: 18
                                iconColor: activeTab === modelData.id ? Style.primary : Style.textTertiary
                            }

                            Text {
                                text: modelData.label
                                font.pixelSize: 13
                                font.bold: true
                                color: activeTab === modelData.id ? Style.primary : Style.textTertiary
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 4
                            radius: 2
                            color: activeTab === modelData.id ? Style.primary : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                activeTab = modelData.id
                                searchTerm = ""
                            }
                        }
                    }
                }
            }
        }

        // ─── Filter Bar ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            visible: activeTab !== "journal"

            SearchField {
                Layout.fillWidth: true
                placeholder: "Rechercher..."
                onTextChanged: searchTerm = text
            }

            PrimaryButton {
                text: activeTab === "schooling" ? "Générer Mensualités" : (activeTab === "donations" ? "Nouveau Don" : "Nouveau Frais")
                iconName: "plus"
                onClicked: {
                    if (activeTab === "schooling") showAutoModal = true
                    else if (activeTab === "donations") showDonationModal = true
                    else if (activeTab === "expenses") showExpenseModal = true
                }
            }
        }

        // ─── Tab Content ───
        Loader {
            Layout.fillWidth: true
            active: activeTab === "schooling"
            visible: active
            sourceComponent: schoolingTab
        }

        Loader {
            Layout.fillWidth: true
            active: activeTab === "donations"
            visible: active
            sourceComponent: donationsTab
        }

        Loader {
            Layout.fillWidth: true
            active: activeTab === "expenses"
            visible: active
            sourceComponent: expensesTab
        }

        Loader {
            Layout.fillWidth: true
            active: activeTab === "journal"
            visible: active
            sourceComponent: journalTab
        }

        Item { Layout.preferredHeight: 32 }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // TAB COMPONENTS
    // ═══════════════════════════════════════════════════════════════════════

    Component {
        id: schoolingTab

        AppCard {
            title: "Scolarité - " + selectedMonth + " " + selectedYear
            subtitle: "Suivi des règlements élèves"

            Column {
                width: parent.width
                spacing: 16

                // Table Header
                RowLayout {
                    width: parent.width
                    height: 40

                    SectionLabel {
                        Layout.preferredWidth: 200
                        text: "ÉLÈVE"
                    }

                    SectionLabel {
                        Layout.fillWidth: true
                        text: "DÉTAILS RÈGLEMENT (DT)"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 100
                        text: "MÉTHODE"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 100
                        text: "STATUT"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 80
                        text: "ACTIONS"
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Separator { width: parent.width }

                // Table Rows
                Column {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: ListModel {
                            ListElement {
                                studentName: "Yassine Mansour"
                                level: "Niveau 3"
                                totalDue: "150"
                                amountPaid: "150"
                                method: "Espèces"
                                status: "Payé"
                            }
                            ListElement {
                                studentName: "Sara Khalil"
                                level: "Niveau 2"
                                totalDue: "150"
                                amountPaid: "150"
                                method: "Virement"
                                status: "Payé"
                            }
                            ListElement {
                                studentName: "Amine Ben Salem"
                                level: "Niveau 3"
                                totalDue: "150"
                                amountPaid: "75"
                                method: "Espèces"
                                status: "Partiel"
                            }
                            ListElement {
                                studentName: "Layla Mansour"
                                level: "Niveau 1"
                                totalDue: "150"
                                amountPaid: "0"
                                method: "Chèque"
                                status: "En attente"
                            }
                        }

                        delegate: Column {
                            width: parent.width

                            Rectangle {
                                width: parent.width
                                height: 64
                                color: rowMa.containsMouse ? Style.bgPage : "transparent"

                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 0
                                    anchors.rightMargin: 0
                                    spacing: 12

                                    Text {
                                        Layout.preferredWidth: 200
                                        text: model.studentName
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Style.textPrimary
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        RowLayout {
                                            spacing: 8

                                            Text {
                                                text: model.amountPaid + " DT"
                                                font.pixelSize: 13
                                                font.weight: Font.Black
                                                color: Style.primary
                                            }

                                            Text {
                                                text: "/ " + model.totalDue + " DT"
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: Style.textTertiary
                                            }
                                        }

                                        Text {
                                            text: {
                                                var rest = parseFloat(model.totalDue) - parseFloat(model.amountPaid)
                                                return rest > 0 ? "Reste: " + rest + " DT" : ""
                                            }
                                            font.pixelSize: 9
                                            font.weight: Font.Black
                                            color: Style.errorColor
                                            visible: text !== ""
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 100
                                        text: model.method
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Style.textSecondary
                                    }

                                    Item {
                                        Layout.preferredWidth: 100
                                        implicitHeight: 24

                                        Badge {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: model.status
                                            variant: model.status === "Payé" ? "success" : (model.status === "Partiel" ? "warning" : "error")
                                        }
                                    }

                                    RowLayout {
                                        Layout.preferredWidth: 80
                                        spacing: 8

                                        IconButton {
                                            iconName: "edit"
                                            iconSize: 16
                                            onClicked: showSchoolingModal = true
                                        }

                                        IconButton {
                                            iconName: "trash"
                                            iconSize: 16
                                            hoverColor: Style.errorColor
                                            onClicked: {
                                                deleteType = "schooling"
                                                deleteItemName = model.studentName
                                                showDeleteModal = true
                                            }
                                        }
                                    }
                                }
                            }

                            Separator { width: parent.width }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: donationsTab

        AppCard {
            title: "Dons & Waqf - " + selectedMonth + " " + selectedYear

            Column {
                width: parent.width
                spacing: 16

                // Table Header
                RowLayout {
                    width: parent.width
                    height: 40

                    SectionLabel {
                        Layout.fillWidth: true
                        text: "DONATEUR"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 150
                        text: "PROJET"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 120
                        text: "MONTANT"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 80
                        text: "ACTIONS"
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Separator { width: parent.width }

                // Table Rows
                Column {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: ListModel {
                            ListElement {
                                donorName: "Association Bienfaisance"
                                amount: "1000"
                                project: "Parrainage"
                            }
                            ListElement {
                                donorName: "Dr. Brahim El Amrani"
                                amount: "500"
                                project: "Rénovation"
                            }
                            ListElement {
                                donorName: "Donateur Anonyme"
                                amount: "250"
                                project: "Waqf"
                            }
                        }

                        delegate: Column {
                            width: parent.width

                            Rectangle {
                                width: parent.width
                                height: 64
                                color: donRowMa.containsMouse ? Style.bgPage : "transparent"

                                MouseArea {
                                    id: donRowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.donorName
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Style.textPrimary
                                    }

                                    Text {
                                        Layout.preferredWidth: 150
                                        text: model.project
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Style.textSecondary
                                    }

                                    Text {
                                        Layout.preferredWidth: 120
                                        text: model.amount + " DT"
                                        font.pixelSize: 13
                                        font.weight: Font.Black
                                        color: Style.successColor
                                    }

                                    RowLayout {
                                        Layout.preferredWidth: 80
                                        spacing: 8

                                        IconButton {
                                            iconName: "edit"
                                            iconSize: 16
                                            onClicked: showDonationModal = true
                                        }

                                        IconButton {
                                            iconName: "trash"
                                            iconSize: 16
                                            hoverColor: Style.errorColor
                                            onClicked: {
                                                deleteType = "donation"
                                                deleteItemName = model.donorName
                                                showDeleteModal = true
                                            }
                                        }
                                    }
                                }
                            }

                            Separator { width: parent.width }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: expensesTab

        AppCard {
            title: "Dépenses - " + selectedMonth + " " + selectedYear

            Column {
                width: parent.width
                spacing: 16

                // Table Header
                RowLayout {
                    width: parent.width
                    height: 40

                    SectionLabel {
                        Layout.fillWidth: true
                        text: "BÉNÉFICIAIRE"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 120
                        text: "CATÉGORIE"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 120
                        text: "MONTANT"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 80
                        text: "ACTIONS"
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Separator { width: parent.width }

                // Table Rows
                Column {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: ListModel {
                            ListElement {
                                recipient: "Sheikh Ahmed"
                                category: "Salaires"
                                amount: "850"
                            }
                            ListElement {
                                recipient: "STEG"
                                category: "Charges"
                                amount: "120"
                            }
                            ListElement {
                                recipient: "Librairie Al-Kitab"
                                category: "Fournitures"
                                amount: "85"
                            }
                        }

                        delegate: Column {
                            width: parent.width

                            Rectangle {
                                width: parent.width
                                height: 64
                                color: expRowMa.containsMouse ? Style.bgPage : "transparent"

                                MouseArea {
                                    id: expRowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.recipient
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Style.textPrimary
                                    }

                                    Text {
                                        Layout.preferredWidth: 120
                                        text: model.category
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        color: Style.textSecondary
                                        font.letterSpacing: 1
                                    }

                                    Text {
                                        Layout.preferredWidth: 120
                                        text: "-" + model.amount + " DT"
                                        font.pixelSize: 13
                                        font.weight: Font.Black
                                        color: Style.errorColor
                                    }

                                    RowLayout {
                                        Layout.preferredWidth: 80
                                        spacing: 8

                                        IconButton {
                                            iconName: "edit"
                                            iconSize: 16
                                            onClicked: showExpenseModal = true
                                        }

                                        IconButton {
                                            iconName: "trash"
                                            iconSize: 16
                                            hoverColor: Style.errorColor
                                            onClicked: {
                                                deleteType = "expense"
                                                deleteItemName = model.recipient
                                                showDeleteModal = true
                                            }
                                        }
                                    }
                                }
                            }

                            Separator { width: parent.width }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: journalTab

        AppCard {
            title: "Journal - " + selectedMonth + " " + selectedYear

            Column {
                width: parent.width
                spacing: 24

                // Table Header
                RowLayout {
                    width: parent.width
                    height: 40

                    SectionLabel {
                        Layout.preferredWidth: 100
                        text: "DATE"
                    }

                    SectionLabel {
                        Layout.fillWidth: true
                        text: "DÉTAILS"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 100
                        text: "TYPE"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 120
                        text: "MONTANT"
                    }

                    SectionLabel {
                        Layout.preferredWidth: 80
                        text: "FLUX"
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Separator { width: parent.width }

                // Table Rows
                Column {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: ListModel {
                            ListElement {
                                date: "06/02/2026"
                                name: "Yassine Mansour"
                                type: "Scolarité"
                                amount: "150"
                                flow: "in"
                            }
                            ListElement {
                                date: "05/02/2026"
                                name: "Association Bienfaisance"
                                type: "Donation"
                                amount: "1000"
                                flow: "in"
                            }
                            ListElement {
                                date: "04/02/2026"
                                name: "Sheikh Ahmed"
                                type: "Dépense"
                                amount: "850"
                                flow: "out"
                            }
                            ListElement {
                                date: "04/02/2026"
                                name: "STEG"
                                type: "Dépense"
                                amount: "120"
                                flow: "out"
                            }
                        }

                        delegate: Column {
                            width: parent.width

                            Rectangle {
                                width: parent.width
                                height: 64
                                color: jRowMa.containsMouse ? Style.bgPage : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Text {
                                        Layout.preferredWidth: 100
                                        text: model.date
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Style.textTertiary
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.name
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Style.textPrimary
                                    }

                                    Text {
                                        Layout.preferredWidth: 100
                                        text: model.type
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        color: Style.textSecondary
                                        font.letterSpacing: 1
                                    }

                                    Text {
                                        Layout.preferredWidth: 120
                                        text: (model.flow === "in" ? "+" : "-") + model.amount + " DT"
                                        font.pixelSize: 13
                                        font.weight: Font.Black
                                        color: model.flow === "in" ? Style.successColor : Style.errorColor
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 80
                                        implicitWidth: 40
                                        implicitHeight: 40
                                        radius: 12
                                        color: model.flow === "in" ? Style.successBg : Style.errorBg

                                        IconLabel {
                                            anchors.centerIn: parent
                                            iconName: model.flow === "in" ? "trending-up" : "trending-down"
                                            iconSize: 16
                                            iconColor: model.flow === "in" ? Style.successColor : Style.errorColor
                                        }
                                    }
                                }

                                MouseArea {
                                    id: jRowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }

                            Separator { width: parent.width }
                        }
                    }
                }

                // Export Button
                PrimaryButton {
                    width: parent.width
                    height: 56
                    text: "EXPORTER GRAND LIVRE (.CSV)"
                    iconName: "download"
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MODALS
    // ═══════════════════════════════════════════════════════════════════════

    // Auto-generation Modal
    ModalOverlay {
        show: showAutoModal
        modalWidth: 560
        modalRadius: 40
        onClose: showAutoModal = false

        Column {
            width: parent.width
            spacing: 24
            padding: 40

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    width: 48
                    height: 48
                    radius: 20
                    color: Style.successBg

                    IconLabel {
                        anchors.centerIn: parent
                        iconName: "activity"
                        iconSize: 24
                        iconColor: Style.successColor
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Génération Automatique"
                        font.pixelSize: 24
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "SESSION " + selectedMonth.toUpperCase() + " " + selectedYear
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.textTertiary
                        font.letterSpacing: 2
                    }
                }
            }

            Rectangle {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: infoText.implicitHeight + 48
                radius: 24
                color: Style.bgPage
                border.color: Style.borderLight

                Text {
                    id: infoText
                    anchors.fill: parent
                    anchors.margins: 24
                    text: "Cette action va créer des factures de scolarité pour tous les élèves inscrits qui n'ont pas encore de règlement pour <b>" + selectedMonth + " " + selectedYear + "</b>."
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Style.textSecondary
                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText
                    lineHeight: 1.5
                }
            }

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    radius: 20
                    color: "transparent"
                    border.color: Style.borderLight

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        SectionLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "TARIF ENFANT"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "150 DT"
                            font.pixelSize: 18
                            font.weight: Font.Black
                            color: Style.primary
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    radius: 20
                    color: "transparent"
                    border.color: Style.borderLight

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        SectionLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "TARIF ADULTE"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "250 DT"
                            font.pixelSize: 18
                            font.weight: Font.Black
                            color: Style.primary
                        }
                    }
                }
            }

            ModalButtons {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: "Lancer la génération"
                onCancel: showAutoModal = false
                onConfirm: showAutoModal = false
            }
        }
    }

    // Schooling Payment Modal
    ModalOverlay {
        show: showSchoolingModal
        modalWidth: 560
        modalRadius: 40
        onClose: showSchoolingModal = false

        Column {
            width: parent.width
            spacing: 24
            padding: 40

            Text {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nouveau Paiement"
                font.pixelSize: 24
                font.weight: Font.Black
                color: Style.textPrimary
            }

            FormField {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                label: "ÉLÈVE"
                placeholder: "Nom de l'élève"
                fieldHeight: 48
            }

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                FormField {
                    Layout.fillWidth: true
                    label: "SOMME TOTALE (DÛ)"
                    placeholder: "150"
                    fieldHeight: 48
                }

                FormField {
                    Layout.fillWidth: true
                    label: "SOMME PAYÉE"
                    placeholder: "0"
                    fieldHeight: 48
                }
            }

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Column {
                    Layout.fillWidth: true
                    spacing: 12

                    SectionLabel {
                        text: "MÉTHODE"
                    }

                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 12
                        color: Style.bgPage
                        border.color: Style.borderLight

                        Text {
                            anchors.centerIn: parent
                            text: "Espèces"
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }
                    }
                }

                FormField {
                    Layout.fillWidth: true
                    label: "CLASSE"
                    placeholder: "Niveau 1"
                    fieldHeight: 48
                }
            }

            ModalButtons {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: "Valider"
                onCancel: showSchoolingModal = false
                onConfirm: showSchoolingModal = false
            }
        }
    }

    // Donation Modal
    ModalOverlay {
        show: showDonationModal
        modalWidth: 560
        modalRadius: 40
        onClose: showDonationModal = false

        Column {
            width: parent.width
            spacing: 24
            padding: 40

            Text {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nouveau Don"
                font.pixelSize: 24
                font.weight: Font.Black
                color: Style.textPrimary
            }

            FormField {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                label: "DONATEUR"
                placeholder: "Nom du donateur"
                fieldHeight: 48
            }

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                FormField {
                    Layout.fillWidth: true
                    label: "MONTANT (DT)"
                    placeholder: "0"
                    fieldHeight: 48
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 12

                    SectionLabel {
                        text: "PROJET"
                    }

                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 12
                        color: Style.bgPage
                        border.color: Style.borderLight

                        Text {
                            anchors.centerIn: parent
                            text: "Rénovation"
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }
                    }
                }
            }

            ModalButtons {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: "Confirmer"
                onCancel: showDonationModal = false
                onConfirm: showDonationModal = false
            }
        }
    }

    // Expense Modal
    ModalOverlay {
        show: showExpenseModal
        modalWidth: 560
        modalRadius: 40
        onClose: showExpenseModal = false

        Column {
            width: parent.width
            spacing: 24
            padding: 40

            Text {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nouvelle Dépense"
                font.pixelSize: 24
                font.weight: Font.Black
                color: Style.textPrimary
            }

            FormField {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                label: "BÉNÉFICIAIRE"
                placeholder: "Nom du bénéficiaire"
                fieldHeight: 48
            }

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                FormField {
                    Layout.fillWidth: true
                    label: "MONTANT (DT)"
                    placeholder: "0"
                    fieldHeight: 48
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 12

                    SectionLabel {
                        text: "CATÉGORIE"
                    }

                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 12
                        color: Style.bgPage
                        border.color: Style.borderLight

                        Text {
                            anchors.centerIn: parent
                            text: "Salaires"
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                        }
                    }
                }
            }

            ModalButtons {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: "ENREGISTRER"
                confirmColor: "#DC2626"
                onCancel: showExpenseModal = false
                onConfirm: showExpenseModal = false
            }
        }
    }

    // ── MonthYearSelector flottant — enfant direct de financePage, z élevé ──
    MonthYearSelector {
        id: monthPicker
        z: 200
        onMonthYearChanged: function(month, year) {
            financePage.selectedMonthIndex = month - 1
            financePage.selectedYear = year
        }
    }

    // Delete Confirmation Modal
    ModalOverlay {
        show: showDeleteModal
        modalWidth: 480
        modalRadius: 32
        onClose: showDeleteModal = false

        Column {
            width: parent.width
            spacing: 24
            padding: 40

            RowLayout {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Rectangle {
                    width: 56
                    height: 56
                    radius: 20
                    color: Style.errorBg

                    IconLabel {
                        anchors.centerIn: parent
                        iconName: "alert"
                        iconSize: 28
                        iconColor: Style.errorColor
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Confirmer la suppression"
                        font.pixelSize: 22
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Text {
                        text: "CETTE ACTION EST IRRÉVERSIBLE"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Style.errorColor
                        font.letterSpacing: 1
                    }
                }
            }

            Rectangle {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: warningText.implicitHeight + 32
                radius: 20
                color: Style.errorBg
                border.color: Style.errorBorder

                Text {
                    id: warningText
                    anchors.fill: parent
                    anchors.margins: 16
                    text: "Êtes-vous sûr de vouloir supprimer l'opération de <b>" + deleteItemName + "</b> ? Cette action ne peut pas être annulée."
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Style.errorColor
                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText
                    lineHeight: 1.5
                }
            }

            ModalButtons {
                width: parent.width - 80
                anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"
                confirmText: "SUPPRIMER"
                confirmColor: Style.errorColor
                onCancel: showDeleteModal = false
                onConfirm: {
                    console.log("Deleting " + deleteType + ": " + deleteItemName)
                    showDeleteModal = false
                }
            }
        }
    }
}
