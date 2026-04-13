import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

ColumnLayout {
    id: root
    spacing: 28

    required property var students
    required property var niveaux
    required property var classes
    property string filterLevel: "all"

    signal studentSelected(int index)
    signal studentViewClicked(int index)
    signal studentEditClicked(int index)
    signal studentDeleteClicked(int studentId)
    signal enrollmentEditClicked(int studentIdx, int studentId)
    signal registrationRequested()
    signal searchRequested(string text)
    signal filterByClass(int classeId)
    signal loadAllRequested()
    signal niveauFilterChanged(int niveauId)

    // ─── Column widths (shared between header and rows) ───
    readonly property int colNom:      280
    readonly property int colId:       80
    readonly property int colSexe:     60
    readonly property int colCat:      90
    readonly property int colStatut:   100
    readonly property int colPaiement: 80
    readonly property int colNiveau:   120
    readonly property int colClasse:   100
    readonly property int colActions:  116

    // ─── Filter & Sort State ───
    property string sexeFilter:       "all"
    property string categorieFilter:  "all"
    property string statutFilter:     "all"   // "all" | "inscrit" | "non-inscrit"
    property string paiementFilter:   "all"   // "all" | "paye"   | "impaye"
    property string sortColumn:       ""
    property bool   sortAsc:          true
    property int    currentPage:      0
    readonly property int pageSize:   10

    // Niveau-class filter: 0 = aucun filtre, >0 = niveau actif + "Toutes classes"
    // Nom distinct de "niveauFilter" pour éviter le conflit avec le signal niveauFilterChanged
    property int    activeNiveauId:        0
    property int    classeSelectedFilter:  0   // >0 = classe spécifique sélectionnée

    // ─── Categories derived from data ───
    readonly property var uniqueCategories: {
        var seen = {}, cats = []
        for (var i = 0; i < students.length; i++) {
            var c = students[i].categorie
            if (c && !seen[c]) { seen[c] = true; cats.push(c) }
        }
        return cats
    }

    readonly property var processedStudents: {
        var result = []
        for (var i = 0; i < students.length; i++) {
            var s = students[i]
            // Filtre Hall Ezzaytouna (activeNiveauId === -1)
            if (activeNiveauId === -1) { if (!s.hallOnly) continue }
            // Filtre niveau normal (sauf si une classe spécifique est sélectionnée)
            else if (activeNiveauId !== 0 && classeSelectedFilter === 0 && s.niveauId !== activeNiveauId) continue
            if (sexeFilter      !== "all" && s.sexe      !== sexeFilter)      continue
            if (categorieFilter !== "all" && s.categorie !== categorieFilter)  continue
            if (statutFilter === "inscrit"     && !s.inscritAnneeActive)  continue
            if (statutFilter === "non-inscrit" &&  s.inscritAnneeActive)  continue
            if (paiementFilter === "paye"   && !s.fraisPayeAnneeActive)   continue
            if (paiementFilter === "impaye" &&  s.fraisPayeAnneeActive)   continue
            result.push({ s: s, idx: i })
        }
        if (sortColumn !== "") {
            var col = sortColumn, asc = sortAsc
            result.sort(function(a, b) {
                var va = a.s[col] !== undefined ? a.s[col] : ""
                var vb = b.s[col] !== undefined ? b.s[col] : ""
                if (typeof va === "boolean" || typeof vb === "boolean") {
                    var na = va ? 1 : 0, nb = vb ? 1 : 0
                    return asc ? na - nb : nb - na
                }
                if (typeof va === "number" && typeof vb === "number") {
                    // 0 = pas de valeur (niveau/classe non assigné) → toujours en dernier
                    if (va === 0 && vb !== 0) return 1
                    if (vb === 0 && va !== 0) return -1
                    return asc ? va - vb : vb - va
                }
                va = String(va).toLowerCase()
                vb = String(vb).toLowerCase()
                if (va < vb) return asc ? -1 : 1
                if (va > vb) return asc ? 1 : -1
                return 0
            })
        }
        return result
    }

    onProcessedStudentsChanged: currentPage = 0

    readonly property int totalPages:   Math.max(1, Math.ceil(processedStudents.length / pageSize))
    readonly property var pageStudents: processedStudents.slice(currentPage * pageSize, (currentPage + 1) * pageSize)
    readonly property var visiblePages: {
        var pages = [], start = Math.max(0, currentPage - 2), end = Math.min(totalPages - 1, currentPage + 2)
        for (var p = start; p <= end; p++) pages.push(p)
        return pages
    }

    // ─── Helper: lookup ───
    function niveauNomById(nId) {
        if (!nId) return "—"
        for (var i = 0; i < niveaux.length; i++)
            if (niveaux[i].id === nId) return niveaux[i].nom
        return "—"
    }
    function classeNomById(cId) {
        if (!cId) return "—"
        for (var i = 0; i < classes.length; i++)
            if (classes[i].id === cId) return classes[i].nom
        return "—"
    }
    // Pour les élèves hallOnly : niveauId=0/classeId=0, seul hallClasseId est renseigné.
    // On remonte le niveau depuis la classe du hall.
    function niveauNomForStudent(s) {
        if (s.niveauId) return niveauNomById(s.niveauId)
        if (s.hallClasseId) {
            for (var i = 0; i < classes.length; i++)
                if (classes[i].id === s.hallClasseId) return niveauNomById(classes[i].niveauId)
        }
        return "—"
    }
    function classeNomForStudent(s) {
        if (s.classeId)     return classeNomById(s.classeId)
        if (s.hallClasseId) return classeNomById(s.hallClasseId)
        return "—"
    }

    // ─── Helper: sort arrow ───
    function sortArrow(col) { return sortColumn === col ? (sortAsc ? " ▲" : " ▼") : "" }
    function sortColor(col) { return sortColumn === col ? Style.primary : Style.textTertiary }
    function onSortCol(col) {
        if (sortColumn === col) sortAsc = !sortAsc
        else { sortColumn = col; sortAsc = true }
    }

    // ─── Page Header ───
    RowLayout {
        Layout.fillWidth: true
        PageHeader {
            Layout.fillWidth: true
            title: qsTr("Annuaire des Étudiants")
            subtitle: qsTr("Gestion des dossiers individuels et du suivi.")
        }
        PrimaryButton {
            text: qsTr("Ajouter un Élève"); iconName: "plus"
            onClicked: root.registrationRequested()
        }
    }

    // ─── Table Card ───
    AppCard {
        Layout.fillWidth: true

        Column {
            width: parent.width
            spacing: 16

            // Filters
            StudentListFilters {
                id: filtersComp
                width: parent.width
                niveaux: root.niveaux; classes: root.classes; categories: root.uniqueCategories
                onSearchChanged: (t) => { root.classeSelectedFilter = 0; root.searchRequested(t) }
                onSearchCleared:        root.loadAllRequested()
                onNiveauFilterChanged: (nId) => {
                    root.activeNiveauId       = nId
                    root.classeSelectedFilter = 0
                    root.niveauFilterChanged(nId)
                    root.loadAllRequested()
                }
                onClassFilterChanged: (cId) => {
                    root.classeSelectedFilter = cId
                    if (cId === 0) root.loadAllRequested()
                    else           root.filterByClass(cId)
                }
                onSexeChanged:      (s) => root.sexeFilter      = s
                onCategorieChanged: (c) => root.categorieFilter = c
                onStatutChanged:    (s) => root.statutFilter    = s
                onPaiementChanged:  (p) => root.paiementFilter  = p
            }

            Separator { width: parent.width }

            // ─── Table Header (inline — same Column as rows) ───
            Row {
                width: parent.width
                height: 36

                // ÉLÈVE
                Item {
                    width: root.colNom; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("ÉLÈVE") + root.sortArrow("nom")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("nom")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("nom") }
                }
                // MATRICULE
                Item {
                    width: root.colId; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("MATRICULE") + root.sortArrow("id")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("id")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("id") }
                }
                // SEXE
                Item {
                    width: root.colSexe; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("SEXE") + root.sortArrow("sexe")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("sexe")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("sexe") }
                }
                // CATÉGORIE
                Item {
                    width: root.colCat; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("CATÉGORIE") + root.sortArrow("categorie")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("categorie")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("categorie") }
                }
                // STATUT
                Item {
                    width: root.colStatut; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("STATUT") + root.sortArrow("inscritAnneeActive")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("inscritAnneeActive")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("inscritAnneeActive") }
                }
                // PAIEMENT
                Item {
                    width: root.colPaiement; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("PAIEMENT") + root.sortArrow("fraisPayeAnneeActive")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("fraisPayeAnneeActive")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("fraisPayeAnneeActive") }
                }
                // NIVEAU
                Item {
                    width: root.colNiveau; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("NIVEAU") + root.sortArrow("niveauId")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("niveauId")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("niveauId") }
                }
                // CLASSE
                Item {
                    width: root.colClasse; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("CLASSE") + root.sortArrow("classeId")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("classeId")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("classeId") }
                }
                // CONTACT (fills remaining space)
                Item {
                    width: parent.width - root.colNom - root.colId - root.colSexe - root.colCat - root.colStatut - root.colPaiement - root.colNiveau - root.colClasse - root.colActions
                    height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("CONTACT") + root.sortArrow("telephone")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("telephone")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("telephone") }
                }
                // ACTIONS
                Item {
                    width: root.colActions; height: parent.height
                    Text {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("ACTIONS"); font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary
                    }
                }
            }

            // ─── Data Rows ───
            Column {
                width: parent.width
                spacing: 0

                Repeater {
                    model: root.pageStudents

                    delegate: Rectangle {
                        width: parent.width; height: 64
                        color: rowHover.hovered ? Style.background : "transparent"

                        HoverHandler { id: rowHover }
                        Separator { anchors.bottom: parent.bottom; width: parent.width }
                        MouseArea { anchors.fill: parent; z: -1; cursorShape: Qt.PointingHandCursor; onDoubleClicked: root.studentViewClicked(modelData.idx) }

                        Row {
                            anchors.fill: parent

                            // ÉLÈVE
                            Item {
                                width: root.colNom; height: parent.height
                                Row {
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10
                                    Avatar { initials: modelData.s.nom.charAt(0); size: 38 }
                                    Text {
                                        width: root.colNom - 38 - 10 - 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.s.nom + " " + modelData.s.prenom
                                        font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                                        elide: Text.ElideRight
                                        clip: true
                                    }
                                }
                            }
                            // MATRICULE
                            Item {
                                width: root.colId; height: parent.height
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.s.id.toString()
                                    font.pixelSize: 12; font.weight: Font.Medium; color: Style.textSecondary
                                }
                            }
                            // SEXE
                            Item {
                                width: root.colSexe; height: parent.height
                                Badge {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.s.sexe === "F" ? "F" : "M"
                                    customTextColor:   Style.background
                                    customBgColor:     modelData.s.sexe === "F" ? Style.errorColor  : Style.primary
                                    customBorderColor: modelData.s.sexe === "F" ? Style.errorColor  : Style.primaryDark
                                }
                            }
                            // CATÉGORIE
                            Item {
                                width: root.colCat; height: parent.height
                                Badge {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.s.categorie; variant: "info"
                                }
                            }
                            // STATUT
                            Item {
                                width: root.colStatut; height: parent.height
                                Badge {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.s.inscritAnneeActive ? "INSCRIT" : "NON INSCRIT"
                                    customTextColor: Style.background
                                    customBgColor: modelData.s.inscritAnneeActive ? Style.successColor : Style.textTertiary
                                    customBorderColor: modelData.s.inscritAnneeActive ? Style.successColor : Style.borderMedium
                                }
                            }
                            // PAIEMENT
                            Item {
                                width: root.colPaiement; height: parent.height
                                Badge {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: modelData.s.inscritAnneeActive
                                    text: modelData.s.fraisPayeAnneeActive ? "PAYÉ" : "IMPAYÉ"
                                    customTextColor: Style.background
                                    customBgColor: modelData.s.fraisPayeAnneeActive ? Style.successColor : Style.errorColor
                                    customBorderColor: modelData.s.fraisPayeAnneeActive ? Style.successColor : Style.errorColor
                                }
                            }
                            // NIVEAU
                            Item {
                                width: root.colNiveau; height: parent.height
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 4
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.niveauNomForStudent(modelData.s)
                                    font.pixelSize: 12; font.weight: Font.Medium; color: Style.textSecondary
                                    elide: Text.ElideRight
                                }
                            }
                            // CLASSE
                            Item {
                                width: root.colClasse; height: parent.height
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 4
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.classeNomForStudent(modelData.s)
                                    font.pixelSize: 12; font.weight: Font.Medium; color: Style.textSecondary
                                    elide: Text.ElideRight
                                }
                            }
                            // CONTACT
                            Item {
                                width: parent.width - root.colNom - root.colId - root.colSexe - root.colCat - root.colStatut - root.colPaiement - root.colNiveau - root.colClasse - root.colActions
                                height: parent.height
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text { text: modelData.s.telephone; font.pixelSize: 12; font.weight: Font.Medium; color: Style.textPrimary }
                                    Text { text: modelData.s.adresse;   font.pixelSize: 9;  font.weight: Font.Bold;   color: Style.textTertiary }
                                }
                            }
                            // ACTIONS
                            Item {
                                width: root.colActions; height: parent.height
                                Row {
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    IconButton { iconName: "eye";    iconSize: 16; onClicked: root.studentViewClicked(modelData.idx) }
                                    IconButton { iconName: "edit";   iconSize: 16; hoverColor: Style.warningColor || Style.warningColor; onClicked: root.enrollmentEditClicked(modelData.idx, modelData.s.id) }
                                    IconButton { iconName: "delete"; iconSize: 16; hoverColor: Style.errorColor; onClicked: root.studentDeleteClicked(modelData.s.id) }
                                }
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    width: parent.width; height: 80
                    visible: root.pageStudents.length === 0
                    Text { anchors.centerIn: parent; text: qsTr("Aucun élève trouvé"); font.pixelSize: 13; font.italic: true; color: Style.textTertiary }
                }
            }

            Separator { width: parent.width }

            // ─── Pagination ───
            Item {
                width: parent.width; height: 44

                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: root.processedStudents.length + " élève(s)  ·  Page " + (root.currentPage + 1) + " / " + root.totalPages
                    font.pixelSize: 12; color: Style.textTertiary
                }

                Row {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: prevMa.pressed ? Style.bgTertiary : Style.bgPage; border.color: Style.borderLight
                        opacity: root.currentPage > 0 ? 1.0 : 0.35
                        Text { anchors.centerIn: parent; text: qsTr("‹"); font.pixelSize: 20; color: Style.textPrimary }
                        MouseArea { id: prevMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.currentPage > 0) root.currentPage-- }
                    }

                    Repeater {
                        model: root.visiblePages
                        delegate: Rectangle {
                            width: 36; height: 36; radius: 10
                            color: root.currentPage === modelData ? Style.primary : (pgMa.pressed ? Style.bgTertiary : Style.bgPage)
                            border.color: root.currentPage === modelData ? Style.primary : Style.borderLight
                            Text {
                                anchors.centerIn: parent; text: modelData + 1
                                font.pixelSize: 12; font.bold: root.currentPage === modelData
                                color: root.currentPage === modelData ? Style.background : Style.textPrimary
                            }
                            MouseArea { id: pgMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentPage = modelData }
                        }
                    }

                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: nextMa.pressed ? Style.bgTertiary : Style.bgPage; border.color: Style.borderLight
                        opacity: root.currentPage < root.totalPages - 1 ? 1.0 : 0.35
                        Text { anchors.centerIn: parent; text: qsTr("›"); font.pixelSize: 20; color: Style.textPrimary }
                        MouseArea { id: nextMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.currentPage < root.totalPages - 1) root.currentPage++ }
                    }
                }
            }
        }
    }
}
