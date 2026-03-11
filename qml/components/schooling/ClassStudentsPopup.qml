import QtQuick
import QtQuick.Layouts
import UI.Components

Item {
    id: classStudentsOverlay
    anchors.fill: parent
    z: 10

    required property bool show
    required property int classeId
    required property string classeNom
    required property var students

    signal closeRequested()
    signal studentViewRequested(int studentId)
    signal studentRemoveRequested(int studentId)

    visible: show

    // Dimmer
    Rectangle {
        anchors.fill: parent
        color: "#0F172A99"
        MouseArea {
            anchors.fill: parent
            onClicked: classStudentsOverlay.closeRequested()
        }
    }

    // Fenêtre modale
    Rectangle {
        anchors.centerIn: parent
        width: 560
        height: csModalContent.implicitHeight
        radius: 20
        color: Style.bgWhite
        border.color: Style.borderLight
        clip: true

        // Absorbe les clics pour ne pas fermer le dimmer
        MouseArea { anchors.fill: parent }

        Column {
            id: csModalContent
            width: parent.width
            spacing: 0

            // ─── Header ───
            Item {
                width: parent.width
                height: 76

                RowLayout {
                    anchors { fill: parent; leftMargin: 24; rightMargin: 24; topMargin: 16; bottomMargin: 16 }
                    spacing: 12

                    Column {
                        spacing: 4
                        Text {
                            text: "Classe " + classStudentsOverlay.classeNom
                            font.pixelSize: 20
                            font.weight: Font.Black
                            color: Style.textPrimary
                        }
                        Text {
                            property int cnt: {
                                var c = 0
                                for (var i = 0; i < classStudentsOverlay.students.length; i++)
                                    if (classStudentsOverlay.students[i].classeId === classStudentsOverlay.classeId) c++
                                return c
                            }
                            text: cnt + " élève" + (cnt > 1 ? "s" : "") + " inscrits"
                            font.pixelSize: 13
                            color: Style.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    IconButton {
                        iconName: "close"
                        iconSize: 16
                        onClicked: classStudentsOverlay.closeRequested()
                    }
                }
            }

            Separator { width: parent.width }

            // ─── Liste des élèves ───
            Column {
                id: csStudentList
                width: parent.width - 56
                x: 28
                spacing: 0

                Repeater {
                    model: {
                        var result = []
                        for (var i = 0; i < classStudentsOverlay.students.length; i++) {
                            if (classStudentsOverlay.students[i].classeId === classStudentsOverlay.classeId)
                                result.push(classStudentsOverlay.students[i])
                        }
                        return result
                    }

                    Rectangle {
                        width: parent.width
                        height: 58
                        color: csRowHover.hovered ? Style.bgPage : "transparent"
                        radius: 10

                        HoverHandler { id: csRowHover }

                        Separator { anchors.bottom: parent.bottom; width: parent.width }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Avatar { initials: modelData.nom.charAt(0); size: 34 }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                Text { text: modelData.nom + " " + modelData.prenom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                Text { text: modelData.telephone; font.pixelSize: 11; color: Style.textTertiary }
                            }

                            Badge { text: modelData.categorie; variant: "info" }

                            Row {
                                spacing: 4
                                IconButton {
                                    iconName: "eye"; iconSize: 14
                                    onClicked: {
                                        classStudentsOverlay.studentViewRequested(modelData.id)
                                        classStudentsOverlay.closeRequested()
                                    }
                                }
                                IconButton {
                                    iconName: "close"; iconSize: 14
                                    hoverColor: Style.errorColor
                                    onClicked: {
                                        console.log("Retirer: studentId =", modelData.id, "classeId =", modelData.classeId)
                                        classStudentsOverlay.studentRemoveRequested(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }

                // État vide
                Item {
                    width: parent.width
                    height: 72
                    visible: {
                        var c = 0
                        for (var i = 0; i < classStudentsOverlay.students.length; i++)
                            if (classStudentsOverlay.students[i].classeId === classStudentsOverlay.classeId) c++
                        return c === 0
                    }
                    Text { anchors.centerIn: parent; text: "Aucun élève dans cette classe"; font.pixelSize: 13; color: Style.textTertiary }
                }
            }

            Item { width: 1; height: 16 }
        }
    }
}
