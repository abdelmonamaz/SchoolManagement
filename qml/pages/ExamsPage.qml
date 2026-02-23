import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: examsPage
    implicitHeight: mainLayout.implicitHeight

    property string activeView: "planning"
    property string modalType: ""
    property bool showAssignModal: false
    property bool showDetailModal: false
    property var selectedItem: null
    property int selectedMonth: new Date().getMonth()
    property int selectedYear: new Date().getFullYear()
    property int selectedWeek: 1
    property int selectedWeekYear: new Date().getFullYear()

    // Error popup state
    property bool showErrorPopup: false
    property string errorPopupMessage: ""

    // Calendar state
    property int filterNiveauId: -1
    property int filterSalleId: -1
    property int filterProfId: -1
    property int selectedDay: -1

    Component.onCompleted: {
        selectedWeek = weekPickerPopup.currentWeekNumber()
        schoolingController.loadNiveaux()
        schoolingController.loadAllMatieres()
        schoolingController.loadAllClasses()
        schoolingController.loadSalles()
        staffController.loadAllPersonnel()
        examsController.loadSessionsByWeek(selectedWeek, selectedWeekYear)
    }

    function reloadCurrentView() {
        if (activeView === "planning")
            examsController.loadSessionsByWeek(selectedWeek, selectedWeekYear)
        else
            examsController.loadAllSessionsByMonth(selectedMonth + 1, selectedYear)
    }

    onSelectedWeekChanged: examsController.loadSessionsByWeek(selectedWeek, selectedWeekYear)
    onSelectedWeekYearChanged: examsController.loadSessionsByWeek(selectedWeek, selectedWeekYear)
    onSelectedMonthChanged: { selectedDay = -1; if (activeView === "calendar") examsController.loadAllSessionsByMonth(selectedMonth + 1, selectedYear) }
    onSelectedYearChanged: { selectedDay = -1; if (activeView === "calendar") examsController.loadAllSessionsByMonth(selectedMonth + 1, selectedYear) }

    Connections {
        target: examsController
        function onOperationSucceeded(msg) {
            console.log("ExamsPage:", msg)
            showAssignModal = false
            reloadCurrentView()
        }
        function onOperationFailed(err) {
            errorPopupMessage = err
            showErrorPopup = true
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 28

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true

            PageHeader {
                Layout.fillWidth: true
                title: "Planning & Organisation"
                subtitle: "Gestion centralisée des cours, examens et évènements scolaires."
            }

            Row {
                spacing: 12

                // View Toggle
                Rectangle {
                    implicitWidth: viewToggleRow.implicitWidth + 8
                    height: 42
                    radius: 16
                    color: Style.bgSecondary

                    Row {
                        id: viewToggleRow
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: planningLabel.implicitWidth + 28
                            height: 34
                            radius: 12
                            color: activeView === "planning" ? Style.bgWhite : "transparent"

                            Text {
                                id: planningLabel
                                anchors.centerIn: parent
                                text: "PLANNING"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: activeView === "planning" ? Style.primary : Style.textTertiary
                                font.letterSpacing: 0.5
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: activeView = "planning"
                            }
                        }

                        Rectangle {
                            width: calendarLabel.implicitWidth + 28
                            height: 34
                            radius: 12
                            color: activeView === "calendar" ? Style.bgWhite : "transparent"

                            Text {
                                id: calendarLabel
                                anchors.centerIn: parent
                                text: "CALENDRIER"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                color: activeView === "calendar" ? Style.primary : Style.textTertiary
                                font.letterSpacing: 0.5
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    activeView = "calendar"
                                    examsController.loadAllSessionsByMonth(selectedMonth + 1, selectedYear)
                                }
                            }
                        }
                    }
                }

                // Action Buttons
                Rectangle {
                    implicitWidth: courseRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: Style.bgWhite
                    border.color: courseMa.containsMouse ? Style.primary : Style.borderLight

                    RowLayout {
                        id: courseRow
                        anchors.centerIn: parent
                        spacing: 6

                        IconLabel { iconName: "book"; iconSize: 14; iconColor: Style.primary }

                        Text {
                            text: "COURS"
                            font.pixelSize: 10; font.weight: Font.Black
                            color: Style.textPrimary; font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: courseMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            assignModal.resetForm()
                            modalType = "course"
                            showAssignModal = true
                        }
                    }
                }

                Rectangle {
                    implicitWidth: examRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: examMa.containsMouse ? Style.primaryDark : Style.primary

                    RowLayout {
                        id: examRow
                        anchors.centerIn: parent
                        spacing: 6

                        IconLabel { iconName: "check"; iconSize: 14; iconColor: "#FFFFFF" }

                        Text {
                            text: "EXAMEN"
                            font.pixelSize: 10; font.weight: Font.Black
                            color: "#FFFFFF"; font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: examMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            assignModal.resetForm()
                            modalType = "exam"
                            showAssignModal = true
                        }
                    }
                }

                Rectangle {
                    implicitWidth: eventRow.implicitWidth + 24
                    height: 40
                    radius: 12
                    color: eventMa.containsMouse ? "#D97706" : Style.warningColor

                    RowLayout {
                        id: eventRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text { text: "✨"; font.pixelSize: 14 }

                        Text {
                            text: "ÉVÈNEMENT"
                            font.pixelSize: 10; font.weight: Font.Black
                            color: "#FFFFFF"; font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: eventMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            assignModal.resetForm()
                            modalType = "event"
                            showAssignModal = true
                        }
                    }
                }
            }
        }

        // ─── Planning View ───
        Loader {
            Layout.fillWidth: true
            active: activeView === "planning"
            visible: active

            sourceComponent: Component {
                PlanningView {
                    selectedWeek: examsPage.selectedWeek
                    selectedWeekYear: examsPage.selectedWeekYear
                    onOpenWeekPicker: weekPickerPopup.open()
                    onOpenDetail: function(item) {
                        selectedItem = item
                        showDetailModal = true
                    }
                }
            }
        }

        // ─── Calendar View ───
        Loader {
            Layout.fillWidth: true
            active: activeView === "calendar"
            visible: active

            sourceComponent: Component {
                CalendarView {
                    selectedMonth: examsPage.selectedMonth
                    selectedYear: examsPage.selectedYear
                    filterNiveauId: examsPage.filterNiveauId
                    filterSalleId: examsPage.filterSalleId
                    filterProfId: examsPage.filterProfId
                    selectedDay: examsPage.selectedDay

                    onMonthChanged: function(month) { examsPage.selectedMonth = month }
                    onYearChanged: function(year) { examsPage.selectedYear = year }
                    onDaySelected: function(day) { examsPage.selectedDay = day }
                    onFilterNiveauChanged: function(id) { examsPage.filterNiveauId = id }
                    onFilterSalleChanged: function(id) { examsPage.filterSalleId = id }
                    onFilterProfChanged: function(id) { examsPage.filterProfId = id }
                    onSessionClicked: function(item) {
                        selectedItem = item
                        showDetailModal = true
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 32 }
    }

    // ─── Assign Modal ───
    SessionFormModal {
        id: assignModal
        show: showAssignModal
        modalType: examsPage.modalType
        pageWidth: examsPage.width
        onClose: showAssignModal = false
        onDatePickerRequested: datePickerPopup.open()
    }

    // ─── Week Picker Popup ───
    WeekPickerPopup {
        id: weekPickerPopup
        onConfirmed: function(week, year) {
            examsPage.selectedWeek = week
            examsPage.selectedWeekYear = year
        }
    }

    // ─── Date Picker Popup ───
    DatePickerPopup {
        id: datePickerPopup
        onConfirmed: function(isoDate) {
            assignModal.formDate = isoDate
        }
    }

    // ─── Detail / Edit Modal ───
    SessionDetailModal {
        show: showDetailModal
        selectedItem: examsPage.selectedItem
        pageWidth: examsPage.width
        onClose: showDetailModal = false
    }

    // ─── Error Popup ───
    ModalOverlay {
        visible: showErrorPopup
        onClose: showErrorPopup = false

        Rectangle {
            width: 520
            anchors.centerIn: parent
            implicitHeight: errorCol.implicitHeight + 48
            radius: Style.radiusRound
            color: Style.bgWhite
            border.color: Style.borderLight

            Column {
                id: errorCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 16

                RowLayout {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 36; height: 36; radius: 12
                        color: "#FEE2E2"

                        Text {
                            anchors.centerIn: parent
                            text: "!"
                            font.pixelSize: 16; font.weight: Font.Black
                            color: Style.errorColor
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Conflit détecté"
                        font.pixelSize: 16; font.weight: Font.Black
                        color: Style.textPrimary
                    }

                    IconButton {
                        iconName: "close"; iconSize: 16
                        onClicked: showErrorPopup = false
                    }
                }

                Separator { width: parent.width }

                Text {
                    width: parent.width
                    text: errorPopupMessage
                    font.pixelSize: 13; font.weight: Font.Medium
                    color: Style.textSecondary
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }

                Rectangle {
                    width: parent.width
                    height: 42; radius: 12
                    color: okErrorMa.containsMouse ? Style.bgTertiary : Style.bgSecondary

                    Text {
                        anchors.centerIn: parent
                        text: "COMPRIS"
                        font.pixelSize: 10; font.weight: Font.Black
                        color: Style.textPrimary; font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: okErrorMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showErrorPopup = false
                    }
                }
            }
        }
    }
}
