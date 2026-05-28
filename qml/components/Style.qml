pragma Singleton
import QtQuick

QtObject {
    // ─── Palette Principale (Zitouna & Sauge) ───
    readonly property color zitouna: "#2D4A3E"        // Vert Forêt (Deep Green) - Logo, Boutons
    readonly property color zitounaDark: "#1E352B"    // Variante plus foncée
    readonly property color zitounaLight: "#8EAC90"   // Vert Sauge (Muted Sage)
    readonly property color zitounaBg: "#1A2D4A3E"    // 10% d'opacité

    // ─── Fond & Structure (Mode Clair) ───
    readonly property color background: "#F8F9FA"     // Fond d'Écran (Off-White)
    readonly property color card: "#FFFFFF"           // Blanc Pur (Cartes)
    readonly property color popover: "#FFFFFF"
    readonly property color sidebar: "#FFFFFF"        // Fond de la sidebar (les éléments actifs utilisent le vert forêt)
    
    // Alias pour compatibilité existante
    readonly property color bgPage: "#F8F9FA"
    readonly property color bgWhite: "#FFFFFF"
    readonly property color bgSecondary: "#FFFFFF" 
    readonly property color bgTertiary: "#E0E0E0"
    readonly property color sandBg: "#F5F1E9"
    readonly property color borderLight: "#E0E0E0"    // Bordures / Lignes
    readonly property color borderMedium: "#CCCCCC"
    readonly property color primaryBg: zitounaBg
    readonly property color primaryDark: zitounaDark
    readonly property color primaryLight: zitounaLight

    // ─── Couleurs d'Accent & Statuts ───
    readonly property color successColor: "#27AE60"   // Succès / Positif
    readonly property color successBg: "#EAF7EF"      
    readonly property color successBorder: "#C3E8D1"

    readonly property color warningColor: "#D4AF37"   // Or / Scolarité
    readonly property color warningBg: "#FBF7E9"
    readonly property color warningBorder: "#EFE1B3"

    readonly property color errorColor: "#D63031"     // Danger / Alerte
    readonly property color errorBg: "#FBEAEB"
    readonly property color errorBorder: "#F3BCC3"
    
    readonly property color destructive: errorColor
    readonly property color destructiveForeground: "#FFFFFF"

    readonly property color infoColor: "#3498DB"      // Bleu Doux
    readonly property color infoBg: "#EBF5FB"
    readonly property color infoBorder: "#C0DDF1"

    // ─── Texte & Typographie ───
    readonly property color foreground: "#2C3E50"     // Texte Principal (bleu-noir foncé)
    readonly property color cardForeground: foreground
    readonly property color sidebarForeground: foreground
    readonly property color mutedForeground: "#7F8C8D" // Texte Secondaire / Gris
    
    readonly property color textPrimary: foreground
    readonly property color textSecondary: mutedForeground
    readonly property color textTertiary: "#7F8C8D"
    readonly property color textOnPrimary: "#FFFFFF"

    // ─── Couleurs Système ───
    readonly property color primary: "#2D4A3E"        // Vert Forêt pour la couleur primaire
    readonly property color primaryForeground: "#FFFFFF"
    
    readonly property color secondary: "#F8F9FA"      
    readonly property color secondaryForeground: "#2C3E50"
    
    readonly property color muted: "#E0E0E0"          // Bordures / Lignes
    readonly property color accent: zitounaLight      // Vert Sauge pour les accents

    // ─── Bordures & Inputs ───
    readonly property color border: "#E0E0E0"         // Bordures très légères
    readonly property color sidebarBorder: "#E0E0E0" 
    readonly property color inputBackground: "#FFFFFF"
    readonly property color switchBackground: "#E0E0E0"

    // ─── Graphiques (Charts) & Alias ───
    readonly property color chart1: "#27AE60"
    readonly property color chart2: "#8EAC90"
    readonly property color chart3: "#3498DB"
    readonly property color chart4: "#D4AF37"
    readonly property color chart5: "#2D4A3E"
    
    readonly property color chartBlue: infoColor
    readonly property color chartBlueLight: infoBg
    readonly property color chartPurple: "#9B59B6"
    readonly property color chartPurpleLight: "#F4ECF7"

    // ─── Spécifications Design (Spacing & Radius) ───
    readonly property int radius: 10
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 14
    readonly property int radiusXL: 18
    readonly property int radiusRound: 24

    // ─── Ombres ───
    readonly property color shadowColor: "#0D000000" // rgba(0,0,0,0.05) - 5% d'opacité
}
