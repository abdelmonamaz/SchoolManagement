import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1
import UI.Components

// Popup d'aperçu et d'export du bulletin scolaire
ModalOverlay {
    id: root

    property var    bulletinData:      ({})
    property string studentName:       ""
    property string studentMatricule:  ""
    property string niveauNom:         ""
    property string classeNom:         ""
    property string anneeScolaire:     ""
    property int    eleveId:           -1
    property string exportedFilePath:  ""
    property bool   exporting:         false

    modalWidth: 820

    // ── Helpers ──────────────────────────────────────────────────────────────
    function matiereName(matiereId) {
        var list = schoolingController.allMatieres
        for (var i = 0; i < list.length; i++)
            if (list[i].id === matiereId) return list[i].nom
        list = schoolingController.matieres
        for (var j = 0; j < list.length; j++)
            if (list[j].id === matiereId) return list[j].nom
        return "Matière #" + matiereId
    }

    function appreciation(note) {
        if (note >= 18) return "Excellent"
        if (note >= 15) return "Très Bien"
        if (note >= 12) return "Bien"
        if (note >= 10) return "Assez Bien"
        if (note >= 7)  return "Passable"
        return "Insuffisant"
    }

    function apprBg(note) {
        if (note >= 15) return "#d4edda"
        if (note >= 10) return "#fff3cd"
        return "#f8d7da"
    }

    function apprFg(note) {
        if (note >= 15) return "#155724"
        if (note >= 10) return "#856404"
        return "#721c24"
    }

    // Tous les titres d'épreuves uniques (ordre d'apparition)
    readonly property var allTitres: {
        var mats = bulletinData.matieres || []
        var t = []
        for (var i = 0; i < mats.length; i++) {
            var eps = mats[i].epreuves || []
            for (var j = 0; j < eps.length; j++) {
                var ti = eps[j].titre || ""
                if (ti && t.indexOf(ti) < 0) t.push(ti)
            }
        }
        return t
    }

    readonly property double moyenneGenerale: {
        var v = bulletinData.moyenneGenerale
        return (v !== null && v !== undefined) ? v : -1
    }

    // ── Largeurs de colonnes (fixes pour aligner header ↔ données) ──────────
    readonly property int cMat: 170   // Matière
    readonly property int cMoy: 80    // Moyenne
    readonly property int cApp: 96    // Appréciation
    readonly property int cPre: 72    // Présence
    readonly property int tableWidth: billContent.width > 0 ? billContent.width - 32 : 660
    readonly property int cEp: allTitres.length > 0
        ? Math.max(50, Math.floor((tableWidth - cMat - cMoy - cApp - cPre) / allTitres.length))
        : 60

    // ── Données présence (niveau classe) ─────────────────────────────────────
    readonly property int presenceTotale:  (bulletinData.presenceTotale  !== undefined) ? bulletinData.presenceTotale  : 0
    readonly property int seancesTotales:  (bulletinData.seancesTotales  !== undefined) ? bulletinData.seancesTotales  : 0

    onOpened: { exportedFilePath = ""; exporting = false }

    // ── Contenu ──────────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 16
        padding: 24
        bottomPadding: 24

        // ── Header ──────────────────────────────────────────────────────────
        RowLayout {
            width: parent.width - 48
            anchors.horizontalCenter: parent.horizontalCenter

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    width: 44; height: 44; radius: 14
                    color: Style.primaryBg
                    Text { anchors.centerIn: parent; text: "📄"; font.pixelSize: 20 }
                }

                Column {
                    spacing: 2
                    Text { text: "Aperçu du Bulletin"; font.pixelSize: 17; font.weight: Font.Black; color: Style.textPrimary }
                    Text { text: root.studentName || "Élève"; font.pixelSize: 11; color: Style.textTertiary }
                }
            }

            // ✕ — utilise root.visible = false car root.close() émet le signal
            // sans appeler la méthode Popup.close() (shadowed)
            IconButton { iconName: "close"; iconSize: 18; onClicked: root.visible = false }
        }

        Separator { width: parent.width - 48; anchors.horizontalCenter: parent.horizontalCenter }

        // ── Zone bulletin (scrollable) ───────────────────────────────────────
        Rectangle {
            id: bodyRect
            width: parent.width - 48
            anchors.horizontalCenter: parent.horizontalCenter
            height: Math.min(billScroll.contentHeight + 2, 560)
            radius: 12; color: "#FFFFFF"
            border.color: Style.borderLight
            clip: true

            ScrollView {
                id: billScroll
                anchors.fill: parent; anchors.margins: 1
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    id: billContent
                    width: billScroll.availableWidth
                    spacing: 0
                    topPadding: 16; bottomPadding: 16
                    leftPadding: 16; rightPadding: 16

                    // ── En-tête école ────────────────────────────────────────
                    Row {
                        width: parent.width - 32
                        x: 16

                        Column {
                            width: parent.width - 112
                            spacing: 2
                            Text { text: setupController.associationData.nomAssociation || "Ez-Zaytouna"; font.pixelSize: 20; font.weight: Font.Black; color: "#2E7D52" }
                            Text { text: "INSTITUT D'ENSEIGNEMENT ISLAMIQUE"; font.pixelSize: 8; font.weight: Font.Bold; color: "#888" }
                            Text { text: setupController.associationData.adresse || ""; font.pixelSize: 9; color: "#AAA"; visible: text.length > 0 }
                        }

                        Item { width: 4; height: 1 }

                        // Badge année
                        Rectangle {
                            width: 108; height: 52; radius: 4
                            color: "transparent"; border.color: "#F59E0B"; border.width: 2
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "ANNÉE SCOLAIRE"; font.pixelSize: 7; font.weight: Font.Black; color: "#F59E0B" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.anneeScolaire || "—"; font.pixelSize: 13; font.weight: Font.Black; color: "#F59E0B" }
                            }
                        }
                    }

                    Item { width: 1; height: 8 }
                    Rectangle { x: 16; width: parent.width - 32; height: 2; color: "#2E7D52" }
                    Item { width: 1; height: 10 }

                    // ── Titre ────────────────────────────────────────────────
                    Rectangle {
                        x: 16; width: parent.width - 32; height: 34
                        color: "#2E7D52"
                        Text { anchors.centerIn: parent; text: "BULLETIN SCOLAIRE"; font.pixelSize: 14; font.weight: Font.Black; color: "white" }
                    }

                    Item { width: 1; height: 12 }

                    // ── Info élève ───────────────────────────────────────────
                    Rectangle {
                        x: 16; width: parent.width - 32
                        height: infoGrid.implicitHeight + 20
                        radius: 6; color: "#F8F9FA"; border.color: "#E0E0E0"

                        GridLayout {
                            id: infoGrid
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            columns: 2; rowSpacing: 8; columnSpacing: 16

                            Column { spacing: 2
                                Text { text: "NOM DE L'ÉLÈVE"; font.pixelSize: 7; font.weight: Font.Bold; color: "#999" }
                                Text { text: root.studentName || "—"; font.pixelSize: 13; font.weight: Font.Black; color: "#1a1a2e" }
                            }
                            Column { spacing: 2
                                Text { text: "MATRICULE"; font.pixelSize: 7; font.weight: Font.Bold; color: "#999" }
                                Text { text: root.studentMatricule || "—"; font.pixelSize: 13; font.weight: Font.Black; color: "#1a1a2e" }
                            }
                            Column { spacing: 2
                                Text { text: "NIVEAU"; font.pixelSize: 7; font.weight: Font.Bold; color: "#999" }
                                Text { text: root.niveauNom || "—"; font.pixelSize: 13; font.weight: Font.Black; color: "#1a1a2e" }
                            }
                            Column { spacing: 2
                                Text { text: "CLASSE"; font.pixelSize: 7; font.weight: Font.Bold; color: "#999" }
                                Text { text: root.classeNom || "—"; font.pixelSize: 13; font.weight: Font.Black; color: "#1a1a2e" }
                            }
                        }
                    }

                    Item { width: 1; height: 14 }

                    // Label section
                    Row {
                        x: 16; width: parent.width - 32; spacing: 8
                        Rectangle { width: 3; height: 14; radius: 2; color: "#2E7D52"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "RÉSULTATS ACADÉMIQUES"; font.pixelSize: 10; font.weight: Font.Black; color: "#1a1a2e"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { width: 1; height: 8 }

                    // ── En-tête du tableau ───────────────────────────────────
                    Rectangle {
                        x: 16; width: parent.width - 32; height: 32
                        color: "#2E7D52"; radius: 2

                        Row {
                            width: parent.width; height: parent.height

                            Item {
                                width: root.cMat; height: parent.height
                                Text { anchors.fill: parent; leftPadding: 8; text: "MATIÈRE"; font.pixelSize: 8; font.weight: Font.Black; color: "white"; verticalAlignment: Text.AlignVCenter }
                            }
                            Repeater {
                                model: root.allTitres
                                delegate: Item {
                                    width: root.cEp; height: parent.height
                                    Text { anchors.fill: parent; text: (modelData || "").toUpperCase(); font.pixelSize: 8; font.weight: Font.Black; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap }
                                }
                            }
                            Item {
                                width: root.cMoy; height: parent.height
                                Text { anchors.fill: parent; text: "MOY."; font.pixelSize: 8; font.weight: Font.Black; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                            Item {
                                width: root.cApp; height: parent.height
                                Text { anchors.fill: parent; text: "APPRÉCIATION"; font.pixelSize: 8; font.weight: Font.Black; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap; rightPadding: 4 }
                            }
                            Item {
                                width: root.cPre; height: parent.height
                                Text { anchors.fill: parent; text: "PRÉSENCE"; font.pixelSize: 8; font.weight: Font.Black; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap; rightPadding: 4 }
                            }
                        }
                    }

                    // ── Lignes des matières ──────────────────────────────────
                    Repeater {
                        model: bulletinData.matieres || []

                        delegate: Rectangle {
                            id: matRow
                            x: 16; width: parent.width - 32; height: 40
                            color: index % 2 === 0 ? "#FFFFFF" : "#F8FFFE"
                            border.color: "#F0F0F0"

                            // Capture outer modelData before nested Repeater
                            property var mat:  modelData
                            property var nMap: {
                                var m = {}
                                var eps = mat.epreuves || []
                                for (var k = 0; k < eps.length; k++)
                                    if (eps[k].hasNote) m[eps[k].titre] = eps[k].note
                                return m
                            }
                            property double moy: {
                                var v = mat.moyenne
                                return (v !== null && v !== undefined) ? v : -1
                            }
                            property int presPres: mat.presenceCount  !== undefined ? mat.presenceCount  : 0
                            property int presTotal: mat.totalSeances  !== undefined ? mat.totalSeances   : 0

                            Row {
                                width: parent.width; height: parent.height

                                // Nom matière
                                Item {
                                    width: root.cMat; height: parent.height
                                    Text { anchors.fill: parent; leftPadding: 8; text: root.matiereName(matRow.mat.matiereId); font.pixelSize: 10; font.weight: Font.Bold; color: "#1a1a2e"; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                                }

                                // Notes épreuves
                                Repeater {
                                    model: root.allTitres
                                    delegate: Item {
                                        width: root.cEp; height: parent.height
                                        property double nv: matRow.nMap[modelData] !== undefined ? matRow.nMap[modelData] : -1
                                        Text {
                                            anchors.centerIn: parent
                                            text: nv >= 0 ? nv.toFixed(1) + "/20" : "—"
                                            font.pixelSize: 10
                                            font.weight: nv >= 0 ? Font.Bold : Font.Normal
                                            color: nv >= 0 ? "#1a1a2e" : "#CCCCCC"
                                        }
                                    }
                                }

                                // Moyenne
                                Item {
                                    width: root.cMoy; height: parent.height
                                    Text {
                                        anchors.centerIn: parent
                                        text: matRow.moy >= 0 ? matRow.moy.toFixed(2) + "/20" : "—"
                                        font.pixelSize: 11; font.weight: Font.Black
                                        color: matRow.moy >= 0 ? "#2E7D52" : "#CCCCCC"
                                    }
                                }

                                // Appréciation
                                Item {
                                    width: root.cApp; height: parent.height
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: root.cApp - 8; height: 22; radius: 6
                                        visible: matRow.moy >= 0
                                        color: root.apprBg(matRow.moy)
                                        Text { anchors.centerIn: parent; text: root.appreciation(matRow.moy); font.pixelSize: 8; font.weight: Font.Bold; color: root.apprFg(matRow.moy) }
                                    }
                                    Text { anchors.centerIn: parent; visible: matRow.moy < 0; text: "—"; font.pixelSize: 10; color: "#CCCCCC" }
                                }

                                // Présence
                                Item {
                                    width: root.cPre; height: parent.height
                                    Text {
                                        anchors.centerIn: parent
                                        text: matRow.presPres + "/" + matRow.presTotal
                                        font.pixelSize: 10; font.weight: Font.Bold
                                        color: matRow.presTotal > 0 && matRow.presPres === matRow.presTotal
                                               ? "#2E7D52"
                                               : matRow.presPres < matRow.presTotal ? "#856404" : "#1a1a2e"
                                    }
                                }
                            }
                        }
                    }

                    // ── Moyenne générale ─────────────────────────────────────
                    Rectangle {
                        x: 16; width: parent.width - 32; height: 44
                        color: "#F0FFF4"; border.color: "#2E7D52"; border.width: 1; radius: 2

                        Row {
                            width: parent.width; height: parent.height

                            Item {
                                width: root.cMat + root.allTitres.length * root.cEp
                                height: parent.height
                                Text { anchors.fill: parent; leftPadding: 8; text: "MOYENNE GÉNÉRALE"; font.pixelSize: 10; font.weight: Font.Black; color: "#2E7D52"; verticalAlignment: Text.AlignVCenter }
                            }
                            Item {
                                width: root.cMoy; height: parent.height
                                Text {
                                    anchors.centerIn: parent
                                    text: root.moyenneGenerale >= 0 ? root.moyenneGenerale.toFixed(2) + "/20" : "—"
                                    font.pixelSize: 14; font.weight: Font.Black; color: "#2E7D52"
                                }
                            }
                            Item { width: root.cApp; height: parent.height }
                            Item {
                                width: root.cPre; height: parent.height
                                Text {
                                    anchors.centerIn: parent
                                    text: root.presenceTotale + "/" + root.seancesTotales
                                    font.pixelSize: 11; font.weight: Font.Black; color: "#2E7D52"
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 28 }

                    // ── Signatures ───────────────────────────────────────────
                    Row {
                        x: 16; width: parent.width - 32

                        Column {
                            width: (parent.width - 80) / 2; spacing: 4
                            Rectangle { width: parent.width; height: 1; color: "#CCCCCC" }
                            Item { width: 1; height: 28 }
                            Text { text: "ENSEIGNANT"; font.pixelSize: 8; font.weight: Font.Black; color: "#999" }
                        }

                        Item { width: 80; height: 1 }

                        Column {
                            width: (parent.width - 80) / 2; spacing: 4
                            Rectangle { width: parent.width; height: 1; color: "#CCCCCC" }
                            Item { width: 1; height: 28 }
                            Text { text: "DIRECTEUR"; font.pixelSize: 8; font.weight: Font.Black; color: "#999" }
                        }
                    }

                    Item { width: 1; height: 12 }
                    Rectangle { x: 16; width: parent.width - 32; height: 1; color: "#EEEEEE" }
                    Item { width: 1; height: 6 }

                    Text {
                        x: 16; width: parent.width - 32
                        text: setupController.associationData.nomAssociation || "Ez-Zaytouna"
                        font.pixelSize: 8; color: "#AAAAAA"; horizontalAlignment: Text.AlignHCenter
                    }

                    Item { width: 1; height: 8 }
                }
            }
        }

        // ── Feedback export ──────────────────────────────────────────────────
        Rectangle {
            width: parent.width - 48
            anchors.horizontalCenter: parent.horizontalCenter
            height: 36; radius: 10
            color: "#F0FDF4"; border.color: "#BBF7D0"
            visible: root.exportedFilePath.length > 0

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 8
                Text { text: "✓"; font.pixelSize: 14; color: "#166534" }
                Text { Layout.fillWidth: true; text: "PDF : " + root.exportedFilePath; font.pixelSize: 9; color: "#166534"; elide: Text.ElideMiddle }
                Rectangle {
                    width: 60; height: 22; radius: 6; color: "#166534"
                    Text { anchors.centerIn: parent; text: "OUVRIR"; font.pixelSize: 8; font.weight: Font.Black; color: "white" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally("file:///" + root.exportedFilePath) }
                }
            }
        }

        // ── Boutons ──────────────────────────────────────────────────────────
        RowLayout {
            width: parent.width - 48
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            // FERMER
            Rectangle {
                Layout.fillWidth: true; height: 48; radius: 14
                color: fMa.containsMouse ? Style.bgSecondary : Style.bgPage
                border.color: Style.borderLight
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "FERMER"; font.pixelSize: 11; font.weight: Font.Black; color: Style.textTertiary }
                MouseArea {
                    id: fMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.visible = false   // close() est un signal ici, pas la méthode Popup
                }
            }

            // EXPORTER CSV
            Rectangle {
                Layout.fillWidth: true; height: 48; radius: 14
                color: csvMa.containsMouse ? "#166534" : "#22C55E"
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout { anchors.centerIn: parent; spacing: 8
                    IconLabel { iconName: "download"; iconSize: 14; iconColor: "white" }
                    Text { text: "CSV"; font.pixelSize: 11; font.weight: Font.Black; color: "white" }
                }

                MouseArea {
                    id: csvMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root._exportData = root.buildEnrichedData()
                        csvSaveDialog.open()
                    }
                }
            }

            // EXPORTER PDF
            Rectangle {
                Layout.fillWidth: true; height: 48; radius: 14
                color: root.exporting ? Style.bgTertiary : (pMa.containsMouse ? Style.primaryDark : Style.primary)
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout { anchors.centerIn: parent; spacing: 8
                    IconLabel { iconName: "printer"; iconSize: 14; iconColor: "white" }
                    Text { text: root.exporting ? "GÉNÉRATION..." : "EXPORTER PDF"; font.pixelSize: 11; font.weight: Font.Black; color: "white" }
                }

                MouseArea {
                    id: pMa; anchors.fill: parent
                    enabled: !root.exporting
                    hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        root.exporting = true
                        root._exportData = root.buildEnrichedData()
                        pdfSaveDialog.open()
                    }
                }
            }
        }
    }

    // ── Temp storage for async file dialogs ──────────────────────────────────
    property var _exportData: ({})

    function buildEnrichedData() {
        var data = JSON.parse(JSON.stringify(root.bulletinData))
        var mats = data.matieres || []
        for (var i = 0; i < mats.length; i++)
            if (!mats[i].nom) mats[i].nom = root.matiereName(mats[i].matiereId)
        data.matieres = mats
        // Inject association info from setupController
        var assoc = setupController.associationData
        data.associationNom      = assoc.nomAssociation || "Ez-Zaytouna"
        data.associationAdresse  = assoc.adresse || ""
        return data
    }

    function urlToPath(fileUrl) {
        var s = fileUrl.toString()
        if (s.startsWith("file:///")) return s.substring(8)
        if (s.startsWith("file://"))  return s.substring(7)
        return s
    }

    // ── File dialogs ─────────────────────────────────────────────────────────
    FileDialog {
        id: pdfSaveDialog
        fileMode: FileDialog.SaveFile
        title: "Enregistrer le bulletin PDF"
        nameFilters: ["Fichiers PDF (*.pdf)", "Tous les fichiers (*)"]
        defaultSuffix: "pdf"
        onAccepted: {
            var path = root.urlToPath(file)
            var result = gradesController.exportBulletinPdf(
                root._exportData,
                root.studentName,
                root.studentMatricule,
                root.niveauNom,
                root.classeNom,
                root.anneeScolaire,
                path
            )
            root.exporting = false
            if (result.length > 0) root.exportedFilePath = result
        }
        onRejected: { root.exporting = false }
    }

    FileDialog {
        id: csvSaveDialog
        fileMode: FileDialog.SaveFile
        title: "Enregistrer le bulletin CSV"
        nameFilters: ["Fichiers CSV (*.csv)", "Tous les fichiers (*)"]
        defaultSuffix: "csv"
        onAccepted: {
            var path = root.urlToPath(file)
            var result = gradesController.exportBulletinCsv(
                root._exportData,
                root.studentName,
                root.niveauNom,
                root.classeNom,
                root.anneeScolaire,
                path
            )
            if (result.length > 0) Qt.openUrlExternally("file:///" + result)
        }
    }

    Connections {
        target: gradesController
        function onOperationFailed(error) { root.exporting = false }
    }
}
