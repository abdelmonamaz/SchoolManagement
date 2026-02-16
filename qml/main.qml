import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
// 2. Import du module de vos composants (Style, boutons, badges, etc.)
import UI.Components 1.0

// 3. Import du module de vos pages (DashboardPage, etc.)
import UI.Pages 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1440
    height: 900
    minimumWidth: 1024
    minimumHeight: 700
    title: "Ez-Zaytouna — Gestion Scolaire"
    color: Style.bgPage

    property string currentPage: "dashboard"
    property bool showNotifications: false
    property int pendingStudentId: 0

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
            color: "#FFFFFF"
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
                            color: "#FFFFFF"
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
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Style.borderLight
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 12
                            radius: 16
                            color: Style.bgPage

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Rectangle {
                                    width: 40; height: 40
                                    radius: 20
                                    color: Style.bgSecondary
                                    border.color: "#FFFFFF"
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
                                        text: "Scolarité v2.0"
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
                color: "#FFFFFF"

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
                            text: "2025 - 2026"
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.primary
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                        }
                    }

                    // Notification Bell
                    Rectangle {
                        width: 42
                        height: 42
                        radius: 12
                        color: notifMa.containsMouse || showNotifications ? Style.bgPage : "transparent"
                        border.color: Style.borderLight
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        IconLabel {
                            anchors.centerIn: parent
                            iconName: "bell"
                            iconSize: 20
                            iconColor: Style.textSecondary
                        }

                        Rectangle {
                            x: parent.width - 14
                            y: 8
                            width: 8
                            height: 8
                            radius: 4
                            color: Style.errorColor
                            border.color: "#FFFFFF"
                            border.width: 2
                        }

                        MouseArea {
                            id: notifMa
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: showNotifications = !showNotifications
                        }
                    }
                }
            }

            // ─── Page Content ───
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: pageLoader.item ? pageLoader.item.implicitHeight + 64 : height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Loader {
                    id: pageLoader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 32
                    anchors.rightMargin: 32
                    anchors.topMargin: 32

                    sourceComponent: {
                        switch (root.currentPage) {
                                    case "dashboard":  return compDashboard;
                                    case "schooling":  return compSchooling;
                                    case "attendance": return compAttendance;
                                    case "students":   return compStudents;
                                    case "staff":      return compStaff;
                                    case "exams":      return compExams;
                                    case "grades":     return compGrades;
                                    case "finance":    return compFinance;
                                    case "settings":   return compSettings;
                                    default:           return compDashboard;
                                }
                    }

                    // Fade transition
                    opacity: status === Loader.Ready ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }

    // ─── Notifications Panel ───
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 90
        anchors.rightMargin: 32
        width: 360
        implicitHeight: notifCol.implicitHeight
        radius: 20
        color: "#FFFFFF"
        border.color: Style.borderLight
        visible: showNotifications
        opacity: showNotifications ? 1.0 : 0.0
        scale: showNotifications ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: true

        Column {
            id: notifCol
            width: parent.width
            spacing: 0

            Rectangle {
                width: parent.width
                height: 56
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20

                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        font.pixelSize: 16
                        font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 8
                        color: Style.errorBg

                        Text {
                            anchors.centerIn: parent
                            text: "3"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            color: Style.errorColor
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Style.borderLight
                }
            }

            Repeater {
                model: ListModel {
                    ListElement {
                        title: "Nouveau paiement reçu"
                        message: "Sara Khalil - 150 DT"
                        time: "Il y a 5 min"
                        type_: "success"
                    }
                    ListElement {
                        title: "Absence non justifiée"
                        message: "Amine Ben Salem - Cours d'Arabe"
                        time: "Il y a 1 heure"
                        type_: "warning"
                    }
                    ListElement {
                        title: "Nouvel examen planifié"
                        message: "Coran - Niveau 3 - 15/02"
                        time: "Il y a 2 heures"
                        type_: "info"
                    }
                }

                delegate: Column {
                    width: parent.width

                    Rectangle {
                        width: parent.width
                        height: 80
                        color: notifItemMa.containsMouse ? Style.bgPage : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 12
                                color: model.type_ === "success" ? Style.successBg :
                                       model.type_ === "warning" ? Style.warningBg : Style.primaryBg

                                Text {
                                    anchors.centerIn: parent
                                    text: model.type_ === "success" ? "✓" :
                                          model.type_ === "warning" ? "⚠" : "📅"
                                    font.pixelSize: 16
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: model.title
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Style.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: model.message
                                    font.pixelSize: 11
                                    color: Style.textSecondary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: model.time
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Style.textTertiary
                                }
                            }
                        }

                        MouseArea {
                            id: notifItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Style.borderLight
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 48
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "TOUT MARQUER COMME LU"
                    font.pixelSize: 10
                    font.weight: Font.Black
                    color: Style.primary
                    font.letterSpacing: 1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: showNotifications = false
                }
            }
        }
    }

    Component { id: compDashboard;  DashboardPage {} }
    Component { id: compSchooling;  SchoolingPage {} }
    Component { id: compAttendance; AttendancePage {} }
    Component { id: compStudents;   StudentsPage {} }
    Component { id: compStaff;      StaffPage {} }
    Component { id: compExams;      ExamsPage {} }
    Component { id: compGrades;     GradesPage {} }
    Component { id: compFinance;    FinancePage {} }
    Component { id: compSettings;   SettingsPage {} }
}
