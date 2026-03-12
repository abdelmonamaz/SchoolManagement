import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
// 2. Import du module de vos composants (Style, boutons, badges, etc.)
import UI.Components 1.0

// 3. Import du module de vos pages (DashboardPage, etc.)
import UI.Pages 1.0

ApplicationWindow {
    id: root
    visible: true
    visibility: Window.FullScreen
    width: 1440
    height: 900
    minimumWidth: 1024
    minimumHeight: 700
    title: "Ez-Zaytouna — Gestion Scolaire"
    color: Style.bgPage

    property string currentPage: "dashboard"
    property int pendingStudentId: 0

    // ─── Wizard de Mise en Marche ───
    SetupWizardModal {
        id: setupWizard
    }

    // ─── DB Init Error Popup ───
    Popup {
        id: dbErrorPopup
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 460; padding: 0
        modal: true
        closePolicy: Popup.NoAutoClose
        Overlay.modal: Rectangle { color: Qt.alpha(Style.foreground, 0.80) }
        background: Rectangle { radius: 16; color: Style.bgWhite; border.color: Style.errorBorder; border.width: 2 }

        Column {
            width: dbErrorPopup.width
            padding: 28; spacing: 18

            Row {
                spacing: 12
                Text { text: "🚫"; font.pixelSize: 24 }
                Text {
                    text: "Erreur d'initialisation"
                    font.pixelSize: 17; font.weight: Font.Black; color: Style.errorColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                width: dbErrorPopup.width - 56
                text: appController.dbInitError
                font.pixelSize: 13; color: Style.textSecondary
                wrapMode: Text.WordWrap; lineHeight: 1.5
            }
            Rectangle {
                width: dbErrorPopup.width - 56; height: 42; radius: 10
                color: Style.errorColor
                Text { anchors.centerIn: parent; text: "Fermer l'application"; font.pixelSize: 13; font.bold: true; color: "white" }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.quit()
                }
            }
        }
    }

    Connections {
        target: appController
        function onDbInitErrorChanged() {
            if (appController.dbInitError.length > 0) dbErrorPopup.open()
        }
    }

    Connections {
        target: setupController

        // Fired once the async checkInitialized() result returns.
        // At this point isInitialized has its real value.
        function onIsCheckingChanged() {
            if (!setupController.isChecking) {
                if (!setupController.isInitialized) {
                    setupWizard.open()
                } else {
                    schoolingController.loadNiveaux()
                    schoolingController.loadSalles()
                    schoolingController.loadEquipements()
                }
            }
        }

        // Fired when the wizard completes (isInitialized goes true after setup).
        function onIsInitializedChanged() {
            if (setupController.isChecking) return   // still in initial check — ignore
            if (setupController.isInitialized) {
                // Wizard vient de se terminer — recharger les données académiques
                schoolingController.loadNiveaux()
                schoolingController.loadSalles()
                schoolingController.loadEquipements()
            }
        }
    }

    Component.onCompleted: {
        // Do NOT open the wizard here: isInitialized is false by default while
        // the async check is in flight. onIsCheckingChanged() handles this.
    }

    // ─── Font Loading ───
    FontLoader { id: fontRegular; source: "qrc:/qt/qml//GestionScolaire/fonts/Inter-Regular.ttf" }
    FontLoader { id: fontMedium; source: "qrc:/qt/qml//GestionScolaire/fonts/Inter-Medium.ttf" }
    FontLoader { id: fontBold; source: "qrc:/qt/qml//GestionScolaire/fonts/Inter-Bold.ttf" }
    FontLoader { id: fontBlack; source: "qrc:/qt/qml//GestionScolaire/fonts/Inter-Black.ttf" }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ══════════════════════════════════════════
        //  SIDEBAR
        // ══════════════════════════════════════════
        Rectangle {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: Style.sidebar
            border.color: Style.borderLight
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ─── Logo ───
                RowLayout {
                    Layout.margins: 28
                    Layout.bottomMargin: 16
                    spacing: 12

                    Rectangle {
                        width: 40; height: 40
                        radius: 10
                        color: Style.primary

                        Text {
                            anchors.centerIn: parent
                            text: "Z"
                            font.pixelSize: 18
                            font.bold: true
                            color: Style.background
                        }
                    }

                    Column {
                        spacing: 2
                        Text {
                            text: "Ez-Zaytouna"
                            font.pixelSize: 16
                            font.bold: true
                            color: Style.textPrimary
                        }
                        Text {
                            text: "GESTION SCOLAIRE"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Style.textTertiary
                            font.letterSpacing: 1
                        }
                    }
                }

                // ─── Navigation Items ───
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.topMargin: 8
                    spacing: 4

                    Repeater {
                        model: ListModel {
                            ListElement { pageId: "dashboard"; label: "Tableau de Bord"; iconName: "dashboard" }
                            ListElement { pageId: "schooling"; label: "Architecture Académique"; iconName: "book" }
                            ListElement { pageId: "attendance"; label: "Présences"; iconName: "clipboard" }
                            ListElement { pageId: "students"; label: "Étudiants"; iconName: "users" }
                            ListElement { pageId: "staff"; label: "Personnel"; iconName: "contact" }
                            ListElement { pageId: "exams"; label: "Examens & Planning"; iconName: "calendar" }
                            ListElement { pageId: "grades"; label: "Notes & Bulletins"; iconName: "graduation" }
                            ListElement { pageId: "finance"; label: "Finance & Trésorerie"; iconName: "wallet" }
                            ListElement { pageId: "settings"; label: "Paramètres"; iconName: "settings" }
                        }

                        delegate: SidebarButton {
                            Layout.fillWidth: true
                            text: model.label
                            iconName: model.iconName
                            active: root.currentPage === model.pageId
                            onClicked: root.currentPage = model.pageId
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // ─── User Profile Card ───
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 16
                        anchors.topMargin: 0
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 12
                            radius: 16
                            color: Style.bgPage

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                anchors.centerIn: parent;
                                spacing: 10

                                Rectangle {
                                    width: 40; height: 40
                                    radius: 20
                                    color: Style.bgSecondary
                                    border.color: Style.background
                                    border.width: 2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "A"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: Style.textSecondary
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: "Admin Principal"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: Style.textPrimary
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: "Scolarité " + appVersion
                                        font.pixelSize: 11
                                        color: Style.textTertiary
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }

                                IconButton {
                                    iconName: "logout"
                                    iconSize: 18
                                    hoverColor: Style.errorColor
                                    onClicked: Qt.quit()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════════════
        //  MAIN CONTENT AREA
        // ══════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ─── Header Bar ───
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                color: Style.background

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Style.borderLight
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 32
                    anchors.rightMargin: 32
                    spacing: 16

                    Item { Layout.fillWidth: true }

                    // Année Scolaire
                    Column {
                        spacing: 2
                        Layout.rightMargin: 8
                        Text {
                            text: "Année Scolaire"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Style.textTertiary
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                        }
                        Text {
                            text: setupController.activeTarifs.libelle || "—"
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.primary
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                        }
                    }

                }
            }

            // ─── Page Content ───
            Flickable {
                id: pageFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: pageContainer.currentPageItem
                               ? pageContainer.currentPageItem.implicitHeight + 64
                               : height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Reset scroll position on each page change
                Connections {
                    target: root
                    function onCurrentPageChanged() { pageFlickable.contentY = 0 }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                // All pages are kept alive; only opacity/visibility toggles on navigation.
                // Component.onCompleted fires once at startup → data pre-loaded.
                Item {
                    id: pageContainer
                    anchors.left:        parent.left
                    anchors.right:       parent.right
                    anchors.leftMargin:  32
                    anchors.rightMargin: 32
                    anchors.topMargin:   32
                    implicitHeight: currentPageItem ? currentPageItem.implicitHeight : 0

                    readonly property var currentPageItem: {
                        switch (root.currentPage) {
                            case "dashboard":  return dashboardPage
                            case "schooling":  return schoolingPage
                            case "attendance": return attendancePage
                            case "students":   return studentsPage
                            case "staff":      return staffPage
                            case "exams":      return examsPage
                            case "grades":     return gradesPage
                            case "finance":    return financePage
                            case "settings":   return settingsPage
                            default:           return dashboardPage
                        }
                    }

                    DashboardPage  { id: dashboardPage;  width: parent.width; opacity: root.currentPage === "dashboard"  ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                    SchoolingPage  { id: schoolingPage;  width: parent.width; opacity: root.currentPage === "schooling"  ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                    AttendancePage { id: attendancePage; width: parent.width; opacity: root.currentPage === "attendance" ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                    StudentsPage   { id: studentsPage;   width: parent.width; opacity: root.currentPage === "students"   ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                    StaffPage      { id: staffPage;      width: parent.width; opacity: root.currentPage === "staff"      ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                    ExamsPage      { id: examsPage;      width: parent.width; opacity: root.currentPage === "exams"      ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                    GradesPage     { id: gradesPage;     width: parent.width; opacity: root.currentPage === "grades"     ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                    FinancePage    { id: financePage;    width: parent.width; opacity: root.currentPage === "finance"    ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                    SettingsPage   { id: settingsPage;   width: parent.width; opacity: root.currentPage === "settings"   ? 1.0 : 0.0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
                }
            }
        }
    }

}
