import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import UI.Components

// ── Étape 1 : Identité de l'association + exercice comptable ─────────────────
ColumnLayout {
    id: root
    spacing: 20

    // ── Public API ──────────────────────────────────────────────────────────
    readonly property bool canProceed:
        nomAssocField.text.trim() !== "" && exDebutField.isValid && exFinField.isValid

    function getData() {
        return {
            nomAssociation:   nomAssocField.text.trim(),
            adresse:          adresseField.text.trim(),
            exerciceDebut:    exDebutField.dateString,
            exerciceFin:      exFinField.dateString,
            agePassageAdulte: parseInt(agePassageInput.text) || 12,
            langue:           langueCombo.currentValue || "français"
        }
    }

    // ── Internal helpers ───────────────────────────────────────────────────
    property bool _updatingDate: false

    function _isoToLocalDate(iso) {
        var p = iso.split("-")
        return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
    }
    function _localDateToIso(d) {
        var m = d.getMonth() + 1; var day = d.getDate()
        return d.getFullYear() + "-" + (m < 10 ? "0" + m : "" + m)
                                + "-" + (day < 10 ? "0" + day : "" + day)
    }

    Component.onCompleted: {
        nomAssocField.text = setupController.associationData.nomAssociation || ""
        adresseField.text  = setupController.associationData.adresse        || ""
        var savedLang = setupController.associationData.langue || "français"
        langueCombo.savedValue = savedLang
        var idx = langueCombo.indexOfValue(savedLang)
        langueCombo.currentIndex = idx !== -1 ? idx : 0
    }

    // ── Info banner ─────────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true; height: 48; radius: 14; color: Style.primaryBg
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
            IconLabel { iconName: "info"; iconColor: Style.primary }
            Text {
                Layout.fillWidth: true
                text: qsTr("Ces informations identifient votre association dans les documents officiels.")
                font.pixelSize: 12; font.bold: true; color: Style.primary; wrapMode: Text.WordWrap
            }
        }
    }

    FormField {
        id: nomAssocField
        Layout.fillWidth: true
        label: qsTr("NOM DE L'ASSOCIATION")
        placeholder: qsTr("ex: Ez-Zaytouna")
        nextTabItem: adresseField.inputItem
    }

    FormField {
        id: adresseField
        Layout.fillWidth: true
        label: qsTr("ADRESSE")
        placeholder: qsTr("ex: 12 Rue de la Mosquée, Tunis")
        prevTabItem: nomAssocField.inputItem
        nextTabItem: langueCombo
    }

    // ── Langue ──────────────────────────────────────────────────────────────
    SectionLabel { text: qsTr("LANGUE DE L'APPLICATION") }
    Rectangle {
        Layout.fillWidth: true; height: 40; radius: 10
        color: Style.bgPage; border.color: Style.borderLight
        ComboBox {
            id: langueCombo
            property string savedValue: "français"
            anchors.fill: parent; anchors.margins: 2
            model: [
                {"label": qsTr("Français"), "value": "français"},
                {"label": qsTr("Arabe"),    "value": "arabe"}
            ]
            textRole: "label"; valueRole: "value"
            background: Rectangle { color: "transparent" }
            contentItem: Text {
                text: langueCombo.displayText
                font.pixelSize: 13; font.bold: true; color: Style.textPrimary
                verticalAlignment: Text.AlignVCenter; leftPadding: 8
            }
            onActivated: {
                savedValue = currentValue
                appController.applyLanguage(currentValue)
            }
            onModelChanged: {
                var idx = indexOfValue(savedValue)
                currentIndex = idx !== -1 ? idx : 0
            }
        }
    }

    // ── Exercice comptable ──────────────────────────────────────────────────
    SectionLabel { text: qsTr("EXERCICE COMPTABLE") }
    RowLayout {
        Layout.fillWidth: true; spacing: 16
        DateField {
            id: exDebutField
            Layout.fillWidth: true; Layout.preferredWidth: 0
            label: qsTr("DATE DE DÉBUT")
            nextTabItem: exFinField.inputItem
            Component.onCompleted: setDate(
                (setupController.associationData.exerciceDebut !== undefined
                 && setupController.associationData.exerciceDebut !== "")
                    ? setupController.associationData.exerciceDebut
                    : (new Date().getFullYear() - (new Date().getMonth() < 8 ? 1 : 0)) + "-01-01")
            onDateStringChanged: {
                if (root._updatingDate || !isValid) return
                root._updatingDate = true
                var d = root._isoToLocalDate(dateString)
                d.setMonth(d.getMonth() + 12); d.setDate(d.getDate() - 1)
                exFinField.setDate(root._localDateToIso(d))
                root._updatingDate = false
            }
        }
        DateField {
            id: exFinField
            Layout.fillWidth: true; Layout.preferredWidth: 0
            label: qsTr("DATE DE FIN")
            prevTabItem: exDebutField.inputItem
            Component.onCompleted: setDate(
                (setupController.associationData.exerciceFin !== undefined
                 && setupController.associationData.exerciceFin !== "")
                    ? setupController.associationData.exerciceFin
                    : (new Date().getFullYear() - (new Date().getMonth() < 8 ? 1 : 0)) + "-12-31")
            onDateStringChanged: {
                if (root._updatingDate || !isValid) return
                root._updatingDate = true
                var d = root._isoToLocalDate(dateString)
                d.setDate(d.getDate() + 1); d.setMonth(d.getMonth() - 12)
                exDebutField.setDate(root._localDateToIso(d))
                root._updatingDate = false
            }
        }
    }

    // ── Âge de passage adulte ───────────────────────────────────────────────
    SectionLabel { text: qsTr("CATÉGORISATION") }
    RowLayout {
        Layout.fillWidth: true; spacing: 12
        Text {
            text: qsTr("Âge de passage Adulte :")
            font.pixelSize: 13; font.bold: true; color: Style.textPrimary
            Layout.alignment: Qt.AlignVCenter
        }
        TextField {
            id: agePassageInput
            Layout.preferredWidth: 72; height: 40
            text: (setupController.associationData.agePassageAdulte || 12).toString()
            font.pixelSize: 14; font.bold: true; color: Style.textPrimary
            horizontalAlignment: TextInput.AlignHCenter; selectByMouse: true
            validator: IntValidator { bottom: 1; top: 99 }
            background: Rectangle {
                radius: 10; color: Style.bgPage; border.color: Style.borderLight
                border.width: parent.activeFocus ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 120 } }
            }
        }
        Text {
            text: qsTr("ans")
            font.pixelSize: 13; font.bold: true; color: Style.textSecondary
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Item { Layout.fillHeight: true }
}
