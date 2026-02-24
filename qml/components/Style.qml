pragma Singleton
import QtQuick 2.15

QtObject {
    // ─── Brand Colors ───
    readonly property color primary: "#3D5A45"
    readonly property color primaryDark: "#2D4233"
    readonly property color primaryLight: "#86A38E"
    readonly property color primaryBg: "#3D5A4510"    // 10% opacity

    // ─── Sand Theme Colors ───
    readonly property color sand: "#D4B483"
    readonly property color sandLight: "#E1CEB1"
    readonly property color sandBg: "#F5F1E9"

    // ─── Background Colors ───
    readonly property color bgPage: "#F9FAFB"
    readonly property color bgWhite: "#FFFFFF"
    readonly property color bgSecondary: "#F3F4F6"
    readonly property color bgTertiary: "#E5E7EB"

    // ─── Text Colors ───
    readonly property color textPrimary: "#1E293B"
    readonly property color textSecondary: "#6B7280"
    readonly property color textTertiary: "#9CA3AF"
    readonly property color textOnPrimary: "#FFFFFF"

    // ─── Border Colors ───
    readonly property color borderLight: "#F3F4F6"
    readonly property color borderMedium: "#E5E7EB"

    // ─── Status Colors ───
    readonly property color successColor: "#059669"
    readonly property color successBg: "#ECFDF5"
    readonly property color successBorder: "#D1FAE5"

    readonly property color warningColor: "#D97706"
    readonly property color warningBg: "#FFFBEB"
    readonly property color warningBorder: "#FEF3C7"

    readonly property color errorColor: "#EF4444"
    readonly property color errorBg: "#FEF2F2"
    readonly property color errorBorder: "#FEE2E2"

    readonly property color infoColor: "#2563EB"
    readonly property color infoBg: "#EFF6FF"
    readonly property color infoBorder: "#DBEAFE"

    // ─── Chart Colors ───
    readonly property color chartBlue: "#3B82F6"
    readonly property color chartBlueLight: "#EFF6FF"
    readonly property color chartGreen: "#059669"
    readonly property color chartGreenLight: "#ECFDF5"
    readonly property color chartAmber: "#D97706"
    readonly property color chartAmberLight: "#FFFBEB"
    readonly property color chartPurple: "#7C3AED"
    readonly property color chartPurpleLight: "#F5F3FF"

    // ─── Spacing ───
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 16
    readonly property int radiusXL: 20
    readonly property int radiusRound: 24

    // ─── Shadows (simulated with borders) ───
    readonly property color shadowColor: "#0000000D"
}
