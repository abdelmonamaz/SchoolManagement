import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import UI.Components

RowLayout {
    id: root
    spacing: 24

    required property int selectedWeek
    required property int selectedWeekYear
    signal openWeekPicker
    signal prevWeek
    signal nextWeek
    signal openDetail(var item)

    // Filter sessions by type
    function sessionsByType(type) {
        var all = examsController.weekSessions
        var result = []
        for (var i = 0; i < all.length; i++) {
            if (all[i].typeSeance === type) result.push(all[i])
        }
        return result
    }

    // Calcule le lundi et dimanche de la semaine ISO sélectionnée
    readonly property string weekDateRange: {
        var jan4    = new Date(root.selectedWeekYear, 0, 4)
        var isoDay  = jan4.getDay() === 0 ? 7 : jan4.getDay()   // 1=Lun … 7=Dim
        var week1Mon = new Date(jan4.getTime() - (isoDay - 1) * 86400000)
        var mon     = new Date(week1Mon.getTime() + (root.selectedWeek - 1) * 7 * 86400000)
        var sun     = new Date(mon.getTime() + 6 * 86400000)

        var months = ["Jan","Fév","Mar","Avr","Mai","Jun","Jul","Aoû","Sep","Oct","Nov","Déc"]
        function fmt(d) {
            return (d.getDate() < 10 ? "0" : "") + d.getDate() + " " + months[d.getMonth()]
        }
        var suffix = (mon.getFullYear() !== sun.getFullYear())
                     ? " " + sun.getFullYear() : ""
        return fmt(mon) + " – " + fmt(sun) + suffix
    }

    AppCard {
        Layout.fillWidth: true
        Layout.preferredWidth: 3
        title: qsTr("Planning Hebdomadaire")
        subtitle: qsTr("Visualisation des assignations actives  ·  ") + root.weekDateRange

        headerAction: Component {
            Row {
                spacing: 4

                // ◀ Semaine précédente
                Rectangle {
                    width: 32; height: 36; radius: 10
                    color: prevWeekMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("‹"); font.pixelSize: 18; font.bold: true
                        color: Style.textSecondary
                    }
                    MouseArea {
                        id: prevWeekMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevWeek()
                    }
                }

                // Semaine courante — clic pour ouvrir le picker
                Rectangle {
                    implicitWidth: weekLabelRow.implicitWidth + 20
                    height: 36; radius: 10
                    color: weekLabelMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: weekLabelRow
                        anchors.centerIn: parent; spacing: 6
                        IconLabel { iconName: "calendar"; iconSize: 14; iconColor: Style.primary }
                        Text {
                            text: qsTr("S") + root.selectedWeek + " / " + root.selectedWeekYear
                            font.pixelSize: 10; font.weight: Font.Black
                            color: Style.textPrimary; font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: weekLabelMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openWeekPicker()
                    }
                }

                // ▶ Semaine suivante
                Rectangle {
                    width: 32; height: 36; radius: 10
                    color: nextWeekMa.containsMouse ? Style.bgSecondary : Style.bgPage
                    border.color: Style.borderLight
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("›"); font.pixelSize: 18; font.bold: true
                        color: Style.textSecondary
                    }
                    MouseArea {
                        id: nextWeekMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextWeek()
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 24

            // ═══════════════════════════════════════════
            // SECTION: COURS
            // ═══════════════════════════════════════════
            Column {
                width: parent.width
                spacing: 0

                RowLayout {
                    width: parent.width
                    spacing: 8
                    height: 36

                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: Style.foreground
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: qsTr("COURS")
                        font.pixelSize: 11; font.weight: Font.Black
                        color: Style.textPrimary; font.letterSpacing: 1
                    }

                    Rectangle {
                        width: countCoursLabel.implicitWidth + 12; height: 20; radius: 10
                        color: Style.bgPage

                        Text {
                            id: countCoursLabel
                            anchors.centerIn: parent
                            text: coursRepeater.count.toString()
                            font.pixelSize: 10; font.weight: Font.Black; color: Style.textTertiary
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Headers
                RowLayout {
                    width: parent.width
                    height: 40
                    spacing: 0

                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("JOUR / HEURE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("MATIÈRE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("PROFESSEUR"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("CLASSE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("SALLE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 0.4; text: ""; horizontalAlignment: Text.AlignHCenter }
                }

                Separator { width: parent.width }

                Text {
                    visible: coursRepeater.count === 0 && !examsController.loading
                    width: parent.width; height: 50
                    text: qsTr("Aucun cours cette semaine")
                    font.pixelSize: 12; font.weight: Font.Medium
                    color: Style.textTertiary
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    id: coursRepeater
                    model: {
                        var _d = examsController.weekSessions
                        return sessionsByType("Cours")
                    }

                    delegate: Column {
                        width: parent.width

                        Rectangle {
                            width: parent.width; height: 58
                            color: coursRowMa.containsMouse ? Style.bgPage : "transparent"

                            MouseArea {
                                id: coursRowMa
                                anchors.fill: parent; hoverEnabled: true; z: -1
                            }

                            RowLayout {
                                anchors.fill: parent; spacing: 0

                                // Jour / Heure
                                Column {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1
                                    Layout.alignment: Qt.AlignVCenter; spacing: 2
                                    Text {
                                        text: modelData.day || ""
                                        font.pixelSize: 13; font.weight: Font.Black; color: Style.textPrimary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: modelData.time || ""
                                        font.pixelSize: 11; font.bold: true; color: Style.textTertiary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // Matière
                                Text {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignVCenter
                                    text: modelData.subject || ""
                                    font.pixelSize: 13; font.bold: true; color: Style.primary
                                    elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                }

                                // Professeur
                                RowLayout {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignVCenter
                                    spacing: 6
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 24; height: 24; radius: 8; color: Style.bgSecondary
                                        IconLabel { anchors.centerIn: parent; iconName: "user"; iconSize: 11; iconColor: Style.textTertiary }
                                    }
                                    Text { text: modelData.professor || ""; font.pixelSize: 12; font.bold: true; color: Style.textSecondary; elide: Text.ElideRight }
                                    Item { Layout.fillWidth: true }
                                }

                                // Classe
                                Item {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1
                                    Badge { anchors.centerIn: parent; text: modelData.className || ""; variant: "neutral" }
                                }

                                // Salle
                                RowLayout {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignVCenter
                                    spacing: 4
                                    Item { Layout.fillWidth: true }
                                    IconLabel { iconName: "location"; iconSize: 11; iconColor: Style.textSecondary }
                                    Text { text: modelData.room || ""; font.pixelSize: 11; font.bold: true; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                }

                                // Action
                                Item {
                                    Layout.fillWidth: true; Layout.preferredWidth: 0.4
                                    IconButton { anchors.centerIn: parent; iconName: "edit"; iconSize: 14; hoverColor: Style.primary; onClicked: root.openDetail(modelData) }
                                }
                            }
                        }

                        Separator { width: parent.width }
                    }
                }
            }

            // ═══════════════════════════════════════════
            // SECTION: EXAMENS
            // ═══════════════════════════════════════════
            Column {
                width: parent.width
                spacing: 0

                RowLayout {
                    width: parent.width
                    spacing: 8
                    height: 36

                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: Style.errorColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: qsTr("EXAMENS")
                        font.pixelSize: 11; font.weight: Font.Black
                        color: Style.textPrimary; font.letterSpacing: 1
                    }

                    Rectangle {
                        width: countExamLabel.implicitWidth + 12; height: 20; radius: 10
                        color: Style.errorBg

                        Text {
                            id: countExamLabel
                            anchors.centerIn: parent
                            text: examRepeater.count.toString()
                            font.pixelSize: 10; font.weight: Font.Black; color: Style.errorColor
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Headers
                RowLayout {
                    width: parent.width
                    height: 40
                    spacing: 0

                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("JOUR / HEURE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1.2; text: qsTr("TITRE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("MATIÈRE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 0.8; text: qsTr("CLASSE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 0.8; text: qsTr("SALLE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 0.4; text: ""; horizontalAlignment: Text.AlignHCenter }
                }

                Separator { width: parent.width }

                Text {
                    visible: examRepeater.count === 0 && !examsController.loading
                    width: parent.width; height: 50
                    text: qsTr("Aucun examen cette semaine")
                    font.pixelSize: 12; font.weight: Font.Medium
                    color: Style.textTertiary
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    id: examRepeater
                    model: {
                        var _d = examsController.weekSessions
                        return sessionsByType("Examen")
                    }

                    delegate: Column {
                        width: parent.width

                        Rectangle {
                            width: parent.width; height: 58
                            color: examRowMa.containsMouse ? Style.bgPage : "transparent"

                            MouseArea {
                                id: examRowMa
                                anchors.fill: parent; hoverEnabled: true; z: -1
                            }

                            RowLayout {
                                anchors.fill: parent; spacing: 0

                                // Jour / Heure
                                Column {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1
                                    Layout.alignment: Qt.AlignVCenter; spacing: 2
                                    Text {
                                        text: modelData.day || ""
                                        font.pixelSize: 13; font.weight: Font.Black; color: Style.textPrimary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: modelData.time || ""
                                        font.pixelSize: 11; font.bold: true; color: Style.textTertiary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // Titre
                                Text {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1.2; Layout.alignment: Qt.AlignVCenter
                                    text: modelData.titre || ""
                                    font.pixelSize: 13; font.weight: Font.Black; color: Style.errorColor
                                    elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                }

                                // Matière
                                Text {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignVCenter
                                    text: modelData.subject || ""
                                    font.pixelSize: 13; font.bold: true; color: Style.primary
                                    elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                }

                                // Classe
                                Item {
                                    Layout.fillWidth: true; Layout.preferredWidth: 0.8
                                    Badge { anchors.centerIn: parent; text: modelData.className || ""; variant: "neutral" }
                                }

                                // Salle
                                RowLayout {
                                    Layout.fillWidth: true; Layout.preferredWidth: 0.8; Layout.alignment: Qt.AlignVCenter
                                    spacing: 4
                                    Item { Layout.fillWidth: true }
                                    IconLabel { iconName: "location"; iconSize: 11; iconColor: Style.textSecondary }
                                    Text { text: modelData.room || ""; font.pixelSize: 11; font.bold: true; color: Style.textSecondary }
                                    Item { Layout.fillWidth: true }
                                }

                                // Action
                                Item {
                                    Layout.fillWidth: true; Layout.preferredWidth: 0.4
                                    IconButton { anchors.centerIn: parent; iconName: "edit"; iconSize: 14; hoverColor: Style.errorColor; onClicked: root.openDetail(modelData) }
                                }
                            }
                        }

                        Separator { width: parent.width }
                    }
                }
            }

            // ═══════════════════════════════════════════
            // SECTION: ÉVÉNEMENTS
            // ═══════════════════════════════════════════
            Column {
                width: parent.width
                spacing: 0

                RowLayout {
                    width: parent.width
                    spacing: 8
                    height: 36

                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: Style.warningColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: qsTr("ÉVÉNEMENTS")
                        font.pixelSize: 11; font.weight: Font.Black
                        color: Style.textPrimary; font.letterSpacing: 1
                    }

                    Rectangle {
                        width: countEventLabel.implicitWidth + 12; height: 20; radius: 10
                        color: Style.warningBg

                        Text {
                            id: countEventLabel
                            anchors.centerIn: parent
                            text: eventRepeater.count.toString()
                            font.pixelSize: 10; font.weight: Font.Black; color: Style.warningColor
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Headers
                RowLayout {
                    width: parent.width
                    height: 40
                    spacing: 0

                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("JOUR / HEURE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1.5; text: qsTr("TITRE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 1; text: qsTr("SALLE"); horizontalAlignment: Text.AlignHCenter }
                    SectionLabel { Layout.fillWidth: true; Layout.preferredWidth: 0.4; text: ""; horizontalAlignment: Text.AlignHCenter }
                }

                Separator { width: parent.width }

                Text {
                    visible: eventRepeater.count === 0 && !examsController.loading
                    width: parent.width; height: 50
                    text: qsTr("Aucun événement cette semaine")
                    font.pixelSize: 12; font.weight: Font.Medium
                    color: Style.textTertiary
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    id: eventRepeater
                    model: {
                        var _d = examsController.weekSessions
                        return sessionsByType("Événement")
                    }

                    delegate: Column {
                        width: parent.width

                        Rectangle {
                            width: parent.width; height: 58
                            color: eventRowMa.containsMouse ? Style.bgPage : "transparent"

                            MouseArea {
                                id: eventRowMa
                                anchors.fill: parent; hoverEnabled: true; z: -1
                            }

                            RowLayout {
                                anchors.fill: parent; spacing: 0

                                // Jour / Heure
                                Column {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1
                                    Layout.alignment: Qt.AlignVCenter; spacing: 2
                                    Text {
                                        text: modelData.day || ""
                                        font.pixelSize: 13; font.weight: Font.Black; color: Style.textPrimary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: modelData.time || ""
                                        font.pixelSize: 11; font.bold: true; color: Style.textTertiary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // Titre
                                Column {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1.5
                                    Layout.alignment: Qt.AlignVCenter; spacing: 2

                                    Text {
                                        text: modelData.titre || "Événement"
                                        font.pixelSize: 13; font.weight: Font.Black; color: Style.warningColor
                                        elide: Text.ElideRight; width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        visible: modelData.descriptif ? true : false
                                        text: {
                                            var d = modelData.descriptif || ""
                                            return d.length > 40 ? d.substring(0, 40) + "…" : d
                                        }
                                        font.pixelSize: 10; color: Style.textTertiary
                                        elide: Text.ElideRight; width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // Salle
                                RowLayout {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignVCenter
                                    spacing: 4
                                    Item { Layout.fillWidth: true }
                                    IconLabel {
                                        iconName: "location"; iconSize: 11; iconColor: Style.textSecondary
                                        visible: modelData.room && modelData.room !== "—"
                                    }
                                    Text {
                                        text: (modelData.room && modelData.room !== "—") ? modelData.room : "—"
                                        font.pixelSize: 11; font.bold: true
                                        color: (modelData.room && modelData.room !== "—") ? Style.textSecondary : Style.textTertiary
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                // Action
                                Item {
                                    Layout.fillWidth: true; Layout.preferredWidth: 0.4
                                    IconButton { anchors.centerIn: parent; iconName: "edit"; iconSize: 14; hoverColor: Style.warningColor; onClicked: root.openDetail(modelData) }
                                }
                            }
                        }

                        Separator { width: parent.width }
                    }
                }
            }
        }
    }

    // Sidebar
    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        spacing: 20

        AppCard {
            Layout.fillWidth: true
            title: qsTr("Guide d'Organisation")

            Column {
                width: parent.width
                spacing: 20

                Repeater {
                    model: [
                        { num: "1", title: qsTr("CHOISIR LA MATIÈRE"), desc: "Définissez le contenu pédagogique de la session." },
                        { num: "2", title: qsTr("ASSIGNER LE PROFESSEUR"), desc: "Sélectionnez l'expert qualifié pour cette matière." },
                        { num: "3", title: qsTr("CIBLER LA CLASSE"), desc: "Identifiez le groupe d'élèves bénéficiaire." }
                    ]

                    delegate: RowLayout {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: Style.primary

                            Text {
                                anchors.centerIn: parent
                                text: modelData.num
                                font.pixelSize: 11
                                font.weight: Font.Black
                                color: Style.background
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: modelData.title
                                font.pixelSize: 11
                                font.weight: Font.Black
                                color: Style.textPrimary
                                font.letterSpacing: 0.5
                            }

                            Text {
                                text: modelData.desc
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: Style.textSecondary
                                wrapMode: Text.WordWrap
                                width: parent.width
                                lineHeight: 1.4
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: alertCol.implicitHeight + 40
            radius: 24
            color: Style.warningBg
            border.color: Style.warningBorder

            Column {
                id: alertCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    width: parent.width
                    spacing: 10

                    IconLabel {
                        iconName: "alert"
                        iconSize: 18
                        iconColor: Style.warningColor
                    }

                    Text {
                        text: qsTr("RAPPEL DE CONFLIT")
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.warningColor
                        font.letterSpacing: 1
                    }
                }

                Text {
                    width: parent.width
                    text: qsTr("Le système vérifie automatiquement la disponibilité du professeur et de la salle lors de l'assignation.")
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Style.warningColor
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }
            }
        }
    }
}
