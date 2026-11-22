// =============================================================================
// File: gamemodes/core/colors.inc
// Fungsi: Definisi kode warna heksadesimal RGBA dan embedding color strings
// Dependensi: <open.mp>
// =============================================================================

#if defined _INC_CORE_COLORS
    #endinput
#endif
#define _INC_CORE_COLORS

// --- Nilai Warna RGBA Standar Server ---
#define COLOR_WHITE             0xFFFFFFFF
#define COLOR_BLACK             0x000000FF
#define COLOR_GREY              0xAFAFAFAA
#define COLOR_LIGHTRED          0xFF6347AA
#define COLOR_RED               0xE81123AA
#define COLOR_DARKRED           0x8B0000AA
#define COLOR_GREEN             0x33AA33AA
#define COLOR_LIME              0x107C10AA
#define COLOR_LIGHTBLUE         0x33CCFFAA
#define COLOR_BLUE              0x0078D7AA
#define COLOR_NAVY              0x000080AA
#define COLOR_YELLOW            0xFFFF00AA
#define COLOR_ORANGE            0xFF8C00AA
#define COLOR_PURPLE            0x800080AA
#define COLOR_CYAN              0x00FFFFFA
#define COLOR_PINK              0xFF69B4AA

// --- Alias Warna Modul Akun & Notifikasi ---
#define COLOR_PRIMARY           0x00D4FFAA
#define COLOR_ERROR             0xFF4D4DAA
#define COLOR_WARNING           0xFFD166AA
#define COLOR_SUCCESS           0x2EC4B6AA
#define COLOR_INFO              0x00AAFFAA

// --- Warna Khusus Sistem Roleplay & Obrolan ---
#define COLOR_RP_ME             0xC2A2DAAA
#define COLOR_RP_DO             0x9B59B6AA
#define COLOR_OOC               0xE0E0E0AA
#define COLOR_RADIO             0x8D8DFFAA
#define COLOR_DEPARTMENT        0xFF8282AA
#define COLOR_FACTION           0x00AA00AA
#define COLOR_ADMIN             0x00FFFFFF
#define COLOR_SERVER_INFO       0x00AAFFAA
#define COLOR_SYNTAX_USAGE      0xFFFF99AA

// --- Kode Warna Embedding String ---
#define COL_WHITE               "{FFFFFF}"
#define COL_BLACK               "{000000}"
#define COL_GREY                "{AFAFAF}"
#define COL_RED                 "{FF0000}"
#define COL_LIGHTRED            "{FF6347}"
#define COL_GREEN               "{00FF00}"
#define COL_LIME                "{107C10}"
#define COL_BLUE                "{0078D7}"
#define COL_LIGHTBLUE           "{33CCFF}"
#define COL_YELLOW              "{FFFF00}"
#define COL_ORANGE              "{FF8C00}"
#define COL_PURPLE              "{800080}"
#define COL_CYAN                "{00FFFF}"
#define COL_RP_ME               "{C2A2DA}"
#define COL_RP_DO               "{9B59B6}"
