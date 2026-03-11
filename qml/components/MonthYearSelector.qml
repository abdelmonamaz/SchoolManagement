import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

Item {
    id: root

    property int selectedMonth: new Date().getMonth() + 1  // 1-12
    property int selectedYear: new Date().getFullYear()
    property bool show: false

    signal monthYearChanged(int month, int year)

    width: 280
    height: show ? popupContent.implicitHeight + 48 : 0
    clip: false

    // Overlay - MouseArea pour fermer en cliquant ailleurs
    MouseArea {
        visible: root.show
        parent: root.parent
        anchors.fill: parent
        z: -1
        onClicked: root.show = false
    }

    // Ombre du popup
    Rectangle {
        visible: root.show
        width: parent.width
        height: parent.height
        radius: 20
        color: Qt.rgba(0, 0, 0, 0.08)
        x: 0
        y: 4
    }

    // Popup
    Rectangle {
        visible: root.show
        width: parent.width
        height: parent.height
        radius: 20
        color: Style.bgWhite
        border.color: Style.borderLight
        border.width: 1
        x: 0
        y: 0

        Column {
            id: popupContent
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Text {
                text: "Sélectionner la période"
                font.pixelSize: 14
                font.weight: Font.Black
                color: Style.textPrimary
            }

            // Sélecteur de mois
            Column {
                width: parent.width
                spacing: 6

                SectionLabel {
                    text: "MOIS"
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    ComboBox {
                        id: monthCombo
                        anchors.fill: parent
                        anchors.margins: 4
                        model: [
                            "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                            "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
                        ]
                        currentIndex: root.selectedMonth - 1

                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: monthCombo.displayText
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0) {
                                root.selectedMonth = currentIndex + 1
                            }
                        }
                    }
                }
            }

            // Sélecteur d'année
            Column {
                width: parent.width
                spacing: 6

                SectionLabel {
                    text: "ANNÉE"
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 12
                    color: Style.bgPage
                    border.color: Style.borderLight

                    ComboBox {
                        id: yearCombo
                        anchors.fill: parent
                        anchors.margins: 4
                        model: {
                            var years = []
                            var currentYear = new Date().getFullYear()
                            for (var i = currentYear - 5; i <= currentYear + 5; i++) {
                                years.push(i)
                            }
                            return years
                        }
                        currentIndex: {
                            var currentYear = new Date().getFullYear()
                            return root.selectedYear - currentYear + 5
                        }

                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: yearCombo.displayText
                            font.pixelSize: 13
                            font.bold: true
                            color: Style.textPrimary
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0) {
                                var currentYear = new Date().getFullYear()
                                root.selectedYear = currentYear - 5 + currentIndex
                            }
                        }
                    }
                }
            }

            // Bouton d'application
            PrimaryButton {
                width: parent.width
                text: "Appliquer"
                onClicked: {
                    root.monthYearChanged(root.selectedMonth, root.selectedYear)
                    root.show = false
                }
            }
        }
    }
}
