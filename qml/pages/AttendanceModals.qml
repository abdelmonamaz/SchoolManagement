import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import UI.Components

Item {
    id: root
    required property var page
    anchors.fill: parent

    function _confirmAppel() {
        var parts = attendanceController.participations
        var ep = {}
        for (var i = 0; i < parts.length; i++) ep[parts[i].eleveId] = parts[i]
        var students = page.classStudents
        for (var j = 0; j < students.length; j++) {
            var sid = students[j].id
            var s = page.stagedStatuts.hasOwnProperty(sid) ? page.stagedStatuts[sid] : "Présent"
            if (ep[sid] !== undefined)
                attendanceController.updateParticipation(ep[sid].id, { seanceId: page.selectedSeanceId, eleveId: sid, statut: s, note: ep[sid].note !== undefined ? ep[sid].note : -1, estInvite: false })
            else
                attendanceController.recordParticipation({ seanceId: page.selectedSeanceId, eleveId: sid, statut: s, note: -1, estInvite: false })
        }
        var v = Object.assign({}, page.validatedSeances)
        v[page.selectedSeanceId] = true; page.validatedSeances = v
        attendanceController.setPresenceValide(page.selectedSeanceId, true)
        page.showCallModal = false
    }

    // ─── Call Modal ───
    ModalOverlay {
        id: callModalOverlay
        show: page.showCallModal
        modalWidth: Math.min(parent.width - 64, 900)
        modalColor: "#FAFBFC"
        onClose: page.showCallModal = false

        Column {
            width: parent.width
            spacing: 0

            // Header
            Item {
                width: parent.width; height: 80
                Separator  { anchors.bottom: parent.bottom; width: parent.width }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 14

                    Column {
                        Layout.fillWidth: true; spacing: 4
                        RowLayout {
                            spacing: 10
                            Text {
                                text: page.selectedSessionSubject
                                font.pixelSize: 20; font.weight: Font.Black; color: Style.textPrimary
                            }
                            Badge { text: "Classe " + page.selectedSessionClass; variant: "info" }
                        }
                        Text {
                            text: page.selectedSessionProf + " - " + page.selectedSessionTime
                            font.pixelSize: 10; font.weight: Font.Bold
                            color: Style.textTertiary; font.letterSpacing: 1
                        }
                    }

                    OutlineButton { text: "Ajouter Invité"; iconName: "plus"; onClicked: page.showGuestModal = true }
                    IconButton    { iconName: "close"; iconSize: 18; onClicked: page.showCallModal = false }
                }
            }

            // Students grid (all students in the class)
            Flickable {
                id: gridFlick
                width: parent.width
                height: Math.min(contentHeight, 480)
                contentWidth: parent.width
                contentHeight: studentGridRect.implicitHeight
                clip: true
                flickableDirection: Flickable.VerticalFlick
                ScrollBar.vertical: ScrollBar {
                    policy: gridFlick.contentHeight > gridFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }

                Rectangle {
                    id: studentGridRect
                    width: parent.width
                    implicitHeight: studentGrid.implicitHeight + 48
                    color: Style.bgWhite

                    Text {
                        visible: attendanceController.loading
                        anchors.centerIn: parent
                        text: "Chargement..."
                        font.pixelSize: 13; font.bold: true; color: Style.textTertiary
                    }

                    GridLayout {
                        id: studentGrid
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top; anchors.margins: 24
                        columns: 4; columnSpacing: 16; rowSpacing: 16

                        Repeater {
                            model: page.callModalStudents

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: cardCol.implicitHeight + 32
                                radius: 24
                                color: Style.bgWhite
                                border.color: isGuest ? "#BAE6FD" : Style.borderLight

                                // Staged statut: updated locally; defaults to "Présent" until explicitly changed
                                property string statut: {
                                    var sid = modelData.id
                                    return page.stagedStatuts.hasOwnProperty(sid)
                                           ? page.stagedStatuts[sid] : "Présent"
                                }

                                // Guest detection: reactive to participations changes
                                property bool isGuest: {
                                    var parts = attendanceController.participations
                                    for (var i = 0; i < parts.length; i++)
                                        if (parts[i].eleveId === modelData.id && parts[i].estInvite) return true
                                    return false
                                }
                                property int guestParticipationId: {
                                    var parts = attendanceController.participations
                                    for (var i = 0; i < parts.length; i++)
                                        if (parts[i].eleveId === modelData.id && parts[i].estInvite) return parts[i].id
                                    return -1
                                }

                                // Remove button — top-right corner, guests only
                                Rectangle {
                                    visible: isGuest
                                    anchors.top: parent.top; anchors.right: parent.right
                                    anchors.topMargin: 8; anchors.rightMargin: 8
                                    width: 24; height: 24; radius: 8
                                    color: removeMa.containsMouse ? Style.errorColor : "#FEE2E2"
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 10; font.bold: true
                                        color: removeMa.containsMouse ? "#FFFFFF" : Style.errorColor
                                    }
                                    MouseArea {
                                        id: removeMa; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (guestParticipationId !== -1) {
                                                attendanceController.deleteParticipation(guestParticipationId)
                                                attendanceController.loadParticipations(page.selectedSeanceId)
                                            }
                                        }
                                    }
                                }

                                Column {
                                    id: cardCol
                                    anchors.fill: parent; anchors.margins: 16; spacing: 12

                                    Rectangle {
                                        width: 56; height: 56; radius: 20
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: isGuest ? "#E0F2FE" : Style.bgSecondary
                                        border.color: "#FFFFFF"; border.width: 2
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.prenom.charAt(0)
                                            font.pixelSize: 18; font.bold: true
                                            color: isGuest ? "#0284C7" : Style.primary
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.prenom + " " + modelData.nom
                                        font.pixelSize: 11; font.bold: true; color: Style.textPrimary
                                        elide: Text.ElideRight; width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // "INVITÉ" badge — only for guests
                                    Rectangle {
                                        visible: isGuest
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        implicitWidth: guestLbl.implicitWidth + 12
                                        height: 18; radius: 6
                                        color: "#E0F2FE"
                                        Text {
                                            id: guestLbl
                                            anchors.centerIn: parent
                                            text: "INVITÉ"
                                            font.pixelSize: 8; font.weight: Font.Black
                                            color: "#0284C7"; font.letterSpacing: 0.5
                                        }
                                    }

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 8

                                        Rectangle {
                                            width: 40; height: 32; radius: 10
                                            color: statut === "Présent" ? Style.successColor : Style.bgPage
                                            border.color: statut === "Présent" ? Style.successColor : Style.borderLight
                                            Text { anchors.centerIn: parent; text: "P"; font.pixelSize: 12; font.bold: true; color: statut === "Présent" ? "#FFFFFF" : Style.textTertiary }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.setStagedStatut(modelData.id, "Présent") }
                                        }

                                        Rectangle {
                                            width: 40; height: 32; radius: 10
                                            color: statut === "Absent" ? Style.errorColor : Style.bgPage
                                            border.color: statut === "Absent" ? Style.errorColor : Style.borderLight
                                            Text { anchors.centerIn: parent; text: "A"; font.pixelSize: 12; font.bold: true; color: statut === "Absent" ? "#FFFFFF" : Style.textTertiary }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.setStagedStatut(modelData.id, "Absent") }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            Item {
                width: parent.width; height: 100
                Separator { anchors.top: parent.top; width: parent.width }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 20; anchors.bottomMargin: 32; spacing: 16

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        height: 48; radius: 16; color: Style.bgWhite; border.color: Style.borderLight
                        Text { anchors.centerIn: parent; text: "FERMER"; font.pixelSize: 11; font.weight: Font.Black; color: Style.textTertiary }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.showCallModal = false }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        height: 48; radius: 16; color: Style.primary
                        Text { anchors.centerIn: parent; text: "CONFIRMER L'APPEL"; font.pixelSize: 11; font.weight: Font.Black; color: "#FFFFFF"; font.letterSpacing: 1 }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var sessionDate = new Date(page.selectedSessionDate)
                                var now = new Date()
                                if (sessionDate > now) {
                                    page.showCallModal = false
                                    page.showFutureConfirmModal = true
                                } else {
                                    root._confirmAppel()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Guest Modal ───
    ModalOverlay {
        id: guestModalOverlay
        show: page.showGuestModal
        modalWidth: 440
        modalColor: "#FAFBFC"
        onClose: { page.showGuestModal = false; guestSearch.text = "" }

        Column {
            width: parent.width
            spacing: 0

            // Header
            Item {
                width: parent.width; height: 72
                Separator  { anchors.bottom: parent.bottom; width: parent.width }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 12

                    Column {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "Ajouter un Invité"; font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                        Text { text: "Même niveau · autre classe"; font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
                    }

                    IconButton { iconName: "close"; onClicked: { page.showGuestModal = false; guestSearch.text = "" } }
                }
            }

            // Body: search + list
            Item {
                width: parent.width
                implicitHeight: guestBodyCol.implicitHeight + 40

                Column {
                    id: guestBodyCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                    spacing: 12

                    // Search field
                    Rectangle {
                        width: parent.width; height: 44; radius: 12
                        color: Style.bgPage
                        border.color: guestSearch.activeFocus ? Style.primary : Style.borderLight

                        HoverHandler { cursorShape: Qt.IBeamCursor }

                        TextInput {
                            id: guestSearch
                            anchors.fill: parent; anchors.margins: 12
                            font.pixelSize: 13; color: Style.textPrimary
                            selectByMouse: true

                            Text {
                                visible: !parent.text
                                text: "Rechercher par nom..."
                                font: parent.font; color: Style.textTertiary
                            }
                        }
                    }

                    // Student list
                    ListView {
                        id: guestList
                        width: parent.width
                        height: 280
                        clip: true
                        spacing: 4
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        model: {
                            var candidates = page.guestCandidates
                            var q = guestSearch.text.toLowerCase().trim()
                            if (!q) return candidates
                            var r = []
                            for (var i = 0; i < candidates.length; i++) {
                                var n = (candidates[i].prenom + " " + candidates[i].nom).toLowerCase()
                                if (n.indexOf(q) !== -1) r.push(candidates[i])
                            }
                            return r
                        }

                        delegate: Rectangle {
                            width: guestList.width; height: 56; radius: 12
                            color: guestItemMa.containsMouse ? Style.bgSecondary : Style.bgPage
                            border.color: Style.borderLight

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12

                                Rectangle {
                                    width: 36; height: 36; radius: 12; color: Style.primaryBg
                                    Text { anchors.centerIn: parent; text: modelData.prenom.charAt(0); font.pixelSize: 14; font.bold: true; color: Style.primary }
                                }

                                Column {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.prenom + " " + modelData.nom; font.pixelSize: 13; font.bold: true; color: Style.textPrimary }
                                    Text { text: page.findClassName(modelData.classeId); font.pixelSize: 10; color: Style.textTertiary; font.weight: Font.Medium }
                                }

                                Rectangle {
                                    width: 60; height: 30; radius: 8; color: Style.primary
                                    Text { anchors.centerIn: parent; text: "INVITER"; font.pixelSize: 9; font.weight: Font.Black; color: "#FFFFFF" }
                                }
                            }

                            MouseArea {
                                id: guestItemMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    attendanceController.recordParticipation({
                                        seanceId: page.selectedSeanceId,
                                        eleveId: modelData.id, statut: "Présent", note: -1, estInvite: true
                                    })
                                    attendanceController.loadParticipations(page.selectedSeanceId)
                                    page.showGuestModal = false
                                    guestSearch.text = ""
                                }
                            }
                        }

                        // Empty state
                        Text {
                            anchors.centerIn: parent
                            visible: guestList.count === 0
                            text: guestSearch.text ? "Aucun résultat pour \"" + guestSearch.text + "\"" : "Aucun élève disponible dans le même niveau"
                            font.pixelSize: 12; font.italic: true; color: Style.textTertiary
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width - 40
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    // ─── Future Date Confirm Modal ───
    ModalOverlay {
        show: page.showFutureConfirmModal
        modalWidth: 460
        modalRadius: 28
        onClose: page.showFutureConfirmModal = false

        Column {
            width: parent.width; spacing: 20; padding: 36; bottomPadding: 28

            RowLayout {
                width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter; spacing: 14
                Rectangle { width: 48; height: 48; radius: 20; color: "#FEF3C7"
                    IconLabel { anchors.centerIn: parent; iconName: "alert"; iconSize: 24; iconColor: "#D97706" } }
                Column { Layout.fillWidth: true; spacing: 2
                    Text { text: "Séance dans le futur"; font.pixelSize: 16; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: "Date : " + Qt.formatDateTime(new Date(page.selectedSessionDate), "dd/MM/yyyy HH:mm"); font.pixelSize: 11; color: Style.textTertiary; font.weight: Font.Medium }
                }
                IconButton { iconName: "close"; iconSize: 18; onClicked: page.showFutureConfirmModal = false }
            }

            Rectangle { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: futText.implicitHeight + 28; radius: 14; color: "#FEF3C7"; border.color: "#F59E0B"
                Text { id: futText; anchors.fill: parent; anchors.margins: 14
                    text: "Vous êtes sur le point de valider l'appel pour une séance qui n'a pas encore eu lieu. Êtes-vous sûr de vouloir continuer ?"
                    font.pixelSize: 13; font.weight: Font.Medium; color: "#92400E"
                    wrapMode: Text.WordWrap; textFormat: Text.RichText; lineHeight: 1.5 }
            }

            ModalButtons { width: parent.width - 72; anchors.horizontalCenter: parent.horizontalCenter
                cancelText: "Annuler"; confirmText: "CONFIRMER L'APPEL"; confirmColor: Style.primary
                onCancel: {
                    page.showFutureConfirmModal = false
                    page.showCallModal = true
                }
                onConfirm: {
                    root._confirmAppel()
                    page.showFutureConfirmModal = false
                }
            }
        }
    }
}