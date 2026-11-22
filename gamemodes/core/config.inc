// =============================================================================
// File: gamemodes/core/config.inc
// Fungsi: Konfigurasi global server, batas array, dan konstanta sistem Roleplay
// Dependensi: <open.mp>
// =============================================================================

#if defined _INC_CORE_CONFIG
    #endinput
#endif
#define _INC_CORE_CONFIG

// --- Informasi Server ---
#define SERVER_NAME                 "Open.mp Roleplay Indonesia"
#define SERVER_GAMEMODE_TEXT        "OMP-RP v1.0.0"
#define SERVER_VERSION              "1.0.0-PROD"
#define SERVER_WEBSITE              "www.samp-roleplay.id"
#define SERVER_TIMEZONE_OFFSET      7 // Waktu Indonesia Barat (WIB = UTC+7)

// --- Mode Debug ---
#define DEBUG_MODE                  true

// --- Batasan Akun & Karakter ---
#define MAX_ACCOUNT_PASSWORD_LEN    64
#define MIN_ACCOUNT_PASSWORD_LEN    6
#define MAX_LOGIN_ATTEMPTS          3
#define LOGIN_TIMEOUT_SECONDS       60
#define MAX_CHARACTERS_PER_ACCOUNT  3
#define MIN_ROLEPLAY_NAME_LEN       3
#define MAX_ROLEPLAY_NAME_LEN       24
#define MIN_CHARACTER_AGE           18
#define MAX_CHARACTER_AGE           80

// --- Pengaturan Finansial Awal ---
#define DEFAULT_STARTER_CASH        500
#define DEFAULT_STARTER_BANK        2500
#define DEFAULT_PAYCHECK_SALARY     150
#define DEFAULT_PAYCHECK_TAX_RATE   0.05 // Pajak 5%

// --- Batasan Maksimal Entitas Dinamis ---
#define MAX_DYNAMIC_HOUSES          500
#define MAX_DYNAMIC_BUSINESSES      250
#define MAX_DYNAMIC_VEHICLES        1000
#define MAX_DYNAMIC_FACTIONS        30
#define MAX_DYNAMIC_DOORS           300
#define MAX_DYNAMIC_ATMS            100
#define MAX_DYNAMIC_GAS_STATIONS    50
#define MAX_INVENTORY_SLOTS         20
#define MAX_INVENTORY_WEIGHT        40.0 // Batas berat inventaris pemain (Kg)

// --- Radius Obrolan (Jarak Suara In-Game dalam Meter) ---
#define CHAT_RADIUS_LOCAL           20.0
#define CHAT_RADIUS_SHOUT           35.0
#define CHAT_RADIUS_WHISPER         3.5
#define CHAT_RADIUS_ME              20.0
#define CHAT_RADIUS_DO              20.0
#define CHAT_RADIUS_LOW             7.5
#define INTERACTION_RADIUS          3.5

// --- Interval Waktu Timer (Milidetik) ---
#define TIMER_ONE_SECOND_MS         1000
#define TIMER_AUTOSAVE_INTERVAL_MS  300000 // Autosave database setiap 5 menit
#define TIMER_PAYCHECK_INTERVAL_MS  3600000 // Paycheck setiap 60 menit (1 jam bermain)

// --- Koordinat Titik Spawn Pendatang Baru (Default: Los Santos City Hall) ---
#define DEFAULT_SPAWN_X             1481.0400
#define DEFAULT_SPAWN_Y             -1772.3100
#define DEFAULT_SPAWN_Z             15.3000
#define DEFAULT_SPAWN_ANGLE         0.0000
#define DEFAULT_SPAWN_INTERIOR      0
#define DEFAULT_SPAWN_VW            0

// --- Level Staf & Admin ---
enum
{
    ADMIN_LEVEL_NONE = 0,
    ADMIN_LEVEL_TRIAL_HELPER = 1,
    ADMIN_LEVEL_HELPER = 2,
    ADMIN_LEVEL_MODERATOR = 3,
    ADMIN_LEVEL_ADMIN = 4,
    ADMIN_LEVEL_SENIOR_ADMIN = 5,
    ADMIN_LEVEL_LEAD_ADMIN = 6,
    ADMIN_LEVEL_OWNER = 7
};

// --- Tipe Faksi ---
enum
{
    FACTION_TYPE_NONE = 0,
    FACTION_TYPE_POLICE,
    FACTION_TYPE_MEDIC,
    FACTION_TYPE_GOVERNMENT,
    FACTION_TYPE_NEWS,
    FACTION_TYPE_GANG
};

// --- ID Pekerjaan Legal ---
enum
{
    JOB_NONE = 0,
    JOB_TRUCKER,
    JOB_MECHANIC,
    JOB_TAXI,
    JOB_BUS,
    JOB_SWEEPER,
    JOB_FISHER,
    JOB_MINER,
    JOB_LUMBERJACK
};
