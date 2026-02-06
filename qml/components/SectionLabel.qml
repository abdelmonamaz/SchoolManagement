import QtQuick 2.15

// Label de section en majuscules, utilisé pour les en-têtes de colonnes de tableaux,
// les titres de sections dans les formulaires, etc.
// Usage:
//   SectionLabel { text: "NOM DU GROUPE" }
Text {
    font.pixelSize: 9
    font.weight: Font.Black
    color: Style.textTertiary
    font.letterSpacing: 1
}
