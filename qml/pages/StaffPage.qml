import QtQuick 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: staffPage
    implicitHeight: mainLayout.implicitHeight

    property bool showModal: false
    property bool isEditing: false
    property string selectedStatus: "active"

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
                title: "Gestion du Personnel"
                subtitle: "Administration des enseignants et calcul des honoraires."
            }

            PrimaryButton {
                text: "Ajouter un Enseignant"
                iconName: "plus"
                onClicked: {
                    isEditing = false
                    selectedStatus = "active"
                    showModal = true
                }
            }
        }

        // ─── Search & Filter Bar ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            SearchField {
                Layout.fillWidth: true
                placeholder: "Rechercher un professeur..."
            }

            Rectangle {
                implicitWidth: monthRow.implicitWidth + 24
                height: 42
                radius: 16
                color: Style.bgWhite
                border.color: Style.borderLight

                RowLayout {
                    id: monthRow
                    anchors.centerIn: parent
                    spacing: 8

                    IconLabel {
                        iconName: "calendar"
                        iconSize: 16
                        iconColor: Style.primary
                    }

                    Text {
                        text: "FÉVRIER 2026"
                        font.pixelSize: 10
                        font.weight: Font.Black
                        color: Style.textPrimary
                        font.letterSpacing: 1
                    }

                    Text {
                        text: "▾"
                        font.pixelSize: 10
                        color: Style.textTertiary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // ─── Professor Cards Grid ───
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 20
            rowSpacing: 20

            Repeater {
                model: ListModel {
                    ListElement {
                        name: "Sheikh Omar Al-Faruq"
                        specialty: "Langue Arabe & Fiqh"
                        phone: "22 445 667"
                        hours: 42
                        rate: 35
                        status: "active"
                    }
                    ListElement {
                        name: "Mme. Fatma Zahra"
                        specialty: "Tajwid & Mémorisation"
                        phone: "55 123 456"
                        hours: 38
                        rate: 30
                        status: "active"
                    }
                    ListElement {
                        name: "Sheikh Ahmed Ben Youssef"
                        specialty: "Histoire de l'Islam"
                        phone: "98 765 432"
                        hours: 25
                        rate: 40
                        status: "active"
                    }
                    ListElement {
                        name: "M. Youssef Mansouri"
                        specialty: "Mathématiques & Sciences"
                        phone: "44 332 211"
                        hours: 30
                        rate: 25
                        status: "on_leave"
                    }
                }

                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: profCardCol.implicitHeight + 48
                    radius: 24
                    color: Style.bgWhite
                    border.color: profCardMa.containsMouse ? Qt.rgba(0.24, 0.35, 0.27, 0.2) : Style.borderLight

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }

                    Column {
                        id: profCardCol
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 18

                        // Header: Avatar + Name + Status
                        RowLayout {
                            width: parent.width
                            spacing: 14

                            Avatar {
                                initials: model.name.charAt(0)
                                size: 56
                                bgColor: Style.bgSecondary
                                textColor: Style.primary
                                textSize: 20
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: model.name
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Style.textPrimary
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Badge {
                                    text: model.status === "active" ? "Actif" : "En congé"
                                    variant: model.status === "active" ? "success" : "warning"
                                }
                            }

                            Column {
                                spacing: 4

                                IconButton {
                                    iconName: "edit"
                                    iconSize: 14
                                    onClicked: {
                                        isEditing = true
                                        selectedStatus = model.status
                                        showModal = true
                                    }
                                }

                                IconButton {
                                    iconName: "delete"
                                    iconSize: 14
                                    hoverColor: Style.errorColor
                                }
                            }
                        }

                        // Info rows
                        Column {
                            width: parent.width
                            spacing: 8

                            RowLayout {
                                width: parent.width
                                spacing: 8

                                IconLabel {
                                    iconName: "briefcase"
                                    iconSize: 14
                                    iconColor: Style.successColor
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: model.specialty
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Style.textSecondary
                                    elide: Text.ElideRight
                                }
                            }

                            RowLayout {
                                width: parent.width
                                spacing: 8

                                IconLabel {
                                    iconName: "phone"
                                    iconSize: 14
                                    iconColor: Style.textTertiary
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: model.phone
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Style.textTertiary
                                }
                            }
                        }

                        // Hours & Rate card
                        Rectangle {
                            width: parent.width
                            height: 70
                            radius: 16
                            color: Style.bgPage
                            border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    SectionLabel {
                                        text: "HEURES/FÉVRIER"
                                    }

                                    Text {
                                        text: model.hours + "h"
                                        font.pixelSize: 18
                                        font.weight: Font.Black
                                        color: Style.textPrimary
                                    }
                                }

                                Rectangle {
                                    width: 1
                                    height: 32
                                    color: Style.borderLight
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    SectionLabel {
                                        text: "TAUX HORAIRE"
                                        anchors.right: parent.right
                                    }

                                    Text {
                                        text: model.rate + " DT"
                                        font.pixelSize: 18
                                        font.weight: Font.Black
                                        color: Style.primary
                                        anchors.right: parent.right
                                    }
                                }
                            }
                        }

                        // Total & Pay button
                        Separator { width: parent.width }

                        RowLayout {
                            width: parent.width

                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                SectionLabel {
                                    text: "TOTAL À RÉGLER"
                                }

                                Text {
                                    text: (model.hours * model.rate) + " DT"
                                    font.pixelSize: 20
                                    font.weight: Font.Black
                                    color: Style.textPrimary
                                }
                            }

                            Rectangle {
                                width: payBtnText.implicitWidth + 28
                                height: 36
                                radius: 12
                                color: payBtnMa.containsMouse ? Style.primaryDark : Style.primary

                                Text {
                                    id: payBtnText
                                    anchors.centerIn: parent
                                    text: "RÉGLER"
                                    font.pixelSize: 10
                                    font.weight: Font.Black
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    id: payBtnMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: profCardMa
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: 32
        }
    }

    // ─── Add/Edit Modal ───
    ModalOverlay {
        show: showModal
        modalWidth: 520
        onClose: showModal = false

        Column {
            width: parent.width
            spacing: 0
            padding: 32

            Text {
                text: isEditing ? "Modifier l'Enseignant" : "Nouvel Enseignant"
                font.pixelSize: 22
                font.weight: Font.Black
                color: Style.textPrimary
                bottomPadding: 28
            }

            GridLayout {
                width: parent.width - 64
                columns: 2
                columnSpacing: 16
                rowSpacing: 18

                FormField {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    label: "NOM COMPLET"
                    placeholder: "Nom et prénom..."
                }

                FormField {
                    Layout.fillWidth: true
                    label: "SPÉCIALITÉ"
                    placeholder: "ex: Arabe, Coran..."
                }

                FormField {
                    Layout.fillWidth: true
                    label: "TÉLÉPHONE"
                    placeholder: "XX XXX XXX"
                }

                FormField {
                    Layout.fillWidth: true
                    label: "HEURES TRAVAILLÉES"
                    placeholder: "0"
                }

                FormField {
                    Layout.fillWidth: true
                    label: "TAUX HORAIRE (DT/H)"
                    text: "25"
                }

                // Statut (full width)
                Column {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    spacing: 6

                    SectionLabel {
                        text: "STATUT DE L'ENSEIGNANT"
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: selectedStatus === "active" ? Style.primary : Style.bgPage
                            border.color: selectedStatus === "active" ? Style.primary : Style.borderLight

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "ACTIF"
                                font.pixelSize: 11
                                font.weight: Font.Black
                                color: selectedStatus === "active" ? "#FFFFFF" : Style.textTertiary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectedStatus = "active"
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: selectedStatus === "on_leave" ? Style.warningColor : Style.bgPage
                            border.color: selectedStatus === "on_leave" ? Style.warningColor : Style.borderLight

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "EN CONGÉ"
                                font.pixelSize: 11
                                font.weight: Font.Black
                                color: selectedStatus === "on_leave" ? "#FFFFFF" : Style.textTertiary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: selectedStatus = "on_leave"
                            }
                        }
                    }
                }
            }

            Item {
                width: 1
                height: 28
            }

            ModalButtons {
                width: parent.width - 64
                confirmText: "ENREGISTRER"
                onCancel: showModal = false
                onConfirm: showModal = false
            }
        }
    }
}
