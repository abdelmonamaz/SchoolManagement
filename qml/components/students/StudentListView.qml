import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
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
    signal registrationRequested()
    signal searchRequested(string text)
    signal filterByClass(int classeId)
    signal loadAllRequested()
    signal niveauFilterChanged(int niveauId)

    // ─── Column widths (shared between header and rows) ───
    readonly property int colNom:      400
    readonly property int colId:       100
    readonly property int colSexe:     70
    readonly property int colCat:      110
    readonly property int colActions:  80

    // ─── Filter & Sort State ───
    property string sexeFilter:       "all"
    property string categorieFilter:  "all"
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

    // ─── Client-side filter + sort ───
    // IDs des classes du niveau sélectionné (recompute quand classes change via backend)
    readonly property var niveauClassIds: {
        if (activeNiveauId === 0 || classeSelectedFilter > 0) return null
        var ids = {}
        for (var k = 0; k < classes.length; k++) ids[classes[k].id] = true
        return ids
    }

    readonly property var processedStudents: {
        var ids = niveauClassIds   // null = pas de filtre niveau
        var result = []
        for (var i = 0; i < students.length; i++) {
            var s = students[i]
            if (ids !== null && !ids[s.classeId])               continue
            if (sexeFilter      !== "all" && s.sexe      !== sexeFilter)      continue
            if (categorieFilter !== "all" && s.categorie !== categorieFilter)  continue
            result.push({ s: s, idx: i })
        }
        if (sortColumn !== "") {
            var col = sortColumn, asc = sortAsc
            result.sort(function(a, b) {
                var va = a.s[col] !== undefined ? a.s[col] : ""
                var vb = b.s[col] !== undefined ? b.s[col] : ""
                if (typeof va === "number" && typeof vb === "number")
                    return asc ? va - vb : vb - va
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
            title: "Annuaire des Étudiants"
            subtitle: "Gestion des dossiers individuels et du suivi."
        }
        PrimaryButton {
            text: "Inscrire un Élève"; iconName: "plus"
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
                        text: "ÉLÈVE" + root.sortArrow("nom")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("nom")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("nom") }
                }
                // MATRICULE
                Item {
                    width: root.colId; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "MATRICULE" + root.sortArrow("id")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("id")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("id") }
                }
                // SEXE
                Item {
                    width: root.colSexe; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SEXE" + root.sortArrow("sexe")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("sexe")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("sexe") }
                }
                // CATÉGORIE
                Item {
                    width: root.colCat; height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CATÉGORIE" + root.sortArrow("categorie")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("categorie")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("categorie") }
                }
                // CONTACT (fills remaining space)
                Item {
                    width: parent.width - root.colNom - root.colId - root.colSexe - root.colCat - root.colActions
                    height: parent.height
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CONTACT" + root.sortArrow("telephone")
                        font.pixelSize: 10; font.weight: Font.Bold; color: root.sortColor("telephone")
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.onSortCol("telephone") }
                }
                // ACTIONS
                Item {
                    width: root.colActions; height: parent.height
                    Text {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: "ACTIONS"; font.pixelSize: 10; font.weight: Font.Bold; color: Style.textTertiary
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
                        color: rowHover.hovered ? "#FAFBFC" : "transparent"

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
                                    customTextColor:   "#FFFFFF"
                                    customBgColor:     modelData.s.sexe === "F" ? "#DB2777"  : Style.primary
                                    customBorderColor: modelData.s.sexe === "F" ? "#BE185D"  : Style.primaryDark
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
                            // CONTACT
                            Item {
                                width: parent.width - root.colNom - root.colId - root.colSexe - root.colCat - root.colActions
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
                    Text { anchors.centerIn: parent; text: "Aucun élève trouvé"; font.pixelSize: 13; font.italic: true; color: Style.textTertiary }
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
                        Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 20; color: Style.textPrimary }
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
                                color: root.currentPage === modelData ? "#FFFFFF" : Style.textPrimary
                            }
                            MouseArea { id: pgMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentPage = modelData }
                        }
                    }

                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: nextMa.pressed ? Style.bgTertiary : Style.bgPage; border.color: Style.borderLight
                        opacity: root.currentPage < root.totalPages - 1 ? 1.0 : 0.35
                        Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 20; color: Style.textPrimary }
                        MouseArea { id: nextMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.currentPage < root.totalPages - 1) root.currentPage++ }
                    }
                }
            }
        }
    }
}
