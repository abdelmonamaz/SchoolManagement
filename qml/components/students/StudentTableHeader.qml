import QtQuick
import QtQuick.Layouts
import UI.Components

RowLayout {
    id: root
    spacing: 0
    height: 36

    property string sortColumn: ""
    property bool   sortAsc:    true

    signal sortRequested(string column)

    Repeater {
        model: [
            { col: "nom",       label: qsTr("ÉLÈVE"),     w: 200, fill: false },
            { col: "id",        label: qsTr("MATRICULE"), w: 100, fill: false },
            { col: "sexe",      label: qsTr("SEXE"),      w: 70,  fill: false },
            { col: "categorie", label: qsTr("CATÉGORIE"), w: 110, fill: false },
            { col: "telephone", label: qsTr("CONTACT"),   w: 0,   fill: true  }
        ]

        delegate: Item {
            Layout.preferredWidth: modelData.w
            Layout.fillWidth:      modelData.fill
            height: 36

            RowLayout {
                anchors.left:           parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: modelData.label
                    font.pixelSize: 10
                    font.weight:    Font.Bold
                    color: root.sortColumn === modelData.col ? Style.primary : Style.textTertiary
                }
                Text {
                    visible:         root.sortColumn === modelData.col
                    text:            root.sortAsc ? "▲" : "▼"
                    font.pixelSize:  8
                    color:           Style.primary
                }
            }

            MouseArea {
                anchors.fill:  parent
                cursorShape:   Qt.PointingHandCursor
                onClicked:     root.sortRequested(modelData.col)
            }
        }
    }

    Text {
        Layout.preferredWidth:  80
        text: qsTr("ACTIONS")
        font.pixelSize:         10
        font.weight:            Font.Bold
        color:                  Style.textTertiary
        horizontalAlignment:    Text.AlignRight
    }
}
