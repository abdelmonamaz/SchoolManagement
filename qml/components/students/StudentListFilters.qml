import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import UI.Components

ColumnLayout {
    id: root
    spacing: 8

    required property var niveaux
    required property var classes
    property var          categories: []

    property int    selectedNiveauId:  0
    property string selectedClass:     "all"
    property string selectedSexe:      "all"
    property string selectedCategorie: "all"
    property string selectedStatut:    "all"
    property string selectedPaiement:  "all"

    readonly property var filteredClasses: {
        if (selectedNiveauId === 0) return classes
        var r = []
        for (var i = 0; i < classes.length; i++)
            if (classes[i].niveauId === selectedNiveauId) r.push(classes[i])
        return r
    }

    signal searchChanged(string text)
    signal searchCleared()
    signal niveauFilterChanged(int niveauId)
    signal classFilterChanged(int classeId)
    signal sexeChanged(string sexe)
    signal categorieChanged(string categorie)
    signal statutChanged(string statut)
    signal paiementChanged(string paiement)

    // ─── Row 1: Search + Niveau + Sexe + Catégorie ───
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        SearchField {
            Layout.fillWidth: true
            placeholder: "Rechercher par nom, matricule..."
            onTextChanged: text.length > 0 ? root.searchChanged(text) : root.searchCleared()
        }

        // Niveau dropdown
        Rectangle {
            width: 140; height: 44; radius: 12
            color: Style.bgPage; border.color: Style.borderLight

            RowLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 6
                Text { text: "📚"; font.pixelSize: 13 }
                Text {
                    Layout.fillWidth: true
                    text: {
                        if (root.selectedNiveauId === 0) return "Niveaux"
                        for (var i = 0; i < root.niveaux.length; i++)
                            if (root.niveaux[i].id === root.selectedNiveauId) return root.niveaux[i].nom
                        return "Niveaux"
                    }
                    font.pixelSize: 11; font.bold: true
                    color: Style.textPrimary; elide: Text.ElideRight
                }
                Text { text: "▼"; font.pixelSize: 8; color: Style.textTertiary }
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: niveauMenu.open()
            }
            Menu {
                id: niveauMenu; y: parent.height
                MenuItem {
                    text: "Tous niveaux"
                    onTriggered: {
                        root.selectedNiveauId = 0
                        root.selectedClass    = "all"
                        root.niveauFilterChanged(0)
                        root.searchCleared()
                    }
                }
                Repeater {
                    model: root.niveaux
                    MenuItem {
                        text: modelData.nom
                        onTriggered: {
                            root.selectedNiveauId = modelData.id
                            root.selectedClass    = "all"
                            root.niveauFilterChanged(modelData.id)
                            root.searchCleared()
                        }
                    }
                }
            }
        }

        // Statut filter dropdown
        Rectangle {
            width: 130; height: 44; radius: 12
            color: root.selectedStatut !== "all" ? Style.primaryBg : Style.bgPage
            border.color: root.selectedStatut !== "all" ? Style.primaryLight : Style.borderLight

            RowLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 6
                Text { text: "📋"; font.pixelSize: 12 }
                Text {
                    Layout.fillWidth: true
                    text: root.selectedStatut === "inscrit" ? "Inscrit"
                        : root.selectedStatut === "non-inscrit" ? "Non inscrit"
                        : "Statut"
                    font.pixelSize: 11; font.bold: true
                    color: root.selectedStatut !== "all" ? Style.primary : Style.textPrimary
                    elide: Text.ElideRight
                }
                Text { text: "▼"; font.pixelSize: 8; color: Style.textTertiary }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: statutMenu.open() }
            Menu {
                id: statutMenu; y: parent.height
                MenuItem { text: "Tous statuts";  onTriggered: { root.selectedStatut = "all";         root.statutChanged("all") } }
                MenuItem { text: "Inscrit";        onTriggered: { root.selectedStatut = "inscrit";     root.statutChanged("inscrit") } }
                MenuItem { text: "Non inscrit";    onTriggered: { root.selectedStatut = "non-inscrit"; root.statutChanged("non-inscrit") } }
            }
        }

        // Paiement filter dropdown
        Rectangle {
            width: 120; height: 44; radius: 12
            color: root.selectedPaiement !== "all" ? Style.primaryBg : Style.bgPage
            border.color: root.selectedPaiement !== "all" ? Style.primaryLight : Style.borderLight

            RowLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 6
                Text { text: "💳"; font.pixelSize: 12 }
                Text {
                    Layout.fillWidth: true
                    text: root.selectedPaiement === "paye" ? "Payé"
                        : root.selectedPaiement === "impaye" ? "Impayé"
                        : "Paiement"
                    font.pixelSize: 11; font.bold: true
                    color: root.selectedPaiement !== "all" ? Style.primary : Style.textPrimary
                    elide: Text.ElideRight
                }
                Text { text: "▼"; font.pixelSize: 8; color: Style.textTertiary }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: paiementMenu.open() }
            Menu {
                id: paiementMenu; y: parent.height
                MenuItem { text: "Tous";    onTriggered: { root.selectedPaiement = "all";    root.paiementChanged("all") } }
                MenuItem { text: "Payé";    onTriggered: { root.selectedPaiement = "paye";   root.paiementChanged("paye") } }
                MenuItem { text: "Impayé";  onTriggered: { root.selectedPaiement = "impaye"; root.paiementChanged("impaye") } }
            }
        }

        // Sexe filter chips
        Rectangle {
            height: 44; radius: 16; color: Style.bgSecondary
            implicitWidth: sexeRow.implicitWidth + 8

            Row {
                id: sexeRow
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 4; spacing: 4

                Repeater {
                    model: [ {key: "all", label: "Tous"}, {key: "M", label: "♂ M"}, {key: "F", label: "♀ F"} ]
                    delegate: Rectangle {
                        width: sxLbl.implicitWidth + 18; height: 36; radius: 12
                        color: root.selectedSexe === modelData.key ? Style.primary : "transparent"
                        Text {
                            id: sxLbl; anchors.centerIn: parent
                            text: modelData.label; font.pixelSize: 10; font.weight: Font.Black
                            color: root.selectedSexe === modelData.key ? "#FFFFFF" : Style.textTertiary
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.selectedSexe = modelData.key; root.sexeChanged(modelData.key) }
                        }
                    }
                }
            }
        }

        // Catégorie dropdown
        Rectangle {
            visible: root.categories.length > 0
            width: 140; height: 44; radius: 12
            color: root.selectedCategorie !== "all" ? Style.primaryBg : Style.bgPage
            border.color: root.selectedCategorie !== "all" ? Style.primaryLight : Style.borderLight

            RowLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 6
                Text { text: "🏷"; font.pixelSize: 12 }
                Text {
                    Layout.fillWidth: true
                    text: root.selectedCategorie === "all" ? "Catégorie" : root.selectedCategorie
                    font.pixelSize: 11; font.bold: true
                    color: root.selectedCategorie !== "all" ? Style.primary : Style.textPrimary
                    elide: Text.ElideRight
                }
                Text { text: "▼"; font.pixelSize: 8; color: Style.textTertiary }
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: catMenu.open()
            }
            Menu {
                id: catMenu; y: parent.height
                MenuItem {
                    text: "Toutes catégories"
                    onTriggered: { root.selectedCategorie = "all"; root.categorieChanged("all") }
                }
                Repeater {
                    model: root.categories
                    MenuItem {
                        text: modelData
                        onTriggered: { root.selectedCategorie = modelData; root.categorieChanged(modelData) }
                    }
                }
            }
        }
    }

    // ─── Row 2: Class chips ───
    Row {
        Layout.fillWidth: true
        spacing: 4
        visible: root.filteredClasses.length > 0

        Rectangle {
            width: allClsTxt.implicitWidth + 24; height: 34; radius: 12
            color: root.selectedClass === "all" ? Style.primary : "transparent"
            Text {
                id: allClsTxt; anchors.centerIn: parent; text: "Toutes"
                font.pixelSize: 10; font.weight: Font.Black
                color: root.selectedClass === "all" ? "#FFFFFF" : Style.textTertiary
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { root.selectedClass = "all"; root.classFilterChanged(0) }
            }
        }

        Repeater {
            model: root.filteredClasses
            delegate: Rectangle {
                width: clsTxt.implicitWidth + 24; height: 34; radius: 12
                color: root.selectedClass === modelData.nom ? Style.primary : "transparent"
                Text {
                    id: clsTxt; anchors.centerIn: parent; text: modelData.nom
                    font.pixelSize: 10; font.weight: Font.Black
                    color: root.selectedClass === modelData.nom ? "#FFFFFF" : Style.textTertiary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { root.selectedClass = modelData.nom; root.classFilterChanged(modelData.id) }
                }
            }
        }
    }
}
