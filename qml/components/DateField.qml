import QtQuick
import QtQuick.Layouts

// Champ de saisie de date réutilisable : label + JJ / MM / AAAA
// La catégorie (Jeune/Adulte) est calculée automatiquement selon l'âge.
// Usage:
//   DateField {
//       label: qsTr("DATE DE NAISSANCE")
//       // accès : isValid, age, categorie, clear()
//   }
Column {
    id: root

    property string label: ""
    property color fieldColor: Style.bgPage
    property var nextTabItem: null
    property var prevTabItem: null
    property alias inputItem: dayInput
    property int agePassage: 12

    // Validation calendaire stricte : ranges + nombre de jours réels dans le mois (années bissextiles incluses)
    readonly property bool isValid: {
        if (yearInput.text.length !== 4) return false
        var d = parseInt(dayInput.text)
        var m = parseInt(monthInput.text)
        var y = parseInt(yearInput.text)
        if (isNaN(d) || isNaN(m) || isNaN(y)) return false
        if (m < 1 || m > 12 || y < 1900 || y > 2099 || d < 1) return false
        // new Date(y, m, 0) = dernier jour du mois m (JS : mois 0-indexé, jour 0 = veille du 1er)
        var daysInMonth = new Date(y, m, 0).getDate()
        return d <= daysInMonth
    }

    // Représentation ISO YYYY-MM-DD pour le stockage en base de données
    readonly property string dateString: isValid
        ? (yearInput.text + "-"
           + (monthInput.text.length === 1 ? "0" + monthInput.text : monthInput.text) + "-"
           + (dayInput.text.length   === 1 ? "0" + dayInput.text   : dayInput.text))
        : ""

    // Âge calculé en années complètes (-1 si date invalide)
    readonly property int age: {
        if (!isValid) return -1
        var today = new Date()
        var d = parseInt(dayInput.text)
        var m = parseInt(monthInput.text)
        var y = parseInt(yearInput.text)
        var a = today.getFullYear() - y
        if (today.getMonth() + 1 < m ||
            (today.getMonth() + 1 === m && today.getDate() < d)) {
            a--
        }
        return a
    }

    // Catégorie déduite selon l'âge de passage configurable (défaut 12 ans)
    readonly property string categorie: age < 0 ? "" : (age < agePassage ? "Jeune" : "Adulte")

    // Réinitialise les trois champs
    function clear() {
        dayInput.text = ""
        monthInput.text = ""
        yearInput.text = ""
    }

    // Pré-remplit les champs depuis une chaîne ISO YYYY-MM-DD
    function setDate(isoString) {
        if (isoString && isoString.length === 10) {
            yearInput.text  = isoString.substring(0, 4)
            monthInput.text = isoString.substring(5, 7)
            dayInput.text   = isoString.substring(8, 10)
        } else {
            clear()
        }
    }

    spacing: 6

    Text {
        visible: root.label !== ""
        text: root.label
        font.pixelSize: 9
        font.weight: Font.Black
        color: Style.textTertiary
        font.letterSpacing: 1
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: 12
        color: root.fieldColor
        border.color: Style.borderLight

        HoverHandler {
            cursorShape: Qt.IBeamCursor
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 2

            // ── Jour ──
            TextInput {
                id: dayInput
                Layout.preferredWidth: 30
                font.pixelSize: 13
                font.bold: true
                color: Style.textPrimary
                maximumLength: 2
                validator: IntValidator { bottom: 1; top: 31 }
                inputMethodHints: Qt.ImhDigitsOnly
                clip: true
                selectByMouse: true

                onTextChanged: {
                    if (text.length === 2) monthInput.forceActiveFocus()
                }

                Keys.onBacktabPressed: function(event) {
                    event.accepted = true
                    if (root.prevTabItem) root.prevTabItem.forceActiveFocus()
                }

                Text {
                    visible: !dayInput.text
                    text: qsTr("JJ")
                    font: dayInput.font
                    color: Style.textTertiary
                }
            }

            Text {
                text: qsTr("/")
                font.pixelSize: 13
                font.bold: true
                color: Style.textTertiary
            }

            // ── Mois ──
            TextInput {
                id: monthInput
                Layout.preferredWidth: 30
                font.pixelSize: 13
                font.bold: true
                color: Style.textPrimary
                maximumLength: 2
                validator: IntValidator { bottom: 1; top: 12 }
                inputMethodHints: Qt.ImhDigitsOnly
                clip: true
                selectByMouse: true

                onTextChanged: {
                    if (text.length === 2) yearInput.forceActiveFocus()
                }

                Keys.onBacktabPressed: function(event) {
                    event.accepted = true
                    dayInput.forceActiveFocus()
                }

                Text {
                    visible: !monthInput.text
                    text: qsTr("MM")
                    font: monthInput.font
                    color: Style.textTertiary
                }
            }

            Text {
                text: qsTr("/")
                font.pixelSize: 13
                font.bold: true
                color: Style.textTertiary
            }

            // ── Année ──
            TextInput {
                id: yearInput
                Layout.preferredWidth: 55
                font.pixelSize: 13
                font.bold: true
                color: Style.textPrimary
                maximumLength: 4
                validator: IntValidator { bottom: 1900; top: 2099 }
                inputMethodHints: Qt.ImhDigitsOnly
                clip: true
                selectByMouse: true

                Keys.onBacktabPressed: function(event) {
                    event.accepted = true
                    monthInput.forceActiveFocus()
                }
                
                Keys.onTabPressed: function(event) {
                    event.accepted = true
                    if (root.nextTabItem) root.nextTabItem.forceActiveFocus()
                }

                Text {
                    visible: !yearInput.text
                    text: qsTr("AAAA")
                    font: yearInput.font
                    color: Style.textTertiary
                }
            }

            Item { Layout.fillWidth: true }

            IconLabel {
                iconName: "calendar"
                iconSize: 16
                iconColor: dateMouseArea.containsMouse ? Style.primary : Style.textTertiary
                MouseArea {
                    id: dateMouseArea
                    anchors.fill: parent
                    anchors.margins: -8 // larger hit area
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        var d = new Date()
                        if (root.isValid) {
                            var y = parseInt(yearInput.text)
                            var m = parseInt(monthInput.text) - 1
                            var dt = parseInt(dayInput.text)
                            d = new Date(y, m, dt)
                        }
                        datePopup.selectedDate = d
                        datePopup.open()
                    }
                }
            }
        }
    }

    DatePickerPopup {
        id: datePopup
        onConfirmed: function(isoDate) {
            // ISO date comes as DD/MM/YYYY from DatePickerPopup formatSelected() wait actually DatePickerPopup confirmed(DD/MM/YYYY)
            // So I must parse DD/MM/YYYY into the fields
            dayInput.text = isoDate.substring(0, 2)
            monthInput.text = isoDate.substring(3, 5)
            yearInput.text = isoDate.substring(6, 10)
        }
    }
}
