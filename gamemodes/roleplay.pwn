#include <open.mp>

// =============================================================================
//                      SA-MP / OPEN.MP ROLEPLAY GAMEMODE
//                                TAHAP 1 - 11
//   (Pondasi, Database, Auth, Ekonomi, Pekerjaan, Kendaraan & Properti Rumah)
//                      + ADMIN & TELEPORTATION SYSTEM
// =============================================================================

#pragma tabsize 4

// --- Definisi Warna ---
#define COLOR_WHITE         0xFFFFFFFF
#define COLOR_YELLOW        0xFFFF00FF
#define COLOR_GREY          0xAFAFAFAA
#define COLOR_RED           0xFF0000FF
#define COLOR_GREEN         0x33AA33AA
#define COLOR_PURPLE        0xC2A2DAAA
#define COLOR_CYAN          0x33CCFFAA
#define COLOR_ORANGE        0xFFA500FF
#define COLOR_LIME          0x10F441AA
#define COLOR_PINK          0xFF66CCAA

// --- Definisi Batas Maksimal ---
#define MAX_OWNED_VEHICLES  100
#define MAX_HOUSES          50

// --- Definisi ID Pekerjaan ---
enum
{
    JOB_NONE = 0,
    JOB_SWEEPER,
    JOB_BUS,
    JOB_TRUCKER
};

// --- Definisi Dialog ID ---
enum
{
    DIALOG_REGISTER = 1,
    DIALOG_LOGIN,
    DIALOG_STATS,
    DIALOG_HELP,
    DIALOG_HELP_ACCOUNT,
    DIALOG_HELP_VEHICLE,
    DIALOG_HELP_HOUSE,
    DIALOG_HELP_JOB,
    DIALOG_HELP_FACILITY,
    DIALOG_HELP_FACTION,
    DIALOG_HELP_GANG,
    DIALOG_HELP_ADMIN,
    DIALOG_HELP_BIZ,
    DIALOG_HELP_ALL_CMDS,
    DIALOG_ATM_MAIN,
    DIALOG_ATM_WITHDRAW,
    DIALOG_ATM_DEPOSIT,
    DIALOG_ATM_TRANSFER_ID,
    DIALOG_ATM_TRANSFER_AMOUNT,
    DIALOG_RESTAURANT,
    DIALOG_JOB_AGENCY,
    DIALOG_DEALERSHIP,
    DIALOG_MY_VEHICLES,
    DIALOG_HOUSE_SAFE_MAIN,
    DIALOG_HOUSE_SAFE_DEPOSIT,
    DIALOG_HOUSE_SAFE_WITHDRAW,
    DIALOG_ADMIN_TP,
    DIALOG_ADMIN_HELP,
    DIALOG_POLICE_DUTY,
    DIALOG_MEDIC_DUTY,
    DIALOG_CALL_911,
    DIALOG_CALL_911_MSG,
    DIALOG_WANTED_LIST,
    DIALOG_FRISK_VIEW,
    DIALOG_GROVE_LOCKER,
    DIALOG_BALLAS_LOCKER,
    DIALOG_BLACK_MARKET,
    DIALOG_TURF_INFO,
    DIALOG_BIZ_SAFE_MAIN,
    DIALOG_BIZ_SAFE_DEPOSIT,
    DIALOG_BIZ_SAFE_WITHDRAW,
    DIALOG_247_SHOP,
    DIALOG_ELECTRONIC_SHOP,
    DIALOG_GPS_MENU,
    DIALOG_TRUCKER_CARGO,
    DIALOG_TRUNK_MAIN,
    DIALOG_TRUNK_DEPOSIT_CASH,
    DIALOG_TRUNK_WITHDRAW_CASH,
    DIALOG_TRUNK_WEAPON_MENU,
    DIALOG_TRUNK_DEPOSIT_POT,
    DIALOG_TRUNK_WITHDRAW_POT,
    DIALOG_TRUNK_DEPOSIT_CRACK,
    DIALOG_TRUNK_WITHDRAW_CRACK,
    DIALOG_VEH_SELL_CONFIRM
};

// --- Konstanta & Enum Faksi (Tahap 8 & 9) ---
#define FACTION_NONE    0
#define FACTION_POLICE  1
#define FACTION_MEDIC   2
#define FACTION_GROVE   3
#define FACTION_BALLAS  4

#define MAX_FACTION_VEHICLES 24

enum E_FACTION_VEHICLE
{
    fvVehicleID,
    fvFaction,
    fvModel,
    Float:fvSpawnX,
    Float:fvSpawnY,
    Float:fvSpawnZ,
    Float:fvSpawnAngle
};

new g_FactionVehicles[MAX_FACTION_VEHICLES][E_FACTION_VEHICLE];
new g_TotalFactionVehicles = 0;

// --- Data Sistem Perang Wilayah Geng (Gang Turf Wars) ---
enum E_TURF_DATA
{
    turfZoneID,
    turfName[32],
    Float:turfMinX,
    Float:turfMinY,
    Float:turfMaxX,
    Float:turfMaxY,
    turfOwner,
    turfAttacker,
    turfWarTimer,
    bool:turfUnderAttack
};

new g_TurfData[3][E_TURF_DATA] = {
    {-1, "Ganton & Grove", 2210.0, -1740.0, 2540.0, -1570.0, FACTION_GROVE, 0, 0, false},
    {-1, "Glen Park & Jefferson", 1880.0, -1350.0, 2150.0, -1080.0, FACTION_BALLAS, 0, 0, false},
    {-1, "Idlewood & East LS", 1880.0, -1740.0, 2210.0, -1350.0, FACTION_NONE, 0, 0, false}
};

// --- Enum Data Pemain ---
enum E_PLAYER_DATA
{
    pID,
    pPassword[65],
    pSalt[17],
    pScore,
    pMoney,
    pBank,
    pAdmin,
    pSkin,
    Float:pHealth,
    Float:pArmour,
    Float:pPosX,
    Float:pPosY,
    Float:pPosZ,
    Float:pAngle,
    pInterior,
    pVirtualWorld,
    bool:pLoggedIn,
    pLoginAttempts,
    pHunger,
    pThirst,
    pPaycheckTime,
    pTransferTarget,
    pJob,
    bool:pWorking,
    pJobCheckpoint,
    PlayerText:pSpeedoTD,
    pFaction,
    pFactionRank,
    bool:pOnDuty,
    bool:pCuffed,
    pJailTime,
    pWantedLevel,
    pWantedReason[64],
    bool:pInjured,
    pInjuredTimer,
    pEmergencyType,
    Text3D:pFactionLabel,
    pPot,
    pCrack,
    pRobCooldown,
    pHasGPS,
    pHasMask,
    bool:pMaskActive,
    pCigarettes,
    bool:pAdminDuty,
    Text3D:pAdminBadge,
    pVehSellSlot,
    pVehSellPrice,
    pVehSellSeller,
    pTruckerCargo
};

new PlayerData[MAX_PLAYERS][E_PLAYER_DATA];
new DB:g_DB;

// --- Enum & Array Kendaraan Pribadi ---
enum E_OWNED_VEHICLE
{
    ovDBID,
    ovOwnerID,
    ovVehicleID,
    ovModel,
    ovColor1,
    ovColor2,
    Float:ovPosX,
    Float:ovPosY,
    Float:ovPosZ,
    Float:ovAngle,
    Float:ovFuel,
    Float:ovHealth,
    bool:ovLocked,
    bool:ovEngine,
    ovPlate[16],
    bool:ovSpawned,
    ovTrunkMoney,
    ovTrunkWeapon,
    ovTrunkAmmo,
    ovTrunkPot,
    ovTrunkCrack,
    bool:ovTrunkOpen
};

new OwnedVehicles[MAX_OWNED_VEHICLES][E_OWNED_VEHICLE];

// --- Enum & Array Properti Rumah ---
enum E_HOUSE_DATA
{
    hID,
    hOwnerID,
    hOwnerName[MAX_PLAYER_NAME],
    hPrice,
    hAddress[48],
    Float:hEnterX,
    Float:hEnterY,
    Float:hEnterZ,
    Float:hExitX,
    Float:hExitY,
    Float:hExitZ,
    hInterior,
    bool:hLocked,
    hSafeMoney,
    hPickup,
    Text3D:hLabel,
    hExitPickup,
    Text3D:hExitLabel,
    bool:hLoaded
};

new HouseData[MAX_HOUSES][E_HOUSE_DATA];
new g_TotalHouses = 0;

// --- Konstanta & Enum Properti Bisnis / Toko (Tahap 10) ---
#define MAX_BUSINESSES          30
#define BIZ_TYPE_247            1
#define BIZ_TYPE_ELECTRONIC     2
#define BIZ_TYPE_RESTAURANT     3

enum E_BIZ_DATA
{
    bID,
    bOwnerID,
    bOwnerName[MAX_PLAYER_NAME],
    bPrice,
    bName[48],
    bType,
    Float:bEnterX,
    Float:bEnterY,
    Float:bEnterZ,
    Float:bExitX,
    Float:bExitY,
    Float:bExitZ,
    bInterior,
    bool:bLocked,
    bVault,
    bPickup,
    Text3D:bLabel,
    bExitPickup,
    Text3D:bExitLabel,
    bool:bLoaded
};

new BizData[MAX_BUSINESSES][E_BIZ_DATA];
new g_TotalBusinesses = 0;

// --- Data Lokasi Teleportasi Admin ---
enum E_TELEPORT_DATA
{
    tpName[48],
    Float:tpX,
    Float:tpY,
    Float:tpZ,
    Float:tpAngle
};

new const g_TeleportLocations[][E_TELEPORT_DATA] = {
    {"Los Santos City Hall (Balai Kota)",       1481.04, -1772.31, 15.30, 0.0},
    {"LSPD Headquarter (Pershing Square)",      1543.90, -1675.20, 13.55, 90.0},
    {"All Saints Hospital (Rumah Sakit)",       1177.50, -1320.00, 14.10, 270.0},
    {"Unity Station (Stasiun Kereta)",          1753.30, -1862.50, 13.57, 0.0},
    {"Showroom Kendaraan (Commerce)",           1124.50, -1451.20, 15.80, 0.0},
    {"SPBU Idlewood",                           1938.20, -1773.50, 13.40, 90.0},
    {"Grove Street (Ganton)",                   2495.30, -1690.50, 13.50, 0.0},
    {"Santa Maria Beach (Pantai)",              368.50,  -2035.20, 7.80,  180.0},
    {"Bandara Los Santos (LS Airport)",         1680.50, -2330.20, 13.50, 0.0},
    {"Puncak Mount Chiliad (Gunung)",           -2310.20,-1640.50, 483.70,0.0},
    {"San Fierro Downtown",                     -1980.50, 138.20,  27.60, 90.0},
    {"Las Venturas Strip (The Strip)",          2025.20, 1008.50,  10.80, 0.0},
    {"Kawasan Mewah Richman (Richman Hills)",   322.50,  -1188.20, 75.80, 0.0}
};

// --- Data Katalog Showroom Kendaraan ---
enum E_DEALER_VEHICLE
{
    dvModel,
    dvName[32],
    dvPrice
};

new const g_DealerCatalog[][E_DEALER_VEHICLE] = {
    {462, "Faggio (Motor Matic)",      600},
    {468, "Sanchez (Motor Trail)",     1200},
    {522, "NRG-500 (Motor Sport)",     5000},
    {542, "Clover (Mobil Klasik)",     3500},
    {426, "Premier (Sedan Modern)",    6000},
    {560, "Sultan (Sedan Sport)",     14000},
    {422, "Bobcat (Pickup Truck)",     4500}
};

// --- Data Kendaraan Dinas Pekerjaan ---
new g_SweeperVehicles[3];
new g_BusVehicles[3];

// --- Data Rute Pekerjaan ---
new const Float:g_SweeperCheckpoints[][3] = {
    {1667.50, -1865.00, 13.20},
    {1711.20, -1888.50, 13.20},
    {1806.40, -1912.80, 13.20},
    {1920.50, -1890.20, 13.20},
    {2030.00, -1820.50, 13.20},
    {2045.20, -1710.00, 13.20},
    {1960.50, -1640.20, 13.20},
    {1825.20, -1640.50, 13.20},
    {1720.50, -1690.00, 13.20},
    {1645.00, -1750.50, 13.20},
    {1640.40, -1883.20, 13.15}
};

new const Float:g_BusCheckpoints[][3] = {
    {1780.20, -1820.00, 13.20},
    {1690.50, -1740.00, 13.20},
    {1525.00, -1670.00, 13.20},
    {1365.20, -1650.00, 13.20},
    {1190.50, -1370.00, 13.20},
    {1380.00, -1250.00, 13.20},
    {1650.00, -1280.00, 13.20},
    {1950.00, -1450.00, 13.20},
    {2150.00, -1670.00, 13.20},
    {2250.00, -1780.00, 13.20},
    {1850.00, -1890.00, 13.20},
    {1795.50, -1908.20, 13.57}
};

// --- Rute & Armada Pekerjaan Supir Truk Kargo (Tahap 11) ---
#define MAX_TRUCKER_VEHICLES 6
new g_TruckerVehicles[MAX_TRUCKER_VEHICLES];

// Rute Kargo 1: Pangan & Snack (24/7 & Restoran)
new const Float:g_TruckerCargo1_CP[][3] = {
    {2415.50, -2460.20, 13.60},
    {2150.20, -1800.50, 13.50},
    {1315.20, -900.50, 39.50},
    {811.20, -1616.40, 13.50},
    {1480.50, -1750.20, 15.30},
    {2185.50, -2256.40, 13.54}
};

// Rute Kargo 2: Gadget & Elektronik
new const Float:g_TruckerCargo2_CP[][3] = {
    {2415.50, -2460.20, 13.60},
    {1920.40, -1850.20, 13.50},
    {1430.50, -1490.20, 13.50},
    {1481.04, -1772.31, 15.30},
    {1800.20, -2100.50, 13.50},
    {2185.50, -2256.40, 13.54}
};

// Rute Kargo 3: Material Berat & Kontainer Ekspor
new const Float:g_TruckerCargo3_CP[][3] = {
    {2755.20, -2400.50, 13.60},
    {2100.50, -1400.20, 24.50},
    {1150.20, -950.40, 42.50},
    {45.20, -2600.40, 40.50},
    {1750.20, -2100.50, 13.50},
    {2185.50, -2256.40, 13.54}
};


// --- Data Lokasi ATM ---
enum E_ATM_DATA
{
    Float:atmX,
    Float:atmY,
    Float:atmZ
};
new const g_ATM_Locations[][E_ATM_DATA] = {
    {1753.30, -1862.50, 13.57},
    {1177.50, -1320.00, 14.10},
    {1543.90, -1675.20, 13.55},
    {1457.21, -1012.08, 26.84}
};

// --- Data Lokasi Restoran ---
enum E_FOOD_DATA
{
    fName[32],
    Float:foodX,
    Float:foodY,
    Float:foodZ
};
new const g_Food_Locations[][E_FOOD_DATA] = {
    {"Well Stacked Pizza (Idlewood)", 2105.10, -1806.40, 13.55},
    {"Cluckin' Bell (Willowfield)",    2393.50, -1898.80, 13.54},
    {"Burger Shot (Marina)",           811.50, -1616.20, 13.54}
};

// Forward Declarations
forward CheckPlayerAccount(playerid);
forward OnAccountCreated(playerid);
forward OnServerMinuteTimer();
forward OnSpeedometerTimer();
forward SavePlayerData(playerid);
forward SaveVehicleData(slot);
forward SaveHouseData(index);
forward UpdateHouseLabel(index);

// =============================================================================
// MAIN ENTRY
// =============================================================================
// =============================================================================
// SISTEM ADMIN DUTY & GOD MODE OTOMATIS
// =============================================================================
stock SetAdminDuty(playerid, bool:duty)
{
    if (PlayerData[playerid][pAdmin] < 1) return 0;

    PlayerData[playerid][pAdminDuty] = duty;

    if (PlayerData[playerid][pAdminBadge] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(PlayerData[playerid][pAdminBadge]);
        PlayerData[playerid][pAdminBadge] = Text3D:INVALID_3DTEXT_ID;
    }

    if (duty)
    {
        SetPlayerHealth(playerid, 100.0);
        SetPlayerArmour(playerid, 100.0);
        PlayerData[playerid][pHunger] = 100;
        PlayerData[playerid][pThirst] = 100;

        new badge[128];
        format(badge, sizeof(badge), "{FF0000}[ADMIN ON-DUTY]\n{FFFF00}%s (Level %d)", GetPlayerNameEx(playerid), PlayerData[playerid][pAdmin]);
        PlayerData[playerid][pAdminBadge] = Create3DTextLabel(badge, COLOR_RED, 0.0, 0.0, 0.5, 25.0, 0, true);
        Attach3DTextLabelToPlayer(PlayerData[playerid][pAdminBadge], playerid, 0.0, 0.0, 0.55);

        SendClientMessage(playerid, COLOR_LIME, "[ADMIN DUTY] Anda sekarang ON-DUTY. Mode Dewa (God Mode) OTOMATIS AKTIF.");
        SendClientMessage(playerid, COLOR_YELLOW, "[PETUNJUK] Karakter Anda kebal terhadap segala serangan & kematian. Ketik /aduty untuk menjadi warga biasa.");
    }
    else
    {
        SetPlayerHealth(playerid, 100.0);
        SetPlayerArmour(playerid, 0.0);

        SendClientMessage(playerid, COLOR_YELLOW, "[ADMIN DUTY] Anda sekarang OFF-DUTY. Mode Dewa (God Mode) DIMATIKAN.");
        SendClientMessage(playerid, COLOR_RED, "[PERINGATAN] Karakter Anda kini menjadi karakter biasa dan DAPAT TERLUKA / MATI.");
    }
    return 1;
}

main()
{
    printf(" ");
    printf("=================================================");
    printf("        Open.mp Roleplay Gamemode Started        ");
    printf("   Tahap 1-11: Trucker Job, Trunk & Vehicle Trade   ");
    printf("=================================================");
    printf(" ");
}

// =============================================================================
// SERVER INITIALIZATION
// =============================================================================
public OnGameModeInit()
{
    SetGameModeText("Roleplay v0.8.0");
    SendRconCommand("hostname Open.mp Indonesian Roleplay");
    SendRconCommand("weburl https://open.mp");

    ShowPlayerMarkers(PLAYER_MARKERS_MODE_STREAMED);
    SetNameTagDrawDistance(20.0);
    EnableStuntBonusForAll(false);
    DisableInteriorEnterExits();

    SetWorldTime(12);
    SetWeather(10);

    // Buka / Buat Database SQLite
    g_DB = DB_Open("roleplay.db");
    if (!g_DB)
    {
        printf("[FATAL ERROR] Gagal membuka database roleplay.db!");
        return 1;
    }
    printf("[DATABASE] Berhasil terhubung ke scriptfiles/roleplay.db");

    // Inisialisasi Tabel Players
    DB_FreeResultSet(DB_ExecuteQuery(g_DB,
        "CREATE TABLE IF NOT EXISTS players (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            username TEXT COLLATE NOCASE UNIQUE,\
            password TEXT,\
            salt TEXT,\
            score INTEGER DEFAULT 1,\
            money INTEGER DEFAULT 500,\
            bank INTEGER DEFAULT 1500,\
            admin INTEGER DEFAULT 0,\
            skin INTEGER DEFAULT 299,\
            health REAL DEFAULT 100.0,\
            armour REAL DEFAULT 0.0,\
            pos_x REAL DEFAULT 1743.0804,\
            pos_y REAL DEFAULT -1863.8569,\
            pos_z REAL DEFAULT 13.5781,\
            angle REAL DEFAULT 357.0,\
            interior INTEGER DEFAULT 0,\
            world INTEGER DEFAULT 0,\
            hunger INTEGER DEFAULT 100,\
            thirst INTEGER DEFAULT 100,\
            paycheck_time INTEGER DEFAULT 0,\
            job INTEGER DEFAULT 0,\
            faction INTEGER DEFAULT 0,\
            faction_rank INTEGER DEFAULT 0,\
            jail_time INTEGER DEFAULT 0\
        );"
    ));

    // Migrasi kolom faksi jika tabel sudah ada sebelumnya
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN faction INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN faction_rank INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN jail_time INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN pot INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN crack INTEGER DEFAULT 0;"));

    // Otomatis berikan Admin Level 5 kepada akun pertama / akun yang sudah ada
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "UPDATE players SET admin = 5 WHERE id = 1;"));

    // Inisialisasi Tabel Vehicles
    DB_FreeResultSet(DB_ExecuteQuery(g_DB,
        "CREATE TABLE IF NOT EXISTS vehicles (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            owner_id INTEGER,\
            model INTEGER,\
            color1 INTEGER DEFAULT 1,\
            color2 INTEGER DEFAULT 1,\
            pos_x REAL,\
            pos_y REAL,\
            pos_z REAL,\
            angle REAL,\
            fuel REAL DEFAULT 100.0,\
            health REAL DEFAULT 1000.0,\
            plate TEXT\
        );"
    ));

    // Inisialisasi Tabel Houses
    DB_FreeResultSet(DB_ExecuteQuery(g_DB,
        "CREATE TABLE IF NOT EXISTS houses (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            owner_id INTEGER DEFAULT 0,\
            price INTEGER,\
            address TEXT,\
            enter_x REAL,\
            enter_y REAL,\
            enter_z REAL,\
            exit_x REAL,\
            exit_y REAL,\
            exit_z REAL,\
            interior INTEGER,\
            locked INTEGER DEFAULT 1,\
            safe_money INTEGER DEFAULT 0\
        );"
    ));

    // Seed Rumah Default jika kosong
    new DBResult:chk = DB_ExecuteQuery(g_DB, "SELECT COUNT(*) AS total FROM houses;");
    if (DB_GetRowCount(chk) > 0 && DB_GetFieldIntByName(chk, "total") == 0)
    {
        DB_FreeResultSet(chk);
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO houses (owner_id, price, address, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, safe_money) VALUES (0, 8500, '101 Grove Street, Ganton', 2495.30, -1690.50, 13.50, 2496.05, -1695.17, 1014.74, 3, 1, 0);"));
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO houses (owner_id, price, address, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, safe_money) VALUES (0, 12000, '204 Atlantic Avenue, Idlewood', 1982.50, -1700.20, 13.40, 2262.83, -1137.80, 1050.63, 10, 1, 0);"));
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO houses (owner_id, price, address, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, safe_money) VALUES (0, 15000, '305 North Hill, Jefferson', 2215.30, -1140.20, 25.80, 2233.78, -1115.17, 1050.88, 2, 1, 0);"));
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO houses (owner_id, price, address, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, safe_money) VALUES (0, 35000, '501 Marina Coast, Verona Beach', 855.20, -1640.50, 13.50, 140.28, 1366.49, 1083.86, 5, 1, 0);"));
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO houses (owner_id, price, address, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, safe_money) VALUES (0, 75000, '777 Richman Luxury Mansion', 322.50, -1188.20, 75.80, 140.28, 1366.49, 1083.86, 5, 1, 0);"));
    }
    else
    {
        DB_FreeResultSet(chk);
        new DBResult:chk_rich = DB_ExecuteQuery(g_DB, "SELECT id FROM houses WHERE address LIKE '%Richman%' LIMIT 1;");
        if (DB_GetRowCount(chk_rich) == 0)
        {
            DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO houses (owner_id, price, address, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, safe_money) VALUES (0, 75000, '777 Richman Luxury Mansion', 322.50, -1188.20, 75.80, 140.28, 1366.49, 1083.86, 5, 1, 0);"));
        }
        DB_FreeResultSet(chk_rich);
    }

    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN pot INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN crack INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN has_gps INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN has_mask INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE players ADD COLUMN cigs INTEGER DEFAULT 0;"));

    // Migrasi Kolom Bagasi Kendaraan (Tahap 11)
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE vehicles ADD COLUMN trunk_money INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE vehicles ADD COLUMN trunk_weapon INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE vehicles ADD COLUMN trunk_ammo INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE vehicles ADD COLUMN trunk_pot INTEGER DEFAULT 0;"));
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, "ALTER TABLE vehicles ADD COLUMN trunk_crack INTEGER DEFAULT 0;"));

    // Inisialisasi Tabel Businesses (Tahap 10)
    DB_FreeResultSet(DB_ExecuteQuery(g_DB,
        "CREATE TABLE IF NOT EXISTS businesses (\
            id INTEGER PRIMARY KEY AUTOINCREMENT,\
            owner_id INTEGER DEFAULT 0,\
            price INTEGER,\
            name TEXT,\
            type INTEGER,\
            enter_x REAL,\
            enter_y REAL,\
            enter_z REAL,\
            exit_x REAL,\
            exit_y REAL,\
            exit_z REAL,\
            interior INTEGER,\
            locked INTEGER DEFAULT 0,\
            vault INTEGER DEFAULT 0\
        );"
    ));

    new DBResult:chkb = DB_ExecuteQuery(g_DB, "SELECT COUNT(*) AS total FROM businesses;");
    if (DB_GetRowCount(chkb) > 0 && DB_GetFieldIntByName(chkb, "total") == 0)
    {
        DB_FreeResultSet(chkb);
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO businesses (owner_id, price, name, type, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, vault) VALUES (0, 45000, '24/7 Supermarket Idlewood', 1, 1929.50, -1776.20, 13.50, -30.95, -89.61, 1003.55, 18, 0, 0);"));
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO businesses (owner_id, price, name, type, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, vault) VALUES (0, 60000, 'Tech & Gadget Store Commerce', 2, 1153.20, -1460.50, 15.80, 372.35, -131.65, 1001.49, 6, 0, 0);"));
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, "INSERT INTO businesses (owner_id, price, name, type, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, vault) VALUES (0, 35000, 'Ganton Vintage Diner & Bar', 3, 2421.50, -1645.20, 13.60, 452.92, -18.23, 1000.73, 17, 0, 0);"));
    }
    else
    {
        DB_FreeResultSet(chkb);
    }

    for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
    {
        OwnedVehicles[i][ovSpawned] = false;
        OwnedVehicles[i][ovVehicleID] = INVALID_VEHICLE_ID;
    }

    LoadAllHouses();
    LoadAllBusinesses();

    AddPlayerClass(0, 1743.0804, -1863.8569, 13.5781, 357.0, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);

    // Titik ATM
    for (new i = 0; i < sizeof(g_ATM_Locations); i++)
    {
        CreatePickup(1274, 1, g_ATM_Locations[i][atmX], g_ATM_Locations[i][atmY], g_ATM_Locations[i][atmZ]);
        Create3DTextLabel("{00AAFF}[MESIN ATM SAN ANDREAS]\n{FFFFFF}Gunakan {FFFF00}/atm {FFFFFF}atau tekan {FFFF00}[ENTER / F]",
            COLOR_WHITE, g_ATM_Locations[i][atmX], g_ATM_Locations[i][atmY], g_ATM_Locations[i][atmZ] + 0.6, 15.0, 0, true
        );
    }

    // Titik Restoran
    for (new i = 0; i < sizeof(g_Food_Locations); i++)
    {
        CreatePickup(1239, 1, g_Food_Locations[i][foodX], g_Food_Locations[i][foodY], g_Food_Locations[i][foodZ]);
        new label[128];
        format(label, sizeof(label), "{FF9900}[RESTORAN: %s]\n{FFFFFF}Gunakan {FFFF00}/buyfood {FFFFFF}atau tekan {FFFF00}[ENTER / F]", g_Food_Locations[i][fName]);
        Create3DTextLabel(label, COLOR_WHITE, g_Food_Locations[i][foodX], g_Food_Locations[i][foodY], g_Food_Locations[i][foodZ] + 0.6, 15.0, 0, true);
    }

    // Titik Balai Tenaga Kerja (City Hall)
    CreatePickup(1239, 1, 1481.04, -1772.31, 15.30);
    Create3DTextLabel("{00AAFF}[PUSAT LOWONGAN KERJA / EMPLOYMENT AGENCY]\n{FFFFFF}Gunakan {FFFF00}/job {FFFFFF}atau tekan {FFFF00}[ENTER / F]",
        COLOR_WHITE, 1481.04, -1772.31, 15.30 + 0.6, 15.0, 0, true
    );

    // Titik Showroom Dealership Kendaraan Los Santos
    CreatePickup(1239, 1, 1124.50, -1451.20, 15.80);
    Create3DTextLabel("{00AAFF}[SHOWROOM KENDARAAN LOS SANTOS]\n{FFFFFF}Gunakan {FFFF00}/buyvehicle {FFFFFF}atau tekan {FFFF00}[ENTER / F]",
        COLOR_WHITE, 1124.50, -1451.20, 15.80 + 0.6, 15.0, 0, true
    );

    // Titik SPBU / Gas Station (Idlewood)
    CreatePickup(1274, 1, 1938.20, -1773.50, 13.40);
    Create3DTextLabel("{00FF00}[SPBU IDLEWOOD - PENGISIAN BAHAN BAKAR]\n{FFFFFF}Gunakan {FFFF00}/refuel {FFFFFF}atau tekan {FFFF00}[ENTER / F]",
        COLOR_WHITE, 1938.20, -1773.50, 13.40 + 0.6, 15.0, 0, true
    );

    // Titik Loker Markas Polisi SAPD (Pershing Square LSPD)
    CreatePickup(1275, 1, 1552.0, -1678.0, 16.20);
    Create3DTextLabel("{0099FF}[LOKER DINAS KEPOLISIAN - SAPD]\n{FFFFFF}Gunakan {FFFF00}/duty {FFFFFF}untuk On-Duty / Off-Duty\n{00FF99}Tekan [ENTER / F]",
        COLOR_WHITE, 1552.0, -1678.0, 16.20 + 0.6, 15.0, 0, true
    );

    // Titik Loker Rumah Sakit SAMD (All Saints General Hospital)
    CreatePickup(1240, 1, 1173.0, -1323.0, 15.40);
    Create3DTextLabel("{FF0055}[LOKER DINAS MEDIS - SAMD]\n{FFFFFF}Gunakan {FFFF00}/duty {FFFFFF}untuk On-Duty / Off-Duty\n{00FF99}Tekan [ENTER / F]",
        COLOR_WHITE, 1173.0, -1323.0, 15.40 + 0.6, 15.0, 0, true
    );

    // Sel Penjara LSPD (Interior 6)
    CreatePickup(1239, 1, 264.62, 77.57, 1001.03);
    Create3DTextLabel("{FF0000}[SEL PENJARA LSPD]\n{FFFFFF}Kawasan tahanan narapidana kota",
        COLOR_WHITE, 264.62, 77.57, 1001.03 + 0.6, 15.0, 6, true
    );

    // Titik Loker Markas Geng Grove Street (Ganton Cul-de-Sac)
    CreatePickup(1277, 1, 2495.30, -1668.50, 13.34);
    Create3DTextLabel("{00FF00}[MARKAS GROVE STREET FAMILIES]\n{FFFFFF}Gunakan {FFFF00}/duty {FFFFFF}atau tekan {FFFF00}[ENTER / F]\n{00FF99}Loker Persenjataan Geng",
        COLOR_WHITE, 2495.30, -1668.50, 13.34 + 0.6, 15.0, 0, true
    );

    // Titik Loker Markas Geng Ballas (Glen Park)
    CreatePickup(1277, 1, 1995.50, -1117.80, 27.10);
    Create3DTextLabel("{AA00FF}[MARKAS BALLAS GANG]\n{FFFFFF}Gunakan {FFFF00}/duty {FFFFFF}atau tekan {FFFF00}[ENTER / F]\n{CC66FF}Loker Persenjataan Geng",
        COLOR_WHITE, 1995.50, -1117.80, 27.10 + 0.6, 15.0, 0, true
    );

    // Titik Pasar Gelap (Black Market Ocean Docks)
    CreatePickup(1210, 1, 2352.00, -2005.00, 13.50);
    Create3DTextLabel("{FF9900}[PASAR GELAP / BLACK MARKET]\n{FFFFFF}Gunakan {FFFF00}/buyblackmarket {FFFFFF}atau tekan {FFFF00}[ENTER / F]\n{FF0000}Dilarang untuk Polisi!",
        COLOR_WHITE, 2352.00, -2005.00, 13.50 + 0.6, 15.0, 0, true
    );

    // Kendaraan Dinas Faksi Kepolisian (SAPD)
    g_FactionVehicles[0][fvVehicleID] = AddStaticVehicle(596, 1545.0, -1684.0, 5.89, 90.0, 0, 1); // Police Cruiser 1
    g_FactionVehicles[0][fvFaction] = FACTION_POLICE;
    g_FactionVehicles[1][fvVehicleID] = AddStaticVehicle(596, 1545.0, -1680.0, 5.89, 90.0, 0, 1); // Police Cruiser 2
    g_FactionVehicles[1][fvFaction] = FACTION_POLICE;
    g_FactionVehicles[2][fvVehicleID] = AddStaticVehicle(596, 1545.0, -1676.0, 5.89, 90.0, 0, 1); // Police Cruiser 3
    g_FactionVehicles[2][fvFaction] = FACTION_POLICE;
    g_FactionVehicles[3][fvVehicleID] = AddStaticVehicle(523, 1545.0, -1672.0, 5.89, 90.0, 0, 1); // HPV-1000 Bike
    g_FactionVehicles[3][fvFaction] = FACTION_POLICE;
    g_FactionVehicles[4][fvVehicleID] = AddStaticVehicle(427, 1545.0, -1668.0, 5.89, 90.0, 0, 1); // SWAT Enforcer
    g_FactionVehicles[4][fvFaction] = FACTION_POLICE;

    // Kendaraan Dinas Faksi Medis (SAMD Ambulances)
    g_FactionVehicles[5][fvVehicleID] = AddStaticVehicle(416, 1178.50, -1308.20, 13.80, 270.0, 1, 3); // Ambulance 1
    g_FactionVehicles[5][fvFaction] = FACTION_MEDIC;
    g_FactionVehicles[6][fvVehicleID] = AddStaticVehicle(416, 1178.50, -1314.00, 13.80, 270.0, 1, 3); // Ambulance 2
    g_FactionVehicles[6][fvFaction] = FACTION_MEDIC;
    g_FactionVehicles[7][fvVehicleID] = AddStaticVehicle(416, 1178.50, -1320.00, 13.80, 270.0, 1, 3); // Ambulance 3
    g_FactionVehicles[7][fvFaction] = FACTION_MEDIC;

    // Kendaraan Faksi Geng Grove Street (Hijau)
    g_FactionVehicles[8][fvVehicleID] = AddStaticVehicle(567, 2485.0, -1655.0, 13.34, 180.0, 86, 86); // Savanna Hijau 1
    g_FactionVehicles[8][fvFaction] = FACTION_GROVE;
    g_FactionVehicles[9][fvVehicleID] = AddStaticVehicle(567, 2480.0, -1655.0, 13.34, 180.0, 86, 86); // Savanna Hijau 2
    g_FactionVehicles[9][fvFaction] = FACTION_GROVE;
    g_FactionVehicles[10][fvVehicleID] = AddStaticVehicle(492, 2475.0, -1655.0, 13.34, 180.0, 86, 86); // Greenwood Hijau
    g_FactionVehicles[10][fvFaction] = FACTION_GROVE;

    // Kendaraan Faksi Geng Ballas (Ungu)
    g_FactionVehicles[11][fvVehicleID] = AddStaticVehicle(412, 1990.0, -1125.0, 27.10, 0.0, 149, 149); // Voodoo Ungu 1
    g_FactionVehicles[11][fvFaction] = FACTION_BALLAS;
    g_FactionVehicles[12][fvVehicleID] = AddStaticVehicle(412, 1985.0, -1125.0, 27.10, 0.0, 149, 149); // Voodoo Ungu 2
    g_FactionVehicles[12][fvFaction] = FACTION_BALLAS;
    g_FactionVehicles[13][fvVehicleID] = AddStaticVehicle(566, 1980.0, -1125.0, 27.10, 0.0, 149, 149); // Tahoma Ungu
    g_FactionVehicles[13][fvFaction] = FACTION_BALLAS;
    g_TotalFactionVehicles = 14;

    for (new i = 0; i < g_TotalFactionVehicles; i++)
    {
        SetVehicleParamsEx(g_FactionVehicles[i][fvVehicleID], 0, 0, 0, 0, 0, 0, 0);
    }

    // Inisialisasi Zona Wilayah Geng (Gang Zones)
    for (new i = 0; i < sizeof(g_TurfData); i++)
    {
        g_TurfData[i][turfZoneID] = GangZoneCreate(g_TurfData[i][turfMinX], g_TurfData[i][turfMinY], g_TurfData[i][turfMaxX], g_TurfData[i][turfMaxY]);
    }

    // Kendaraan Dinas Sweeper
    g_SweeperVehicles[0] = AddStaticVehicle(574, 1640.40, -1883.20, 13.15, 0.0, 1, 1);
    g_SweeperVehicles[1] = AddStaticVehicle(574, 1645.40, -1883.20, 13.15, 0.0, 1, 1);
    g_SweeperVehicles[2] = AddStaticVehicle(574, 1650.40, -1883.20, 13.15, 0.0, 1, 1);

    // Kendaraan Dinas Bus Kota
    g_BusVehicles[0] = AddStaticVehicle(431, 1795.50, -1908.20, 13.57, 90.0, 1, 3);
    g_BusVehicles[1] = AddStaticVehicle(431, 1795.50, -1916.20, 13.57, 90.0, 1, 3);
    g_BusVehicles[2] = AddStaticVehicle(431, 1795.50, -1924.20, 13.57, 90.0, 1, 3);

    for (new i = 0; i < 3; i++)
    {
        SetVehicleParamsEx(g_SweeperVehicles[i], 0, 0, 0, 0, 0, 0, 0);
        SetVehicleParamsEx(g_BusVehicles[i], 0, 0, 0, 0, 0, 0, 0);
    }

    // Armada Truk Logistik Ocean Docks (Tahap 11)
    g_TruckerVehicles[0] = AddStaticVehicle(499, 2170.00, -2250.00, 13.60, 180.0, 1, 1); // Benson 1
    g_TruckerVehicles[1] = AddStaticVehicle(499, 2175.00, -2250.00, 13.60, 180.0, 1, 1); // Benson 2
    g_TruckerVehicles[2] = AddStaticVehicle(456, 2180.00, -2250.00, 13.60, 180.0, 3, 3); // Yankee 1
    g_TruckerVehicles[3] = AddStaticVehicle(456, 2185.00, -2250.00, 13.60, 180.0, 3, 3); // Yankee 2
    g_TruckerVehicles[4] = AddStaticVehicle(455, 2190.00, -2250.00, 13.60, 180.0, 0, 0); // Flatbed 1
    g_TruckerVehicles[5] = AddStaticVehicle(455, 2195.00, -2250.00, 13.60, 180.0, 0, 0); // Flatbed 2

    for (new i = 0; i < MAX_TRUCKER_VEHICLES; i++)
    {
        SetVehicleParamsEx(g_TruckerVehicles[i], 0, 0, 0, 0, 0, 0, 0);
    }

    // Timers
    SetTimer("OnServerMinuteTimer", 60000, true);
    SetTimer("OnSpeedometerTimer", 1000, true);

    return 1;
}

public OnGameModeExit()
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn])
        {
            SavePlayerData(i);
        }
    }

    // Hitung Mundur Perang Wilayah Geng (Turf War Countdown)
    for (new t = 0; t < sizeof(g_TurfData); t++)
    {
        if (g_TurfData[t][turfUnderAttack])
        {
            g_TurfData[t][turfWarTimer] -= 60;
            if (g_TurfData[t][turfWarTimer] <= 0)
            {
                new new_owner = g_TurfData[t][turfAttacker];
                g_TurfData[t][turfOwner] = new_owner;
                g_TurfData[t][turfUnderAttack] = false;
                g_TurfData[t][turfAttacker] = 0;
                g_TurfData[t][turfWarTimer] = 0;

                GangZoneStopFlashForAll(g_TurfData[t][turfZoneID]);
                UpdateGangZoneColors();

                new f_att[48], broadcast[200];
                GetFactionName(new_owner, f_att, sizeof(f_att));
                format(broadcast, sizeof(broadcast), "[PERANG WILAYAH] Wilayah %s resmi DIKUASAI oleh geng %s!", g_TurfData[t][turfName], f_att);
                SendClientMessageToAll((new_owner == FACTION_GROVE) ? 0x00FF00AA : 0xAA00FFAA, broadcast);
            }
            else
            {
                new war_msg[160];
                format(war_msg, sizeof(war_msg), "[PERANG WILAYAH] Perebutan zona %s sedang berlangsung! Waktu tersisa: %d detik.", g_TurfData[t][turfName], g_TurfData[t][turfWarTimer]);
                for (new p = 0; p < MAX_PLAYERS; p++)
                {
                    if (IsPlayerConnected(p) && (PlayerData[p][pFaction] == FACTION_GROVE || PlayerData[p][pFaction] == FACTION_BALLAS || PlayerData[p][pAdmin] >= 1))
                    {
                        SendClientMessage(p, COLOR_YELLOW, war_msg);
                    }
                }
            }
        }
    }

    for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
    {
        if (OwnedVehicles[i][ovSpawned])
        {
            SaveVehicleData(i);
            DestroyVehicle(OwnedVehicles[i][ovVehicleID]);
            OwnedVehicles[i][ovSpawned] = false;
        }
    }

    for (new i = 0; i < g_TotalHouses; i++)
    {
        if (HouseData[i][hLoaded])
        {
            SaveHouseData(i);
        }
    }

    if (g_DB)
    {
        DB_Close(g_DB);
        printf("[DATABASE] Koneksi SQLite ditutup.");
    }
    return 1;
}

// =============================================================================
// TIMER: SPEEDOMETER & FUEL CONSUMPTION
// =============================================================================
stock GetVehicleSpeed(vehicleid)
{
    new Float:vx, Float:vy, Float:vz;
    GetVehicleVelocity(vehicleid, vx, vy, vz);
    return floatround(floatsqroot((vx * vx) + (vy * vy) + (vz * vz)) * 180.0);
}

public OnSpeedometerTimer()
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i) || !PlayerData[i][pLoggedIn]) continue;

        if (GetPlayerState(i) == PLAYER_STATE_DRIVER)
        {
            new veh = GetPlayerVehicleID(i);
            new speed = GetVehicleSpeed(veh);

            new slot = GetVehicleSlotFromID(veh);
            new Float:fuel = 100.0;
            new bool:is_locked = false;
            new bool:is_engine = false;

            if (slot != -1)
            {
                fuel = OwnedVehicles[slot][ovFuel];
                is_locked = OwnedVehicles[slot][ovLocked];
                is_engine = OwnedVehicles[slot][ovEngine];

                if (is_engine)
                {
                    OwnedVehicles[slot][ovFuel] -= 0.05 + (float(speed) * 0.001);
                    if (OwnedVehicles[slot][ovFuel] <= 0.0)
                    {
                        OwnedVehicles[slot][ovFuel] = 0.0;
                        OwnedVehicles[slot][ovEngine] = false;
                        SetVehicleParamsEx(veh, 0, 0, 0, is_locked ? 1 : 0, 0, 0, 0);
                        SendClientMessage(i, COLOR_RED, "[KENDARAAN] Bensin kendaraan habis! Mesin mati otomatis. Segera isi di SPBU.");
                    }
                    fuel = OwnedVehicles[slot][ovFuel];
                }
            }
            else
            {
                new eng, lgt, alm, dor, bnt, bot, obj;
                GetVehicleParamsEx(veh, eng, lgt, alm, dor, bnt, bot, obj);
                is_engine = (eng == 1);
                is_locked = (dor == 1);
            }

            new str[160];
            format(str, sizeof(str),
                "~y~Speed: ~w~%d KM/H~n~~g~Fuel: ~w~%.0f%%~n~~p~Engine: %s  ~b~Lock: %s",
                speed, fuel,
                is_engine ? ("~g~ON") : ("~r~OFF"),
                is_locked ? ("~r~LOCKED") : ("~g~OPEN")
            );
            PlayerTextDrawSetString(i, PlayerData[i][pSpeedoTD], str);
            PlayerTextDrawShow(i, PlayerData[i][pSpeedoTD]);
        }
        else
        {
            PlayerTextDrawHide(i, PlayerData[i][pSpeedoTD]);
        }
    }
    return 1;
}

// =============================================================================
// TIMER: PAYCHECK & KEBUTUHAN LAPAR/HAUS
// =============================================================================
public OnServerMinuteTimer()
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i) || !PlayerData[i][pLoggedIn]) continue;

        PlayerData[i][pPaycheckTime]++;

        if (PlayerData[i][pPaycheckTime] % 2 == 0)
        {
            if (PlayerData[i][pAdmin] >= 1 && PlayerData[i][pAdminDuty])
            {
                PlayerData[i][pHunger] = 100;
                PlayerData[i][pThirst] = 100;
            }
            else
            {
                if (PlayerData[i][pHunger] > 0) PlayerData[i][pHunger]--;
                if (PlayerData[i][pThirst] > 0) PlayerData[i][pThirst] -= 2;
            }

            if (PlayerData[i][pThirst] < 0) PlayerData[i][pThirst] = 0;
            if (PlayerData[i][pHunger] < 0) PlayerData[i][pHunger] = 0;

            if (PlayerData[i][pHunger] <= 0 || PlayerData[i][pThirst] <= 0)
            {
                new Float:hp;
                GetPlayerHealth(i, hp);
                if (hp > 10.0)
                {
                    SetPlayerHealth(i, hp - 4.0);
                    SendClientMessage(i, COLOR_RED, "[PERINGATAN] Tubuh Anda sangat lapar/haus! Cari makan di restoran terdekat.");
                }
            }
        }

        if (PlayerData[i][pRobCooldown] > 0)
        {
            PlayerData[i][pRobCooldown]--;
        }

        // Logika Penjara Tahanan LSPD (Jail Timer)
        if (PlayerData[i][pJailTime] > 0)
        {
            PlayerData[i][pJailTime]--;
            if (PlayerData[i][pJailTime] <= 0)
            {
                PlayerData[i][pJailTime] = 0;
                SetPlayerPos(i, 1554.0, -1675.0, 16.20);
                SetPlayerFacingAngle(i, 90.0);
                SetPlayerInterior(i, 0);
                SetPlayerVirtualWorld(i, 0);
                SendClientMessage(i, COLOR_GREEN, "[PENJARA] Masa hukuman penjara Anda telah selesai! Anda telah dibebaskan.");
            }
            else
            {
                new jm[128];
                format(jm, sizeof(jm), "[PENJARA] Sisa masa tahanan Anda: %d menit lagi.", PlayerData[i][pJailTime]);
                SendClientMessage(i, COLOR_YELLOW, jm);
            }
        }

        // Logika Sekarat / Pingsan (Injured Timer)
        if (PlayerData[i][pInjured])
        {
            PlayerData[i][pInjuredTimer] -= 60;
            if (PlayerData[i][pInjuredTimer] <= 0)
            {
                PlayerData[i][pInjured] = false;
                PlayerData[i][pInjuredTimer] = 0;
                ClearAnimations(i);
                TogglePlayerControllable(i, true);

                SetPlayerPos(i, 1177.38, -1323.77, 14.07);
                SetPlayerFacingAngle(i, 270.0);
                SetPlayerInterior(i, 0);
                SetPlayerVirtualWorld(i, 0);
                SetPlayerHealth(i, 100.0);
                PlayerData[i][pHealth] = 100.0;
                PlayerData[i][pHunger] = 80;
                PlayerData[i][pThirst] = 80;

                new cost = 100;
                if (GetPlayerMoney(i) >= cost) GivePlayerMoney(i, -cost);
                else PlayerData[i][pBank] -= cost;

                SendClientMessage(i, COLOR_RED, "[RUMAH SAKIT] Anda sadar di Rumah Sakit All Saints setelah masa kritis.");
                SendClientMessage(i, COLOR_YELLOW, "[BIAYA] Anda dikenakan biaya rawat inap dan penanganan sebesar $100.");
            }
            else
            {
                new im[128];
                format(im, sizeof(im), "[SEKARAT] Sisa waktu bertahan: %d detik lagi sebelum dilarikan ke rumah sakit.", PlayerData[i][pInjuredTimer]);
                SendClientMessage(i, COLOR_RED, im);
            }
        }

        if (PlayerData[i][pPaycheckTime] >= 60)
        {
            PlayerData[i][pPaycheckTime] = 0;

            new welfare = 350;
            new interest = floatround(float(PlayerData[i][pBank]) * 0.002);
            if (interest > 500) interest = 500;
            new tax = 50;
            new net_salary = welfare + interest - tax;

            PlayerData[i][pBank] += net_salary;
            PlayerData[i][pScore]++;
            SetPlayerScore(i, PlayerData[i][pScore]);

            new slip[400];
            format(slip, sizeof(slip),
                "{00AAFF}================== [ SLIP GAJI / PAYCHECK ] =================={FFFFFF}\n\
                {FFFFFF}Tunjangan Pemerintah (Welfare) : {00FF00}+$%d{FFFFFF}\n\
                {FFFFFF}Bunga Rekening Tabungan (0.2%%)  : {00FF00}+$%d{FFFFFF}\n\
                {FFFFFF}Pajak Fasilitas Kota Los Santos : {FF0000}-$%d{FFFFFF}\n\
                --------------------------------------------------------------\n\
                {FFFFFF}Total Bersih Masuk Rekening    : {FFFF00}+$%d{FFFFFF}\n\
                {FFFFFF}Saldo Bank Anda Saat Ini       : {00FF00}$%d{FFFFFF}\n\
                {FFFFFF}Level Karakter Anda Naik Menjadi: {00AAFF}Level %d{FFFFFF}\n\
                {00AAFF}==============================================================",
                welfare, interest, tax, net_salary, PlayerData[i][pBank], PlayerData[i][pScore]
            );
            ShowPlayerDialog(i, -1, DIALOG_STYLE_MSGBOX, "{00AAFF}Slip Gaji Kota Los Santos", slip, "Tutup", "");
            SendClientMessage(i, COLOR_LIME, "[BANK] Gaji berkala (Paycheck) Anda telah ditransfer ke rekening bank.");

            SavePlayerData(i);
        }
    }

    // Hitung Mundur Perang Wilayah Geng (Turf War Countdown)
    for (new t = 0; t < sizeof(g_TurfData); t++)
    {
        if (g_TurfData[t][turfUnderAttack])
        {
            g_TurfData[t][turfWarTimer] -= 60;
            if (g_TurfData[t][turfWarTimer] <= 0)
            {
                new new_owner = g_TurfData[t][turfAttacker];
                g_TurfData[t][turfOwner] = new_owner;
                g_TurfData[t][turfUnderAttack] = false;
                g_TurfData[t][turfAttacker] = 0;
                g_TurfData[t][turfWarTimer] = 0;

                GangZoneStopFlashForAll(g_TurfData[t][turfZoneID]);
                UpdateGangZoneColors();

                new f_att[48], broadcast[200];
                GetFactionName(new_owner, f_att, sizeof(f_att));
                format(broadcast, sizeof(broadcast), "[PERANG WILAYAH] Wilayah %s resmi DIKUASAI oleh geng %s!", g_TurfData[t][turfName], f_att);
                SendClientMessageToAll((new_owner == FACTION_GROVE) ? 0x00FF00AA : 0xAA00FFAA, broadcast);
            }
            else
            {
                new war_msg[160];
                format(war_msg, sizeof(war_msg), "[PERANG WILAYAH] Perebutan zona %s sedang berlangsung! Waktu tersisa: %d detik.", g_TurfData[t][turfName], g_TurfData[t][turfWarTimer]);
                for (new p = 0; p < MAX_PLAYERS; p++)
                {
                    if (IsPlayerConnected(p) && (PlayerData[p][pFaction] == FACTION_GROVE || PlayerData[p][pFaction] == FACTION_BALLAS || PlayerData[p][pAdmin] >= 1))
                    {
                        SendClientMessage(p, COLOR_YELLOW, war_msg);
                    }
                }
            }
        }
    }
    return 1;
}

// =============================================================================
// HELPER FUNCTIONS & STRING PARSER
// =============================================================================
stock GenerateSalt(dest[], size = sizeof(dest))
{
    new const charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (new i = 0; i < size - 1; i++)
    {
        dest[i] = charset[random(sizeof(charset) - 1)];
    }
    dest[size - 1] = '\0';
}

stock DB_Escape(const string[], output[], size = sizeof(output))
{
    new out_idx = 0;
    for (new i = 0; string[i] != '\0' && out_idx < size - 2; i++)
    {
        if (string[i] == '\'')
        {
            output[out_idx++] = '\'';
            output[out_idx++] = '\'';
        }
        else
        {
            output[out_idx++] = string[i];
        }
    }
    output[out_idx] = '\0';
}

stock GetPlayerNameEx(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

stock GetJobName(jobid)
{
    new name[40];
    switch (jobid)
    {
        case JOB_SWEEPER: format(name, sizeof(name), "Pembersih Jalan (Sweeper)");
        case JOB_BUS: format(name, sizeof(name), "Supir Bus Kota");
        case JOB_TRUCKER: format(name, sizeof(name), "Sopir Truk Kargo (Trucker)");
        default: format(name, sizeof(name), "Pengangguran / Belum Bekerja");
    }
    return name;
}

stock bool:IsTruckerVehicle(vehicleid)
{
    for (new i = 0; i < MAX_TRUCKER_VEHICLES; i++)
    {
        if (g_TruckerVehicles[i] == vehicleid) return true;
    }
    return false;
}

stock GetNearPlayerVehicle(playerid, Float:radius = 4.5)
{
    for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
    {
        if (OwnedVehicles[i][ovSpawned])
        {
            new veh = OwnedVehicles[i][ovVehicleID];
            new Float:vx, Float:vy, Float:vz;
            GetVehiclePos(veh, vx, vy, vz);
            if (IsPlayerInRangeOfPoint(playerid, radius, vx, vy, vz))
            {
                return i;
            }
        }
    }
    return -1;
}

stock SaveVehicleTrunkData(slot)
{
    if (slot < 0 || slot >= MAX_OWNED_VEHICLES || !OwnedVehicles[slot][ovSpawned]) return 0;
    new query[256];
    format(query, sizeof(query),
        "UPDATE vehicles SET trunk_money = %d, trunk_weapon = %d, trunk_ammo = %d, trunk_pot = %d, trunk_crack = %d WHERE id = %d;",
        OwnedVehicles[slot][ovTrunkMoney],
        OwnedVehicles[slot][ovTrunkWeapon],
        OwnedVehicles[slot][ovTrunkAmmo],
        OwnedVehicles[slot][ovTrunkPot],
        OwnedVehicles[slot][ovTrunkCrack],
        OwnedVehicles[slot][ovDBID]
    );
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));
    return 1;
}

stock OpenTrunkMenu(playerid, slot)
{
    new title[64], list[450];
    format(title, sizeof(title), "{00AAFF}Bagasi Kendaraan (Plat: %s)", OwnedVehicles[slot][ovPlate]);
    new wep_name[32];
    GetWeaponName(WEAPON:OwnedVehicles[slot][ovTrunkWeapon], wep_name, sizeof(wep_name));
    if (OwnedVehicles[slot][ovTrunkWeapon] == 0) format(wep_name, sizeof(wep_name), "Kosong");

    format(list, sizeof(list),
        "Item Bagasi\tJumlah / Status\n"\
        "1. Uang Tunai (Cash)\t{00FF00}$%d\n"\
        "2. Senjata Api\t{FFFF00}%s (%d Peluru)\n"\
        "3. Narkoba Ganja (Pot)\t{00FF00}%d Gram\n"\
        "4. Narkoba Kokain (Crack)\t{00FF00}%d Gram\n"\
        "5. {FF0000}Tutup Pintu Bagasi\t{AFAFAF}Kunci Kembali",
        OwnedVehicles[slot][ovTrunkMoney],
        wep_name, OwnedVehicles[slot][ovTrunkAmmo],
        OwnedVehicles[slot][ovTrunkPot],
        OwnedVehicles[slot][ovTrunkCrack]
    );
    ShowPlayerDialog(playerid, DIALOG_TRUNK_MAIN, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Pilih", "Batal");
    return 1;
}

stock GetNextToken(const string[], &index, dest[], size = sizeof(dest))
{
    new length = strlen(string);
    while ((index < length) && (string[index] <= ' '))
    {
        index++;
    }

    new out_idx = 0;
    while ((index < length) && (string[index] > ' ') && (out_idx < size - 1))
    {
        dest[out_idx++] = string[index++];
    }
    dest[out_idx] = '\0';
}

stock IsPlayerNearATM(playerid)
{
    for (new i = 0; i < sizeof(g_ATM_Locations); i++)
    {
        if (IsPlayerInRangeOfPoint(playerid, 2.5, g_ATM_Locations[i][atmX], g_ATM_Locations[i][atmY], g_ATM_Locations[i][atmZ]))
        {
            return 1;
        }
    }
    return 0;
}

stock IsPlayerNearFood(playerid)
{
    for (new i = 0; i < sizeof(g_Food_Locations); i++)
    {
        if (IsPlayerInRangeOfPoint(playerid, 2.8, g_Food_Locations[i][foodX], g_Food_Locations[i][foodY], g_Food_Locations[i][foodZ]))
        {
            return 1;
        }
    }
    return 0;
}

stock IsSweeperVehicle(vehicleid)
{
    for (new i = 0; i < sizeof(g_SweeperVehicles); i++)
    {
        if (vehicleid == g_SweeperVehicles[i]) return 1;
    }
    return 0;
}

stock IsBusVehicle(vehicleid)
{
    for (new i = 0; i < sizeof(g_BusVehicles); i++)
    {
        if (vehicleid == g_BusVehicles[i]) return 1;
    }
    return 0;
}

// --- Faction Helper Functions (Tahap 8 & 9) ---
stock GetFactionName(factionid, dest[], size = sizeof(dest))
{
    switch (factionid)
    {
        case FACTION_POLICE: format(dest, size, "San Andreas Police Department (SAPD)");
        case FACTION_MEDIC:  format(dest, size, "San Andreas Medical Department (SAMD)");
        case FACTION_GROVE:  format(dest, size, "Grove Street Families (GSF)");
        case FACTION_BALLAS: format(dest, size, "Ballas Gang");
        default:             format(dest, size, "Warga Sipil");
    }
}

stock GetFactionRankName(faction, rank, dest[], size = sizeof(dest))
{
    if (faction == FACTION_POLICE)
    {
        switch (rank)
        {
            case 1: format(dest, size, "Cadet");
            case 2: format(dest, size, "Police Officer");
            case 3: format(dest, size, "Sergeant");
            case 4: format(dest, size, "Lieutenant");
            case 5: format(dest, size, "Chief of Police");
            default: format(dest, size, "Recruit");
        }
    }
    else if (faction == FACTION_MEDIC)
    {
        switch (rank)
        {
            case 1: format(dest, size, "Trainee Paramedic");
            case 2: format(dest, size, "Paramedic");
            case 3: format(dest, size, "Doctor");
            case 4: format(dest, size, "Surgeon");
            case 5: format(dest, size, "Hospital Director");
            default: format(dest, size, "Volunteer");
        }
    }
    else if (faction == FACTION_GROVE)
    {
        switch (rank)
        {
            case 1: format(dest, size, "Outsider");
            case 2: format(dest, size, "Hustler");
            case 3: format(dest, size, "Gangster");
            case 4: format(dest, size, "Underboss");
            case 5: format(dest, size, "OG / Kingpin");
            default: format(dest, size, "Homie");
        }
    }
    else if (faction == FACTION_BALLAS)
    {
        switch (rank)
        {
            case 1: format(dest, size, "Frontliner");
            case 2: format(dest, size, "Shooter");
            case 3: format(dest, size, "Enforcer");
            case 4: format(dest, size, "Warlord");
            case 5: format(dest, size, "Boss");
            default: format(dest, size, "Balla");
        }
    }
    else
    {
        format(dest, size, "Warga");
    }
}

stock IsPlayerNearPoliceLocker(playerid)
{
    return IsPlayerInRangeOfPoint(playerid, 3.0, 1552.0, -1678.0, 16.20);
}

stock IsPlayerNearMedicLocker(playerid)
{
    return IsPlayerInRangeOfPoint(playerid, 3.0, 1173.0, -1323.0, 15.40);
}

stock IsPlayerNearGroveLocker(playerid)
{
    return IsPlayerInRangeOfPoint(playerid, 3.0, 2495.30, -1668.50, 13.34);
}

stock IsPlayerNearBallasLocker(playerid)
{
    return IsPlayerInRangeOfPoint(playerid, 3.0, 1995.50, -1117.80, 27.10);
}

stock IsPlayerNearBlackMarket(playerid)
{
    return IsPlayerInRangeOfPoint(playerid, 3.0, 2352.00, -2005.00, 13.50);
}

stock GetPlayerTurfZone(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    for (new i = 0; i < sizeof(g_TurfData); i++)
    {
        if (px >= g_TurfData[i][turfMinX] && px <= g_TurfData[i][turfMaxX] &&
            py >= g_TurfData[i][turfMinY] && py <= g_TurfData[i][turfMaxY])
        {
            return i;
        }
    }
    return -1;
}

stock UpdateGangZoneColors()
{
    for (new i = 0; i < sizeof(g_TurfData); i++)
    {
        if (g_TurfData[i][turfZoneID] != -1)
        {
            new color;
            switch (g_TurfData[i][turfOwner])
            {
                case FACTION_GROVE:  color = 0x00FF0088;
                case FACTION_BALLAS: color = 0xAA00FF88;
                default:             color = 0x88888888;
            }
            GangZoneShowForAll(g_TurfData[i][turfZoneID], color);
        }
    }
}

stock IsPlayerNearJail(playerid)
{
    if (GetPlayerInterior(playerid) == 6 && IsPlayerInRangeOfPoint(playerid, 10.0, 264.62, 77.57, 1001.03))
    {
        return 1;
    }
    if (IsPlayerInRangeOfPoint(playerid, 6.0, 1554.0, -1675.0, 16.20))
    {
        return 1;
    }
    return 0;
}

stock GetFactionFromVehicle(vehicleid)
{
    for (new i = 0; i < g_TotalFactionVehicles; i++)
    {
        if (g_FactionVehicles[i][fvVehicleID] == vehicleid)
        {
            return g_FactionVehicles[i][fvFaction];
        }
    }
    return FACTION_NONE;
}

stock UpdatePlayerFactionBadge(playerid)
{
    if (PlayerData[playerid][pFactionLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(PlayerData[playerid][pFactionLabel]);
        PlayerData[playerid][pFactionLabel] = Text3D:INVALID_3DTEXT_ID;
    }

    if (PlayerData[playerid][pOnDuty])
    {
        new r_name[32];
        GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
        new badge[128];

        if (PlayerData[playerid][pFaction] == FACTION_POLICE)
        {
            format(badge, sizeof(badge), "{00AAFF}[SAPD: %s]", r_name);
            PlayerData[playerid][pFactionLabel] = Create3DTextLabel(badge, COLOR_WHITE, 0.0, 0.0, 0.35, 20.0, 0, true);
            Attach3DTextLabelToPlayer(PlayerData[playerid][pFactionLabel], playerid, 0.0, 0.0, 0.35);
        }
        else if (PlayerData[playerid][pFaction] == FACTION_MEDIC)
        {
            format(badge, sizeof(badge), "{FF0055}[SAMD: %s]", r_name);
            PlayerData[playerid][pFactionLabel] = Create3DTextLabel(badge, COLOR_WHITE, 0.0, 0.0, 0.35, 20.0, 0, true);
            Attach3DTextLabelToPlayer(PlayerData[playerid][pFactionLabel], playerid, 0.0, 0.0, 0.35);
        }
        else if (PlayerData[playerid][pFaction] == FACTION_GROVE)
        {
            format(badge, sizeof(badge), "{00FF00}[GROVE: %s]", r_name);
            PlayerData[playerid][pFactionLabel] = Create3DTextLabel(badge, COLOR_WHITE, 0.0, 0.0, 0.35, 20.0, 0, true);
            Attach3DTextLabelToPlayer(PlayerData[playerid][pFactionLabel], playerid, 0.0, 0.0, 0.35);
        }
        else if (PlayerData[playerid][pFaction] == FACTION_BALLAS)
        {
            format(badge, sizeof(badge), "{AA00FF}[BALLAS: %s]", r_name);
            PlayerData[playerid][pFactionLabel] = Create3DTextLabel(badge, COLOR_WHITE, 0.0, 0.0, 0.35, 20.0, 0, true);
            Attach3DTextLabelToPlayer(PlayerData[playerid][pFactionLabel], playerid, 0.0, 0.0, 0.35);
        }
    }
}

// =============================================================================
// KENDARAAN PRIBADI SYSTEM (DYNAMIC VEHICLE)
// =============================================================================
stock GetFreeVehicleSlot()
{
    for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
    {
        if (!OwnedVehicles[i][ovSpawned]) return i;
    }
    return -1;
}

stock GetVehicleSlotFromID(vehicleid)
{
    if (vehicleid == INVALID_VEHICLE_ID) return -1;
    for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
    {
        if (OwnedVehicles[i][ovSpawned] && OwnedVehicles[i][ovVehicleID] == vehicleid)
        {
            return i;
        }
    }
    return -1;
}

stock GetPlayerOwnedVehicleCount(playerid)
{
    new count = 0;
    for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
    {
        if (OwnedVehicles[i][ovSpawned] && OwnedVehicles[i][ovOwnerID] == PlayerData[playerid][pID])
        {
            count++;
        }
    }
    return count;
}

stock LoadPlayerVehicles(playerid)
{
    new query[160];
    format(query, sizeof(query), "SELECT * FROM vehicles WHERE owner_id = %d LIMIT 3;", PlayerData[playerid][pID]);
    new DBResult:res = DB_ExecuteQuery(g_DB, query);
    new rows = DB_GetRowCount(res);

    for (new r = 0; r < rows; r++)
    {
        new slot = GetFreeVehicleSlot();
        if (slot == -1) break;

        OwnedVehicles[slot][ovDBID] = DB_GetFieldIntByName(res, "id");
        OwnedVehicles[slot][ovOwnerID] = PlayerData[playerid][pID];
        OwnedVehicles[slot][ovModel] = DB_GetFieldIntByName(res, "model");
        OwnedVehicles[slot][ovColor1] = DB_GetFieldIntByName(res, "color1");
        OwnedVehicles[slot][ovColor2] = DB_GetFieldIntByName(res, "color2");
        OwnedVehicles[slot][ovPosX] = DB_GetFieldFloatByName(res, "pos_x");
        OwnedVehicles[slot][ovPosY] = DB_GetFieldFloatByName(res, "pos_y");
        OwnedVehicles[slot][ovPosZ] = DB_GetFieldFloatByName(res, "pos_z");
        OwnedVehicles[slot][ovAngle] = DB_GetFieldFloatByName(res, "angle");
        OwnedVehicles[slot][ovFuel] = DB_GetFieldFloatByName(res, "fuel");
        OwnedVehicles[slot][ovHealth] = DB_GetFieldFloatByName(res, "health");
        DB_GetFieldStringByName(res, "plate", OwnedVehicles[slot][ovPlate], 16);

        OwnedVehicles[slot][ovTrunkMoney] = DB_GetFieldIntByName(res, "trunk_money");
        OwnedVehicles[slot][ovTrunkWeapon] = DB_GetFieldIntByName(res, "trunk_weapon");
        OwnedVehicles[slot][ovTrunkAmmo] = DB_GetFieldIntByName(res, "trunk_ammo");
        OwnedVehicles[slot][ovTrunkPot] = DB_GetFieldIntByName(res, "trunk_pot");
        OwnedVehicles[slot][ovTrunkCrack] = DB_GetFieldIntByName(res, "trunk_crack");
        OwnedVehicles[slot][ovTrunkOpen] = false;

        OwnedVehicles[slot][ovLocked] = true;
        OwnedVehicles[slot][ovEngine] = false;

        new veh = CreateVehicle(OwnedVehicles[slot][ovModel],
            OwnedVehicles[slot][ovPosX], OwnedVehicles[slot][ovPosY], OwnedVehicles[slot][ovPosZ], OwnedVehicles[slot][ovAngle],
            OwnedVehicles[slot][ovColor1], OwnedVehicles[slot][ovColor2], -1
        );
        SetVehicleNumberPlate(veh, OwnedVehicles[slot][ovPlate]);
        SetVehicleHealth(veh, OwnedVehicles[slot][ovHealth]);
        SetVehicleParamsEx(veh, 0, 0, 0, 1, 0, 0, 0);

        OwnedVehicles[slot][ovVehicleID] = veh;
        OwnedVehicles[slot][ovSpawned] = true;

        DB_SelectNextRow(res);
    }
    DB_FreeResultSet(res);
}

public SaveVehicleData(slot)
{
    if (!OwnedVehicles[slot][ovSpawned]) return 0;

    new veh = OwnedVehicles[slot][ovVehicleID];
    GetVehiclePos(veh, OwnedVehicles[slot][ovPosX], OwnedVehicles[slot][ovPosY], OwnedVehicles[slot][ovPosZ]);
    GetVehicleZAngle(veh, OwnedVehicles[slot][ovAngle]);
    GetVehicleHealth(veh, OwnedVehicles[slot][ovHealth]);

    new query[350];
    format(query, sizeof(query),
        "UPDATE vehicles SET pos_x = %.4f, pos_y = %.4f, pos_z = %.4f, angle = %.4f, fuel = %.2f, health = %.2f \
        WHERE id = %d;",
        OwnedVehicles[slot][ovPosX], OwnedVehicles[slot][ovPosY], OwnedVehicles[slot][ovPosZ], OwnedVehicles[slot][ovAngle],
        OwnedVehicles[slot][ovFuel], OwnedVehicles[slot][ovHealth],
        OwnedVehicles[slot][ovDBID]
    );
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));
    return 1;
}

stock UnloadPlayerVehicles(playerid)
{
    for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
    {
        if (OwnedVehicles[i][ovSpawned] && OwnedVehicles[i][ovOwnerID] == PlayerData[playerid][pID])
        {
            SaveVehicleData(i);
            DestroyVehicle(OwnedVehicles[i][ovVehicleID]);
            OwnedVehicles[i][ovSpawned] = false;
            OwnedVehicles[i][ovVehicleID] = INVALID_VEHICLE_ID;
        }
    }
}

// =============================================================================
// SISTEM PROPERTI RUMAH (DYNAMIC HOUSES)
// =============================================================================
stock LoadAllHouses()
{
    new DBResult:res = DB_ExecuteQuery(g_DB, "SELECT * FROM houses LIMIT 50;");
    g_TotalHouses = DB_GetRowCount(res);

    for (new i = 0; i < g_TotalHouses; i++)
    {
        HouseData[i][hID] = DB_GetFieldIntByName(res, "id");
        HouseData[i][hOwnerID] = DB_GetFieldIntByName(res, "owner_id");
        HouseData[i][hPrice] = DB_GetFieldIntByName(res, "price");
        DB_GetFieldStringByName(res, "address", HouseData[i][hAddress], 48);
        HouseData[i][hEnterX] = DB_GetFieldFloatByName(res, "enter_x");
        HouseData[i][hEnterY] = DB_GetFieldFloatByName(res, "enter_y");
        HouseData[i][hEnterZ] = DB_GetFieldFloatByName(res, "enter_z");
        HouseData[i][hExitX] = DB_GetFieldFloatByName(res, "exit_x");
        HouseData[i][hExitY] = DB_GetFieldFloatByName(res, "exit_y");
        HouseData[i][hExitZ] = DB_GetFieldFloatByName(res, "exit_z");
        HouseData[i][hInterior] = DB_GetFieldIntByName(res, "interior");
        HouseData[i][hLocked] = (DB_GetFieldIntByName(res, "locked") == 1);
        HouseData[i][hSafeMoney] = DB_GetFieldIntByName(res, "safe_money");
        HouseData[i][hPickup] = 0;
        HouseData[i][hLabel] = Text3D:INVALID_3DTEXT_ID;
        HouseData[i][hExitPickup] = 0;
        HouseData[i][hExitLabel] = Text3D:INVALID_3DTEXT_ID;
        HouseData[i][hLoaded] = true;

        if (HouseData[i][hOwnerID] > 0)
        {
            new q[128];
            format(q, sizeof(q), "SELECT username FROM players WHERE id = %d LIMIT 1;", HouseData[i][hOwnerID]);
            new DBResult:pres = DB_ExecuteQuery(g_DB, q);
            if (DB_GetRowCount(pres) > 0)
            {
                DB_GetFieldStringByName(pres, "username", HouseData[i][hOwnerName], MAX_PLAYER_NAME);
            }
            else
            {
                format(HouseData[i][hOwnerName], MAX_PLAYER_NAME, "Warga");
            }
            DB_FreeResultSet(pres);
        }
        else
        {
            format(HouseData[i][hOwnerName], MAX_PLAYER_NAME, "Tidak Ada");
        }

        UpdateHouseLabel(i);
        DB_SelectNextRow(res);
    }
    DB_FreeResultSet(res);
    printf("[HOUSES] Berhasil memuat %d properti rumah dari database.", g_TotalHouses);
}

public UpdateHouseLabel(index)
{
    if (HouseData[index][hPickup] != 0)
    {
        DestroyPickup(HouseData[index][hPickup]);
        HouseData[index][hPickup] = 0;
    }
    if (HouseData[index][hLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(HouseData[index][hLabel]);
        HouseData[index][hLabel] = Text3D:INVALID_3DTEXT_ID;
    }
    if (HouseData[index][hExitPickup] != 0)
    {
        DestroyPickup(HouseData[index][hExitPickup]);
        HouseData[index][hExitPickup] = 0;
    }
    if (HouseData[index][hExitLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(HouseData[index][hExitLabel]);
        HouseData[index][hExitLabel] = Text3D:INVALID_3DTEXT_ID;
    }

    if (HouseData[index][hOwnerID] == 0)
    {
        HouseData[index][hPickup] = CreatePickup(1273, 1, HouseData[index][hEnterX], HouseData[index][hEnterY], HouseData[index][hEnterZ]);
        new text[256];
        format(text, sizeof(text),
            "{00FF00}[RUMAH DIJUAL]\n{FFFFFF}Alamat: %s\nHarga: {00FF00}$%d\n{FFFFFF}Gunakan {FFFF00}/buyhouse {FFFFFF}untuk membeli",
            HouseData[index][hAddress], HouseData[index][hPrice]
        );
        HouseData[index][hLabel] = Create3DTextLabel(text, COLOR_WHITE, HouseData[index][hEnterX], HouseData[index][hEnterY], HouseData[index][hEnterZ] + 0.6, 15.0, 0, true);
    }
    else
    {
        HouseData[index][hPickup] = CreatePickup(1272, 1, HouseData[index][hEnterX], HouseData[index][hEnterY], HouseData[index][hEnterZ]);
        new text[300];
        format(text, sizeof(text),
            "{00AAFF}[RUMAH PRIBADI]\n{FFFFFF}Pemilik: {FFFF00}%s\n{FFFFFF}Alamat: %s\nStatus: %s\n{FFFFFF}Tekan {FFFF00}[ENTER / F] {FFFFFF}atau ketik {FFFF00}/enter",
            HouseData[index][hOwnerName], HouseData[index][hAddress],
            HouseData[index][hLocked] ? ("{FF0000}Terkunci") : ("{00FF00}Terbuka")
        );
        HouseData[index][hLabel] = Create3DTextLabel(text, COLOR_WHITE, HouseData[index][hEnterX], HouseData[index][hEnterY], HouseData[index][hEnterZ] + 0.6, 15.0, 0, true);
    }

    // Label & Pickup di dalam rumah (Pintu Keluar Interior)
    HouseData[index][hExitPickup] = CreatePickup(1318, 1, HouseData[index][hExitX], HouseData[index][hExitY], HouseData[index][hExitZ], HouseData[index][hID] + 100);
    HouseData[index][hExitLabel] = Create3DTextLabel("{00AAFF}[PINTU KELUAR]\n{FFFFFF}Tekan {FFFF00}[ENTER / F] {FFFFFF}atau ketik {FFFF00}/exit", COLOR_WHITE, HouseData[index][hExitX], HouseData[index][hExitY], HouseData[index][hExitZ] + 0.6, 12.0, HouseData[index][hID] + 100, true);
}

public SaveHouseData(index)
{
    new query[450];
    format(query, sizeof(query),
        "UPDATE houses SET owner_id = %d, locked = %d, safe_money = %d, price = %d, address = '%s', enter_x = %f, enter_y = %f, enter_z = %f, exit_x = %f, exit_y = %f, exit_z = %f, interior = %d WHERE id = %d;",
        HouseData[index][hOwnerID], HouseData[index][hLocked] ? 1 : 0, HouseData[index][hSafeMoney], HouseData[index][hPrice],
        HouseData[index][hAddress],
        HouseData[index][hEnterX], HouseData[index][hEnterY], HouseData[index][hEnterZ],
        HouseData[index][hExitX], HouseData[index][hExitY], HouseData[index][hExitZ],
        HouseData[index][hInterior],
        HouseData[index][hID]
    );
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));
    return 1;
}

stock GetHouseInteriorPreset(preset_id, &interior, &Float:exit_x, &Float:exit_y, &Float:exit_z)
{
    switch (preset_id)
    {
        case 1: // Sederhana (Ganton Small)
        {
            interior = 3;
            exit_x = 2496.05; exit_y = -1695.17; exit_z = 1014.74;
        }
        case 2: // Menengah (Jefferson 2-Room)
        {
            interior = 2;
            exit_x = 2233.78; exit_y = -1115.17; exit_z = 1050.88;
        }
        case 3: // Modern Flat (Idlewood)
        {
            interior = 10;
            exit_x = 2262.83; exit_y = -1137.80; exit_z = 1050.63;
        }
        case 4: // Mewah / Richman Luxury Villa
        {
            interior = 5;
            exit_x = 140.28; exit_y = 1366.49; exit_z = 1083.86;
        }
        case 5: // Mansion Sultan (Madd Dogg)
        {
            interior = 5;
            exit_x = 1261.12; exit_y = -785.34; exit_z = 1091.91;
        }
        case 6: // Penthouse / High-End
        {
            interior = 15;
            exit_x = 295.14; exit_y = 1472.25; exit_z = 1080.26;
        }
        default:
        {
            interior = 3;
            exit_x = 2496.05; exit_y = -1695.17; exit_z = 1014.74;
        }
    }
}

stock GetHouseIndexByID(houseid)
{
    for (new i = 0; i < g_TotalHouses; i++)
    {
        if (HouseData[i][hID] == houseid) return i;
    }
    if (houseid >= 0 && houseid < g_TotalHouses) return houseid;
    return -1;
}

stock GetNearHouseEntrance(playerid)
{
    for (new i = 0; i < g_TotalHouses; i++)
    {
        if (IsPlayerInRangeOfPoint(playerid, 2.5, HouseData[i][hEnterX], HouseData[i][hEnterY], HouseData[i][hEnterZ]))
        {
            return i;
        }
    }
    return -1;
}

stock GetNearHouseExit(playerid)
{
    new vw = GetPlayerVirtualWorld(playerid);
    if (vw >= 101)
    {
        new house_id = vw - 100;
        for (new i = 0; i < g_TotalHouses; i++)
        {
            if (HouseData[i][hID] == house_id)
            {
                if (IsPlayerInRangeOfPoint(playerid, 4.5, HouseData[i][hExitX], HouseData[i][hExitY], HouseData[i][hExitZ]))
                {
                    return i;
                }
            }
        }
    }
    return -1;
}

stock GetCurrentHouseIndex(playerid)
{
    new vw = GetPlayerVirtualWorld(playerid);
    if (vw >= 101)
    {
        new house_id = vw - 100;
        for (new i = 0; i < g_TotalHouses; i++)
        {
            if (HouseData[i][hID] == house_id) return i;
        }
    }
    return -1;
}

stock DestroyHouse(index)
{
    if (index < 0 || index >= g_TotalHouses) return 0;

    new db_id = HouseData[index][hID];

    // 1. Hapus pickup dan label pintu masuk
    if (HouseData[index][hPickup] != 0)
    {
        DestroyPickup(HouseData[index][hPickup]);
        HouseData[index][hPickup] = 0;
    }
    if (HouseData[index][hLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(HouseData[index][hLabel]);
        HouseData[index][hLabel] = Text3D:INVALID_3DTEXT_ID;
    }

    // 2. Hapus pickup dan label pintu keluar interior
    if (HouseData[index][hExitPickup] != 0)
    {
        DestroyPickup(HouseData[index][hExitPickup]);
        HouseData[index][hExitPickup] = 0;
    }
    if (HouseData[index][hExitLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(HouseData[index][hExitLabel]);
        HouseData[index][hExitLabel] = Text3D:INVALID_3DTEXT_ID;
    }

    // 3. Eject seluruh pemain yang ada di dalam rumah ini
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn])
        {
            if (GetPlayerVirtualWorld(i) == (db_id + 100))
            {
                SetPlayerPos(i, HouseData[index][hEnterX], HouseData[index][hEnterY], HouseData[index][hEnterZ] + 0.5);
                SetPlayerInterior(i, 0);
                SetPlayerVirtualWorld(i, 0);
                PlayerData[i][pInterior] = 0;
                PlayerData[i][pVirtualWorld] = 0;
                SavePlayerData(i);
                SendClientMessage(i, COLOR_RED, "[RUMAH] Rumah ini telah dihapus oleh Administrator! Anda dipindahkan ke luar.");
            }
        }
    }

    // 4. Hapus dari SQLite Database
    new query[128];
    format(query, sizeof(query), "DELETE FROM houses WHERE id = %d;", db_id);
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));

    // 5. Geser array HouseData ke bawah
    for (new i = index; i < g_TotalHouses - 1; i++)
    {
        HouseData[i] = HouseData[i + 1];
    }

    // 6. Bersihkan slot terakhir
    HouseData[g_TotalHouses - 1][hID] = 0;
    HouseData[g_TotalHouses - 1][hOwnerID] = 0;
    HouseData[g_TotalHouses - 1][hPrice] = 0;
    HouseData[g_TotalHouses - 1][hAddress][0] = '\0';
    HouseData[g_TotalHouses - 1][hPickup] = 0;
    HouseData[g_TotalHouses - 1][hLabel] = Text3D:INVALID_3DTEXT_ID;
    HouseData[g_TotalHouses - 1][hExitPickup] = 0;
    HouseData[g_TotalHouses - 1][hExitLabel] = Text3D:INVALID_3DTEXT_ID;
    HouseData[g_TotalHouses - 1][hLoaded] = false;

    g_TotalHouses--;
    return 1;
}

// =============================================================================
// SISTEM PROPERTI BISNIS & TOKO (DYNAMIC BUSINESSES - TAHAP 10)
// =============================================================================
stock GetBusinessTypeName(type, dest[], size = sizeof(dest))
{
    switch (type)
    {
        case BIZ_TYPE_247: format(dest, size, "24/7 Supermarket");
        case BIZ_TYPE_ELECTRONIC: format(dest, size, "Toko Elektronik & Gadget");
        case BIZ_TYPE_RESTAURANT: format(dest, size, "Restoran & Diner Bar");
        default: format(dest, size, "Toko Bisnis Umum");
    }
}

stock GetBusinessInteriorPreset(type, &interior, &Float:exit_x, &Float:exit_y, &Float:exit_z)
{
    switch (type)
    {
        case BIZ_TYPE_247:
        {
            interior = 18;
            exit_x = -30.95; exit_y = -89.61; exit_z = 1003.55;
        }
        case BIZ_TYPE_ELECTRONIC:
        {
            interior = 6;
            exit_x = 372.35; exit_y = -131.65; exit_z = 1001.49;
        }
        case BIZ_TYPE_RESTAURANT:
        {
            interior = 17;
            exit_x = 452.92; exit_y = -18.23; exit_z = 1000.73;
        }
        default:
        {
            interior = 18;
            exit_x = -30.95; exit_y = -89.61; exit_z = 1003.55;
        }
    }
}

forward UpdateBusinessLabel(index);
public UpdateBusinessLabel(index)
{
    if (BizData[index][bPickup] != 0)
    {
        DestroyPickup(BizData[index][bPickup]);
        BizData[index][bPickup] = 0;
    }
    if (BizData[index][bLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(BizData[index][bLabel]);
        BizData[index][bLabel] = Text3D:INVALID_3DTEXT_ID;
    }
    if (BizData[index][bExitPickup] != 0)
    {
        DestroyPickup(BizData[index][bExitPickup]);
        BizData[index][bExitPickup] = 0;
    }
    if (BizData[index][bExitLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(BizData[index][bExitLabel]);
        BizData[index][bExitLabel] = Text3D:INVALID_3DTEXT_ID;
    }

    new type_name[32];
    GetBusinessTypeName(BizData[index][bType], type_name, sizeof(type_name));

    if (BizData[index][bOwnerID] == 0)
    {
        BizData[index][bPickup] = CreatePickup(1274, 1, BizData[index][bEnterX], BizData[index][bEnterY], BizData[index][bEnterZ]);
        new text[280];
        format(text, sizeof(text),
            "{00FF00}[BISNIS DIJUAL]\n{FFFFFF}Nama: {FFFF00}%s\n{FFFFFF}Kategori: %s\nHarga: {00FF00}$%d\n{FFFFFF}Ketik {FFFF00}/buybiz {FFFFFF}untuk membeli",
            BizData[index][bName], type_name, BizData[index][bPrice]
        );
        BizData[index][bLabel] = Create3DTextLabel(text, COLOR_WHITE, BizData[index][bEnterX], BizData[index][bEnterY], BizData[index][bEnterZ] + 0.6, 15.0, 0, true);
    }
    else
    {
        BizData[index][bPickup] = CreatePickup(1314, 1, BizData[index][bEnterX], BizData[index][bEnterY], BizData[index][bEnterZ]);
        new text[320];
        format(text, sizeof(text),
            "{00AAFF}[PROPERTI BISNIS]\n{FFFFFF}Nama: {FFFF00}%s\n{FFFFFF}Pemilik: {00FF00}%s\n{FFFFFF}Kategori: %s\nStatus: %s\n{FFFFFF}Tekan {FFFF00}[ENTER / F] {FFFFFF}atau {FFFF00}/enter",
            BizData[index][bName], BizData[index][bOwnerName], type_name,
            BizData[index][bLocked] ? ("{FF0000}Tutup / Terkunci") : ("{00FF00}Buka")
        );
        BizData[index][bLabel] = Create3DTextLabel(text, COLOR_WHITE, BizData[index][bEnterX], BizData[index][bEnterY], BizData[index][bEnterZ] + 0.6, 15.0, 0, true);
    }

    // Pintu keluar di dalam bisnis (Virtual World = bID + 500)
    BizData[index][bExitPickup] = CreatePickup(1318, 1, BizData[index][bExitX], BizData[index][bExitY], BizData[index][bExitZ], BizData[index][bID] + 500);
    BizData[index][bExitLabel] = Create3DTextLabel("{00AAFF}[PINTU KELUAR BISNIS]\n{FFFFFF}Tekan {FFFF00}[ENTER / F] {FFFFFF}atau ketik {FFFF00}/exit\n{FFFFFF}Ketik {FFFF00}/buy {FFFFFF}untuk berbelanja", COLOR_WHITE, BizData[index][bExitX], BizData[index][bExitY], BizData[index][bExitZ] + 0.6, 12.0, BizData[index][bID] + 500, true);
}

forward SaveBusinessData(index);
public SaveBusinessData(index)
{
    new query[450];
    format(query, sizeof(query),
        "UPDATE businesses SET owner_id = %d, locked = %d, vault = %d, price = %d, name = '%s', enter_x = %f, enter_y = %f, enter_z = %f, exit_x = %f, exit_y = %f, exit_z = %f, interior = %d, type = %d WHERE id = %d;",
        BizData[index][bOwnerID], BizData[index][bLocked] ? 1 : 0, BizData[index][bVault], BizData[index][bPrice],
        BizData[index][bName],
        BizData[index][bEnterX], BizData[index][bEnterY], BizData[index][bEnterZ],
        BizData[index][bExitX], BizData[index][bExitY], BizData[index][bExitZ],
        BizData[index][bInterior], BizData[index][bType],
        BizData[index][bID]
    );
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));
    return 1;
}

stock LoadAllBusinesses()
{
    new DBResult:res = DB_ExecuteQuery(g_DB, "SELECT * FROM businesses LIMIT 30;");
    g_TotalBusinesses = DB_GetRowCount(res);

    for (new i = 0; i < g_TotalBusinesses; i++)
    {
        BizData[i][bID] = DB_GetFieldIntByName(res, "id");
        BizData[i][bOwnerID] = DB_GetFieldIntByName(res, "owner_id");
        BizData[i][bPrice] = DB_GetFieldIntByName(res, "price");
        DB_GetFieldStringByName(res, "name", BizData[i][bName], 48);
        BizData[i][bType] = DB_GetFieldIntByName(res, "type");
        BizData[i][bEnterX] = DB_GetFieldFloatByName(res, "enter_x");
        BizData[i][bEnterY] = DB_GetFieldFloatByName(res, "enter_y");
        BizData[i][bEnterZ] = DB_GetFieldFloatByName(res, "enter_z");
        BizData[i][bExitX] = DB_GetFieldFloatByName(res, "exit_x");
        BizData[i][bExitY] = DB_GetFieldFloatByName(res, "exit_y");
        BizData[i][bExitZ] = DB_GetFieldFloatByName(res, "exit_z");
        BizData[i][bInterior] = DB_GetFieldIntByName(res, "interior");
        BizData[i][bLocked] = (DB_GetFieldIntByName(res, "locked") == 1);
        BizData[i][bVault] = DB_GetFieldIntByName(res, "vault");
        BizData[i][bPickup] = 0;
        BizData[i][bLabel] = Text3D:INVALID_3DTEXT_ID;
        BizData[i][bExitPickup] = 0;
        BizData[i][bExitLabel] = Text3D:INVALID_3DTEXT_ID;
        BizData[i][bLoaded] = true;

        if (BizData[i][bOwnerID] > 0)
        {
            new q[128];
            format(q, sizeof(q), "SELECT username FROM players WHERE id = %d LIMIT 1;", BizData[i][bOwnerID]);
            new DBResult:pres = DB_ExecuteQuery(g_DB, q);
            if (DB_GetRowCount(pres) > 0)
            {
                DB_GetFieldStringByName(pres, "username", BizData[i][bOwnerName], MAX_PLAYER_NAME);
            }
            else
            {
                format(BizData[i][bOwnerName], MAX_PLAYER_NAME, "Warga");
            }
            DB_FreeResultSet(pres);
        }
        else
        {
            format(BizData[i][bOwnerName], MAX_PLAYER_NAME, "Pemerintah");
        }

        UpdateBusinessLabel(i);
        DB_SelectNextRow(res);
    }
    DB_FreeResultSet(res);
    printf("[BUSINESS] Berhasil memuat %d properti bisnis dari database.", g_TotalBusinesses);
    return 1;
}

stock GetBusinessIndexByID(bizid)
{
    for (new i = 0; i < g_TotalBusinesses; i++)
    {
        if (BizData[i][bID] == bizid) return i;
    }
    if (bizid >= 0 && bizid < g_TotalBusinesses) return bizid;
    return -1;
}

stock GetNearBusinessEntrance(playerid)
{
    for (new i = 0; i < g_TotalBusinesses; i++)
    {
        if (IsPlayerInRangeOfPoint(playerid, 2.5, BizData[i][bEnterX], BizData[i][bEnterY], BizData[i][bEnterZ]))
        {
            return i;
        }
    }
    return -1;
}

stock GetNearBusinessExit(playerid)
{
    new vw = GetPlayerVirtualWorld(playerid);
    if (vw >= 501)
    {
        new biz_id = vw - 500;
        for (new i = 0; i < g_TotalBusinesses; i++)
        {
            if (BizData[i][bID] == biz_id)
            {
                if (IsPlayerInRangeOfPoint(playerid, 5.0, BizData[i][bExitX], BizData[i][bExitY], BizData[i][bExitZ]))
                {
                    return i;
                }
            }
        }
    }
    return -1;
}

stock GetCurrentBusinessIndex(playerid)
{
    new vw = GetPlayerVirtualWorld(playerid);
    if (vw >= 501)
    {
        new biz_id = vw - 500;
        for (new i = 0; i < g_TotalBusinesses; i++)
        {
            if (BizData[i][bID] == biz_id) return i;
        }
    }
    return -1;
}

stock DestroyBusiness(index)
{
    if (index < 0 || index >= g_TotalBusinesses) return 0;

    new db_id = BizData[index][bID];

    if (BizData[index][bPickup] != 0)
    {
        DestroyPickup(BizData[index][bPickup]);
        BizData[index][bPickup] = 0;
    }
    if (BizData[index][bLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(BizData[index][bLabel]);
        BizData[index][bLabel] = Text3D:INVALID_3DTEXT_ID;
    }
    if (BizData[index][bExitPickup] != 0)
    {
        DestroyPickup(BizData[index][bExitPickup]);
        BizData[index][bExitPickup] = 0;
    }
    if (BizData[index][bExitLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(BizData[index][bExitLabel]);
        BizData[index][bExitLabel] = Text3D:INVALID_3DTEXT_ID;
    }

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn])
        {
            if (GetPlayerVirtualWorld(i) == (db_id + 500))
            {
                SetPlayerPos(i, BizData[index][bEnterX], BizData[index][bEnterY], BizData[index][bEnterZ] + 0.5);
                SetPlayerInterior(i, 0);
                SetPlayerVirtualWorld(i, 0);
                PlayerData[i][pInterior] = 0;
                PlayerData[i][pVirtualWorld] = 0;
                SavePlayerData(i);
                SendClientMessage(i, COLOR_RED, "[BISNIS] Tempat bisnis ini telah dihapus oleh Administrator! Anda dipindahkan ke luar.");
            }
        }
    }

    new query[128];
    format(query, sizeof(query), "DELETE FROM businesses WHERE id = %d;", db_id);
    DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));

    for (new i = index; i < g_TotalBusinesses - 1; i++)
    {
        BizData[i] = BizData[i + 1];
    }

    BizData[g_TotalBusinesses - 1][bID] = 0;
    BizData[g_TotalBusinesses - 1][bOwnerID] = 0;
    BizData[g_TotalBusinesses - 1][bPrice] = 0;
    BizData[g_TotalBusinesses - 1][bName][0] = '\0';
    BizData[g_TotalBusinesses - 1][bPickup] = 0;
    BizData[g_TotalBusinesses - 1][bLabel] = Text3D:INVALID_3DTEXT_ID;
    BizData[g_TotalBusinesses - 1][bExitPickup] = 0;
    BizData[g_TotalBusinesses - 1][bExitLabel] = Text3D:INVALID_3DTEXT_ID;
    BizData[g_TotalBusinesses - 1][bLoaded] = false;

    g_TotalBusinesses--;
    return 1;
}

// =============================================================================
// DATABASE: AUTHENTICATION & PLAYER DATA
// =============================================================================
public CheckPlayerAccount(playerid)
{
    if (!IsPlayerConnected(playerid)) return 0;

    new name[MAX_PLAYER_NAME], clean_name[MAX_PLAYER_NAME * 2];
    GetPlayerName(playerid, name, sizeof(name));
    DB_Escape(name, clean_name, sizeof(clean_name));

    new query[256];
    format(query, sizeof(query), "SELECT id, password, salt FROM players WHERE username = '%s' LIMIT 1;", clean_name);
    new DBResult:res = DB_ExecuteQuery(g_DB, query);

    if (DB_GetRowCount(res) > 0)
    {
        PlayerData[playerid][pID] = DB_GetFieldIntByName(res, "id");
        DB_GetFieldStringByName(res, "password", PlayerData[playerid][pPassword], 65);
        DB_GetFieldStringByName(res, "salt", PlayerData[playerid][pSalt], 17);
        DB_FreeResultSet(res);

        new str[300];
        format(str, sizeof(str),
            "{FFFFFF}Selamat datang kembali di {00AAFF}Open.mp Roleplay{FFFFFF}, {FFFF00}%s{FFFFFF}!\n\n\
            Akun Anda terdaftar di database server.\n\
            Silakan masukkan password untuk login:",
            name
        );
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{00AAFF}Roleplay - Login", str, "Masuk", "Keluar");
    }
    else
    {
        DB_FreeResultSet(res);

        new str[300];
        format(str, sizeof(str),
            "{FFFFFF}Selamat datang di {00AAFF}Open.mp Roleplay{FFFFFF}, {FFFF00}%s{FFFFFF}!\n\n\
            Nama Anda belum terdaftar di sistem kami.\n\
            Silakan buat password baru (minimal 5 karakter) untuk mendaftarkan akun:",
            name
        );
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{00AAFF}Roleplay - Register", str, "Daftar", "Keluar");
    }
    return 1;
}

public OnAccountCreated(playerid)
{
    if (!IsPlayerConnected(playerid)) return 0;

    new name[MAX_PLAYER_NAME], clean_name[MAX_PLAYER_NAME * 2];
    GetPlayerName(playerid, name, sizeof(name));
    DB_Escape(name, clean_name, sizeof(clean_name));

    new query[128];
    format(query, sizeof(query), "SELECT id FROM players WHERE username = '%s' LIMIT 1;", clean_name);
    new DBResult:res = DB_ExecuteQuery(g_DB, query);
    if (DB_GetRowCount(res) > 0)
    {
        PlayerData[playerid][pID] = DB_GetFieldIntByName(res, "id");
    }
    DB_FreeResultSet(res);
    return 1;
}

stock LoadPlayerData(playerid)
{
    new query[128];
    format(query, sizeof(query), "SELECT * FROM players WHERE id = %d LIMIT 1;", PlayerData[playerid][pID]);
    new DBResult:res = DB_ExecuteQuery(g_DB, query);

    if (DB_GetRowCount(res) > 0)
    {
        PlayerData[playerid][pScore] = DB_GetFieldIntByName(res, "score");
        PlayerData[playerid][pMoney] = DB_GetFieldIntByName(res, "money");
        PlayerData[playerid][pBank] = DB_GetFieldIntByName(res, "bank");
        PlayerData[playerid][pAdmin] = DB_GetFieldIntByName(res, "admin");
        PlayerData[playerid][pSkin] = DB_GetFieldIntByName(res, "skin");
        PlayerData[playerid][pHealth] = DB_GetFieldFloatByName(res, "health");
        PlayerData[playerid][pArmour] = DB_GetFieldFloatByName(res, "armour");
        PlayerData[playerid][pPosX] = DB_GetFieldFloatByName(res, "pos_x");
        PlayerData[playerid][pPosY] = DB_GetFieldFloatByName(res, "pos_y");
        PlayerData[playerid][pPosZ] = DB_GetFieldFloatByName(res, "pos_z");
        PlayerData[playerid][pAngle] = DB_GetFieldFloatByName(res, "angle");
        PlayerData[playerid][pInterior] = DB_GetFieldIntByName(res, "interior");
        PlayerData[playerid][pVirtualWorld] = DB_GetFieldIntByName(res, "world");
        PlayerData[playerid][pHunger] = DB_GetFieldIntByName(res, "hunger");
        PlayerData[playerid][pThirst] = DB_GetFieldIntByName(res, "thirst");
        PlayerData[playerid][pPaycheckTime] = DB_GetFieldIntByName(res, "paycheck_time");
        PlayerData[playerid][pJob] = DB_GetFieldIntByName(res, "job");
        PlayerData[playerid][pFaction] = DB_GetFieldIntByName(res, "faction");
        PlayerData[playerid][pFactionRank] = DB_GetFieldIntByName(res, "faction_rank");
        PlayerData[playerid][pJailTime] = DB_GetFieldIntByName(res, "jail_time");
        PlayerData[playerid][pPot] = DB_GetFieldIntByName(res, "pot");
        PlayerData[playerid][pCrack] = DB_GetFieldIntByName(res, "crack");
        PlayerData[playerid][pHasGPS] = DB_GetFieldIntByName(res, "has_gps");
        PlayerData[playerid][pHasMask] = DB_GetFieldIntByName(res, "has_mask");
        PlayerData[playerid][pCigarettes] = DB_GetFieldIntByName(res, "cigs");
        PlayerData[playerid][pMaskActive] = false;
        PlayerData[playerid][pRobCooldown] = 0;
        PlayerData[playerid][pOnDuty] = false;
        PlayerData[playerid][pCuffed] = false;
        PlayerData[playerid][pWantedLevel] = 0;
        PlayerData[playerid][pInjured] = false;
        PlayerData[playerid][pInjuredTimer] = 0;
        PlayerData[playerid][pFactionLabel] = Text3D:INVALID_3DTEXT_ID;

        if (PlayerData[playerid][pHunger] <= 0) PlayerData[playerid][pHunger] = 100;
        if (PlayerData[playerid][pThirst] <= 0) PlayerData[playerid][pThirst] = 100;

        // Auto grant admin Level 5 jika ini akun pertama di database
        if (PlayerData[playerid][pID] == 1 && PlayerData[playerid][pAdmin] < 5)
        {
            PlayerData[playerid][pAdmin] = 5;
        }

        if (PlayerData[playerid][pAdmin] >= 1)
        {
            SetAdminDuty(playerid, true);
        }

        SetPlayerScore(playerid, PlayerData[playerid][pScore]);
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, PlayerData[playerid][pMoney]);
        SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);

        PlayerData[playerid][pLoggedIn] = true;

        LoadPlayerVehicles(playerid);
    }
    DB_FreeResultSet(res);
}

public SavePlayerData(playerid)
{
    if (!PlayerData[playerid][pLoggedIn]) return 0;

    if (GetPlayerState(playerid) != PLAYER_STATE_WASTED && GetPlayerState(playerid) != PLAYER_STATE_NONE)
    {
        GetPlayerPos(playerid, PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ]);
        GetPlayerFacingAngle(playerid, PlayerData[playerid][pAngle]);
        GetPlayerHealth(playerid, PlayerData[playerid][pHealth]);
        GetPlayerArmour(playerid, PlayerData[playerid][pArmour]);
        PlayerData[playerid][pInterior] = GetPlayerInterior(playerid);
        PlayerData[playerid][pVirtualWorld] = GetPlayerVirtualWorld(playerid);
    }

    PlayerData[playerid][pMoney] = GetPlayerMoney(playerid);
    PlayerData[playerid][pScore] = GetPlayerScore(playerid);

    new query[700];
    format(query, sizeof(query),
        "UPDATE players SET \
        score = %d, money = %d, bank = %d, admin = %d, skin = %d, \
        health = %.2f, armour = %.2f, pos_x = %.4f, pos_y = %.4f, pos_z = %.4f, \
        angle = %.4f, interior = %d, world = %d, hunger = %d, thirst = %d, paycheck_time = %d, job = %d, \
        faction = %d, faction_rank = %d, jail_time = %d, pot = %d, crack = %d, has_gps = %d, has_mask = %d, cigs = %d \
        WHERE id = %d;",
        PlayerData[playerid][pScore],
        PlayerData[playerid][pMoney],
        PlayerData[playerid][pBank],
        PlayerData[playerid][pAdmin],
        PlayerData[playerid][pSkin],
        PlayerData[playerid][pHealth],
        PlayerData[playerid][pArmour],
        PlayerData[playerid][pPosX],
        PlayerData[playerid][pPosY],
        PlayerData[playerid][pPosZ],
        PlayerData[playerid][pAngle],
        PlayerData[playerid][pInterior],
        PlayerData[playerid][pVirtualWorld],
        PlayerData[playerid][pHunger],
        PlayerData[playerid][pThirst],
        PlayerData[playerid][pPaycheckTime],
        PlayerData[playerid][pJob],
        PlayerData[playerid][pFaction],
        PlayerData[playerid][pFactionRank],
        PlayerData[playerid][pJailTime],
        PlayerData[playerid][pPot],
        PlayerData[playerid][pCrack],
        PlayerData[playerid][pHasGPS],
        PlayerData[playerid][pHasMask],
        PlayerData[playerid][pCigarettes],
        PlayerData[playerid][pID]
    );

    DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));
    return 1;
}

// =============================================================================
// MENUS: ATM, RESTORAN, JOB AGENCY, DEALERSHIP, BRANKAS, TELEPORT
// =============================================================================
stock OpenATMMenu(playerid)
{
    new title[64], list[256];
    format(title, sizeof(title), "{00AAFF}ATM SAN ANDREAS (Saldo: $%d)", PlayerData[playerid][pBank]);
    format(list, sizeof(list),
        "1. Cek Saldo Rekening\n\
        2. Tarik Uang Tunai (Withdraw)\n\
        3. Setor Uang Tunai (Deposit)\n\
        4. Transfer Antar Rekening"
    );
    ShowPlayerDialog(playerid, DIALOG_ATM_MAIN, DIALOG_STYLE_LIST, title, list, "Pilih", "Batal");
    return 1;
}

stock OpenFoodMenu(playerid)
{
    new menu[400];
    format(menu, sizeof(menu),
        "Menu Makanan / Minuman\tHarga\tKhasiat\n\
        {FFFFFF}Burger Daging Lezat\t{00FF00}$15\t{33CCFF}+35 Lapar & +10 Darah\n\
        {FFFFFF}Pizza Pepperoni Jumbo\t{00FF00}$20\t{33CCFF}+50 Lapar & +15 Darah\n\
        {FFFFFF}Ayam Crispy Special\t{00FF00}$18\t{33CCFF}+40 Lapar & +12 Darah\n\
        {FFFFFF}Air Mineral Dingin\t{00FF00}$5\t{33CCFF}+40 Haus\n\
        {FFFFFF}Soda Kaleng Segar\t{00FF00}$8\t{33CCFF}+30 Haus & +5 Darah"
    );
    ShowPlayerDialog(playerid, DIALOG_RESTAURANT, DIALOG_STYLE_TABLIST_HEADERS, "{FF9900}Restoran - Menu Makanan", menu, "Beli", "Batal");
    return 1;
}

stock OpenJobAgencyMenu(playerid)
{
    new title[64], list[450];
    format(title, sizeof(title), "{00AAFF}Pusat Lowongan Kerja (Pekerjaan Anda: %s)", GetJobName(PlayerData[playerid][pJob]));
    format(list, sizeof(list),
        "Pekerjaan\tGaji Estimasi\n"\
        "{FFFFFF}Pembersih Jalan (Sweeper)\t{00FF00}$320 / Rute\n"\
        "{FFFFFF}Supir Bus Kota (Bus Driver)\t{00FF00}$450 / Rute\n"\
        "{FFFFFF}Sopir Truk Kargo (Trucker)\t{00FF00}$650 - $1,150 / Rute\n"\
        "{FF0000}Berhenti Bekerja (Resign)\t{AFAFAF}Kembali Menganggur"
    );
    ShowPlayerDialog(playerid, DIALOG_JOB_AGENCY, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Pilih", "Batal");
    return 1;
}

stock OpenDealershipMenu(playerid)
{
    new list[500];
    format(list, sizeof(list), "Kendaraan\tHarga\n");
    for (new i = 0; i < sizeof(g_DealerCatalog); i++)
    {
        new row[80];
        format(row, sizeof(row), "{FFFFFF}%s\t{00FF00}$%d\n", g_DealerCatalog[i][dvName], g_DealerCatalog[i][dvPrice]);
        strcat(list, row);
    }
    ShowPlayerDialog(playerid, DIALOG_DEALERSHIP, DIALOG_STYLE_TABLIST_HEADERS, "{00AAFF}Showroom Kendaraan Los Santos", list, "Beli", "Batal");
    return 1;
}

stock OpenHouseSafeMenu(playerid, h_idx)
{
    new title[64], list[200];
    format(title, sizeof(title), "{00AAFF}Brankas Rumah (Uang: $%d)", HouseData[h_idx][hSafeMoney]);
    format(list, sizeof(list),
        "1. Simpan Uang ke Brankas\n\
        2. Ambil Uang dari Brankas"
    );
    ShowPlayerDialog(playerid, DIALOG_HOUSE_SAFE_MAIN, DIALOG_STYLE_LIST, title, list, "Pilih", "Tutup");
    return 1;
}

stock OpenAdminTeleportMenu(playerid)
{
    new list[600];
    for (new i = 0; i < sizeof(g_TeleportLocations); i++)
    {
        new row[80];
        format(row, sizeof(row), "{FFFF00}%d.{FFFFFF} %s\n", i + 1, g_TeleportLocations[i][tpName]);
        strcat(list, row);
    }
    ShowPlayerDialog(playerid, DIALOG_ADMIN_TP, DIALOG_STYLE_LIST, "{00AAFF}Teleportasi Cepat Admin (Navigasi)", list, "Teleport", "Batal");
    return 1;
}

stock OpenPoliceDutyMenu(playerid)
{
    new title[64], list[300], r_name[32];
    GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
    format(title, sizeof(title), "{00AAFF}Loker Kepolisian SAPD (%s)", r_name);

    if (!PlayerData[playerid][pOnDuty])
    {
        format(list, sizeof(list),
            "{00FF00}1. Masuk Dinas (On-Duty)\n\
            {FFFFFF}   * Seragam Polisi Dinas\n\
            {FFFFFF}   * Rompi Pelindung Kevlar 100%%\n\
            {FFFFFF}   * Senjata: Tongkat, Deagle, Shotgun, MP5\n\
            {AFAFAF}2. Batalkan"
        );
    }
    else
    {
        format(list, sizeof(list),
            "{FF0000}1. Selesai Dinas (Off-Duty)\n\
            {FFFFFF}   * Kembalikan Seragam & Senjata Dinas\n\
            {FFFFFF}   * Lepas Rompi Kevlar\n\
            {AFAFAF}2. Batalkan"
        );
    }
    ShowPlayerDialog(playerid, DIALOG_POLICE_DUTY, DIALOG_STYLE_LIST, title, list, "Pilih", "Batal");
    return 1;
}

stock OpenMedicDutyMenu(playerid)
{
    new title[64], list[300], r_name[32];
    GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
    format(title, sizeof(title), "{FF0055}Loker Medis SAMD (%s)", r_name);

    if (!PlayerData[playerid][pOnDuty])
    {
        format(list, sizeof(list),
            "{00FF00}1. Masuk Dinas Medis (On-Duty)\n\
            {FFFFFF}   * Seragam Dokter / Paramedis\n\
            {FFFFFF}   * Peralatan Medis & Kotak P3K\n\
            {FFFFFF}   * Memulihkan Kesehatan 100%%\n\
            {AFAFAF}2. Batalkan"
        );
    }
    else
    {
        format(list, sizeof(list),
            "{FF0000}1. Selesai Dinas Medis (Off-Duty)\n\
            {FFFFFF}   * Kembalikan Seragam Medis\n\
            {AFAFAF}2. Batalkan"
        );
    }
    ShowPlayerDialog(playerid, DIALOG_MEDIC_DUTY, DIALOG_STYLE_LIST, title, list, "Pilih", "Batal");
    return 1;
}

stock Open911Menu(playerid)
{
    new list[256];
    format(list, sizeof(list),
        "{00AAFF}1. Kantor Kepolisian (SAPD) {FFFFFF}- Kejahatan, Pembegalan, Teror, Kerusuhan\n\
        {FF0055}2. Ambulans & Rumah Sakit (SAMD) {FFFFFF}- Kecelakaan, Korban Pingsan, Bencana"
    );
    ShowPlayerDialog(playerid, DIALOG_CALL_911, DIALOG_STYLE_LIST, "{FF9900}Layanan Darurat San Andreas (911)", list, "Pilih", "Batal");
    return 1;
}

stock ShowAllCommandsDialog(playerid)
{
    new text[1500];
    format(text, sizeof(text),
        "{00AAFF}=== DAFTAR LENGKAP PERINTAH SERVER (/CMDS) ==={FFFFFF}\n\n"\
        "{00FF00}[1. AKUN & CHAT ROLEPLAY]{FFFFFF}\n"\
        "{FFFF00}/stats{FFFFFF}  {FFFF00}/pay{FFFFFF}  {FFFF00}/savemypos{FFFFFF}  {FFFF00}/stuck{FFFFFF}  {FFFF00}/stuck spawn{FFFFFF}  {FFFF00}/help{FFFFFF}  {FFFF00}/cmds{FFFFFF}\n"\
        "{FFFF00}/me{FFFFFF}  {FFFF00}/do{FFFFFF}  {FFFF00}/b{FFFFFF}  {FFFF00}/ooc{FFFFFF}\n\n"\
        "{00FF00}[2. KENDARAAN PRIBADI]{FFFFFF}\n"\
        "{FFFF00}/buyvehicle{FFFFFF}  {FFFF00}/myveh{FFFFFF}  {FFFF00}/engine{FFFFFF}  {FFFF00}/lock{FFFFFF}  {FFFF00}/park{FFFFFF}  {FFFF00}/refuel{FFFFFF}\n\n"\
        "{00FF00}[3. RUMAH PRIBADI]{FFFFFF}\n"\
        "{FFFF00}/buyhouse{FFFFFF}  {FFFF00}/enter{FFFFFF}  {FFFF00}/exit{FFFFFF}  {FFFF00}/houselock{FFFFFF} (/hl)  {FFFF00}/housesafe{FFFFFF} (/brankas)  {FFFF00}/myhouse{FFFFFF}\n\n"\
        "{00FF00}[4. PROPERTI BISNIS & TOKO]{FFFFFF}\n"\
        "{FFFF00}/buybiz{FFFFFF}  {FFFF00}/enter{FFFFFF}  {FFFF00}/exit{FFFFFF}  {FFFF00}/bizlock{FFFFFF} (/bl)  {FFFF00}/bizsafe{FFFFFF} (/bizvault)\n"\
        "{FFFF00}/bizinfo{FFFFFF}  {FFFF00}/mybiz{FFFFFF}  {FFFF00}/buy{FFFFFF}\n\n"\
        "{00FF00}[5. PEKERJAAN SAMPINGAN]{FFFFFF}\n"\
        "{FFFF00}/job{FFFFFF}  {FFFF00}/startjob{FFFFFF}  {FFFF00}/stopjob{FFFFFF} (Pembersih Jalan & Supir Bus Kota)\n\n"\
        "{00FF00}[6. FASILITAS UMUM & ITEM]{FFFFFF}\n"\
        "{FFFF00}/atm{FFFFFF}  {FFFF00}/buyfood{FFFFFF}  {FFFF00}/usegps{FFFFFF} (/gps)  {FFFF00}/usemask{FFFFFF} (/mask)  {FFFF00}/smokecigarette{FFFFFF} (/smoke)\n\n"\
        "{00AAFF}[7. KEPOLISIAN (SAPD) & MEDIS (SAMD)]{FFFFFF}\n"\
        "{FFFF00}/call 911{FFFFFF}  {FFFF00}/duty{FFFFFF}  {FFFF00}/r{FFFFFF}  {FFFF00}/d{FFFFFF}  {FFFF00}/m{FFFFFF}  {FFFF00}/cuff{FFFFFF}  {FFFF00}/uncuff{FFFFFF}  {FFFF00}/frisk{FFFFFF}\n"\
        "{FFFF00}/wanted{FFFFFF}  {FFFF00}/clearwanted{FFFFFF}  {FFFF00}/checkwanted{FFFFFF}  {FFFF00}/jail{FFFFFF}  {FFFF00}/unjail{FFFFFF}  {FFFF00}/heal{FFFFFF}  {FFFF00}/revive{FFFFFF}\n\n"\
        "{FF6600}[8. GENG JALANAN & PASAR GELAP]{FFFFFF}\n"\
        "{FFFF00}/duty{FFFFFF}  {FFFF00}/g{FFFFFF}  {FFFF00}/ganginfo{FFFFFF}  {FFFF00}/attackturf{FFFFFF}  {FFFF00}/turfinfo{FFFFFF}  {FFFF00}/buyblackmarket{FFFFFF}\n"\
        "{FFFF00}/usepot{FFFFFF}  {FFFF00}/usecrack{FFFFFF}  {FFFF00}/rob{FFFFFF}\n\n"\
        "{FFFF00}[9. ADMINISTRATOR & DEVELOPER]{FFFFFF}\n"\
        "{FFFF00}/ahelp{FFFFFF}  {FFFF00}/aduty{FFFFFF}  {FFFF00}/tp{FFFFFF}  Map Click Teleport  {FFFF00}/jp{FFFFFF}  {FFFF00}/veh{FFFFFF}  {FFFF00}/dv{FFFFFF}  {FFFF00}/heal{FFFFFF}\n"\
        "{FFFF00}/givemoney{FFFFFF}  {FFFF00}/setmoney{FFFFFF}  {FFFF00}/setbank{FFFFFF}  {FFFF00}/sethouse{FFFFFF}  {FFFF00}/createhouse{FFFFFF}  {FFFF00}/destroyhouse{FFFFFF}\n"\
        "{FFFF00}/setbiz{FFFFFF}  {FFFF00}/createbiz{FFFFFF}  {FFFF00}/destroybiz{FFFFFF}  {FFFF00}/makeadmin{FFFFFF}  {FFFF00}/setmyadmin{FFFFFF}  {FFFF00}/setfaction{FFFFFF}"
    );
    ShowPlayerDialog(playerid, DIALOG_HELP_ALL_CMDS, DIALOG_STYLE_MSGBOX, "{00AAFF}Daftar Seluruh Perintah Server", text, "Tutup", "Kembali");
    return 1;
}

stock OpenHelpMenu(playerid)
{
    new list[800];
    strcat(list, "1. Akun, Karakter & Chat Roleplay\t{00FF00}[Warga]\n");
    strcat(list, "2. Kendaraan Pribadi & Transportasi\t{00FF00}[Warga]\n");
    strcat(list, "3. Rumah, Properti & Brankas Uang\t{00FF00}[Warga]\n");
    strcat(list, "4. Properti Bisnis, Toko & Brankas Kas\t{00FF00}[Warga]\n");
    strcat(list, "5. Pekerjaan Sampingan & Paycheck\t{00FF00}[Warga]\n");
    strcat(list, "6. Fasilitas Umum & Item Perlengkapan\t{00FF00}[Warga]\n");
    strcat(list, "7. Faksi Pemerintahan (SAPD & SAMD)\t{00AAFF}[Faction]\n");
    strcat(list, "8. Geng Jalanan & Perang Wilayah\t{FF0000}[Gang]\n");
    strcat(list, "9. Bantuan Perintah Admin & Server\t{FFFF00}[Admin]\n");
    strcat(list, "10. Ringkasan Semua Perintah Server\t{00FFFF}[Commands]");

    ShowPlayerDialog(playerid, DIALOG_HELP, DIALOG_STYLE_TABLIST, "{00AAFF}Pusat Bantuan & Panduan Server (/help)", list, "Pilih", "Tutup");
    return 1;
}

stock OpenGroveDutyMenu(playerid)
{
    new title[64], list[300], r_name[32];
    GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
    format(title, sizeof(title), "{00FF00}Loker Persenjataan GSF (%s)", r_name);

    if (!PlayerData[playerid][pOnDuty])
    {
        format(list, sizeof(list),
            "{00FF00}1. Masuk Tugas Geng (On-Duty)\n\
            {FFFFFF}   * Kaos Hijau GSF Khas Ganton\n\
            {FFFFFF}   * Rompi Kevlar 100%%\n\
            {FFFFFF}   * Senjata: Baseball Bat, Deagle, Tec-9, AK-47\n\
            {AFAFAF}2. Batalkan"
        );
    }
    else
    {
        format(list, sizeof(list),
            "{FF0000}1. Selesai Tugas Geng (Off-Duty)\n\
            {FFFFFF}   * Kembalikan Senjata Geng & Rompi\n\
            {AFAFAF}2. Batalkan"
        );
    }
    ShowPlayerDialog(playerid, DIALOG_GROVE_LOCKER, DIALOG_STYLE_LIST, title, list, "Pilih", "Batal");
    return 1;
}

stock OpenBallasDutyMenu(playerid)
{
    new title[64], list[300], r_name[32];
    GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
    format(title, sizeof(title), "{AA00FF}Loker Persenjataan Ballas (%s)", r_name);

    if (!PlayerData[playerid][pOnDuty])
    {
        format(list, sizeof(list),
            "{00FF00}1. Masuk Tugas Geng (On-Duty)\n\
            {FFFFFF}   * Baju Ungu Khas Ballas Glen Park\n\
            {FFFFFF}   * Rompi Kevlar 100%%\n\
            {FFFFFF}   * Senjata: Baseball Bat, Deagle, Micro Uzi, AK-47\n\
            {AFAFAF}2. Batalkan"
        );
    }
    else
    {
        format(list, sizeof(list),
            "{FF0000}1. Selesai Tugas Geng (Off-Duty)\n\
            {FFFFFF}   * Kembalikan Senjata Geng & Rompi\n\
            {AFAFAF}2. Batalkan"
        );
    }
    ShowPlayerDialog(playerid, DIALOG_BALLAS_LOCKER, DIALOG_STYLE_LIST, title, list, "Pilih", "Batal");
    return 1;
}

stock OpenBlackMarketMenu(playerid)
{
    new list[500];
    format(list, sizeof(list),
        "Barang Ilegal\tKategori\tHarga\n\
        {FFFFFF}Pistol Silenced 9mm (100 Peluru)\t{FF9900}Senjata Api\t{00FF00}$600\n\
        {FFFFFF}Micro SMG / Uzi (250 Peluru)\t{FF9900}Senjata Api\t{00FF00}$1,200\n\
        {FFFFFF}AK-47 Assault Rifle (300 Peluru)\t{FF9900}Senjata Berat\t{00FF00}$2,500\n\
        {FFFFFF}Sniper Rifle Jarak Jauh (30 Peluru)\t{FF9900}Senjata Khusus\t{00FF00}$4,000\n\
        {00FF00}Paket Ganja / Pot (5 Gram)\t{33CCFF}Narkotika\t{00FF00}$150\n\
        {FF00FF}Paket Kokain / Crack (5 Gram)\t{33CCFF}Narkotika\t{00FF00}$300"
    );
    ShowPlayerDialog(playerid, DIALOG_BLACK_MARKET, DIALOG_STYLE_TABLIST_HEADERS, "{FF9900}Pasar Gelap Bawah Tanah (Black Market)", list, "Beli", "Batal");
    return 1;
}

// =============================================================================
// PLAYER CALLBACKS
// =============================================================================
public OnPlayerConnect(playerid)
{
    PlayerData[playerid][pID] = 0;
    PlayerData[playerid][pPassword][0] = '\0';
    PlayerData[playerid][pSalt][0] = '\0';
    PlayerData[playerid][pScore] = 1;
    PlayerData[playerid][pMoney] = 500;
    PlayerData[playerid][pBank] = 1500;
    PlayerData[playerid][pAdmin] = 0;
    PlayerData[playerid][pSkin] = 299;
    PlayerData[playerid][pHealth] = 100.0;
    PlayerData[playerid][pArmour] = 0.0;
    PlayerData[playerid][pPosX] = 1743.0804;
    PlayerData[playerid][pPosY] = -1863.8569;
    PlayerData[playerid][pPosZ] = 13.5781;
    PlayerData[playerid][pAngle] = 357.0;
    PlayerData[playerid][pInterior] = 0;
    PlayerData[playerid][pVirtualWorld] = 0;
    PlayerData[playerid][pLoggedIn] = false;
    PlayerData[playerid][pLoginAttempts] = 0;
    PlayerData[playerid][pHunger] = 100;
    PlayerData[playerid][pThirst] = 100;
    PlayerData[playerid][pPaycheckTime] = 0;
    PlayerData[playerid][pTransferTarget] = INVALID_PLAYER_ID;
    PlayerData[playerid][pJob] = JOB_NONE;
    PlayerData[playerid][pWorking] = false;
    PlayerData[playerid][pJobCheckpoint] = 0;
    PlayerData[playerid][pFaction] = FACTION_NONE;
    PlayerData[playerid][pFactionRank] = 0;
    PlayerData[playerid][pOnDuty] = false;
    PlayerData[playerid][pCuffed] = false;
    PlayerData[playerid][pJailTime] = 0;
    PlayerData[playerid][pWantedLevel] = 0;
    PlayerData[playerid][pWantedReason][0] = '\0';
    PlayerData[playerid][pInjured] = false;
    PlayerData[playerid][pInjuredTimer] = 0;
    PlayerData[playerid][pFactionLabel] = Text3D:INVALID_3DTEXT_ID;
    PlayerData[playerid][pPot] = 0;
    PlayerData[playerid][pCrack] = 0;
    PlayerData[playerid][pRobCooldown] = 0;
    PlayerData[playerid][pHasGPS] = 0;
    PlayerData[playerid][pHasMask] = 0;
    PlayerData[playerid][pMaskActive] = false;
    PlayerData[playerid][pCigarettes] = 0;
    PlayerData[playerid][pAdminDuty] = false;
    PlayerData[playerid][pAdminBadge] = Text3D:INVALID_3DTEXT_ID;
    PlayerData[playerid][pVehSellSlot] = -1;
    PlayerData[playerid][pVehSellPrice] = 0;
    PlayerData[playerid][pVehSellSeller] = INVALID_PLAYER_ID;
    PlayerData[playerid][pTruckerCargo] = 0;

    PlayerData[playerid][pSpeedoTD] = CreatePlayerTextDraw(playerid, 490.0, 360.0, "~y~Speed: ~w~0 KM/H~n~~g~Fuel: ~w~100%~n~~p~Engine: ~r~OFF  ~b~Lock: ~g~OPEN");
    PlayerTextDrawLetterSize(playerid, PlayerData[playerid][pSpeedoTD], 0.28, 1.20);
    PlayerTextDrawAlignment(playerid, PlayerData[playerid][pSpeedoTD], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, PlayerData[playerid][pSpeedoTD], COLOR_WHITE);
    PlayerTextDrawUseBox(playerid, PlayerData[playerid][pSpeedoTD], true);
    PlayerTextDrawBoxColour(playerid, PlayerData[playerid][pSpeedoTD], 0x00000099);
    PlayerTextDrawSetOutline(playerid, PlayerData[playerid][pSpeedoTD], 1);
    PlayerTextDrawBackgroundColour(playerid, PlayerData[playerid][pSpeedoTD], 0x000000FF);
    PlayerTextDrawFont(playerid, PlayerData[playerid][pSpeedoTD], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, PlayerData[playerid][pSpeedoTD], true);
    PlayerTextDrawTextSize(playerid, PlayerData[playerid][pSpeedoTD], 620.0, 75.0);

    TogglePlayerControllable(playerid, false);

    SetPlayerCameraPos(playerid, 1478.8953, -1720.1772, 35.5398);
    SetPlayerCameraLookAt(playerid, 1481.0, -1771.0, 15.3);

    CheckPlayerAccount(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (PlayerData[playerid][pAdminBadge] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(PlayerData[playerid][pAdminBadge]);
        PlayerData[playerid][pAdminBadge] = Text3D:INVALID_3DTEXT_ID;
    }

    if (PlayerData[playerid][pLoggedIn])
    {
        SavePlayerData(playerid);
        UnloadPlayerVehicles(playerid);
    }
    PlayerData[playerid][pLoggedIn] = false;
    PlayerData[playerid][pWorking] = false;

    if (PlayerData[playerid][pSpeedoTD] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, PlayerData[playerid][pSpeedoTD]);
        PlayerData[playerid][pSpeedoTD] = PlayerText:INVALID_TEXT_DRAW;
    }

    if (PlayerData[playerid][pFactionLabel] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(PlayerData[playerid][pFactionLabel]);
        PlayerData[playerid][pFactionLabel] = Text3D:INVALID_3DTEXT_ID;
    }
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    if (!PlayerData[playerid][pLoggedIn])
    {
        return 0;
    }
    SetSpawnInfo(playerid, NO_TEAM, PlayerData[playerid][pSkin],
        PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ],
        PlayerData[playerid][pAngle]
    );
    SpawnPlayer(playerid);
    return 0;
}

public OnPlayerSpawn(playerid)
{
    if (!PlayerData[playerid][pLoggedIn])
    {
        SendClientMessage(playerid, COLOR_RED, "Anda harus login terlebih dahulu!");
        Kick(playerid);
        return 0;
    }

    if (PlayerData[playerid][pInjured])
    {
        SetPlayerInterior(playerid, PlayerData[playerid][pInterior]);
        SetPlayerVirtualWorld(playerid, PlayerData[playerid][pVirtualWorld]);
        SetPlayerPos(playerid, PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ]);
        SetPlayerFacingAngle(playerid, PlayerData[playerid][pAngle]);
        SetPlayerHealth(playerid, 15.0);
        ApplyAnimation(playerid, "CRACK", "crckdeth2", 4.0, bool:true, bool:false, bool:false, bool:true, 0);
        TogglePlayerControllable(playerid, false);
        SendClientMessage(playerid, COLOR_RED, "[KONDISI SEKARAT] Anda sedang tidak berdaya. Hubungi /call 911 untuk memanggil paramedis!");
        return 1;
    }

    if (PlayerData[playerid][pJailTime] > 0)
    {
        SetPlayerPos(playerid, 264.62, 77.57, 1001.03);
        SetPlayerFacingAngle(playerid, 270.0);
        SetPlayerInterior(playerid, 6);
        SetPlayerVirtualWorld(playerid, 0);
        ResetPlayerWeapons(playerid);
        new j_msg[128];
        format(j_msg, sizeof(j_msg), "[PENJARA] Anda masih menjalani masa hukuman selama %d menit lagi.", PlayerData[playerid][pJailTime]);
        SendClientMessage(playerid, COLOR_RED, j_msg);
        return 1;
    }

    SetPlayerInterior(playerid, PlayerData[playerid][pInterior]);
    SetPlayerVirtualWorld(playerid, PlayerData[playerid][pVirtualWorld]);
    SetPlayerPos(playerid, PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ]);
    SetPlayerFacingAngle(playerid, PlayerData[playerid][pAngle]);
    SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);
    SetPlayerHealth(playerid, PlayerData[playerid][pHealth]);
    SetPlayerArmour(playerid, PlayerData[playerid][pArmour]);

    SetCameraBehindPlayer(playerid);
    TogglePlayerControllable(playerid, true);

    UpdateGangZoneColors();

    SendClientMessage(playerid, COLOR_GREEN, "Selamat datang di kota! Gunakan {FFFFFF}/help {33AA33}untuk melihat panduan.");
    if (PlayerData[playerid][pAdmin] >= 1)
    {
        new admin_msg[144];
        format(admin_msg, sizeof(admin_msg), "[ADMIN] Anda terdaftar sebagai Admin Level %d! Buka peta map & klik di mana saja untuk teleport instan, atau ketik /ahelp.", PlayerData[playerid][pAdmin]);
        SendClientMessage(playerid, COLOR_CYAN, admin_msg);
    }
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, WEAPON:weaponid, bodypart)
{
    if (PlayerData[playerid][pAdmin] >= 1 && PlayerData[playerid][pAdminDuty])
    {
        SetPlayerHealth(playerid, 100.0);
        return 0;
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    if (PlayerData[playerid][pAdmin] >= 1 && PlayerData[playerid][pAdminDuty])
    {
        SetPlayerHealth(playerid, 100.0);
        SetPlayerArmour(playerid, 100.0);
        ClearAnimations(playerid);
        TogglePlayerControllable(playerid, true);
        PlayerData[playerid][pInjured] = false;
        PlayerData[playerid][pInjuredTimer] = 0;
        SendClientMessage(playerid, COLOR_LIME, "[GOD MODE] Mode Dewa melindungi Anda dari kematian.");
        return 1;
    }

    GetPlayerPos(playerid, PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ]);
    GetPlayerFacingAngle(playerid, PlayerData[playerid][pAngle]);
    PlayerData[playerid][pInterior] = GetPlayerInterior(playerid);
    PlayerData[playerid][pVirtualWorld] = GetPlayerVirtualWorld(playerid);

    PlayerData[playerid][pInjured] = true;
    PlayerData[playerid][pInjuredTimer] = 180;

    if (PlayerData[playerid][pWorking])
    {
        PlayerData[playerid][pWorking] = false;
        PlayerData[playerid][pJobCheckpoint] = 0;
        PlayerData[playerid][pTruckerCargo] = 0;
        DisablePlayerCheckpoint(playerid);
        SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Tugas Anda dibatalkan karena Anda mengalami kecelakaan/pingsan.");
    }

    SendClientMessage(playerid, COLOR_RED, "[PINGSAN] Anda terluka parah dan tidak sadarkan diri!");
    SendClientMessage(playerid, COLOR_YELLOW, "[PETUNJUK] Gunakan /call 911 untuk memanggil ambulans (SAMD), atau tunggu bantuan tiba.");
    return 1;
}

// --- CLICK ON MAP TELEPORTASI INSTAN ADMIN ---
forward OnAdminMapTeleport(playerid, Float:fX, Float:fY, vehicleid);
public OnAdminMapTeleport(playerid, Float:fX, Float:fY, vehicleid)
{
    if (!IsPlayerConnected(playerid)) return 1;

    SetPlayerPosFindZ(playerid, fX, fY, 500.0);
    TogglePlayerControllable(playerid, true);

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    if (pz < 1.0)
    {
        SetPlayerPos(playerid, fX, fY, 15.0);
        pz = 15.0;
    }

    if (vehicleid != 0)
    {
        SetVehiclePos(vehicleid, fX, fY, pz + 1.0);
        PutPlayerInVehicle(playerid, vehicleid, 0);
    }

    PlayerData[playerid][pPosX] = fX;
    PlayerData[playerid][pPosY] = fY;
    PlayerData[playerid][pPosZ] = pz;
    SavePlayerData(playerid);
    return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
    if (PlayerData[playerid][pAdmin] >= 1)
    {
        new veh = 0;
        if (IsPlayerInAnyVehicle(playerid))
        {
            veh = GetPlayerVehicleID(playerid);
            LinkVehicleToInterior(veh, 0);
            SetVehicleVirtualWorld(veh, 0);
        }

        SetPlayerInterior(playerid, 0);
        SetPlayerVirtualWorld(playerid, 0);
        PlayerData[playerid][pInterior] = 0;
        PlayerData[playerid][pVirtualWorld] = 0;

        SetPlayerPos(playerid, fX, fY, 100.0);
        TogglePlayerControllable(playerid, false);

        SetTimerEx("OnAdminMapTeleport", 500, false, "iffi", playerid, fX, fY, veh);

        new msg[128];
        format(msg, sizeof(msg), "[TELEPORT] Teleportasi instan ke koordinat map (X: %.1f, Y: %.1f). Menyesuaikan daratan...", fX, fY);
        SendClientMessage(playerid, COLOR_LIME, msg);
        PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
        return 1;
    }
    return 1;
}

public OnPlayerUpdate(playerid)
{
    if (PlayerData[playerid][pLoggedIn])
    {
        if (PlayerData[playerid][pAdmin] >= 1 && PlayerData[playerid][pAdminDuty])
        {
            new Float:hp, Float:arm;
            GetPlayerHealth(playerid, hp);
            GetPlayerArmour(playerid, arm);
            if (hp < 100.0) SetPlayerHealth(playerid, 100.0);
            if (arm < 100.0) SetPlayerArmour(playerid, 100.0);
        }

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);
        if (pz < -25.0 && GetPlayerInterior(playerid) == 0)
        {
            SetPlayerVelocity(playerid, 0.0, 0.0, 0.0);
            SetPlayerPos(playerid, px, py, 15.0);
            SendClientMessage(playerid, COLOR_YELLOW, "[SYSTEM] Anda terdeteksi jatuh di bawah map. Karakter otomatis diangkat ke permukaan daratan.");
        }
    }
    return 1;
}

public OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
    if (newkeys & KEY_SECONDARY_ATTACK) // Tekan F atau ENTER
    {
        new h_in = GetNearHouseEntrance(playerid);
        if (h_in != -1)
        {
            if (HouseData[h_in][hLocked] && HouseData[h_in][hOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[RUMAH] Pintu rumah ini sedang terkunci!");
            }

            SetPlayerPos(playerid, HouseData[h_in][hExitX], HouseData[h_in][hExitY], HouseData[h_in][hExitZ]);
            SetPlayerInterior(playerid, HouseData[h_in][hInterior]);
            SetPlayerVirtualWorld(playerid, HouseData[h_in][hID] + 100);
            PlayerData[playerid][pInterior] = HouseData[h_in][hInterior];
            PlayerData[playerid][pVirtualWorld] = HouseData[h_in][hID] + 100;
            SavePlayerData(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "[RUMAH] Anda memasuki rumah. Tekan [ENTER / F] di dekat pintu atau ketik /exit untuk keluar.");
            return 1;
        }

        new h_out = GetNearHouseExit(playerid);
        if (h_out == -1)
        {
            new h_curr = GetCurrentHouseIndex(playerid);
            if (h_curr != -1 && IsPlayerInRangeOfPoint(playerid, 4.5, HouseData[h_curr][hExitX], HouseData[h_curr][hExitY], HouseData[h_curr][hExitZ]))
            {
                h_out = h_curr;
            }
        }

        if (h_out != -1)
        {
            SetPlayerPos(playerid, HouseData[h_out][hEnterX], HouseData[h_out][hEnterY], HouseData[h_out][hEnterZ]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            PlayerData[playerid][pInterior] = 0;
            PlayerData[playerid][pVirtualWorld] = 0;
            SavePlayerData(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "[RUMAH] Anda keluar dari rumah.");
            return 1;
        }

        new b_in = GetNearBusinessEntrance(playerid);
        if (b_in != -1)
        {
            if (BizData[b_in][bLocked] && BizData[b_in][bOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Pintu bisnis ini sedang tutup / terkunci!");
            }

            SetPlayerPos(playerid, BizData[b_in][bExitX], BizData[b_in][bExitY], BizData[b_in][bExitZ]);
            SetPlayerInterior(playerid, BizData[b_in][bInterior]);
            SetPlayerVirtualWorld(playerid, BizData[b_in][bID] + 500);
            PlayerData[playerid][pInterior] = BizData[b_in][bInterior];
            PlayerData[playerid][pVirtualWorld] = BizData[b_in][bID] + 500;
            SavePlayerData(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "[BISNIS] Anda memasuki bisnis. Ketik /buy untuk belanja atau /exit untuk keluar.");
            return 1;
        }

        new b_out = GetNearBusinessExit(playerid);
        if (b_out == -1)
        {
            new b_curr = GetCurrentBusinessIndex(playerid);
            if (b_curr != -1 && IsPlayerInRangeOfPoint(playerid, 4.5, BizData[b_curr][bExitX], BizData[b_curr][bExitY], BizData[b_curr][bExitZ]))
            {
                b_out = b_curr;
            }
        }

        if (b_out != -1)
        {
            SetPlayerPos(playerid, BizData[b_out][bEnterX], BizData[b_out][bEnterY], BizData[b_out][bEnterZ]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            PlayerData[playerid][pInterior] = 0;
            PlayerData[playerid][pVirtualWorld] = 0;
            SavePlayerData(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "[BISNIS] Anda keluar dari properti bisnis.");
            return 1;
        }

        if (IsPlayerNearATM(playerid))
        {
            OpenATMMenu(playerid);
            return 1;
        }
        if (IsPlayerNearFood(playerid))
        {
            OpenFoodMenu(playerid);
            return 1;
        }
        if (IsPlayerInRangeOfPoint(playerid, 3.0, 1481.04, -1772.31, 15.30))
        {
            OpenJobAgencyMenu(playerid);
            return 1;
        }
        if (IsPlayerInRangeOfPoint(playerid, 3.0, 1124.50, -1451.20, 15.80))
        {
            OpenDealershipMenu(playerid);
            return 1;
        }
        if (IsPlayerNearPoliceLocker(playerid))
        {
            if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[SAPD] Loker ini khusus untuk anggota kepolisian SAPD!");
            }
            OpenPoliceDutyMenu(playerid);
            return 1;
        }
        if (IsPlayerNearMedicLocker(playerid))
        {
            if (PlayerData[playerid][pFaction] != FACTION_MEDIC && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[SAMD] Loker ini khusus untuk petugas medis SAMD!");
            }
            OpenMedicDutyMenu(playerid);
            return 1;
        }
        if (IsPlayerNearGroveLocker(playerid))
        {
            if (PlayerData[playerid][pFaction] != FACTION_GROVE && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[GROVE] Loker ini khusus untuk anggota geng Grove Street Families!");
            }
            OpenGroveDutyMenu(playerid);
            return 1;
        }
        if (IsPlayerNearBallasLocker(playerid))
        {
            if (PlayerData[playerid][pFaction] != FACTION_BALLAS && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[BALLAS] Loker ini khusus untuk anggota geng Ballas Gang!");
            }
            OpenBallasDutyMenu(playerid);
            return 1;
        }
        if (IsPlayerNearBlackMarket(playerid))
        {
            if (PlayerData[playerid][pFaction] == FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[BLACK MARKET] Anggota kepolisian dilarang bertransaksi di pasar gelap!");
            }
            OpenBlackMarketMenu(playerid);
            return 1;
        }
    }
    return 1;
}

public OnPlayerStateChange(playerid, PLAYER_STATE:newstate, PLAYER_STATE:oldstate)
{
    if (newstate == PLAYER_STATE_DRIVER)
    {
        new vehicleid = GetPlayerVehicleID(playerid);

        if (IsTruckerVehicle(vehicleid))
        {
            if (PlayerData[playerid][pJob] != JOB_TRUCKER && PlayerData[playerid][pAdmin] == 0)
            {
                RemovePlayerFromVehicle(playerid);
                return SendClientMessage(playerid, COLOR_RED, "[AKSES DITOLAK] Truk kargo logistik ini khusus untuk pekerja Sopir Truk (Trucker)! Lamar di Balai Kota.");
            }
            if (!PlayerData[playerid][pWorking])
            {
                SendClientMessage(playerid, COLOR_YELLOW, "[TRUCKER] Ketik /startjob untuk memilih muatan kargo dan memulai rute pengiriman logistik.");
            }
        }

        new f_veh = GetFactionFromVehicle(vehicleid);
        if (f_veh != FACTION_NONE)
        {
            if (PlayerData[playerid][pFaction] != f_veh && PlayerData[playerid][pAdmin] == 0)
            {
                if (f_veh == FACTION_POLICE)
                {
                    SendClientMessage(playerid, COLOR_RED, "[AKSES DITOLAK] Kendaraan ini adalah armada dinas Kepolisian SAPD!");
                }
                else if (f_veh == FACTION_MEDIC)
                {
                    SendClientMessage(playerid, COLOR_RED, "[AKSES DITOLAK] Kendaraan ini adalah armada ambulans dinas Rumah Sakit SAMD!");
                }
                else if (f_veh == FACTION_GROVE)
                {
                    SendClientMessage(playerid, COLOR_RED, "[AKSES DITOLAK] Kendaraan ini adalah mobil geng Grove Street Families!");
                }
                else if (f_veh == FACTION_BALLAS)
                {
                    SendClientMessage(playerid, COLOR_RED, "[AKSES DITOLAK] Kendaraan ini adalah mobil geng Ballas Gang!");
                }
                RemovePlayerFromVehicle(playerid);
                return 1;
            }
            if (!PlayerData[playerid][pOnDuty] && PlayerData[playerid][pAdmin] == 0)
            {
                SendClientMessage(playerid, COLOR_RED, "[DINAS] Anda harus bertugas (/duty) terlebih dahulu di loker untuk mengendarai armada dinas!");
                RemovePlayerFromVehicle(playerid);
                return 1;
            }
        }

        if (IsSweeperVehicle(vehicleid))
        {
            if (PlayerData[playerid][pJob] != JOB_SWEEPER)
            {
                SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Kendaraan ini khusus untuk Pembersih Jalan! Lamar di Balai Kota (/job).");
                RemovePlayerFromVehicle(playerid);
                return 1;
            }
            if (!PlayerData[playerid][pWorking])
            {
                SendClientMessage(playerid, COLOR_YELLOW, "[TIPS] Anda di mobil Sweeper. Ketik {FFFFFF}/startjob {FFFF00}untuk mulai membersihkan jalan!");
            }
        }
        else if (IsBusVehicle(vehicleid))
        {
            if (PlayerData[playerid][pJob] != JOB_BUS)
            {
                SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Kendaraan ini khusus untuk Supir Bus Kota! Lamar di Balai Kota (/job).");
                RemovePlayerFromVehicle(playerid);
                return 1;
            }
            if (!PlayerData[playerid][pWorking])
            {
                SendClientMessage(playerid, COLOR_YELLOW, "[TIPS] Anda di Bus Kota. Ketik {FFFFFF}/startjob {FFFF00}untuk mulai melayani halte bus!");
            }
        }
        else
        {
            new slot = GetVehicleSlotFromID(vehicleid);
            if (slot != -1)
            {
                if (OwnedVehicles[slot][ovOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
                {
                    SendClientMessage(playerid, COLOR_YELLOW, "[KENDARAAN] Anda menaiki kendaraan milik orang lain.");
                }
                else
                {
                    SendClientMessage(playerid, COLOR_GREEN, "[KENDARAAN] Ini adalah kendaraan pribadi Anda. Ketik {FFFFFF}/engine {33AA33}untuk menyalakan mesin.");
                }
            }
        }
    }
    else if (oldstate == PLAYER_STATE_DRIVER && newstate == PLAYER_STATE_ONFOOT)
    {
        PlayerTextDrawHide(playerid, PlayerData[playerid][pSpeedoTD]);
        if (PlayerData[playerid][pWorking])
        {
            SendClientMessage(playerid, COLOR_ORANGE, "[PERINGATAN] Anda keluar dari kendaraan kerja! Segera kembali atau ketik /stopjob.");
        }
    }
    return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    if (!PlayerData[playerid][pWorking])
    {
        DisablePlayerCheckpoint(playerid);
        SendClientMessage(playerid, COLOR_GREEN, "[NAVIGASI] Anda telah sampai di tempat tujuan!");
        return 1;
    }

    if (PlayerData[playerid][pJob] == JOB_SWEEPER)
    {
        if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER || !IsSweeperVehicle(GetPlayerVehicleID(playerid)))
        {
            SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda harus berada di kendaraan Sweeper untuk membersihkan jalan!");
            return 1;
        }

        PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);
        PlayerData[playerid][pJobCheckpoint]++;

        if (PlayerData[playerid][pJobCheckpoint] >= sizeof(g_SweeperCheckpoints))
        {
            PlayerData[playerid][pWorking] = false;
            PlayerData[playerid][pJobCheckpoint] = 0;
            DisablePlayerCheckpoint(playerid);

            new salary = 320;
            GivePlayerMoney(playerid, salary);
            SavePlayerData(playerid);

            PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
            SendClientMessage(playerid, COLOR_LIME, "[SELESAI] Luar biasa! Seluruh rute pembersihan jalan telah selesai.");
            new msg[128];
            format(msg, sizeof(msg), "[GAJI] Anda menerima bayaran tunai sebesar $%d.", salary);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        new cp = PlayerData[playerid][pJobCheckpoint];
        SetPlayerCheckpoint(playerid, g_SweeperCheckpoints[cp][0], g_SweeperCheckpoints[cp][1], g_SweeperCheckpoints[cp][2], 4.0);

        new msg[128];
        format(msg, sizeof(msg), "[SWEEPER] Titik [%d/%d] selesai. Lanjutkan ke titik berikutnya!", cp, sizeof(g_SweeperCheckpoints));
        SendClientMessage(playerid, COLOR_CYAN, msg);
        return 1;
    }
    else if (PlayerData[playerid][pJob] == JOB_BUS)
    {
        if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER || !IsBusVehicle(GetPlayerVehicleID(playerid)))
        {
            SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda harus berada di Bus Kota untuk melayani halte!");
            return 1;
        }

        PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);
        PlayerData[playerid][pJobCheckpoint]++;

        if (PlayerData[playerid][pJobCheckpoint] >= sizeof(g_BusCheckpoints))
        {
            PlayerData[playerid][pWorking] = false;
            PlayerData[playerid][pJobCheckpoint] = 0;
            DisablePlayerCheckpoint(playerid);

            new salary = 450;
            GivePlayerMoney(playerid, salary);
            SavePlayerData(playerid);

            PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
            SendClientMessage(playerid, COLOR_LIME, "[SELESAI] Rute perjalanan bus kota telah selesai sepenuhnya.");
            new msg[128];
            format(msg, sizeof(msg), "[GAJI] Anda menerima bayaran tunai sebesar $%d atas jasa supir bus.", salary);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        new cp = PlayerData[playerid][pJobCheckpoint];
        SetPlayerCheckpoint(playerid, g_BusCheckpoints[cp][0], g_BusCheckpoints[cp][1], g_BusCheckpoints[cp][2], 5.0);

        new msg[128];
        format(msg, sizeof(msg), "[BUS] Halte [%d/%d] terlewati. Lanjutkan perjalanan ke halte berikutnya!", cp, sizeof(g_BusCheckpoints));
        SendClientMessage(playerid, COLOR_CYAN, msg);
        return 1;
    }
    return 1;
}

// =============================================================================
// DIALOG RESPONSE
// =============================================================================
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_REGISTER:
        {
            if (!response)
            {
                SendClientMessage(playerid, COLOR_RED, "Pendaftaran dibatalkan. Anda telah dikeluarkan dari server.");
                Kick(playerid);
                return 1;
            }

            if (strlen(inputtext) < 5 || strlen(inputtext) > 32)
            {
                new str[300];
                format(str, sizeof(str),
                    "{FF0000}ERROR: Password harus terdiri dari 5 hingga 32 karakter!{FFFFFF}\n\n\
                    Silakan masukkan kembali password Anda untuk mendaftar akun:"
                );
                ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{00AAFF}Roleplay - Register", str, "Daftar", "Keluar");
                return 1;
            }

            GenerateSalt(PlayerData[playerid][pSalt], 17);
            SHA256_Hash(inputtext, PlayerData[playerid][pSalt], PlayerData[playerid][pPassword], 65);

            new name[MAX_PLAYER_NAME], clean_name[MAX_PLAYER_NAME * 2];
            GetPlayerName(playerid, name, sizeof(name));
            DB_Escape(name, clean_name, sizeof(clean_name));

            new query[512];
            format(query, sizeof(query),
                "INSERT INTO players (username, password, salt, score, money, bank, skin, pos_x, pos_y, pos_z, angle, hunger, thirst, paycheck_time, job, admin) \
                VALUES ('%s', '%s', '%s', 1, 500, 1500, 299, 1743.0804, -1863.8569, 13.5781, 357.0, 100, 100, 0, 0, 5);",
                clean_name, PlayerData[playerid][pPassword], PlayerData[playerid][pSalt]
            );

            DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));
            OnAccountCreated(playerid);

            PlayerData[playerid][pScore] = 1;
            PlayerData[playerid][pMoney] = 500;
            PlayerData[playerid][pBank] = 1500;
            PlayerData[playerid][pSkin] = 299;
            PlayerData[playerid][pPosX] = 1743.0804;
            PlayerData[playerid][pPosY] = -1863.8569;
            PlayerData[playerid][pPosZ] = 13.5781;
            PlayerData[playerid][pAngle] = 357.0;
            PlayerData[playerid][pHealth] = 100.0;
            PlayerData[playerid][pArmour] = 0.0;
            PlayerData[playerid][pHunger] = 100;
            PlayerData[playerid][pThirst] = 100;
            PlayerData[playerid][pPaycheckTime] = 0;
            PlayerData[playerid][pJob] = JOB_NONE;
            PlayerData[playerid][pWorking] = false;
            PlayerData[playerid][pAdmin] = 5;
            PlayerData[playerid][pLoggedIn] = true;
            SetAdminDuty(playerid, true);

            ResetPlayerMoney(playerid);
            GivePlayerMoney(playerid, 500);
            SetPlayerScore(playerid, 1);

            SendClientMessage(playerid, COLOR_GREEN, "Pendaftaran berhasil! Akun Anda telah dibuat sebagai Server Admin.");
            SetSpawnInfo(playerid, NO_TEAM, PlayerData[playerid][pSkin],
                PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ],
                PlayerData[playerid][pAngle]
            );
            SpawnPlayer(playerid);
            return 1;
        }

        case DIALOG_LOGIN:
        {
            if (!response)
            {
                SendClientMessage(playerid, COLOR_RED, "Anda membatalkan login.");
                Kick(playerid);
                return 1;
            }

            new hash[65];
            SHA256_Hash(inputtext, PlayerData[playerid][pSalt], hash, sizeof(hash));

            if (strcmp(hash, PlayerData[playerid][pPassword]) == 0)
            {
                LoadPlayerData(playerid);
                SendClientMessage(playerid, COLOR_GREEN, "Login berhasil! Memuat karakter Anda...");

                SetSpawnInfo(playerid, NO_TEAM, PlayerData[playerid][pSkin],
                    PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ],
                    PlayerData[playerid][pAngle]
                );
                SpawnPlayer(playerid);
            }
            else
            {
                PlayerData[playerid][pLoginAttempts]++;
                if (PlayerData[playerid][pLoginAttempts] >= 3)
                {
                    SendClientMessage(playerid, COLOR_RED, "Anda telah salah memasukkan password 3 kali. Terputus dari server.");
                    Kick(playerid);
                    return 1;
                }

                new str[300];
                format(str, sizeof(str),
                    "{FF0000}ERROR: Password yang Anda masukkan salah! (Percobaan %d/3){FFFFFF}\n\n\
                    Silakan masukkan kembali password Anda untuk login:",
                    PlayerData[playerid][pLoginAttempts]
                );
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{00AAFF}Roleplay - Login", str, "Masuk", "Keluar");
            }
            return 1;
        }

        case DIALOG_ADMIN_TP:
        {
            if (!response) return 1;
            if (PlayerData[playerid][pAdmin] < 1) return 1;

            if (listitem >= 0 && listitem < sizeof(g_TeleportLocations))
            {
                SetPlayerPos(playerid, g_TeleportLocations[listitem][tpX], g_TeleportLocations[listitem][tpY], g_TeleportLocations[listitem][tpZ]);
                SetPlayerFacingAngle(playerid, g_TeleportLocations[listitem][tpAngle]);
                SetPlayerInterior(playerid, 0);
                SetPlayerVirtualWorld(playerid, 0);

                new msg[128];
                format(msg, sizeof(msg), "[TELEPORT] Anda telah diteleportasi ke: %s.", g_TeleportLocations[listitem][tpName]);
                SendClientMessage(playerid, COLOR_GREEN, msg);
                PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
            }
            return 1;
        }

                case DIALOG_HELP:
        {
            if (!response) return 1;

            switch (listitem)
            {
                case 0: // Akun & Karakter
                {
                    new text[800];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN AKUN, KARAKTER & CHAT ROLEPLAY ==={FFFFFF}\n\n"\
                        "{FFFF00}/stats{FFFFFF} - Melihat profil, faksi, skor, uang, dan status karakter\n"\
                        "{FFFF00}/savemypos{FFFFFF} - Menyimpan data dan koordinat posisi karakter secara manual\n"\
                        "{FFFF00}/stuck{FFFFFF} - Mengangkat karakter (+2m) & reset animasi jika tersangkut / bug\n"\
                        "{FFFF00}/stuck spawn{FFFFFF} - Menteleportasikan karakter ke Balai Kota jika terjebak interior\n"\
                        "{FFFF00}/pay [id] [jumlah]{FFFFFF} - Memberikan uang tunai kepada pemain di dekat Anda\n\n"\
                        "{00FF00}[PERINTAH CHAT ROLEPLAY]{FFFFFF}\n"\
                        "{FFFF00}/me [aksi]{FFFFFF} - Menjelaskan tindakan karakter (In-Character)\n"\
                        "{FFFF00}/do [kondisi]{FFFFFF} - Menjelaskan situasi lingkungan sekitar\n"\
                        "{FFFF00}/b [pesan]{FFFFFF} - Chat OOC (Out of Character) lokal\n"\
                        "{FFFF00}/ooc [pesan]{FFFFFF} - Chat OOC global ke seluruh pemain di server"
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_ACCOUNT, DIALOG_STYLE_MSGBOX, "{00AAFF}1. Akun & Karakter", text, "Tutup", "Kembali");
                }
                case 1: // Kendaraan Pribadi
                {
                    new text[950];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN KENDARAAN PRIBADI ==={FFFFFF}\n\n"\
                        "{FFFF00}/buyvehicle{FFFFFF} - Membuka showroom dealer mobil & motor di Commerce\n"\
                        "{FFFF00}/myveh{FFFFFF} - Melihat daftar semua kendaraan yang Anda miliki & statusnya\n"\
                        "{FFFF00}/engine{FFFFFF} (atau ~k~~VEHICLE_SUBMISSION~) - Menyalakan / mematikan mesin kendaraan\n"\
                        "{FFFF00}/lock{FFFFFF} - Mengunci / membuka kunci pintu kendaraan milik Anda\n"\
                        "{FFFF00}/park{FFFFFF} - Menyimpan posisi parkir permanen kendaraan Anda saat ini\n"\
                        "{FFFF00}/refuel{FFFFFF} - Mengisi bahan bakar bensin saat berada di SPBU\n"\
                        "{FFFF00}/trunk (/bagasi){FFFFFF} - Membuka bagasi untuk menyimpan/mengambil uang, senjata & narkoba\n"\
                        "{FFFF00}/vehsell [id] [harga]{FFFFFF} - Menjual kendaraan pribadi kepada pemain lain\n\n"\
                        "{00FF00}[PETUNJUK TAMBAHAN]{FFFFFF}\n"\
                        "* Speedometer di pojok kanan bawah memuat Kecepatan, Bensin, Status Mesin, dan Kunci.\n"\
                        "* Kendaraan akan mogok jika bensin habis atau mesin rusak parah."
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_VEHICLE, DIALOG_STYLE_MSGBOX, "{00AAFF}2. Kendaraan Pribadi", text, "Tutup", "Kembali");
                }
                case 2: // Rumah & Properti
                {
                    new text[800];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN RUMAH & PROPERTI ==={FFFFFF}\n\n"\
                        "{FFFF00}/buyhouse{FFFFFF} - Membeli rumah yang berstatus dijual (Pickup hijau di pintu)\n"\
                        "{FFFF00}/enter{FFFFFF} (atau [F / ENTER]) - Masuk ke dalam rumah\n"\
                        "{FFFF00}/exit{FFFFFF} (atau [F / ENTER]) - Keluar dari rumah (dilengkapi penanda panah keluar)\n"\
                        "{FFFF00}/houselock (/hl){FFFFFF} - Mengunci / membuka kunci pintu rumah pribadi\n"\
                        "{FFFF00}/housesafe (/brankas){FFFFFF} - Membuka brankas untuk menyimpan / menarik uang cash\n"\
                        "{FFFF00}/myhouse{FFFFFF} - Melihat informasi lengkap rumah yang Anda miliki\n\n"\
                        "{00FF00}[PETUNJUK TAMBAHAN]{FFFFFF}\n"\
                        "* Anda dapat mengetik /exit dari titik mana saja di dalam rumah jika tersesat."
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_HOUSE, DIALOG_STYLE_MSGBOX, "{00AAFF}3. Rumah & Properti", text, "Tutup", "Kembali");
                }
                case 3: // Properti Bisnis & Toko
                {
                    new text[900];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN PROPERTI BISNIS & TOKO ==={FFFFFF}\n\n"\
                        "{FFFF00}/buybiz{FFFFFF} - Membeli properti bisnis berpickup hijau yang dijual\n"\
                        "{FFFF00}/enter{FFFFFF} (atau [F / ENTER]) - Masuk ke dalam gedung bisnis\n"\
                        "{FFFF00}/exit{FFFFFF} (atau [F / ENTER]) - Keluar dari bisnis ke jalanan\n"\
                        "{FFFF00}/bizlock (/bl){FFFFFF} - Mengunci atau membuka pintu bisnis Anda\n"\
                        "{FFFF00}/bizsafe (/bizvault){FFFFFF} - Setor & tarik saldo kas brankas bisnis Anda\n"\
                        "{FFFF00}/bizinfo{FFFFFF} - Menampilkan informasi status, kategori & keuangan bisnis\n"\
                        "{FFFF00}/mybiz{FFFFFF} - Melihat daftar seluruh bisnis yang Anda miliki\n"\
                        "{FFFF00}/buy{FFFFFF} - Membuka katalog belanja di dalam Toko 24/7, Gadget, atau Restoran\n\n"\
                        "{00FF00}[KEUNTUNGAN EKONOMI]{FFFFFF}\n"\
                        "* 70% dari setiap pembelian pelanggan otomatis masuk ke brankas kas bisnis Anda!"
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_BIZ, DIALOG_STYLE_MSGBOX, "{00AAFF}4. Bisnis & Toko", text, "Tutup", "Kembali");
                }
                case 4: // Pekerjaan Sampingan
                {
                    new text[950];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN PEKERJAAN SAMPINGAN & PAYCHECK ==={FFFFFF}\n\n"\
                        "{FFFF00}/job{FFFFFF} - Pusat informasi lowongan pekerjaan di Balai Kota (City Hall)\n"\
                        "{FFFF00}/startjob{FFFFFF} - Memulai rute kerja saat berada di kendaraan dinas\n"\
                        "{FFFF00}/stopjob{FFFFFF} - Berhenti dan membatalkan pekerjaan yang sedang berjalan\n"\
                        "{FFFF00}/trucker (/tc){FFFFFF} - Saluran radio komunikasi CB antar sesama Sopir Truk\n\n"\
                        "{00FF00}[DAFTAR PEKERJAAN LEGAL]{FFFFFF}\n"\
                        "* {FFFF00}Pembersih Jalan (Sweeper){FFFFFF}: Di Stasiun Unity, menyapu 11 checkpoint ($320)\n"\
                        "* {FFFF00}Supir Bus (Bus Driver){FFFFFF}: Di halte bus Unity, melayani 12 halte ($450)\n"\
                        "* {FFFF00}Sopir Truk Kargo (Trucker){FFFFFF}: Di Ocean Docks, kirim 3 tipe muatan ($650 - $1,150)\n\n"\
                        "{00FF00}[SISTEM GAJI (PAYCHECK)]{FFFFFF}\n"\
                        "* Setiap 60 menit aktif bermain, Anda akan menerima gaji pokok, bunga simpanan bank,\n"\
                        "  serta potongan pajak secara otomatis ke rekening bank."
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_JOB, DIALOG_STYLE_MSGBOX, "{00AAFF}5. Pekerjaan & Paycheck", text, "Tutup", "Kembali");
                }
                case 5: // Fasilitas Umum & Item Perlengkapan
                {
                    new text[900];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN FASILITAS UMUM & ITEM PERLENGKAPAN ==={FFFFFF}\n\n"\
                        "{FFFF00}/atm{FFFFFF} (atau [F / ENTER]) - Layanan ATM Bank (Tarik, Setor, Transfer Rekening)\n"\
                        "{FFFF00}/buyfood{FFFFFF} (atau [F / ENTER]) - Restoran makanan cepat saji (Burger, Cluckin, Pizza)\n"\
                        "{FFFF00}/buy{FFFFFF} - Berbelanja barang kebutuhan di toko 24/7 atau Toko Elektronik\n"\
                        "{FFFF00}/usegps (/gps){FFFFFF} - Buka menu navigasi checkpoint radar ke fasilitas kota\n"\
                        "{FFFF00}/usemask (/mask){FFFFFF} - Menyamarkan nama karakter di chat IC menjadi Topeng_<ID>\n"\
                        "{FFFF00}/smokecigarette (/smoke){FFFFFF} - Menghisap sebatang rokok dengan animasi khusus\n\n"\
                        "{00FF00}[STATUS KEBUTUHAN KARAKTER]{FFFFFF}\n"\
                        "* Tingkat Lapar & Haus berkurang seiring waktu. Jika 0%, darah (HP) akan berkurang bertahap."
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_FACILITY, DIALOG_STYLE_MSGBOX, "{00AAFF}6. Fasilitas & Item", text, "Tutup", "Kembali");
                }
                case 6: // Faksi Kepolisian & Medis
                {
                    new text[850];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN FAKSI KEPOLISIAN (SAPD) & MEDIS (SAMD) ==={FFFFFF}\n\n"\
                        "{FFFF00}/call 911{FFFFFF} - Hotline darurat polisi atau ambulans jika butuh pertolongan\n"\
                        "{FFFF00}/duty{FFFFFF} - Masuk / selesai tugas dinas di loker HQ LSPD atau RS All Saints\n"\
                        "{FFFF00}/r [pesan]{FFFFFF} - Radio komunikasi internal faksi\n"\
                        "{FFFF00}/d [pesan]{FFFFFF} - Radio departemen gabungan antar polisi & medis\n"\
                        "{FFFF00}/m [pesan]{FFFFFF} - Pengeras suara (megaphone) kendaraan dinas\n"\
                        "{FFFF00}/cuff & /uncuff [id]{FFFFFF} - Memborgol / melepas borgol tersangka\n"\
                        "{FFFF00}/frisk [id]{FFFFFF} - Menggeledah barang bawaan (senjata, narkoba, uang)\n"\
                        "{FFFF00}/wanted [id] [1-6] [alasan]{FFFFFF} - Memberikan bintang buronan kepolisian\n"\
                        "{FFFF00}/clearwanted [id]{FFFFFF} - Menghapus status buronan warga\n"\
                        "{FFFF00}/checkwanted{FFFFFF} - Menampilkan daftar buronan aktif di server\n"\
                        "{FFFF00}/jail [id] [menit] [alasan]{FFFFFF} - Memenjarakan tersangka ke sel LSPD\n"\
                        "{FFFF00}/unjail [id]{FFFFFF} - Membebaskan tahanan dari penjara\n"\
                        "{FFFF00}/heal [id]{FFFFFF} - Paramedis mengobati luka & memulihkan darah pasien ($25)\n"\
                        "{FFFF00}/revive [id]{FFFFFF} - Paramedis menyelamatkan korban kritis/pingsan ($50)"
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_FACTION, DIALOG_STYLE_MSGBOX, "{00AAFF}7. Polisi & Medis", text, "Tutup", "Kembali");
                }
                case 7: // Geng & Turf War
                {
                    new text[850];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN GENG KRIMINAL & PERANG WILAYAH ==={FFFFFF}\n\n"\
                        "{FFFF00}/duty{FFFFFF} - Masuk tugas geng di HQ Grove Street (Ganton) atau Ballas (Glen Park)\n"\
                        "{FFFF00}/g [pesan]{FFFFFF} - Chat radio internal khusus anggota geng Anda\n"\
                        "{FFFF00}/ganginfo{FFFFFF} - Menampilkan info geng, pangkat, anggota online & stok narkoba\n"\
                        "{FFFF00}/attackturf [0/1/2]{FFFFFF} - Memulai perebutan wilayah (0: Ganton, 1: Glen Park, 2: Idlewood)\n"\
                        "{FFFF00}/turfinfo{FFFFFF} - Menampilkan status pemilik & situasi pertempuran seluruh wilayah\n"\
                        "{FFFF00}/buyblackmarket{FFFFFF} - Membeli senjata ilegal, ganja & kokain di Ocean Docks\n"\
                        "{FFFF00}/usepot{FFFFFF} - Mengisap ganja untuk memulihkan +20 HP (efek mabuk)\n"\
                        "{FFFF00}/usecrack{FFFFFF} - Mengonsumsi kokain untuk memulihkan +35 HP (wanted star bertambah)\n"\
                        "{FFFF00}/rob [id]{FFFFFF} - Merampok uang tunai pemain lain di sekitar (cooldown 10 menit)"
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_GANG, DIALOG_STYLE_MSGBOX, "{00AAFF}8. Geng & Turf War", text, "Tutup", "Kembali");
                }
                case 8: // Admin & Server
                {
                    new text[950];
                    format(text, sizeof(text),
                        "{00AAFF}=== BANTUAN PERINTAH ADMIN & DEVELOPER ==={FFFFFF}\n\n"\
                        "{FFFF00}/ahelp{FFFFFF} - Menampilkan daftar lengkap seluruh perintah administrasi\n"\
                        "{FFFF00}/aduty{FFFFFF} - Masuk/keluar dinas admin (Mengaktifkan/mematikan God Mode)\n"\
                        "{FFFF00}/tp / /teleport{FFFFFF} - Menu teleportasi cepat 13 lokasi populer (termasuk Richman)\n"\
                        "{FFFF00}Klik Peta Map (ESC -> MAP){FFFFFF} - Teleportasi instan aman ke mana saja di map\n"\
                        "{FFFF00}/jetpack (/jp){FFFFFF} - Memunculkan jetpack terbang bebas\n"\
                        "{FFFF00}/veh [modelid]{FFFFFF} - Spawn kendaraan instan & /dv untuk menghapus\n"\
                        "{FFFF00}/heal{FFFFFF} - Memulihkan 100%% HP, Armour, Lapar & Haus diri sendiri\n"\
                        "{FFFF00}/setmoney [id] [uang] [cash/bank]{FFFFFF} - Mengatur uang cash / rekening bank\n"\
                        "{FFFF00}/setbank [id] [uang]{FFFFFF} - Mengatur saldo bank pemain langsung\n"\
                        "{FFFF00}/givemoney [id] [uang]{FFFFFF} - Memberikan uang tunai kepada pemain\n"\
                        "{FFFF00}/sethouse [list/owner/price/pos/address/int/tp/lock/delete]{FFFFFF} - Manajemen rumah\n"\
                        "{FFFF00}/createhouse [harga] [tipe: 1-6] [alamat...]{FFFFFF} - Membuat rumah baru di posisi Anda\n"\
                        "{FFFF00}/destroyhouse [id]{FFFFFF} - Menghapus rumah permanen dari database\n"\
                        "{FFFF00}/setbiz [list/tp/price/owner/name/pos/lock/delete]{FFFFFF} - Manajemen bisnis server\n"\
                        "{FFFF00}/createbiz [harga] [tipe: 1-3] [nama...]{FFFFFF} - Buat bisnis baru di posisi berdiri\n"\
                        "{FFFF00}/destroybiz [bizid]{FFFFFF} - Menghapus bisnis permanen dari database\n"\
                        "{FFFF00}/setmyadmin [level]{FFFFFF} - Mengatur level admin akun Anda (1-5)\n"\
                        "{FFFF00}/setfaction [id] [fac] [rank]{FFFFFF} - Mengangkat anggota faksi polisi/medis/geng"
                    );
                    ShowPlayerDialog(playerid, DIALOG_HELP_ADMIN, DIALOG_STYLE_MSGBOX, "{00AAFF}9. Perintah Admin", text, "Tutup", "Kembali");
                }
                case 9: // Ringkasan Semua Command
                {
                    ShowAllCommandsDialog(playerid);
                }
            }
            return 1;
        }

        case DIALOG_HELP_ACCOUNT, DIALOG_HELP_VEHICLE, DIALOG_HELP_HOUSE,
             DIALOG_HELP_BIZ, DIALOG_HELP_JOB, DIALOG_HELP_FACILITY, DIALOG_HELP_FACTION,
             DIALOG_HELP_GANG, DIALOG_HELP_ADMIN, DIALOG_HELP_ALL_CMDS:
        {
            if (!response)
            {
                OpenHelpMenu(playerid);
                return 1;
            }
            return 1;
        }

        case DIALOG_ATM_MAIN:
        {
            if (!response) return 1;

            switch (listitem)
            {
                case 0:
                {
                    new str[128];
                    format(str, sizeof(str), "{FFFFFF}Saldo tabungan di rekening bank Anda saat ini adalah: {00FF00}$%d", PlayerData[playerid][pBank]);
                    ShowPlayerDialog(playerid, -1, DIALOG_STYLE_MSGBOX, "{00AAFF}ATM - Informasi Saldo", str, "Kembali", "");
                }
                case 1:
                {
                    new str[256];
                    format(str, sizeof(str), "{FFFFFF}Saldo rekening: {00FF00}$%d\n\n{FFFFFF}Masukkan jumlah uang yang ingin Anda tarik:", PlayerData[playerid][pBank]);
                    ShowPlayerDialog(playerid, DIALOG_ATM_WITHDRAW, DIALOG_STYLE_INPUT, "{00AAFF}ATM - Tarik Tunai", str, "Tarik", "Batal");
                }
                case 2:
                {
                    new str[256];
                    format(str, sizeof(str), "{FFFFFF}Uang tunai di dompet: {00FF00}$%d\n\n{FFFFFF}Masukkan jumlah uang yang ingin Anda setor ke bank:", GetPlayerMoney(playerid));
                    ShowPlayerDialog(playerid, DIALOG_ATM_DEPOSIT, DIALOG_STYLE_INPUT, "{00AAFF}ATM - Setor Tunai", str, "Setor", "Batal");
                }
                case 3:
                {
                    ShowPlayerDialog(playerid, DIALOG_ATM_TRANSFER_ID, DIALOG_STYLE_INPUT, "{00AAFF}ATM - Transfer Rekening",
                        "{FFFFFF}Masukkan {FFFF00}Player ID {FFFFFF}tujuan transfer:", "Lanjut", "Batal"
                    );
                }
            }
            return 1;
        }

        case DIALOG_ATM_WITHDRAW:
        {
            if (!response) return OpenATMMenu(playerid);

            new amount = strval(inputtext);
            if (amount <= 0)
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Jumlah penarikan harus lebih dari $0!");
                return OpenATMMenu(playerid);
            }
            if (amount > PlayerData[playerid][pBank])
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Saldo rekening Anda tidak mencukupi untuk menarik jumlah tersebut!");
                return OpenATMMenu(playerid);
            }

            PlayerData[playerid][pBank] -= amount;
            GivePlayerMoney(playerid, amount);
            SavePlayerData(playerid);

            new msg[128];
            format(msg, sizeof(msg), "[ATM] Berhasil menarik uang tunai $%d. Sisa saldo rekening: $%d.", amount, PlayerData[playerid][pBank]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        case DIALOG_ATM_DEPOSIT:
        {
            if (!response) return OpenATMMenu(playerid);

            new amount = strval(inputtext);
            new cash = GetPlayerMoney(playerid);
            if (amount <= 0)
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Jumlah setoran harus lebih dari $0!");
                return OpenATMMenu(playerid);
            }
            if (amount > cash)
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Anda tidak memiliki cukup uang tunai di dompet!");
                return OpenATMMenu(playerid);
            }

            GivePlayerMoney(playerid, -amount);
            PlayerData[playerid][pBank] += amount;
            SavePlayerData(playerid);

            new msg[128];
            format(msg, sizeof(msg), "[ATM] Berhasil menyetor uang $%d ke rekening. Total saldo rekening: $%d.", amount, PlayerData[playerid][pBank]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        case DIALOG_ATM_TRANSFER_ID:
        {
            if (!response) return OpenATMMenu(playerid);

            new targetid = strval(inputtext);
            if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Pemain dengan ID tersebut tidak ditemukan atau belum login!");
                return OpenATMMenu(playerid);
            }
            if (targetid == playerid)
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Anda tidak dapat mentransfer uang ke rekening Anda sendiri!");
                return OpenATMMenu(playerid);
            }

            PlayerData[playerid][pTransferTarget] = targetid;

            new str[256];
            format(str, sizeof(str),
                "{FFFFFF}Tujuan Transfer: {FFFF00}%s (ID: %d){FFFFFF}\n\
                Saldo Rekening Anda: {00FF00}$%d{FFFFFF}\n\n\
                Masukkan jumlah uang yang ingin ditransfer:",
                GetPlayerNameEx(targetid), targetid, PlayerData[playerid][pBank]
            );
            ShowPlayerDialog(playerid, DIALOG_ATM_TRANSFER_AMOUNT, DIALOG_STYLE_INPUT, "{00AAFF}ATM - Jumlah Transfer", str, "Kirim", "Batal");
            return 1;
        }

        case DIALOG_ATM_TRANSFER_AMOUNT:
        {
            if (!response) return OpenATMMenu(playerid);

            new targetid = PlayerData[playerid][pTransferTarget];
            if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Pemain tujuan sudah keluar dari server!");
                return 1;
            }

            new amount = strval(inputtext);
            if (amount <= 0)
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Jumlah transfer harus lebih besar dari $0!");
                return 1;
            }
            if (amount > PlayerData[playerid][pBank])
            {
                SendClientMessage(playerid, COLOR_RED, "[ATM] Saldo rekening Anda tidak cukup untuk transfer sebesar itu!");
                return 1;
            }

            PlayerData[playerid][pBank] -= amount;
            PlayerData[targetid][pBank] += amount;

            SavePlayerData(playerid);
            SavePlayerData(targetid);

            new msg1[144], msg2[144];
            format(msg1, sizeof(msg1), "[ATM] Anda berhasil mentransfer $%d ke rekening bank %s (ID: %d).", amount, GetPlayerNameEx(targetid), targetid);
            SendClientMessage(playerid, COLOR_GREEN, msg1);

            format(msg2, sizeof(msg2), "[BANK] Anda telah menerima transfer masuk sebesar $%d dari %s (ID: %d).", amount, GetPlayerNameEx(playerid), playerid);
            SendClientMessage(targetid, COLOR_LIME, msg2);

            PlayerData[playerid][pTransferTarget] = INVALID_PLAYER_ID;
            return 1;
        }

        case DIALOG_RESTAURANT:
        {
            if (!response) return 1;

            new cash = GetPlayerMoney(playerid);
            new Float:health;
            GetPlayerHealth(playerid, health);

            switch (listitem)
            {
                case 0:
                {
                    if (cash < 15) return SendClientMessage(playerid, COLOR_RED, "[RESTORAN] Uang tunai Anda tidak cukup ($15)!");
                    GivePlayerMoney(playerid, -15);
                    PlayerData[playerid][pHunger] += 35;
                    if (PlayerData[playerid][pHunger] > 100) PlayerData[playerid][pHunger] = 100;
                    if (health < 100.0) SetPlayerHealth(playerid, (health + 10.0 > 100.0) ? 100.0 : health + 10.0);

                    ApplyAnimation(playerid, "FOOD", "EAT_Burger", 4.1, false, false, false, false, 3000);
                    SendClientMessage(playerid, COLOR_GREEN, "[RESTORAN] Anda menikmati Burger Daging seharga $15 (+35 Lapar, +10 Darah).");
                }
                case 1:
                {
                    if (cash < 20) return SendClientMessage(playerid, COLOR_RED, "[RESTORAN] Uang tunai Anda tidak cukup ($20)!");
                    GivePlayerMoney(playerid, -20);
                    PlayerData[playerid][pHunger] += 50;
                    if (PlayerData[playerid][pHunger] > 100) PlayerData[playerid][pHunger] = 100;
                    if (health < 100.0) SetPlayerHealth(playerid, (health + 15.0 > 100.0) ? 100.0 : health + 15.0);

                    ApplyAnimation(playerid, "FOOD", "EAT_Pizza", 4.1, false, false, false, false, 3000);
                    SendClientMessage(playerid, COLOR_GREEN, "[RESTORAN] Anda menikmati Pizza Pepperoni seharga $20 (+50 Lapar, +15 Darah).");
                }
                case 2:
                {
                    if (cash < 18) return SendClientMessage(playerid, COLOR_RED, "[RESTORAN] Uang tunai Anda tidak cukup ($18)!");
                    GivePlayerMoney(playerid, -18);
                    PlayerData[playerid][pHunger] += 40;
                    if (PlayerData[playerid][pHunger] > 100) PlayerData[playerid][pHunger] = 100;
                    if (health < 100.0) SetPlayerHealth(playerid, (health + 12.0 > 100.0) ? 100.0 : health + 12.0);

                    ApplyAnimation(playerid, "FOOD", "EAT_Burger", 4.1, false, false, false, false, 3000);
                    SendClientMessage(playerid, COLOR_GREEN, "[RESTORAN] Anda menikmati Ayam Crispy seharga $18 (+40 Lapar, +12 Darah).");
                }
                case 3:
                {
                    if (cash < 5) return SendClientMessage(playerid, COLOR_RED, "[RESTORAN] Uang tunai Anda tidak cukup ($5)!");
                    GivePlayerMoney(playerid, -5);
                    PlayerData[playerid][pThirst] += 40;
                    if (PlayerData[playerid][pThirst] > 100) PlayerData[playerid][pThirst] = 100;

                    ApplyAnimation(playerid, "VENDING", "VEND_Drink_P", 4.1, false, false, false, false, 3000);
                    SendClientMessage(playerid, COLOR_GREEN, "[RESTORAN] Anda meminum Air Mineral dingin seharga $5 (+40 Haus).");
                }
                case 4:
                {
                    if (cash < 8) return SendClientMessage(playerid, COLOR_RED, "[RESTORAN] Uang tunai Anda tidak cukup ($8)!");
                    GivePlayerMoney(playerid, -8);
                    PlayerData[playerid][pThirst] += 30;
                    if (PlayerData[playerid][pThirst] > 100) PlayerData[playerid][pThirst] = 100;
                    if (health < 100.0) SetPlayerHealth(playerid, (health + 5.0 > 100.0) ? 100.0 : health + 5.0);

                    ApplyAnimation(playerid, "VENDING", "VEND_Drink_P", 4.1, false, false, false, false, 3000);
                    SendClientMessage(playerid, COLOR_GREEN, "[RESTORAN] Anda meminum Soda Kaleng segar seharga $8 (+30 Haus, +5 Darah).");
                }
            }
            return 1;
        }

        case DIALOG_JOB_AGENCY:
        {
            if (!response) return 1;

            switch (listitem)
            {
                case 0:
                {
                    if (PlayerData[playerid][pJob] == JOB_SWEEPER)
                    {
                        return SendClientMessage(playerid, COLOR_YELLOW, "[PEKERJAAN] Anda sudah bekerja sebagai Pembersih Jalan.");
                    }
                    PlayerData[playerid][pJob] = JOB_SWEEPER;
                    PlayerData[playerid][pWorking] = false;
                    SavePlayerData(playerid);

                    SendClientMessage(playerid, COLOR_GREEN, "[PEKERJAAN] Selamat! Anda sekarang resmi bekerja sebagai Pembersih Jalan (Sweeper).");
                    SendClientMessage(playerid, COLOR_YELLOW, "[LOKASI] Marker merah telah diset menuju Depo Sweeper. Naik kendaraan dinas & ketik /startjob.");
                    SetPlayerCheckpoint(playerid, 1640.40, -1883.20, 13.15, 4.0);
                }
                case 1:
                {
                    if (PlayerData[playerid][pJob] == JOB_BUS)
                    {
                        return SendClientMessage(playerid, COLOR_YELLOW, "[PEKERJAAN] Anda sudah bekerja sebagai Supir Bus Kota.");
                    }
                    PlayerData[playerid][pJob] = JOB_BUS;
                    PlayerData[playerid][pWorking] = false;
                    SavePlayerData(playerid);

                    SendClientMessage(playerid, COLOR_GREEN, "[PEKERJAAN] Selamat! Anda sekarang resmi bekerja sebagai Supir Bus Kota.");
                    SendClientMessage(playerid, COLOR_YELLOW, "[LOKASI] Marker merah telah diset menuju Terminal Bus. Naik bus dinas & ketik /startjob.");
                    SetPlayerCheckpoint(playerid, 1795.50, -1908.20, 13.57, 5.0);
                }
                case 2:
                {
                    if (PlayerData[playerid][pJob] == JOB_TRUCKER)
                    {
                        return SendClientMessage(playerid, COLOR_YELLOW, "[PEKERJAAN] Anda sudah bekerja sebagai Sopir Truk Kargo.");
                    }
                    PlayerData[playerid][pJob] = JOB_TRUCKER;
                    PlayerData[playerid][pWorking] = false;
                    SavePlayerData(playerid);

                    SendClientMessage(playerid, COLOR_GREEN, "[PEKERJAAN] Selamat! Anda sekarang resmi bekerja sebagai Sopir Truk Kargo (Trucker).");
                    SendClientMessage(playerid, COLOR_YELLOW, "[LOKASI] Marker navigasi diset menuju Depo Truk Ocean Docks. Naik armada truk & ketik /startjob.");
                    SetPlayerCheckpoint(playerid, 2185.50, -2256.40, 13.54, 5.0);
                }
                case 3:
                {
                    if (PlayerData[playerid][pJob] == JOB_NONE)
                    {
                        return SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda saat ini memang belum memiliki pekerjaan!");
                    }
                    PlayerData[playerid][pJob] = JOB_NONE;
                    PlayerData[playerid][pWorking] = false;
                    PlayerData[playerid][pJobCheckpoint] = 0;
                    DisablePlayerCheckpoint(playerid);
                    SavePlayerData(playerid);

                    SendClientMessage(playerid, COLOR_ORANGE, "[PEKERJAAN] Anda telah mengundurkan diri dan saat ini berstatus Pengangguran.");
                }
            }
            return 1;
        }

        case DIALOG_DEALERSHIP:
        {
            if (!response) return 1;

            if (listitem < 0 || listitem >= sizeof(g_DealerCatalog)) return 1;

            if (GetPlayerOwnedVehicleCount(playerid) >= 2)
            {
                return SendClientMessage(playerid, COLOR_RED, "[DEALERSHIP] Anda sudah memiliki batas maksimal kendaraan (2 kendaraan)!");
            }

            new price = g_DealerCatalog[listitem][dvPrice];
            new cash = GetPlayerMoney(playerid);

            if (cash < price)
            {
                new msg[128];
                format(msg, sizeof(msg), "[DEALERSHIP] Uang tunai Anda tidak mencukupi untuk membeli kendaraan ini ($%d)!", price);
                return SendClientMessage(playerid, COLOR_RED, msg);
            }

            new slot = GetFreeVehicleSlot();
            if (slot == -1)
            {
                return SendClientMessage(playerid, COLOR_RED, "[DEALERSHIP] Garasi kota sedang penuh! Hubungi admin.");
            }

            GivePlayerMoney(playerid, -price);

            new plate[16];
            format(plate, sizeof(plate), "LS-%03d", random(900) + 100);

            new query[350];
            format(query, sizeof(query),
                "INSERT INTO vehicles (owner_id, model, color1, color2, pos_x, pos_y, pos_z, angle, fuel, health, plate) \
                VALUES (%d, %d, 1, 1, 1130.00, -1445.00, 15.80, 0.0, 100.0, 1000.0, '%s');",
                PlayerData[playerid][pID], g_DealerCatalog[listitem][dvModel], plate
            );
            DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));

            new DBResult:res = DB_ExecuteQuery(g_DB, "SELECT last_insert_rowid() AS id;");
            new db_id = DB_GetFieldIntByName(res, "id");
            DB_FreeResultSet(res);

            OwnedVehicles[slot][ovDBID] = db_id;
            OwnedVehicles[slot][ovOwnerID] = PlayerData[playerid][pID];
            OwnedVehicles[slot][ovModel] = g_DealerCatalog[listitem][dvModel];
            OwnedVehicles[slot][ovColor1] = 1;
            OwnedVehicles[slot][ovColor2] = 1;
            OwnedVehicles[slot][ovPosX] = 1130.00;
            OwnedVehicles[slot][ovPosY] = -1445.00;
            OwnedVehicles[slot][ovPosZ] = 15.80;
            OwnedVehicles[slot][ovAngle] = 0.0;
            OwnedVehicles[slot][ovFuel] = 100.0;
            OwnedVehicles[slot][ovHealth] = 1000.0;
            OwnedVehicles[slot][ovLocked] = true;
            OwnedVehicles[slot][ovEngine] = false;
            format(OwnedVehicles[slot][ovPlate], 16, "%s", plate);

            new veh = CreateVehicle(OwnedVehicles[slot][ovModel], 1130.00, -1445.00, 15.80, 0.0, 1, 1, -1);
            SetVehicleNumberPlate(veh, plate);
            SetVehicleParamsEx(veh, 0, 0, 0, 1, 0, 0, 0);

            OwnedVehicles[slot][ovVehicleID] = veh;
            OwnedVehicles[slot][ovSpawned] = true;

            SavePlayerData(playerid);

            new msg[160];
            format(msg, sizeof(msg), "[DEALERSHIP] Selamat! Anda telah membeli %s seharga $%d. Plat Nomor: %s.", g_DealerCatalog[listitem][dvName], price, plate);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            SendClientMessage(playerid, COLOR_YELLOW, "[PETUNJUK] Kendaraan Anda telah diantar ke area parkir showroom. Gunakan /lock & /engine.");
            return 1;
        }

        case DIALOG_HOUSE_SAFE_MAIN:
        {
            if (!response) return 1;

            new h_idx = GetCurrentHouseIndex(playerid);
            if (h_idx == -1) return 1;

            if (listitem == 0)
            {
                new str[128];
                format(str, sizeof(str), "{FFFFFF}Uang di dompet: {00FF00}$%d\n\n{FFFFFF}Masukkan jumlah uang yang ingin disimpan ke brankas:", GetPlayerMoney(playerid));
                ShowPlayerDialog(playerid, DIALOG_HOUSE_SAFE_DEPOSIT, DIALOG_STYLE_INPUT, "{00AAFF}Brankas - Simpan Uang", str, "Simpan", "Batal");
            }
            else
            {
                new str[128];
                format(str, sizeof(str), "{FFFFFF}Uang di brankas: {00FF00}$%d\n\n{FFFFFF}Masukkan jumlah uang yang ingin diambil dari brankas:", HouseData[h_idx][hSafeMoney]);
                ShowPlayerDialog(playerid, DIALOG_HOUSE_SAFE_WITHDRAW, DIALOG_STYLE_INPUT, "{00AAFF}Brankas - Ambil Uang", str, "Ambil", "Batal");
            }
            return 1;
        }

        case DIALOG_HOUSE_SAFE_DEPOSIT:
        {
            new h_idx = GetCurrentHouseIndex(playerid);
            if (h_idx == -1) return 1;
            if (!response) return OpenHouseSafeMenu(playerid, h_idx);

            new amount = strval(inputtext);
            if (amount <= 0)
            {
                SendClientMessage(playerid, COLOR_RED, "[BRANKAS] Jumlah uang harus lebih dari $0!");
                return OpenHouseSafeMenu(playerid, h_idx);
            }
            if (GetPlayerMoney(playerid) < amount)
            {
                SendClientMessage(playerid, COLOR_RED, "[BRANKAS] Anda tidak memiliki cukup uang di dompet!");
                return OpenHouseSafeMenu(playerid, h_idx);
            }

            GivePlayerMoney(playerid, -amount);
            HouseData[h_idx][hSafeMoney] += amount;
            SaveHouseData(h_idx);
            SavePlayerData(playerid);

            new msg[128];
            format(msg, sizeof(msg), "[BRANKAS] Anda menyimpan $%d ke brankas rumah. Total brankas: $%d.", amount, HouseData[h_idx][hSafeMoney]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        case DIALOG_HOUSE_SAFE_WITHDRAW:
        {
            new h_idx = GetCurrentHouseIndex(playerid);
            if (h_idx == -1) return 1;
            if (!response) return OpenHouseSafeMenu(playerid, h_idx);

            new amount = strval(inputtext);
            if (amount <= 0)
            {
                SendClientMessage(playerid, COLOR_RED, "[BRANKAS] Jumlah penarikan harus lebih dari $0!");
                return OpenHouseSafeMenu(playerid, h_idx);
            }
            if (amount > HouseData[h_idx][hSafeMoney])
            {
                SendClientMessage(playerid, COLOR_RED, "[BRANKAS] Saldo di brankas rumah tidak mencukupi!");
                return OpenHouseSafeMenu(playerid, h_idx);
            }

            HouseData[h_idx][hSafeMoney] -= amount;
            GivePlayerMoney(playerid, amount);
            SaveHouseData(h_idx);
            SavePlayerData(playerid);

            new msg[128];
            format(msg, sizeof(msg), "[BRANKAS] Anda mengambil $%d dari brankas rumah. Sisa brankas: $%d.", amount, HouseData[h_idx][hSafeMoney]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        case DIALOG_POLICE_DUTY:
        {
            if (!response || listitem == 1) return 1;

            if (!PlayerData[playerid][pOnDuty])
            {
                PlayerData[playerid][pOnDuty] = true;
                if (PlayerData[playerid][pFactionRank] >= 4) SetPlayerSkin(playerid, 288);
                else SetPlayerSkin(playerid, 280);

                SetPlayerArmour(playerid, 100.0);
                ResetPlayerWeapons(playerid);
                GivePlayerWeapon(playerid, WEAPON_NITESTICK, 1);
                GivePlayerWeapon(playerid, WEAPON_DEAGLE, 150);
                GivePlayerWeapon(playerid, WEAPON_SHOTGUN, 75);
                GivePlayerWeapon(playerid, WEAPON_MP5, 300);

                UpdatePlayerFactionBadge(playerid);

                new r_name[32], msg[144];
                GetFactionRankName(FACTION_POLICE, PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
                format(msg, sizeof(msg), "[SAPD DINAS] Anda sekarang ON-DUTY sebagai %s! Rompi pelindung & persenjataan dinas telah disiapkan.", r_name);
                SendClientMessage(playerid, COLOR_CYAN, msg);
            }
            else
            {
                PlayerData[playerid][pOnDuty] = false;
                SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);
                SetPlayerArmour(playerid, 0.0);
                ResetPlayerWeapons(playerid);
                UpdatePlayerFactionBadge(playerid);

                SendClientMessage(playerid, COLOR_YELLOW, "[SAPD DINAS] Anda sekarang OFF-DUTY. Seragam & perlengkapan dinas disimpan di loker.");
            }
            return 1;
        }

        case DIALOG_MEDIC_DUTY:
        {
            if (!response || listitem == 1) return 1;

            if (!PlayerData[playerid][pOnDuty])
            {
                PlayerData[playerid][pOnDuty] = true;
                if (PlayerData[playerid][pFactionRank] >= 4) SetPlayerSkin(playerid, 276);
                else SetPlayerSkin(playerid, 274);

                SetPlayerHealth(playerid, 100.0);
                PlayerData[playerid][pHealth] = 100.0;
                ResetPlayerWeapons(playerid);

                UpdatePlayerFactionBadge(playerid);

                new r_name[32], msg[144];
                GetFactionRankName(FACTION_MEDIC, PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
                format(msg, sizeof(msg), "[SAMD DINAS] Anda sekarang ON-DUTY sebagai %s! Peralatan medis telah disiapkan.", r_name);
                SendClientMessage(playerid, COLOR_PINK, msg);
            }
            else
            {
                PlayerData[playerid][pOnDuty] = false;
                SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);
                UpdatePlayerFactionBadge(playerid);

                SendClientMessage(playerid, COLOR_YELLOW, "[SAMD DINAS] Anda sekarang OFF-DUTY. Seragam medis disimpan di loker.");
            }
            return 1;
        }

        case DIALOG_CALL_911:
        {
            if (!response) return 1;

            if (listitem == 0) PlayerData[playerid][pEmergencyType] = 1;
            else PlayerData[playerid][pEmergencyType] = 2;

            new str[256];
            format(str, sizeof(str),
                "{FFFFFF}Anda menghubungi {FFFF00}%s{FFFFFF}.\n\n\
                Tuliskan {FFFF00}Keterangan Lokasi dan Situasi {FFFFFF}kejadian darurat yang Anda alami:",
                (listitem == 0) ? ("Kepolisian (SAPD)") : ("Ambulans & Medis (SAMD)")
            );
            ShowPlayerDialog(playerid, DIALOG_CALL_911_MSG, DIALOG_STYLE_INPUT, "{FF9900}911 Emergency Dispatch", str, "Kirim", "Batal");
            return 1;
        }

        case DIALOG_CALL_911_MSG:
        {
            if (!response) return 1;
            if (strlen(inputtext) < 3)
            {
                return SendClientMessage(playerid, COLOR_RED, "[911] Pesan darurat terlalu pendek! Berikan keterangan jelas.");
            }

            new Float:px, Float:py, Float:pz;
            GetPlayerPos(playerid, px, py, pz);

            new caller_name[MAX_PLAYER_NAME];
            GetPlayerName(playerid, caller_name, sizeof(caller_name));

            new broadcast[256];
            if (PlayerData[playerid][pEmergencyType] == 1)
            {
                format(broadcast, sizeof(broadcast),
                    "{00AAFF}[911 DISPATCH - POLISI] Dari: %s (ID: %d) | Lokasi: (%.0f, %.0f, %.0f) | Info: {FFFFFF}%s",
                    caller_name, playerid, px, py, pz, inputtext
                );

                for (new i = 0; i < MAX_PLAYERS; i++)
                {
                    if (IsPlayerConnected(i) && (PlayerData[i][pFaction] == FACTION_POLICE || PlayerData[i][pAdmin] >= 1))
                    {
                        SendClientMessage(i, COLOR_CYAN, broadcast);
                        PlayerPlaySound(i, 1058, 0.0, 0.0, 0.0);
                    }
                }
                SendClientMessage(playerid, COLOR_GREEN, "[911] Laporan darurat Anda telah diteruskan ke seluruh unit Kepolisian SAPD!");
            }
            else
            {
                format(broadcast, sizeof(broadcast),
                    "{FF0055}[911 DISPATCH - MEDIS] Dari: %s (ID: %d) | Lokasi: (%.0f, %.0f, %.0f) | Info: {FFFFFF}%s",
                    caller_name, playerid, px, py, pz, inputtext
                );

                for (new i = 0; i < MAX_PLAYERS; i++)
                {
                    if (IsPlayerConnected(i) && (PlayerData[i][pFaction] == FACTION_MEDIC || PlayerData[i][pAdmin] >= 1))
                    {
                        SendClientMessage(i, COLOR_PINK, broadcast);
                        PlayerPlaySound(i, 1058, 0.0, 0.0, 0.0);
                    }
                }
                SendClientMessage(playerid, COLOR_GREEN, "[911] Panggilan darurat medis Anda telah diteruskan ke tim ambulans SAMD!");
            }
            return 1;
        }

        case DIALOG_GROVE_LOCKER:
        {
            if (!response || listitem == 1) return 1;

            if (!PlayerData[playerid][pOnDuty])
            {
                PlayerData[playerid][pOnDuty] = true;
                if (PlayerData[playerid][pFactionRank] >= 4) SetPlayerSkin(playerid, 106);
                else SetPlayerSkin(playerid, 107);

                SetPlayerArmour(playerid, 100.0);
                ResetPlayerWeapons(playerid);
                GivePlayerWeapon(playerid, WEAPON_BAT, 1);
                GivePlayerWeapon(playerid, WEAPON_DEAGLE, 100);
                GivePlayerWeapon(playerid, WEAPON_TEC9, 300);
                GivePlayerWeapon(playerid, WEAPON_AK47, 200);

                UpdatePlayerFactionBadge(playerid);

                new r_name[32], msg[144];
                GetFactionRankName(FACTION_GROVE, PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
                format(msg, sizeof(msg), "[GROVE] Anda ON-DUTY sebagai %s! Persenjataan geng & rompi telah disiapkan.", r_name);
                SendClientMessage(playerid, COLOR_GREEN, msg);
            }
            else
            {
                PlayerData[playerid][pOnDuty] = false;
                SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);
                SetPlayerArmour(playerid, 0.0);
                ResetPlayerWeapons(playerid);
                UpdatePlayerFactionBadge(playerid);

                SendClientMessage(playerid, COLOR_YELLOW, "[GROVE] Anda sekarang OFF-DUTY. Senjata geng disimpan di loker.");
            }
            return 1;
        }

        case DIALOG_BALLAS_LOCKER:
        {
            if (!response || listitem == 1) return 1;

            if (!PlayerData[playerid][pOnDuty])
            {
                PlayerData[playerid][pOnDuty] = true;
                if (PlayerData[playerid][pFactionRank] >= 4) SetPlayerSkin(playerid, 104);
                else SetPlayerSkin(playerid, 102);

                SetPlayerArmour(playerid, 100.0);
                ResetPlayerWeapons(playerid);
                GivePlayerWeapon(playerid, WEAPON_BAT, 1);
                GivePlayerWeapon(playerid, WEAPON_DEAGLE, 100);
                GivePlayerWeapon(playerid, WEAPON_UZI, 300);
                GivePlayerWeapon(playerid, WEAPON_AK47, 200);

                UpdatePlayerFactionBadge(playerid);

                new r_name[32], msg[144];
                GetFactionRankName(FACTION_BALLAS, PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));
                format(msg, sizeof(msg), "[BALLAS] Anda ON-DUTY sebagai %s! Persenjataan geng & rompi telah disiapkan.", r_name);
                SendClientMessage(playerid, 0xAA00FFAA, msg);
            }
            else
            {
                PlayerData[playerid][pOnDuty] = false;
                SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);
                SetPlayerArmour(playerid, 0.0);
                ResetPlayerWeapons(playerid);
                UpdatePlayerFactionBadge(playerid);

                SendClientMessage(playerid, COLOR_YELLOW, "[BALLAS] Anda sekarang OFF-DUTY. Senjata geng disimpan di loker.");
            }
            return 1;
        }

        case DIALOG_BLACK_MARKET:
        {
            if (!response) return 1;

            new price = 0;
            switch (listitem)
            {
                case 0:
                {
                    price = 600;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[BLACK MARKET] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    GivePlayerWeapon(playerid, WEAPON_SILENCED, 100);
                    SendClientMessage(playerid, COLOR_GREEN, "[BLACK MARKET] Anda membeli Pistol Silenced 9mm (100 Peluru) seharga $600.");
                }
                case 1:
                {
                    price = 1200;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[BLACK MARKET] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    GivePlayerWeapon(playerid, WEAPON_UZI, 250);
                    SendClientMessage(playerid, COLOR_GREEN, "[BLACK MARKET] Anda membeli Micro SMG / Uzi (250 Peluru) seharga $1,200.");
                }
                case 2:
                {
                    price = 2500;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[BLACK MARKET] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    GivePlayerWeapon(playerid, WEAPON_AK47, 300);
                    SendClientMessage(playerid, COLOR_GREEN, "[BLACK MARKET] Anda membeli AK-47 Assault Rifle (300 Peluru) seharga $2,500.");
                }
                case 3:
                {
                    price = 4000;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[BLACK MARKET] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    GivePlayerWeapon(playerid, WEAPON_SNIPER, 30);
                    SendClientMessage(playerid, COLOR_GREEN, "[BLACK MARKET] Anda membeli Sniper Rifle Jarak Jauh (30 Peluru) seharga $4,000.");
                }
                case 4:
                {
                    price = 150;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[BLACK MARKET] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    PlayerData[playerid][pPot] += 5;
                    SavePlayerData(playerid);
                    new msg[128];
                    format(msg, sizeof(msg), "[BLACK MARKET] Anda membeli Paket Ganja / Pot 5 Gram seharga $150. Total Pot: %d Gram. (/usepot)", PlayerData[playerid][pPot]);
                    SendClientMessage(playerid, COLOR_GREEN, msg);
                }
                case 5:
                {
                    price = 300;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[BLACK MARKET] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    PlayerData[playerid][pCrack] += 5;
                    SavePlayerData(playerid);
                    new msg[128];
                    format(msg, sizeof(msg), "[BLACK MARKET] Anda membeli Paket Kokain / Crack 5 Gram seharga $300. Total Crack: %d Gram. (/usecrack)", PlayerData[playerid][pCrack]);
                    SendClientMessage(playerid, COLOR_GREEN, msg);
                }
            }
            return 1;
        }

        case DIALOG_BIZ_SAFE_MAIN:
        {
            if (!response) return 1;
            new b_curr = GetCurrentBusinessIndex(playerid);
            if (b_curr == -1) b_curr = GetNearBusinessEntrance(playerid);
            if (b_curr == -1) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Anda harus berada di bisnis Anda!");
            if (BizData[b_curr][bOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] < 3)
            {
                return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Anda bukan pemilik bisnis ini!");
            }

            switch (listitem)
            {
                case 0:
                {
                    new str[256];
                    format(str, sizeof(str), "{FFFFFF}Saldo Kas Bisnis saat ini: {00FF00}$%d
{FFFFFF}Uang Tunai Anda: {00FF00}$%d

Masukkan jumlah uang yang ingin disetor:", BizData[b_curr][bVault], GetPlayerMoney(playerid));
                    ShowPlayerDialog(playerid, DIALOG_BIZ_SAFE_DEPOSIT, DIALOG_STYLE_INPUT, "{00AAFF}Kas Bisnis - Setor Uang", str, "Setor", "Batal");
                }
                case 1:
                {
                    new str[256];
                    format(str, sizeof(str), "{FFFFFF}Saldo Kas Bisnis saat ini: {00FF00}$%d

Masukkan jumlah uang yang ingin ditarik:", BizData[b_curr][bVault]);
                    ShowPlayerDialog(playerid, DIALOG_BIZ_SAFE_WITHDRAW, DIALOG_STYLE_INPUT, "{00AAFF}Kas Bisnis - Tarik Uang", str, "Tarik", "Batal");
                }
                case 2:
                {
                    new str[256];
                    format(str, sizeof(str), "{FFFFFF}Informasi Bisnis: {FFFF00}%s
{FFFFFF}Pemilik: {00FF00}%s
{FFFFFF}Saldo Kas Brankas: {00FF00}$%d", BizData[b_curr][bName], BizData[b_curr][bOwnerName], BizData[b_curr][bVault]);
                    ShowPlayerDialog(playerid, DIALOG_TURF_INFO, DIALOG_STYLE_MSGBOX, "{00AAFF}Info Brankas Bisnis", str, "Tutup", "");
                }
            }
            return 1;
        }

        case DIALOG_BIZ_SAFE_DEPOSIT:
        {
            if (!response) return 1;
            new b_curr = GetCurrentBusinessIndex(playerid);
            if (b_curr == -1) b_curr = GetNearBusinessEntrance(playerid);
            if (b_curr == -1) return 1;

            new amount = strval(inputtext);
            if (amount <= 0) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Jumlah nominal tidak valid!");
            if (GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Uang tunai Anda tidak mencukupi!");

            GivePlayerMoney(playerid, -amount);
            BizData[b_curr][bVault] += amount;
            SaveBusinessData(b_curr);

            new msg[140];
            format(msg, sizeof(msg), "[BISNIS] Berhasil menyetor uang $%d ke brankas kas bisnis. Total kas sekarang: $%d.", amount, BizData[b_curr][bVault]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        case DIALOG_BIZ_SAFE_WITHDRAW:
        {
            if (!response) return 1;
            new b_curr = GetCurrentBusinessIndex(playerid);
            if (b_curr == -1) b_curr = GetNearBusinessEntrance(playerid);
            if (b_curr == -1) return 1;

            new amount = strval(inputtext);
            if (amount <= 0) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Jumlah nominal tidak valid!");
            if (BizData[b_curr][bVault] < amount) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Saldo kas bisnis tidak mencukupi!");

            BizData[b_curr][bVault] -= amount;
            GivePlayerMoney(playerid, amount);
            SaveBusinessData(b_curr);

            new msg[140];
            format(msg, sizeof(msg), "[BISNIS] Berhasil menarik uang $%d dari brankas kas bisnis. Sisa kas: $%d.", amount, BizData[b_curr][bVault]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        case DIALOG_247_SHOP:
        {
            if (!response) return 1;
            new b_curr = GetCurrentBusinessIndex(playerid);
            new price = 0;
            switch (listitem)
            {
                case 0:
                {
                    price = 500;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[24/7] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    PlayerData[playerid][pHasGPS] = 1;
                    SavePlayerData(playerid);
                    SendClientMessage(playerid, COLOR_GREEN, "[24/7] Anda membeli Perangkat GPS Satelit seharga $500. Ketik /usegps atau /gps untuk navigasi.");
                }
                case 1:
                {
                    price = 800;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[24/7] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    PlayerData[playerid][pHasMask] = 1;
                    SavePlayerData(playerid);
                    SendClientMessage(playerid, COLOR_GREEN, "[24/7] Anda membeli Topeng Penyamaran seharga $800. Ketik /usemask atau /mask untuk memakai/melepas.");
                }
                case 2:
                {
                    price = 50;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[24/7] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    PlayerData[playerid][pCigarettes] += 20;
                    SavePlayerData(playerid);
                    new msg[128];
                    format(msg, sizeof(msg), "[24/7] Anda membeli 1 Bungkus Rokok (20 Batang) seharga $50. Total rokok: %d batang. (/smokecigarette)", PlayerData[playerid][pCigarettes]);
                    SendClientMessage(playerid, COLOR_GREEN, msg);
                }
                case 3:
                {
                    price = 25;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[24/7] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    PlayerData[playerid][pHunger] = 100;
                    PlayerData[playerid][pThirst] = 100;
                    SavePlayerData(playerid);
                    SendClientMessage(playerid, COLOR_GREEN, "[24/7] Anda menikmati snack & minuman dingin seharga $25. Tingkat lapar & haus kembali 100%.");
                }
            }

            if (b_curr != -1 && price > 0)
            {
                BizData[b_curr][bVault] += (price * 7) / 10;
                SaveBusinessData(b_curr);
            }
            return 1;
        }

        case DIALOG_ELECTRONIC_SHOP:
        {
            if (!response) return 1;
            new b_curr = GetCurrentBusinessIndex(playerid);
            new price = 0;
            switch (listitem)
            {
                case 0:
                {
                    price = 400;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[ELEKTRONIK] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    PlayerData[playerid][pHasGPS] = 1;
                    SavePlayerData(playerid);
                    SendClientMessage(playerid, COLOR_GREEN, "[ELEKTRONIK] Anda membeli GPS Tracker Digital seharga $400. Gunakan /usegps.");
                }
                case 1:
                {
                    price = 600;
                    if (GetPlayerMoney(playerid) < price) return SendClientMessage(playerid, COLOR_RED, "[ELEKTRONIK] Uang tunai Anda tidak mencukupi!");
                    GivePlayerMoney(playerid, -price);
                    PlayerData[playerid][pHasMask] = 1;
                    SavePlayerData(playerid);
                    SendClientMessage(playerid, COLOR_GREEN, "[ELEKTRONIK] Anda membeli Topeng Balaclava Digital seharga $600. Gunakan /usemask.");
                }
            }

            if (b_curr != -1 && price > 0)
            {
                BizData[b_curr][bVault] += (price * 7) / 10;
                SaveBusinessData(b_curr);
            }
            return 1;
        }

        case DIALOG_TRUCKER_CARGO:
        {
            if (!response) return 1;
            if (PlayerData[playerid][pJob] != JOB_TRUCKER || GetPlayerState(playerid) != PLAYER_STATE_DRIVER || !IsTruckerVehicle(GetPlayerVehicleID(playerid)))
            {
                return SendClientMessage(playerid, COLOR_RED, "[TRUCKER] Anda harus berada di kursi pengemudi truk logistik!");
            }

            PlayerData[playerid][pWorking] = true;
            PlayerData[playerid][pJobCheckpoint] = 0;
            PlayerData[playerid][pTruckerCargo] = listitem + 1;

            switch (listitem)
            {
                case 0:
                {
                    SetPlayerCheckpoint(playerid, g_TruckerCargo1_CP[0][0], g_TruckerCargo1_CP[0][1], g_TruckerCargo1_CP[0][2], 6.0);
                    SendClientMessage(playerid, COLOR_GREEN, "[TRUCKER] Muatan Pasokan Pangan dimuat! Ikuti checkpoint merah menuju Toko 24/7 & Restoran.");
                }
                case 1:
                {
                    SetPlayerCheckpoint(playerid, g_TruckerCargo2_CP[0][0], g_TruckerCargo2_CP[0][1], g_TruckerCargo2_CP[0][2], 6.0);
                    SendClientMessage(playerid, COLOR_GREEN, "[TRUCKER] Muatan Komponen Gadget Elektronik dimuat! Ikuti checkpoint merah ke Toko Commerce.");
                }
                case 2:
                {
                    SetPlayerCheckpoint(playerid, g_TruckerCargo3_CP[0][0], g_TruckerCargo3_CP[0][1], g_TruckerCargo3_CP[0][2], 6.0);
                    SendClientMessage(playerid, COLOR_GREEN, "[TRUCKER] Muatan Kontainer Industri & Material Berat dimuat! Ikuti checkpoint merah ke Pelabuhan & Pabrik.");
                }
            }
            return 1;
        }

        case DIALOG_TRUNK_MAIN:
        {
            new slot = GetNearPlayerVehicle(playerid, 4.5);
            if (slot == -1) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Anda tidak berada di dekat kendaraan pribadi!");

            if (!response || listitem == 4)
            {
                new eng, lgt, alm, drs, bon, boot, obj;
                GetVehicleParamsEx(OwnedVehicles[slot][ovVehicleID], eng, lgt, alm, drs, bon, boot, obj);
                SetVehicleParamsEx(OwnedVehicles[slot][ovVehicleID], eng, lgt, alm, drs, bon, 0, obj);
                OwnedVehicles[slot][ovTrunkOpen] = false;

                new rp[128];
                format(rp, sizeof(rp), "* %s menutup kembali pintu bagasi kendaraan miliknya.", GetPlayerNameEx(playerid));
                SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
                PlayerPlaySound(playerid, 1145, 0.0, 0.0, 0.0);
                return 1;
            }

            switch (listitem)
            {
                case 0: // Uang Tunai
                {
                    new str[256];
                    format(str, sizeof(str), "{FFFFFF}Uang di Bagasi: {00FF00}$%d\n{FFFFFF}Uang Tunai Anda: {00FF00}$%d\n\nPilih tindakan:\n1. Simpan Uang ke Bagasi\n2. Ambil Uang dari Bagasi", OwnedVehicles[slot][ovTrunkMoney], GetPlayerMoney(playerid));
                    ShowPlayerDialog(playerid, DIALOG_TRUNK_DEPOSIT_CASH, DIALOG_STYLE_LIST, "{00AAFF}Bagasi - Kelola Uang Tunai", "1. Simpan Uang ke Bagasi\n2. Ambil Uang dari Bagasi", "Pilih", "Kembali");
                }
                case 1: // Senjata Api
                {
                    new wep_name[32];
                    GetWeaponName(WEAPON:OwnedVehicles[slot][ovTrunkWeapon], wep_name, sizeof(wep_name));
                    if (OwnedVehicles[slot][ovTrunkWeapon] == 0) format(wep_name, sizeof(wep_name), "Kosong");

                    new str[300];
                    format(str, sizeof(str), "1. Simpan Senjata di Tangan ke Bagasi\n2. Ambil Senjata (%s) dari Bagasi", wep_name);
                    ShowPlayerDialog(playerid, DIALOG_TRUNK_WEAPON_MENU, DIALOG_STYLE_LIST, "{00AAFF}Bagasi - Kelola Senjata Api", str, "Pilih", "Kembali");
                }
                case 2: // Pot / Ganja
                {
                    ShowPlayerDialog(playerid, DIALOG_TRUNK_DEPOSIT_POT, DIALOG_STYLE_LIST, "{00AAFF}Bagasi - Kelola Ganja (Pot)", "1. Simpan Ganja ke Bagasi\n2. Ambil Ganja dari Bagasi", "Pilih", "Kembali");
                }
                case 3: // Crack / Kokain
                {
                    ShowPlayerDialog(playerid, DIALOG_TRUNK_DEPOSIT_CRACK, DIALOG_STYLE_LIST, "{00AAFF}Bagasi - Kelola Kokain (Crack)", "1. Simpan Kokain ke Bagasi\n2. Ambil Kokain dari Bagasi", "Pilih", "Kembali");
                }
            }
            return 1;
        }

        case DIALOG_TRUNK_DEPOSIT_CASH:
        {
            new slot = GetNearPlayerVehicle(playerid, 4.5);
            if (slot == -1) return 1;
            if (!response) return OpenTrunkMenu(playerid, slot);

            if (listitem == 0) // Setor
            {
                ShowPlayerDialog(playerid, DIALOG_TRUNK_WITHDRAW_CASH, DIALOG_STYLE_INPUT, "{00AAFF}Bagasi - Simpan Uang", "Masukkan jumlah uang yang ingin disimpan ke bagasi:", "Simpan", "Batal");
            }
            else // Tarik
            {
                new str[256];
                format(str, sizeof(str), "{FFFFFF}Uang di Bagasi: {00FF00}$%d\n\nMasukkan jumlah uang yang ingin diambil:", OwnedVehicles[slot][ovTrunkMoney]);
                ShowPlayerDialog(playerid, DIALOG_TRUNK_WITHDRAW_POT, DIALOG_STYLE_INPUT, "{00AAFF}Bagasi - Ambil Uang", str, "Ambil", "Batal");
            }
            return 1;
        }

        case DIALOG_TRUNK_WITHDRAW_CASH: // Inputbox Simpan Uang
        {
            new slot = GetNearPlayerVehicle(playerid, 4.5);
            if (slot == -1) return 1;
            if (!response) return OpenTrunkMenu(playerid, slot);

            new amount = strval(inputtext);
            if (amount <= 0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Jumlah uang tidak valid!");
            if (GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Uang tunai Anda tidak mencukupi!");

            GivePlayerMoney(playerid, -amount);
            OwnedVehicles[slot][ovTrunkMoney] += amount;
            SaveVehicleTrunkData(slot);

            new msg[128];
            format(msg, sizeof(msg), "[BAGASI] Anda menyimpan $%d ke dalam bagasi mobil. Total di bagasi: $%d.", amount, OwnedVehicles[slot][ovTrunkMoney]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            OpenTrunkMenu(playerid, slot);
            return 1;
        }

        case DIALOG_TRUNK_WITHDRAW_POT: // Inputbox Ambil Uang
        {
            new slot = GetNearPlayerVehicle(playerid, 4.5);
            if (slot == -1) return 1;
            if (!response) return OpenTrunkMenu(playerid, slot);

            new amount = strval(inputtext);
            if (amount <= 0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Jumlah uang tidak valid!");
            if (OwnedVehicles[slot][ovTrunkMoney] < amount) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Uang di dalam bagasi tidak mencukupi!");

            OwnedVehicles[slot][ovTrunkMoney] -= amount;
            GivePlayerMoney(playerid, amount);
            SaveVehicleTrunkData(slot);

            new msg[128];
            format(msg, sizeof(msg), "[BAGASI] Anda mengambil $%d dari bagasi mobil. Sisa di bagasi: $%d.", amount, OwnedVehicles[slot][ovTrunkMoney]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            OpenTrunkMenu(playerid, slot);
            return 1;
        }

        case DIALOG_TRUNK_WEAPON_MENU:
        {
            new slot = GetNearPlayerVehicle(playerid, 4.5);
            if (slot == -1) return 1;
            if (!response) return OpenTrunkMenu(playerid, slot);

            if (listitem == 0) // Simpan Senjata di Tangan
            {
                new WEAPON:wep = GetPlayerWeapon(playerid);
                if (wep == WEAPON:0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Anda tidak sedang memegang senjata apapun!");
                if (OwnedVehicles[slot][ovTrunkWeapon] != 0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Bagasi sudah terisi senjata! Ambil senjata yang ada terlebih dahulu.");

                new ammo = GetPlayerAmmo(playerid);
                OwnedVehicles[slot][ovTrunkWeapon] = _:wep;
                OwnedVehicles[slot][ovTrunkAmmo] = ammo;
                SaveVehicleTrunkData(slot);

                // Hilangkan senjata dari pemain
                SetPlayerArmedWeapon(playerid, WEAPON:0);
                ResetPlayerWeapons(playerid);

                new wep_name[32];
                GetWeaponName(wep, wep_name, sizeof(wep_name));
                new msg[140];
                format(msg, sizeof(msg), "[BAGASI] Anda menyimpan %s (%d Peluru) ke dalam bagasi mobil.", wep_name, ammo);
                SendClientMessage(playerid, COLOR_GREEN, msg);
                OpenTrunkMenu(playerid, slot);
            }
            else // Ambil Senjata
            {
                if (OwnedVehicles[slot][ovTrunkWeapon] == 0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Tidak ada senjata yang tersimpan di dalam bagasi!");

                GivePlayerWeapon(playerid, WEAPON:OwnedVehicles[slot][ovTrunkWeapon], OwnedVehicles[slot][ovTrunkAmmo]);
                new wep_name[32];
                GetWeaponName(WEAPON:OwnedVehicles[slot][ovTrunkWeapon], wep_name, sizeof(wep_name));
                new msg[140];
                format(msg, sizeof(msg), "[BAGASI] Anda mengambil senjata %s (%d Peluru) dari bagasi mobil.", wep_name, OwnedVehicles[slot][ovTrunkAmmo]);
                SendClientMessage(playerid, COLOR_GREEN, msg);

                OwnedVehicles[slot][ovTrunkWeapon] = 0;
                OwnedVehicles[slot][ovTrunkAmmo] = 0;
                SaveVehicleTrunkData(slot);
                OpenTrunkMenu(playerid, slot);
            }
            return 1;
        }

        case DIALOG_TRUNK_DEPOSIT_POT: // Menu Pot
        {
            new slot = GetNearPlayerVehicle(playerid, 4.5);
            if (slot == -1) return 1;
            if (!response) return OpenTrunkMenu(playerid, slot);

            if (listitem == 0) // Simpan Pot
            {
                if (PlayerData[playerid][pPot] <= 0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Anda tidak memiliki ganja (pot)!");
                OwnedVehicles[slot][ovTrunkPot] += PlayerData[playerid][pPot];
                new msg[128];
                format(msg, sizeof(msg), "[BAGASI] Anda menyimpan %d Gram ganja ke bagasi. Total di bagasi: %d Gram.", PlayerData[playerid][pPot], OwnedVehicles[slot][ovTrunkPot]);
                SendClientMessage(playerid, COLOR_GREEN, msg);
                PlayerData[playerid][pPot] = 0;
                SavePlayerData(playerid);
                SaveVehicleTrunkData(slot);
                OpenTrunkMenu(playerid, slot);
            }
            else // Ambil Pot
            {
                if (OwnedVehicles[slot][ovTrunkPot] <= 0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Tidak ada ganja di dalam bagasi!");
                PlayerData[playerid][pPot] += OwnedVehicles[slot][ovTrunkPot];
                new msg[128];
                format(msg, sizeof(msg), "[BAGASI] Anda mengambil %d Gram ganja dari bagasi. Total di saku: %d Gram.", OwnedVehicles[slot][ovTrunkPot], PlayerData[playerid][pPot]);
                SendClientMessage(playerid, COLOR_GREEN, msg);
                OwnedVehicles[slot][ovTrunkPot] = 0;
                SavePlayerData(playerid);
                SaveVehicleTrunkData(slot);
                OpenTrunkMenu(playerid, slot);
            }
            return 1;
        }

        case DIALOG_TRUNK_DEPOSIT_CRACK: // Menu Crack
        {
            new slot = GetNearPlayerVehicle(playerid, 4.5);
            if (slot == -1) return 1;
            if (!response) return OpenTrunkMenu(playerid, slot);

            if (listitem == 0) // Simpan Crack
            {
                if (PlayerData[playerid][pCrack] <= 0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Anda tidak memiliki kokain (crack)!");
                OwnedVehicles[slot][ovTrunkCrack] += PlayerData[playerid][pCrack];
                new msg[128];
                format(msg, sizeof(msg), "[BAGASI] Anda menyimpan %d Gram kokain ke bagasi. Total di bagasi: %d Gram.", PlayerData[playerid][pCrack], OwnedVehicles[slot][ovTrunkCrack]);
                SendClientMessage(playerid, COLOR_GREEN, msg);
                PlayerData[playerid][pCrack] = 0;
                SavePlayerData(playerid);
                SaveVehicleTrunkData(slot);
                OpenTrunkMenu(playerid, slot);
            }
            else // Ambil Crack
            {
                if (OwnedVehicles[slot][ovTrunkCrack] <= 0) return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Tidak ada kokain di dalam bagasi!");
                PlayerData[playerid][pCrack] += OwnedVehicles[slot][ovTrunkCrack];
                new msg[128];
                format(msg, sizeof(msg), "[BAGASI] Anda mengambil %d Gram kokain dari bagasi. Total di saku: %d Gram.", OwnedVehicles[slot][ovTrunkCrack], PlayerData[playerid][pCrack]);
                SendClientMessage(playerid, COLOR_GREEN, msg);
                OwnedVehicles[slot][ovTrunkCrack] = 0;
                SavePlayerData(playerid);
                SaveVehicleTrunkData(slot);
                OpenTrunkMenu(playerid, slot);
            }
            return 1;
        }

        case DIALOG_VEH_SELL_CONFIRM:
        {
            new seller = PlayerData[playerid][pVehSellSeller];
            new slot = PlayerData[playerid][pVehSellSlot];
            new price = PlayerData[playerid][pVehSellPrice];

            PlayerData[playerid][pVehSellSeller] = INVALID_PLAYER_ID;
            PlayerData[playerid][pVehSellSlot] = -1;
            PlayerData[playerid][pVehSellPrice] = 0;

            if (!response)
            {
                if (seller != INVALID_PLAYER_ID && IsPlayerConnected(seller))
                {
                    SendClientMessage(seller, COLOR_RED, "[JUAL-BELI] Calon pembeli menolak tawaran pembelian kendaraan Anda.");
                }
                SendClientMessage(playerid, COLOR_YELLOW, "[JUAL-BELI] Anda menolak tawaran pembelian kendaraan.");
                return 1;
            }

            if (seller == INVALID_PLAYER_ID || !IsPlayerConnected(seller))
            {
                return SendClientMessage(playerid, COLOR_RED, "[ERROR] Penjual kendaraan telah keluar dari server!");
            }

            if (slot < 0 || slot >= MAX_OWNED_VEHICLES || !OwnedVehicles[slot][ovSpawned])
            {
                return SendClientMessage(playerid, COLOR_RED, "[ERROR] Data kendaraan tersebut sudah tidak valid!");
            }

            if (GetPlayerMoney(playerid) < price)
            {
                SendClientMessage(seller, COLOR_RED, "[JUAL-BELI] Calon pembeli tidak memiliki cukup uang tunai!");
                return SendClientMessage(playerid, COLOR_RED, "[JUAL-BELI] Uang tunai Anda tidak mencukupi untuk membeli kendaraan ini!");
            }

            // Transaksi Sukses!
            GivePlayerMoney(playerid, -price);
            GivePlayerMoney(seller, price);

            OwnedVehicles[slot][ovOwnerID] = PlayerData[playerid][pID];

            new q[128];
            format(q, sizeof(q), "UPDATE vehicles SET owner_id = %d WHERE id = %d;", PlayerData[playerid][pID], OwnedVehicles[slot][ovDBID]);
            DB_FreeResultSet(DB_ExecuteQuery(g_DB, q));

            SavePlayerData(playerid);
            SavePlayerData(seller);

            PlayerPlaySound(playerid, 1149, 0.0, 0.0, 0.0);
            PlayerPlaySound(seller, 1149, 0.0, 0.0, 0.0);

            new smsg[160], bmsg[160];
            format(smsg, sizeof(smsg), "[JUAL-BELI] Kendaraan (Plat: %s) berhasil terjual kepada %s seharga $%d!", OwnedVehicles[slot][ovPlate], GetPlayerNameEx(playerid), price);
            format(bmsg, sizeof(bmsg), "[JUAL-BELI] Selamat! Anda resmi membeli kendaraan (Plat: %s) dari %s seharga $%d. Gunakan /myveh.", OwnedVehicles[slot][ovPlate], GetPlayerNameEx(seller), price);
            SendClientMessage(seller, COLOR_GREEN, smsg);
            SendClientMessage(playerid, COLOR_GREEN, bmsg);
            return 1;
        }

        case DIALOG_GPS_MENU:
        {
            if (!response) return 1;
            switch (listitem)
            {
                case 0:
                {
                    SetPlayerCheckpoint(playerid, 1481.04, -1772.31, 15.30, 4.0);
                    SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke: Balai Kota Los Santos (City Hall / Job Agency).");
                }
                case 1:
                {
                    SetPlayerCheckpoint(playerid, 1554.20, -1675.60, 16.19, 4.0);
                    SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke: Kantor Polisi Los Santos (SAPD HQ).");
                }
                case 2:
                {
                    SetPlayerCheckpoint(playerid, 1172.80, -1323.80, 14.10, 4.0);
                    SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke: Rumah Sakit All Saints (SAMD Hospital).");
                }
                case 3:
                {
                    SetPlayerCheckpoint(playerid, 1124.50, -1451.20, 15.80, 4.0);
                    SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke: Showroom Kendaraan Los Santos (Commerce).");
                }
                case 4:
                {
                    SetPlayerCheckpoint(playerid, 1778.0, -1896.0, 13.5, 4.0);
                    SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke: Depo Pembersih Jalan (Sweeper Job).");
                }
                case 5:
                {
                    SetPlayerCheckpoint(playerid, 1785.0, -1905.0, 13.5, 4.0);
                    SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke: Halte Bus Kota Los Santos.");
                }
                case 6:
                {
                    SetPlayerCheckpoint(playerid, 2185.50, -2256.40, 13.54, 5.0);
                    SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke: Depo Truk Kargo & Logistik (Ocean Docks).");
                }
                case 7:
                {
                    SetPlayerCheckpoint(playerid, 1502.50, -1703.80, 14.04, 3.0);
                    SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke: Bank Los Santos & ATM Utama.");
                }
                case 8:
                {
                    new found_h = -1;
                    for (new i = 0; i < g_TotalHouses; i++)
                    {
                        if (HouseData[i][hOwnerID] == PlayerData[playerid][pID])
                        {
                            found_h = i;
                            break;
                        }
                    }
                    if (found_h != -1)
                    {
                        SetPlayerCheckpoint(playerid, HouseData[found_h][hEnterX], HouseData[found_h][hEnterY], HouseData[found_h][hEnterZ], 3.5);
                        SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke lokasi rumah pribadi Anda.");
                    }
                    else
                    {
                        SendClientMessage(playerid, COLOR_RED, "[GPS] Anda belum memiliki properti rumah.");
                    }
                }
                case 9:
                {
                    new found_b = -1;
                    for (new i = 0; i < g_TotalBusinesses; i++)
                    {
                        if (BizData[i][bOwnerID] == PlayerData[playerid][pID])
                        {
                            found_b = i;
                            break;
                        }
                    }
                    if (found_b != -1)
                    {
                        SetPlayerCheckpoint(playerid, BizData[found_b][bEnterX], BizData[found_b][bEnterY], BizData[found_b][bEnterZ], 3.5);
                        SendClientMessage(playerid, COLOR_YELLOW, "[GPS] Checkpoint diarahkan ke lokasi properti bisnis Anda.");
                    }
                    else
                    {
                        SendClientMessage(playerid, COLOR_RED, "[GPS] Anda belum memiliki properti bisnis.");
                    }
                }
                case 10:
                {
                    DisablePlayerCheckpoint(playerid);
                    SendClientMessage(playerid, COLOR_GREEN, "[GPS] Checkpoint navigasi telah dinonaktifkan.");
                }
            }
            return 1;
        }
    }
    return 1;
}

// =============================================================================
// ROLEPLAY CHAT SYSTEM (LOCAL IC CHAT)
// =============================================================================
stock SendLocalMessage(playerid, Float:radius, color, const text[])
{
    new Float:pos_x, Float:pos_y, Float:pos_z;
    GetPlayerPos(playerid, pos_x, pos_y, pos_z);
    new vw = GetPlayerVirtualWorld(playerid);
    new int = GetPlayerInterior(playerid);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && GetPlayerVirtualWorld(i) == vw && GetPlayerInterior(i) == int)
        {
            if (IsPlayerInRangeOfPoint(i, radius, pos_x, pos_y, pos_z))
            {
                SendClientMessage(i, color, text);
            }
        }
    }
}

public OnPlayerText(playerid, text[])
{
    if (!PlayerData[playerid][pLoggedIn])
    {
        SendClientMessage(playerid, COLOR_RED, "Anda belum login!");
        return 0;
    }

    new sender_name[48];
    if (PlayerData[playerid][pMaskActive])
    {
        format(sender_name, sizeof(sender_name), "Topeng_%d", playerid + 100);
    }
    else
    {
        format(sender_name, sizeof(sender_name), "%s", GetPlayerNameEx(playerid));
    }

    new message[256];
    format(message, sizeof(message), "%s berkata: %s", sender_name, text);
    SendLocalMessage(playerid, 20.0, COLOR_WHITE, message);
    return 0;
}

// =============================================================================
// COMMANDS (ROLEPLAY, ADMIN, HOUSES, VEHICLES & UTILITIES)
// =============================================================================
public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!PlayerData[playerid][pLoggedIn])
    {
        SendClientMessage(playerid, COLOR_RED, "Anda harus login untuk menggunakan perintah.");
        return 1;
    }

    new idx;
    new cmd[64];
    GetNextToken(cmdtext, idx, cmd);

    // =========================================================================
    // PERINTAH ADMIN & TELEPORTASI
    // =========================================================================

    // Perintah: /aduty, /adminduty (Toggle Admin Duty & God Mode)
    if (strcmp(cmd, "/aduty", true) == 0 || strcmp(cmd, "/adminduty", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1)
        {
            return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini khusus untuk Administrator!");
        }

        SetAdminDuty(playerid, !PlayerData[playerid][pAdminDuty]);
        return 1;
    }

    // Perintah: /setmyadmin [level] (Klaim pangkat admin untuk pengembang/pemilik server)
    if (strcmp(cmd, "/setmyadmin", true) == 0 || strcmp(cmd, "/adminme", true) == 0)
    {
        new lvl_str[16];
        GetNextToken(cmdtext, idx, lvl_str);
        new level = (lvl_str[0] == '\0') ? 5 : strval(lvl_str);

        if (level < 0 || level > 5) level = 5;

        PlayerData[playerid][pAdmin] = level;
        SavePlayerData(playerid);
        if (level >= 1) SetAdminDuty(playerid, true);
        else SetAdminDuty(playerid, false);

        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Pangkat Anda berhasil diatur menjadi Admin Level %d! Gunakan /ahelp untuk perintah.", level);
        SendClientMessage(playerid, COLOR_LIME, msg);
        return 1;
    }

    // Perintah: /makeadmin [targetid] [level]
    if (strcmp(cmd, "/makeadmin", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 5) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini khusus Server Owner (Admin Level 5)!");

        new target_str[16], lvl_str[16];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, lvl_str);

        if (target_str[0] == '\0' || lvl_str[0] == '\0')
        {
            return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /makeadmin [playerid] [level 0-5]");
        }

        new targetid = strval(target_str);
        new level = strval(lvl_str);

        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Pemain tidak ditemukan atau belum login!");
        }

        PlayerData[targetid][pAdmin] = level;
        SavePlayerData(targetid);
        if (level >= 1) SetAdminDuty(targetid, true);
        else SetAdminDuty(targetid, false);

        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Anda telah menetapkan %s sebagai Admin Level %d.", GetPlayerNameEx(targetid), level);
        SendClientMessage(playerid, COLOR_GREEN, msg);

        format(msg, sizeof(msg), "[ADMIN] Anda telah diangkat menjadi Admin Level %d oleh %s.", level, GetPlayerNameEx(playerid));
        SendClientMessage(targetid, COLOR_LIME, msg);
        return 1;
    }

    // Perintah: /setfaction [playerid] [faction 0-2] [rank 1-5]
    if (strcmp(cmd, "/setfaction", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 3) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini khusus Admin Level 3+!");

        new target_str[16], fac_str[16], rank_str[16];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, fac_str);
        GetNextToken(cmdtext, idx, rank_str);

        if (target_str[0] == '\0' || fac_str[0] == '\0')
        {
            SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /setfaction [playerid] [faction (0: Warga, 1: SAPD, 2: SAMD)] [rank (1-5)]");
            return 1;
        }

        new targetid = strval(target_str);
        new fac = strval(fac_str);
        new rank = (rank_str[0] == '\0') ? 1 : strval(rank_str);

        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Pemain tidak ditemukan atau belum login!");
        }

        if (fac < 0 || fac > 2) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Faksi tidak valid! 0: Sipil, 1: SAPD, 2: SAMD.");
        if (rank < 1) rank = 1;
        if (rank > 5) rank = 5;

        PlayerData[targetid][pFaction] = fac;
        PlayerData[targetid][pFactionRank] = (fac == 0) ? 0 : rank;
        PlayerData[targetid][pOnDuty] = false;
        UpdatePlayerFactionBadge(targetid);
        SavePlayerData(targetid);

        new f_name[48], r_name[32], msg[160];
        GetFactionName(fac, f_name, sizeof(f_name));
        GetFactionRankName(fac, rank, r_name, sizeof(r_name));

        format(msg, sizeof(msg), "[ADMIN] Anda menetapkan %s ke %s dengan pangkat %s.", GetPlayerNameEx(targetid), f_name, r_name);
        SendClientMessage(playerid, COLOR_GREEN, msg);

        format(msg, sizeof(msg), "[FAKSI] Anda telah dimasukkan ke faksi %s (Pangkat: %s) oleh Admin %s.", f_name, r_name, GetPlayerNameEx(playerid));
        SendClientMessage(targetid, COLOR_LIME, msg);
        return 1;
    }

    // Perintah: /tp atau /teleport (Menu Dialog Teleportasi Cepat)
    if (strcmp(cmd, "/tp", true) == 0 || strcmp(cmd, "/teleport", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda bukan Admin server!");
        OpenAdminTeleportMenu(playerid);
        return 1;
    }

    // Perintah: /goto [targetid]
    if (strcmp(cmd, "/goto", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda bukan Admin server!");

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /goto [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Pemain tidak ditemukan!");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(targetid, x, y, z);
        SetPlayerPos(playerid, x + 1.0, y + 1.0, z);
        SetPlayerInterior(playerid, GetPlayerInterior(targetid));
        SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));

        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Anda teleportasi ke posisi %s (ID: %d).", GetPlayerNameEx(targetid), targetid);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        return 1;
    }

    // Perintah: /gethere [targetid]
    if (strcmp(cmd, "/gethere", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda bukan Admin server!");

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /gethere [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Pemain tidak ditemukan!");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        SetPlayerPos(targetid, x + 1.0, y + 1.0, z);
        SetPlayerInterior(targetid, GetPlayerInterior(playerid));
        SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));

        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Anda telah menarik %s (ID: %d) ke posisi Anda.", GetPlayerNameEx(targetid), targetid);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SendClientMessage(targetid, COLOR_YELLOW, "[ADMIN] Anda ditarik oleh Admin ke posisinya.");
        return 1;
    }

    // Perintah: /jetpack atau /jp
    if (strcmp(cmd, "/jetpack", true) == 0 || strcmp(cmd, "/jp", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda bukan Admin server!");

        SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
        SendClientMessage(playerid, COLOR_LIME, "[ADMIN] Jetpack diberikan! Terbang bebas menjelajahi San Andreas.");
        return 1;
    }

    // Perintah: /veh [modelid] (Spawn Kendaraan Instan)
    if (strcmp(cmd, "/veh", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda bukan Admin server!");

        new model_str[16];
        GetNextToken(cmdtext, idx, model_str);
        if (model_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /veh [modelid (400 - 611)] (Contoh: /veh 411 untuk Infernus)");

        new model = strval(model_str);
        if (model < 400 || model > 611) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Model kendaraan harus antara 400 sampai 611!");

        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);

        new veh = CreateVehicle(model, x, y, z, a, -1, -1, 120);
        PutPlayerInVehicle(playerid, veh, 0);
        SetVehicleParamsEx(veh, 1, 1, 0, 0, 0, 0, 0);

        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Berhasil memunculkan kendaraan model %d.", model);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        return 1;
    }

    // Perintah: /destroyveh atau /dv
    if (strcmp(cmd, "/destroyveh", true) == 0 || strcmp(cmd, "/dv", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda bukan Admin server!");

        if (!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda harus berada di dalam kendaraan yang ingin dihapus!");

        new veh = GetPlayerVehicleID(playerid);
        DestroyVehicle(veh);
        SendClientMessage(playerid, COLOR_GREEN, "[ADMIN] Kendaraan berhasil dihapus.");
        return 1;
    }

    // Perintah: /heal (Memulihkan Status Penuh)
    if (strcmp(cmd, "/heal", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda bukan Admin server!");

        SetPlayerHealth(playerid, 100.0);
        SetPlayerArmour(playerid, 100.0);
        PlayerData[playerid][pHunger] = 100;
        PlayerData[playerid][pThirst] = 100;
        SendClientMessage(playerid, COLOR_LIME, "[ADMIN] Tubuh Anda telah dipulihkan sepenuhnya (100% HP, Armour, Lapar & Haus).");
        return 1;
    }

    // Perintah: /givemoney [targetid] [amount]
    if (strcmp(cmd, "/givemoney", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 4) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini membutuhkan Admin Level 4+!");

        new target_str[16], amount_str[16];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, amount_str);

        if (target_str[0] == '\0' || amount_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /givemoney [playerid] [jumlah uang]");

        new targetid = strval(target_str);
        new amount = strval(amount_str);

        if (!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Pemain tidak ditemukan!");

        GivePlayerMoney(targetid, amount);
        SavePlayerData(targetid);

        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Anda memberikan uang $%d kepada %s.", amount, GetPlayerNameEx(targetid));
        SendClientMessage(playerid, COLOR_GREEN, msg);
        return 1;
    }

    // Perintah: /setmoney [targetid] [amount] [opsional: cash/bank]
    if (strcmp(cmd, "/setmoney", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 2) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini membutuhkan Admin Level 2+!");

        new target_str[16], amount_str[16], type_str[16];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, amount_str);
        GetNextToken(cmdtext, idx, type_str);

        if (target_str[0] == '\0' || amount_str[0] == '\0')
        {
            return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /setmoney [playerid] [jumlah] [opsional: cash/bank]");
        }

        new targetid = strval(target_str);
        new amount = strval(amount_str);

        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
            return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Pemain tidak ditemukan atau belum login!");

        if (amount < 0) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Jumlah uang tidak boleh negatif!");

        new msg[144];
        if (strcmp(type_str, "bank", true) == 0)
        {
            PlayerData[targetid][pBank] = amount;
            format(msg, sizeof(msg), "[ADMIN] Anda mengatur saldo Bank %s menjadi $%d.", GetPlayerNameEx(targetid), amount);
            SendClientMessage(playerid, COLOR_GREEN, msg);

            format(msg, sizeof(msg), "[BANK] Saldo rekening bank Anda telah diatur menjadi $%d oleh Admin %s.", amount, GetPlayerNameEx(playerid));
            SendClientMessage(targetid, COLOR_YELLOW, msg);
        }
        else
        {
            ResetPlayerMoney(targetid);
            GivePlayerMoney(targetid, amount);
            PlayerData[targetid][pMoney] = amount;

            format(msg, sizeof(msg), "[ADMIN] Anda mengatur uang cash %s menjadi $%d.", GetPlayerNameEx(targetid), amount);
            SendClientMessage(playerid, COLOR_GREEN, msg);

            format(msg, sizeof(msg), "[UANG] Uang tunai Anda telah diatur menjadi $%d oleh Admin %s.", amount, GetPlayerNameEx(playerid));
            SendClientMessage(targetid, COLOR_YELLOW, msg);
        }

        SavePlayerData(targetid);
        return 1;
    }

    // Perintah: /setbank [targetid] [amount]
    if (strcmp(cmd, "/setbank", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 2) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini membutuhkan Admin Level 2+!");

        new target_str[16], amount_str[16];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, amount_str);

        if (target_str[0] == '\0' || amount_str[0] == '\0')
            return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /setbank [playerid] [jumlah]");

        new targetid = strval(target_str);
        new amount = strval(amount_str);

        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
            return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Pemain tidak ditemukan atau belum login!");

        if (amount < 0) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Jumlah uang tidak boleh negatif!");

        PlayerData[targetid][pBank] = amount;
        SavePlayerData(targetid);

        new msg[144];
        format(msg, sizeof(msg), "[ADMIN] Anda mengatur saldo Bank %s menjadi $%d.", GetPlayerNameEx(targetid), amount);
        SendClientMessage(playerid, COLOR_GREEN, msg);

        format(msg, sizeof(msg), "[BANK] Saldo rekening bank Anda telah diatur menjadi $%d oleh Admin %s.", amount, GetPlayerNameEx(playerid));
        SendClientMessage(targetid, COLOR_YELLOW, msg);
        return 1;
    }

    // Perintah: /sethouse [sub-command]
    if (strcmp(cmd, "/sethouse", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 3) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini membutuhkan Admin Level 3+!");

        new subcmd[16];
        GetNextToken(cmdtext, idx, subcmd);

        if (subcmd[0] == '\0')
        {
            SendClientMessage(playerid, COLOR_CYAN, "=== PERINTAH ADMIN PENGATURAN RUMAH (/sethouse) ===");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse list - Menampilkan daftar semua ID rumah dan pemiliknya");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse owner [houseid] [playerid/0] - Mengatur pemilik rumah (0 = dijual)");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse price [houseid] [harga] - Mengatur harga jual rumah");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse pos [houseid] - Mengubah koordinat pintu masuk ke posisi Anda berdiri");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse address [houseid] [alamat...] - Mengubah nama / alamat jalan rumah");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse int [houseid] [tipe: 1-6] - Mengubah desain interior rumah (4=Richman)");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse lock [houseid] - Mengunci / membuka kunci pintu rumah");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse tp [houseid] - Teleportasi langsung ke pintu depan rumah");
            SendClientMessage(playerid, COLOR_YELLOW, "/sethouse delete [houseid] - Menghapus properti rumah secara permanen");
            SendClientMessage(playerid, COLOR_YELLOW, "/createhouse [harga] [tipe: 1-6] [alamat...] - Membuat rumah baru di posisi Anda");
            return 1;
        }

        // Sub-command: list
        if (strcmp(subcmd, "list", true) == 0)
        {
            SendClientMessage(playerid, COLOR_CYAN, "--- DAFTAR SELURUH PROPERTI RUMAH ---");
            for (new i = 0; i < g_TotalHouses; i++)
            {
                new msg[160];
                format(msg, sizeof(msg), "ID: %d (DB: %d) | Alamat: %s | Pemilik: %s | Harga: $%d | Kunci: %s",
                    i, HouseData[i][hID], HouseData[i][hAddress], HouseData[i][hOwnerName], HouseData[i][hPrice],
                    HouseData[i][hLocked] ? ("Terkunci") : ("Terbuka")
                );
                SendClientMessage(playerid, COLOR_WHITE, msg);
            }
            return 1;
        }

        // Sub-command: owner
        if (strcmp(subcmd, "owner", true) == 0)
        {
            new hid_str[16], target_str[16];
            GetNextToken(cmdtext, idx, hid_str);
            GetNextToken(cmdtext, idx, target_str);

            if (hid_str[0] == '\0' || target_str[0] == '\0')
            {
                return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse owner [houseid] [playerid / 0 untuk hapus pemilik]");
            }

            new hid = strval(hid_str);
            new h_idx = GetHouseIndexByID(hid);
            if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

            new targetid = strval(target_str);
            new msg[160];

            if (targetid == 0 && strcmp(target_str, "0", true) == 0)
            {
                // Reset / unown house
                HouseData[h_idx][hOwnerID] = 0;
                format(HouseData[h_idx][hOwnerName], MAX_PLAYER_NAME, "Tidak Ada");
                HouseData[h_idx][hLocked] = false;
                SaveHouseData(h_idx);
                UpdateHouseLabel(h_idx);

                format(msg, sizeof(msg), "[ADMIN] Rumah ID %d (%s) sekarang berstatus DIJUAL (pemilik dihapus).", HouseData[h_idx][hID], HouseData[h_idx][hAddress]);
                SendClientMessage(playerid, COLOR_GREEN, msg);
                return 1;
            }

            if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
            {
                return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Pemain tidak ditemukan atau belum login!");
            }

            HouseData[h_idx][hOwnerID] = PlayerData[targetid][pID];
            format(HouseData[h_idx][hOwnerName], MAX_PLAYER_NAME, "%s", GetPlayerNameEx(targetid));
            SaveHouseData(h_idx);
            UpdateHouseLabel(h_idx);

            format(msg, sizeof(msg), "[ADMIN] Anda memberikan kepemilikan Rumah ID %d (%s) kepada %s.",
                HouseData[h_idx][hID], HouseData[h_idx][hAddress], GetPlayerNameEx(targetid));
            SendClientMessage(playerid, COLOR_GREEN, msg);

            format(msg, sizeof(msg), "[RUMAH] Admin %s telah memberikan kepemilikan Rumah ID %d (%s) kepada Anda!",
                GetPlayerNameEx(playerid), HouseData[h_idx][hID], HouseData[h_idx][hAddress]);
            SendClientMessage(targetid, COLOR_YELLOW, msg);
            return 1;
        }

        // Sub-command: price
        if (strcmp(subcmd, "price", true) == 0)
        {
            new hid_str[16], price_str[16];
            GetNextToken(cmdtext, idx, hid_str);
            GetNextToken(cmdtext, idx, price_str);

            if (hid_str[0] == '\0' || price_str[0] == '\0')
            {
                return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse price [houseid] [harga baru]");
            }

            new hid = strval(hid_str);
            new h_idx = GetHouseIndexByID(hid);
            if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

            new price = strval(price_str);
            if (price < 0) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Harga tidak boleh negatif!");

            HouseData[h_idx][hPrice] = price;
            SaveHouseData(h_idx);
            UpdateHouseLabel(h_idx);

            new msg[160];
            format(msg, sizeof(msg), "[ADMIN] Harga Rumah ID %d (%s) diatur menjadi $%d.", HouseData[h_idx][hID], HouseData[h_idx][hAddress], price);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        // Sub-command: pos
        if (strcmp(subcmd, "pos", true) == 0)
        {
            new hid_str[16];
            GetNextToken(cmdtext, idx, hid_str);

            if (hid_str[0] == '\0')
            {
                return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse pos [houseid]");
            }

            new hid = strval(hid_str);
            new h_idx = GetHouseIndexByID(hid);
            if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

            new Float:hx, Float:hy, Float:hz;
            GetPlayerPos(playerid, hx, hy, hz);

            HouseData[h_idx][hEnterX] = hx;
            HouseData[h_idx][hEnterY] = hy;
            HouseData[h_idx][hEnterZ] = hz;
            SaveHouseData(h_idx);
            UpdateHouseLabel(h_idx);

            new msg[160];
            format(msg, sizeof(msg), "[ADMIN] Posisi pintu Rumah ID %d (%s) telah dipindahkan ke posisi Anda saat ini.", HouseData[h_idx][hID], HouseData[h_idx][hAddress]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        // Sub-command: address
        if (strcmp(subcmd, "address", true) == 0)
        {
            new hid_str[16];
            GetNextToken(cmdtext, idx, hid_str);

            if (hid_str[0] == '\0')
            {
                return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse address [houseid] [alamat baru...]");
            }

            new hid = strval(hid_str);
            new h_idx = GetHouseIndexByID(hid);
            if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

            while (cmdtext[idx] == ' ') idx++;
            if (cmdtext[idx] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse address [houseid] [alamat baru...]");

            format(HouseData[h_idx][hAddress], 48, "%s", cmdtext[idx]);
            SaveHouseData(h_idx);
            UpdateHouseLabel(h_idx);

            new msg[160];
            format(msg, sizeof(msg), "[ADMIN] Alamat Rumah ID %d diubah menjadi: %s.", HouseData[h_idx][hID], HouseData[h_idx][hAddress]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        // Sub-command: int / interior
        if (strcmp(subcmd, "int", true) == 0 || strcmp(subcmd, "interior", true) == 0)
        {
            new hid_str[16], int_type_str[16];
            GetNextToken(cmdtext, idx, hid_str);
            GetNextToken(cmdtext, idx, int_type_str);

            if (hid_str[0] == '\0' || int_type_str[0] == '\0')
            {
                SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse int [houseid] [tipe: 1-6]");
                SendClientMessage(playerid, COLOR_YELLOW, "Tipe: 1=Ganton Kecil, 2=Jefferson 2-Kamar, 3=Idlewood Flat, 4=Richman Villa Mewah, 5=Mansion Sultan Madd Dogg, 6=Penthouse");
                return 1;
            }

            new hid = strval(hid_str);
            new h_idx = GetHouseIndexByID(hid);
            if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

            new p_int, Float:p_ex, Float:p_ey, Float:p_ez;
            GetHouseInteriorPreset(strval(int_type_str), p_int, p_ex, p_ey, p_ez);

            HouseData[h_idx][hInterior] = p_int;
            HouseData[h_idx][hExitX] = p_ex;
            HouseData[h_idx][hExitY] = p_ey;
            HouseData[h_idx][hExitZ] = p_ez;
            SaveHouseData(h_idx);
            UpdateHouseLabel(h_idx);

            new msg[160];
            format(msg, sizeof(msg), "[ADMIN] Interior Rumah ID %d (%s) diubah ke Tipe %d (Interior ID: %d).",
                HouseData[h_idx][hID], HouseData[h_idx][hAddress], strval(int_type_str), p_int);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        // Sub-command: tp / goto
        if (strcmp(subcmd, "tp", true) == 0 || strcmp(subcmd, "goto", true) == 0)
        {
            new hid_str[16];
            GetNextToken(cmdtext, idx, hid_str);

            if (hid_str[0] == '\0')
            {
                return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse tp [houseid]");
            }

            new hid = strval(hid_str);
            new h_idx = GetHouseIndexByID(hid);
            if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

            SetPlayerPos(playerid, HouseData[h_idx][hEnterX], HouseData[h_idx][hEnterY], HouseData[h_idx][hEnterZ] + 0.5);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);

            new msg[160];
            format(msg, sizeof(msg), "[ADMIN] Teleportasi ke pintu depan Rumah ID %d (%s).", HouseData[h_idx][hID], HouseData[h_idx][hAddress]);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        // Sub-command: lock
        if (strcmp(subcmd, "lock", true) == 0)
        {
            new hid_str[16];
            GetNextToken(cmdtext, idx, hid_str);

            if (hid_str[0] == '\0')
            {
                return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse lock [houseid]");
            }

            new hid = strval(hid_str);
            new h_idx = GetHouseIndexByID(hid);
            if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

            HouseData[h_idx][hLocked] = !HouseData[h_idx][hLocked];
            SaveHouseData(h_idx);
            UpdateHouseLabel(h_idx);

            new msg[160];
            format(msg, sizeof(msg), "[ADMIN] Status Rumah ID %d (%s) sekarang: %s.",
                HouseData[h_idx][hID], HouseData[h_idx][hAddress], HouseData[h_idx][hLocked] ? ("Terkunci") : ("Terbuka"));
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }

        // Sub-command: delete / destroy
        if (strcmp(subcmd, "delete", true) == 0 || strcmp(subcmd, "destroy", true) == 0)
        {
            new hid_str[16];
            GetNextToken(cmdtext, idx, hid_str);

            new h_idx = -1;
            if (hid_str[0] == '\0')
            {
                h_idx = GetNearHouseEntrance(playerid);
                if (h_idx == -1) h_idx = GetCurrentHouseIndex(playerid);
                if (h_idx == -1)
                {
                    return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /sethouse delete [houseid] (atau berdiri di dekat pintu rumah)");
                }
            }
            else
            {
                h_idx = GetHouseIndexByID(strval(hid_str));
            }

            if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

            new h_id_copy = HouseData[h_idx][hID];
            new h_addr[48];
            format(h_addr, sizeof(h_addr), "%s", HouseData[h_idx][hAddress]);

            DestroyHouse(h_idx);

            new msg[160];
            format(msg, sizeof(msg), "[ADMIN] Berhasil menghapus Rumah ID %d (%s) secara permanen!", h_id_copy, h_addr);
            SendClientMessage(playerid, COLOR_RED, msg);
            return 1;
        }

        SendClientMessage(playerid, COLOR_GREY, "Sub-command tidak valid! Ketik /sethouse untuk melihat panduan.");
        return 1;
    }

    // Perintah: /createhouse [harga] [tipe: 1-6] [alamat...]
    if (strcmp(cmd, "/createhouse", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 3) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini membutuhkan Admin Level 3+!");

        if (g_TotalHouses >= MAX_HOUSES)
        {
            return SendClientMessage(playerid, COLOR_RED, "[RUMAH] Batas maksimum jumlah rumah di server telah tercapai!");
        }

        new price_str[16], int_str[16];
        GetNextToken(cmdtext, idx, price_str);
        GetNextToken(cmdtext, idx, int_str);

        while (cmdtext[idx] == ' ') idx++;

        if (price_str[0] == '\0' || int_str[0] == '\0' || cmdtext[idx] == '\0')
        {
            SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /createhouse [harga] [tipe_interior: 1-6] [alamat rumah...]");
            SendClientMessage(playerid, COLOR_YELLOW, "Tipe: 1=Ganton Kecil, 2=Jefferson 2-Kamar, 3=Idlewood Flat, 4=Richman Villa Mewah, 5=Mansion Sultan Madd Dogg, 6=Penthouse");
            return 1;
        }

        new price = strval(price_str);
        new int_type = strval(int_str);
        if (price < 0) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Harga tidak boleh negatif!");

        new Float:hx, Float:hy, Float:hz;
        GetPlayerPos(playerid, hx, hy, hz);

        new p_int, Float:p_ex, Float:p_ey, Float:p_ez;
        GetHouseInteriorPreset(int_type, p_int, p_ex, p_ey, p_ez);

        new address[48];
        format(address, sizeof(address), "%s", cmdtext[idx]);

        new query[450];
        format(query, sizeof(query),
            "INSERT INTO houses (owner_id, price, address, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, safe_money) VALUES (0, %d, '%s', %f, %f, %f, %f, %f, %f, %d, 1, 0);",
            price, address, hx, hy, hz, p_ex, p_ey, p_ez, p_int
        );
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));

        new DBResult:res = DB_ExecuteQuery(g_DB, "SELECT id FROM houses ORDER BY id DESC LIMIT 1;");
        new new_id = 0;
        if (DB_GetRowCount(res) > 0)
        {
            new_id = DB_GetFieldIntByName(res, "id");
        }
        DB_FreeResultSet(res);

        new idx_h = g_TotalHouses;
        HouseData[idx_h][hID] = new_id;
        HouseData[idx_h][hOwnerID] = 0;
        format(HouseData[idx_h][hOwnerName], MAX_PLAYER_NAME, "Tidak Ada");
        HouseData[idx_h][hPrice] = price;
        format(HouseData[idx_h][hAddress], 48, "%s", address);
        HouseData[idx_h][hEnterX] = hx;
        HouseData[idx_h][hEnterY] = hy;
        HouseData[idx_h][hEnterZ] = hz;
        HouseData[idx_h][hExitX] = p_ex;
        HouseData[idx_h][hExitY] = p_ey;
        HouseData[idx_h][hExitZ] = p_ez;
        HouseData[idx_h][hInterior] = p_int;
        HouseData[idx_h][hLocked] = true;
        HouseData[idx_h][hSafeMoney] = 0;
        HouseData[idx_h][hPickup] = 0;
        HouseData[idx_h][hLabel] = Text3D:INVALID_3DTEXT_ID;
        HouseData[idx_h][hExitPickup] = 0;
        HouseData[idx_h][hExitLabel] = Text3D:INVALID_3DTEXT_ID;
        HouseData[idx_h][hLoaded] = true;

        UpdateHouseLabel(idx_h);
        g_TotalHouses++;

        new msg[180];
        format(msg, sizeof(msg), "[ADMIN] Berhasil membuat Rumah Baru ID %d di posisi Anda! Alamat: %s | Harga: $%d | Tipe Int: %d",
            new_id, address, price, int_type);
        SendClientMessage(playerid, COLOR_LIME, msg);
        return 1;
    }

    // Perintah: /destroyhouse [houseid] atau /deletehouse [houseid]
    if (strcmp(cmd, "/destroyhouse", true) == 0 || strcmp(cmd, "/deletehouse", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 3) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini membutuhkan Admin Level 3+!");

        new hid_str[16];
        GetNextToken(cmdtext, idx, hid_str);

        new h_idx = -1;
        if (hid_str[0] == '\0')
        {
            h_idx = GetNearHouseEntrance(playerid);
            if (h_idx == -1) h_idx = GetCurrentHouseIndex(playerid);
            if (h_idx == -1)
            {
                return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /destroyhouse [houseid] (atau berdiri di dekat pintu rumah)");
            }
        }
        else
        {
            h_idx = GetHouseIndexByID(strval(hid_str));
        }

        if (h_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[RUMAH] ID rumah tidak ditemukan! Gunakan /sethouse list.");

        new h_id_copy = HouseData[h_idx][hID];
        new h_addr[48];
        format(h_addr, sizeof(h_addr), "%s", HouseData[h_idx][hAddress]);

        DestroyHouse(h_idx);

        new msg[160];
        format(msg, sizeof(msg), "[ADMIN] Berhasil menghapus Rumah ID %d (%s) secara permanen dari server & database!", h_id_copy, h_addr);
        SendClientMessage(playerid, COLOR_RED, msg);
        return 1;
    }

    // Perintah: /ahelp (Daftar Perintah Admin)
    if (strcmp(cmd, "/ahelp", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 1) return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Anda bukan Admin server!");

        new ahelp[1200];
        format(ahelp, sizeof(ahelp),
            "{00AAFF}=== MENU BANTUAN ADMIN (LEVEL %d) ==={FFFFFF}\n\n"\
            "{00FF00}[STATUS TUGAS & MODE DEWA]{FFFFFF}\n"\
            "* {FFFF00}/aduty / /adminduty{FFFFFF}: Toggle Admin Duty & God Mode (Kebal peluru/ledakan/mati)\n\n"\
            "{00FF00}[NAVIGASI & TELEPORTASI INSTAN]{FFFFFF}\n"\
            "* {FFFF00}Klik Peta Map (ESC -> MAP){FFFFFF}: Teleportasi instan langsung ke titik yang Anda klik!\n"\
            "* {FFFF00}/tp / /teleport{FFFFFF}: Menu dialog 13 titik lokasi populer San Andreas\n"\
            "* {FFFF00}/goto [playerid]{FFFFFF}: Teleportasi ke posisi pemain target\n"\
            "* {FFFF00}/gethere [playerid]{FFFFFF}: Menarik pemain target ke hadapan Anda\n"\
            "* {FFFF00}/jetpack (/jp){FFFFFF}: Memberikan jetpack terbang instan\n\n"\
            "{00FF00}[KENDARAAN & FASILITAS]{FFFFFF}\n"\
            "* {FFFF00}/veh [modelid]{FFFFFF}: Spawn kendaraan apapun seketika (e.g. 411 Infernus, 522 NRG)\n"\
            "* {FFFF00}/destroyveh (/dv){FFFFFF}: Menghapus kendaraan sementara\n"\
            "* {FFFF00}/heal{FFFFFF}: Memulihkan 100%% HP, Armour, Lapar & Haus\n"\
            "* {FFFF00}/givemoney [id] [uang]{FFFFFF}: Menambahkan uang cash pemain\n"\
            "* {FFFF00}/setmoney [id] [uang] [cash/bank]{FFFFFF}: Mengatur uang cash / saldo bank pemain\n"\
            "* {FFFF00}/setbank [id] [uang]{FFFFFF}: Mengatur saldo bank pemain langsung\n"\
            "* {FFFF00}/sethouse [list/owner/price/pos/address/int/tp/lock/delete]{FFFFFF}: Manajemen rumah\n"\
            "* {FFFF00}/createhouse [harga] [tipe: 1-6] [alamat...]{FFFFFF}: Buat rumah baru di posisi berdiri\n"\
            "* {FFFF00}/destroyhouse [houseid]{FFFFFF}: Menghapus rumah permanen dari database\n"\
            "* {FFFF00}/setbiz [list/tp/price/owner/name/pos/lock/delete]{FFFFFF}: Manajemen bisnis server\n"\
            "* {FFFF00}/createbiz [harga] [tipe: 1-3] [nama...]{FFFFFF}: Buat bisnis baru di posisi berdiri\n"\
            "* {FFFF00}/destroybiz [bizid]{FFFFFF}: Menghapus bisnis permanen dari database\n"\
            "* {FFFF00}/makeadmin [id] [level]{FFFFFF}: Memberikan pangkat admin ke pemain lain\n"\
            "* {FFFF00}/setmyadmin [level]{FFFFFF}: Mengatur level admin diri sendiri (1-5)\n"\
            "* {FFFF00}/setfaction [id] [fac] [rank]{FFFFFF}: Mengatur faksi pemain (1: SAPD, 2: SAMD)"
        );
        ShowPlayerDialog(playerid, DIALOG_ADMIN_HELP, DIALOG_STYLE_MSGBOX, "{00AAFF}Daftar Perintah Admin", ahelp, "Tutup", "");
        return 1;
    }

    // =========================================================================
    // PERINTAH RUMAH & KENDARAAN REGULER
    // =========================================================================

    // Perintah: /buyhouse
    if (strcmp(cmd, "/buyhouse", true) == 0)
    {
        new h_idx = GetNearHouseEntrance(playerid);
        if (h_idx == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "[RUMAH] Anda tidak berada di dekat pintu rumah yang dijual!");
            return 1;
        }

        if (HouseData[h_idx][hOwnerID] != 0)
        {
            SendClientMessage(playerid, COLOR_RED, "[RUMAH] Rumah ini sudah memiliki pemilik!");
            return 1;
        }

        new price = HouseData[h_idx][hPrice];
        if (GetPlayerMoney(playerid) < price)
        {
            new msg[128];
            format(msg, sizeof(msg), "[RUMAH] Uang tunai Anda tidak mencukupi untuk membeli rumah ini ($%d)!", price);
            return SendClientMessage(playerid, COLOR_RED, msg);
        }

        GivePlayerMoney(playerid, -price);
        HouseData[h_idx][hOwnerID] = PlayerData[playerid][pID];
        format(HouseData[h_idx][hOwnerName], MAX_PLAYER_NAME, "%s", GetPlayerNameEx(playerid));
        HouseData[h_idx][hLocked] = true;

        SaveHouseData(h_idx);
        SavePlayerData(playerid);
        UpdateHouseLabel(h_idx);

        new msg[160];
        format(msg, sizeof(msg), "[RUMAH] Selamat! Anda resmi menjadi pemilik rumah di %s seharga $%d.", HouseData[h_idx][hAddress], price);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SendClientMessage(playerid, COLOR_YELLOW, "[PETUNJUK] Gunakan /houselock untuk kunci/buka pintu, /enter untuk masuk, dan /housesafe untuk brankas.");
        return 1;
    }

    // Perintah: /enter
    if (strcmp(cmd, "/enter", true) == 0)
    {
        new h_in = GetNearHouseEntrance(playerid);
        if (h_in != -1)
        {
            if (HouseData[h_in][hLocked] && HouseData[h_in][hOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[RUMAH] Pintu rumah ini sedang terkunci!");
            }

            SetPlayerPos(playerid, HouseData[h_in][hExitX], HouseData[h_in][hExitY], HouseData[h_in][hExitZ]);
            SetPlayerInterior(playerid, HouseData[h_in][hInterior]);
            SetPlayerVirtualWorld(playerid, HouseData[h_in][hID] + 100);
            PlayerData[playerid][pInterior] = HouseData[h_in][hInterior];
            PlayerData[playerid][pVirtualWorld] = HouseData[h_in][hID] + 100;
            SavePlayerData(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "[RUMAH] Anda memasuki rumah. Ketik /exit atau tekan [ENTER / F] di dekat pintu untuk keluar.");
            return 1;
        }

        new b_in = GetNearBusinessEntrance(playerid);
        if (b_in != -1)
        {
            if (BizData[b_in][bLocked] && BizData[b_in][bOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Pintu bisnis ini sedang tutup / terkunci!");
            }

            SetPlayerPos(playerid, BizData[b_in][bExitX], BizData[b_in][bExitY], BizData[b_in][bExitZ]);
            SetPlayerInterior(playerid, BizData[b_in][bInterior]);
            SetPlayerVirtualWorld(playerid, BizData[b_in][bID] + 500);
            PlayerData[playerid][pInterior] = BizData[b_in][bInterior];
            PlayerData[playerid][pVirtualWorld] = BizData[b_in][bID] + 500;
            SavePlayerData(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "[BISNIS] Anda memasuki bisnis. Ketik /buy untuk belanja atau /exit untuk keluar.");
            return 1;
        }

        SendClientMessage(playerid, COLOR_RED, "[INFO] Anda tidak berada di pintu masuk rumah atau bisnis manapun!");
        return 1;
    }

    // Perintah: /exit
    if (strcmp(cmd, "/exit", true) == 0)
    {
        new h_out = GetNearHouseExit(playerid);
        if (h_out == -1)
        {
            h_out = GetCurrentHouseIndex(playerid);
        }

        if (h_out != -1)
        {
            SetPlayerPos(playerid, HouseData[h_out][hEnterX], HouseData[h_out][hEnterY], HouseData[h_out][hEnterZ]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            PlayerData[playerid][pInterior] = 0;
            PlayerData[playerid][pVirtualWorld] = 0;
            SavePlayerData(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "[RUMAH] Anda keluar dari rumah.");
            return 1;
        }

        new b_out = GetNearBusinessExit(playerid);
        if (b_out == -1)
        {
            b_out = GetCurrentBusinessIndex(playerid);
        }

        if (b_out != -1)
        {
            SetPlayerPos(playerid, BizData[b_out][bEnterX], BizData[b_out][bEnterY], BizData[b_out][bEnterZ]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            PlayerData[playerid][pInterior] = 0;
            PlayerData[playerid][pVirtualWorld] = 0;
            SavePlayerData(playerid);
            SendClientMessage(playerid, COLOR_GREEN, "[BISNIS] Anda keluar dari properti bisnis.");
            return 1;
        }

        SendClientMessage(playerid, COLOR_RED, "[INFO] Anda tidak berada di dalam rumah atau bisnis manapun!");
        return 1;
    }

    // Perintah: /houselock
    if (strcmp(cmd, "/houselock", true) == 0 || strcmp(cmd, "/hl", true) == 0)
    {
        new h_idx = GetNearHouseEntrance(playerid);
        if (h_idx == -1)
        {
            h_idx = GetCurrentHouseIndex(playerid);
        }

        if (h_idx == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "[RUMAH] Anda harus berada di pintu luar atau di dalam rumah Anda untuk mengunci pintu!");
            return 1;
        }

        if (HouseData[h_idx][hOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
        {
            SendClientMessage(playerid, COLOR_RED, "[RUMAH] Anda bukan pemilik rumah ini!");
            return 1;
        }

        HouseData[h_idx][hLocked] = !HouseData[h_idx][hLocked];
        SaveHouseData(h_idx);
        UpdateHouseLabel(h_idx);

        PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0);
        new rp[128];
        if (HouseData[h_idx][hLocked])
        {
            format(rp, sizeof(rp), "* %s memutar anak kunci dan mengunci pintu rumah.", GetPlayerNameEx(playerid));
            SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
            SendClientMessage(playerid, COLOR_YELLOW, "[RUMAH] Pintu rumah telah DIKUNCI.");
        }
        else
        {
            format(rp, sizeof(rp), "* %s memutar anak kunci dan membuka kunci pintu rumah.", GetPlayerNameEx(playerid));
            SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
            SendClientMessage(playerid, COLOR_GREEN, "[RUMAH] Pintu rumah telah DIBUKA.");
        }
        return 1;
    }

    // Perintah: /housesafe
    if (strcmp(cmd, "/housesafe", true) == 0 || strcmp(cmd, "/brankas", true) == 0)
    {
        new h_idx = GetCurrentHouseIndex(playerid);
        if (h_idx == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "[BRANKAS] Anda harus berada di dalam rumah untuk mengakses brankas!");
            return 1;
        }

        if (HouseData[h_idx][hOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
        {
            SendClientMessage(playerid, COLOR_RED, "[BRANKAS] Anda bukan pemilik rumah ini!");
            return 1;
        }

        OpenHouseSafeMenu(playerid, h_idx);
        return 1;
    }

    // Perintah: /myhouse
    if (strcmp(cmd, "/myhouse", true) == 0)
    {
        new count = 0;
        for (new i = 0; i < g_TotalHouses; i++)
        {
            if (HouseData[i][hOwnerID] == PlayerData[playerid][pID])
            {
                count++;
                new msg[160];
                format(msg, sizeof(msg), "[RUMAH SAYA] Alamat: %s | Status: %s | Uang Brankas: $%d",
                    HouseData[i][hAddress], HouseData[i][hLocked] ? ("Terkunci") : ("Terbuka"), HouseData[i][hSafeMoney]
                );
                SendClientMessage(playerid, COLOR_GREEN, msg);
                SetPlayerCheckpoint(playerid, HouseData[i][hEnterX], HouseData[i][hEnterY], HouseData[i][hEnterZ], 3.0);
                SendClientMessage(playerid, COLOR_YELLOW, "[NAVIGASI] Marker merah telah diset ke pintu masuk rumah Anda.");
                break;
            }
        }
        if (count == 0)
        {
            SendClientMessage(playerid, COLOR_RED, "[RUMAH SAYA] Anda belum memiliki properti rumah! Cari rumah bertanda hijau [DIJUAL].");
        }
        return 1;
    }

    // Perintah: /engine
    if (strcmp(cmd, "/engine", true) == 0)
    {
        if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        {
            SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Anda harus berada di kursi pengemudi untuk mengontrol mesin!");
            return 1;
        }

        new veh = GetPlayerVehicleID(playerid);
        new slot = GetVehicleSlotFromID(veh);

        if (slot != -1)
        {
            if (OwnedVehicles[slot][ovOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
            {
                SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Anda bukan pemilik kendaraan ini!");
                return 1;
            }

            if (OwnedVehicles[slot][ovFuel] <= 0.0)
            {
                SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Tangki bensin kosong! Tidak dapat menyalakan mesin.");
                return 1;
            }

            OwnedVehicles[slot][ovEngine] = !OwnedVehicles[slot][ovEngine];
            SetVehicleParamsEx(veh, OwnedVehicles[slot][ovEngine] ? 1 : 0, OwnedVehicles[slot][ovEngine] ? 1 : 0, 0, OwnedVehicles[slot][ovLocked] ? 1 : 0, 0, 0, 0);

            new rp[128];
            if (OwnedVehicles[slot][ovEngine])
            {
                format(rp, sizeof(rp), "* %s memutar kunci kontak dan menyalakan mesin kendaraan.", GetPlayerNameEx(playerid));
                SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
                SendClientMessage(playerid, COLOR_GREEN, "[KENDARAAN] Mesin kendaraan BERHASIL DINYALAKAN.");
            }
            else
            {
                format(rp, sizeof(rp), "* %s memutar kunci kontak dan mematikan mesin kendaraan.", GetPlayerNameEx(playerid));
                SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
                SendClientMessage(playerid, COLOR_ORANGE, "[KENDARAAN] Mesin kendaraan DIMATIKAN.");
            }
            return 1;
        }
        else
        {
            new eng, lgt, alm, dor, bnt, bot, obj;
            GetVehicleParamsEx(veh, eng, lgt, alm, dor, bnt, bot, obj);
            new new_eng = (eng == 1) ? 0 : 1;
            SetVehicleParamsEx(veh, new_eng, new_eng, alm, dor, bnt, bot, obj);

            new rp[128];
            if (new_eng)
            {
                format(rp, sizeof(rp), "* %s memutar kunci dan menyalakan mesin kendaraan dinas.", GetPlayerNameEx(playerid));
                SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
                SendClientMessage(playerid, COLOR_GREEN, "[KENDARAAN] Mesin dinas DINYALAKAN.");
            }
            else
            {
                format(rp, sizeof(rp), "* %s mematikan mesin kendaraan dinas.", GetPlayerNameEx(playerid));
                SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
                SendClientMessage(playerid, COLOR_ORANGE, "[KENDARAAN] Mesin dinas DIMATIKAN.");
            }
            return 1;
        }
    }

    // Perintah: /lock
    if (strcmp(cmd, "/lock", true) == 0)
    {
        new target_slot = -1;

        if (IsPlayerInAnyVehicle(playerid))
        {
            target_slot = GetVehicleSlotFromID(GetPlayerVehicleID(playerid));
        }
        else
        {
            for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
            {
                if (OwnedVehicles[i][ovSpawned] && OwnedVehicles[i][ovOwnerID] == PlayerData[playerid][pID])
                {
                    new Float:vx, Float:vy, Float:vz;
                    GetVehiclePos(OwnedVehicles[i][ovVehicleID], vx, vy, vz);
                    if (IsPlayerInRangeOfPoint(playerid, 5.0, vx, vy, vz))
                    {
                        target_slot = i;
                        break;
                    }
                }
            }
        }

        if (target_slot == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Tidak ada kendaraan pribadi milik Anda di dekat sini (radius 5m)!");
            return 1;
        }

        if (OwnedVehicles[target_slot][ovOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
        {
            SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Anda bukan pemilik kendaraan ini!");
            return 1;
        }

        new veh = OwnedVehicles[target_slot][ovVehicleID];
        OwnedVehicles[target_slot][ovLocked] = !OwnedVehicles[target_slot][ovLocked];
        SetVehicleParamsEx(veh, OwnedVehicles[target_slot][ovEngine] ? 1 : 0, OwnedVehicles[target_slot][ovEngine] ? 1 : 0, 0, OwnedVehicles[target_slot][ovLocked] ? 1 : 0, 0, 0, 0);

        PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0);
        new rp[128];
        if (OwnedVehicles[target_slot][ovLocked])
        {
            format(rp, sizeof(rp), "* %s menekan tombol remote alarm dan mengunci pintu kendaraan.", GetPlayerNameEx(playerid));
            SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
            SendClientMessage(playerid, COLOR_YELLOW, "[KENDARAAN] Pintu kendaraan telah DIKUNCI.");
        }
        else
        {
            format(rp, sizeof(rp), "* %s menekan tombol remote alarm dan membuka kunci pintu kendaraan.", GetPlayerNameEx(playerid));
            SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
            SendClientMessage(playerid, COLOR_GREEN, "[KENDARAAN] Pintu kendaraan telah DIBUKA.");
        }
        return 1;
    }

    // Perintah: /park
    if (strcmp(cmd, "/park", true) == 0)
    {
        if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        {
            SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Anda harus berada di kursi pengemudi kendaraan pribadi untuk memarkirkannya!");
            return 1;
        }

        new veh = GetPlayerVehicleID(playerid);
        new slot = GetVehicleSlotFromID(veh);

        if (slot == -1 || (OwnedVehicles[slot][ovOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0))
        {
            SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Kendaraan ini bukan kendaraan pribadi milik Anda!");
            return 1;
        }

        SaveVehicleData(slot);
        SendClientMessage(playerid, COLOR_GREEN, "[KENDARAAN] Posisi parkir kendaraan Anda berhasil disimpan secara permanen!");
        return 1;
    }

    // Perintah: /buyvehicle
    if (strcmp(cmd, "/buyvehicle", true) == 0)
    {
        if (!IsPlayerInRangeOfPoint(playerid, 3.0, 1124.50, -1451.20, 15.80))
        {
            SendClientMessage(playerid, COLOR_RED, "[DEALERSHIP] Anda harus berada di Showroom Kendaraan Los Santos!");
            SendClientMessage(playerid, COLOR_YELLOW, "[PETUNJUK] Marker merah telah diset ke lokasi Showroom.");
            SetPlayerCheckpoint(playerid, 1124.50, -1451.20, 15.80, 3.0);
            return 1;
        }
        OpenDealershipMenu(playerid);
        return 1;
    }

    // Perintah: /refuel
    if (strcmp(cmd, "/refuel", true) == 0)
    {
        if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        {
            SendClientMessage(playerid, COLOR_RED, "[SPBU] Anda harus berada di dalam kendaraan sebagai pengemudi!");
            return 1;
        }

        if (!IsPlayerInRangeOfPoint(playerid, 5.0, 1938.20, -1773.50, 13.40))
        {
            SendClientMessage(playerid, COLOR_RED, "[SPBU] Anda tidak berada di SPBU! Kunjungi SPBU Idlewood.");
            SendClientMessage(playerid, COLOR_YELLOW, "[PETUNJUK] Marker merah telah diset ke SPBU Idlewood.");
            SetPlayerCheckpoint(playerid, 1938.20, -1773.50, 13.40, 4.0);
            return 1;
        }

        new veh = GetPlayerVehicleID(playerid);
        new slot = GetVehicleSlotFromID(veh);

        if (slot == -1)
        {
            SendClientMessage(playerid, COLOR_GREEN, "[SPBU] Kendaraan umum/dinas telah diisi bensin penuh secara gratis.");
            return 1;
        }

        if (OwnedVehicles[slot][ovFuel] >= 99.0)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "[SPBU] Tangki bensin kendaraan Anda sudah penuh!");
            return 1;
        }

        new Float:needed = 100.0 - OwnedVehicles[slot][ovFuel];
        new cost = floatround(needed);
        if (cost < 5) cost = 5;

        if (GetPlayerMoney(playerid) < cost)
        {
            new msg[128];
            format(msg, sizeof(msg), "[SPBU] Uang tunai Anda tidak cukup ($%d) untuk mengisi bensin penuh!", cost);
            return SendClientMessage(playerid, COLOR_RED, msg);
        }

        GivePlayerMoney(playerid, -cost);
        OwnedVehicles[slot][ovFuel] = 100.0;
        SaveVehicleData(slot);

        new msg[128];
        format(msg, sizeof(msg), "[SPBU] Pengisian selesai! Tangki bensin kini 100%%. Total biaya: $%d.", cost);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        return 1;
    }

    // Perintah: /myveh
    if (strcmp(cmd, "/myveh", true) == 0)
    {
        new count = 0;
        new list[400];
        format(list, sizeof(list), "{00AAFF}=== KENDARAAN PRIBADI MILIK ANDA ==={FFFFFF}\n\n");

        for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
        {
            if (OwnedVehicles[i][ovSpawned] && OwnedVehicles[i][ovOwnerID] == PlayerData[playerid][pID])
            {
                count++;
                new row[128];
                format(row, sizeof(row), "{FFFF00}%d.{FFFFFF} Model ID: %d | Plat: {00FF00}%s{FFFFFF} | Bensin: %.0f%% | Status: %s\n",
                    count, OwnedVehicles[i][ovModel], OwnedVehicles[i][ovPlate], OwnedVehicles[i][ovFuel],
                    OwnedVehicles[i][ovLocked] ? ("{FF0000}Terkunci") : ("{00FF00}Terbuka")
                );
                strcat(list, row);
            }
        }

        if (count == 0)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "[KENDARAAN] Anda belum memiliki kendaraan pribadi! Beli di Showroom (/buyvehicle).");
            return 1;
        }

        ShowPlayerDialog(playerid, DIALOG_MY_VEHICLES, DIALOG_STYLE_MSGBOX, "{00AAFF}Daftar Kendaraan Pribadi", list, "Tutup", "");
        return 1;
    }

    // Perintah: /job
    if (strcmp(cmd, "/job", true) == 0)
    {
        if (!IsPlayerInRangeOfPoint(playerid, 3.0, 1481.04, -1772.31, 15.30))
        {
            SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda harus berada di Pusat Lowongan Kerja (City Hall Pershing Square)!");
            SendClientMessage(playerid, COLOR_YELLOW, "[PETUNJUK] Marker merah telah diset ke Balai Lowongan Kerja.");
            SetPlayerCheckpoint(playerid, 1481.04, -1772.31, 15.30, 3.0);
            return 1;
        }
        OpenJobAgencyMenu(playerid);
        return 1;
    }

    // Perintah: /startjob
    if (strcmp(cmd, "/startjob", true) == 0)
    {
        if (PlayerData[playerid][pWorking])
        {
            SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda sedang dalam rute tugas! Selesaikan atau ketik /stopjob.");
            return 1;
        }

        if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        {
            SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda harus berada di kursi pengemudi kendaraan dinas kerja!");
            return 1;
        }

        new vehicleid = GetPlayerVehicleID(playerid);

        if (PlayerData[playerid][pJob] == JOB_SWEEPER)
        {
            if (!IsSweeperVehicle(vehicleid))
            {
                SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda harus menggunakan kendaraan Sweeper dinas!");
                return 1;
            }

            PlayerData[playerid][pWorking] = true;
            PlayerData[playerid][pJobCheckpoint] = 0;
            SetPlayerCheckpoint(playerid, g_SweeperCheckpoints[0][0], g_SweeperCheckpoints[0][1], g_SweeperCheckpoints[0][2], 4.0);
            SendClientMessage(playerid, COLOR_GREEN, "[PEKERJAAN] Rute pembersihan jalan dimulai! Ikuti checkpoint merah di jalan.");
            return 1;
        }
        else if (PlayerData[playerid][pJob] == JOB_BUS)
        {
            if (!IsBusVehicle(vehicleid))
            {
                SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda harus menggunakan Bus Kota dinas!");
                return 1;
            }

            PlayerData[playerid][pWorking] = true;
            PlayerData[playerid][pJobCheckpoint] = 0;
            SetPlayerCheckpoint(playerid, g_BusCheckpoints[0][0], g_BusCheckpoints[0][1], g_BusCheckpoints[0][2], 5.0);
            SendClientMessage(playerid, COLOR_GREEN, "[PEKERJAAN] Rute bus kota dimulai! Kendarai bus menuju halte-halte bertanda merah.");
            return 1;
        }
        else if (PlayerData[playerid][pJob] == JOB_TRUCKER)
        {
            if (!IsPlayerInAnyVehicle(playerid))
            {
                return SendClientMessage(playerid, COLOR_RED, "[TRUCKER] Anda harus berada di dalam armada truk kargo dinas!");
            }
            new veh = GetPlayerVehicleID(playerid);
            if (!IsTruckerVehicle(veh))
            {
                return SendClientMessage(playerid, COLOR_RED, "[TRUCKER] Bukan truk kargo resmi perusahaan! Gunakan truk di Depo Ocean Docks.");
            }
            if (GetPlayerVehicleSeat(playerid) != 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[TRUCKER] Anda harus menjadi pengemudi (driver) truk!");
            }

            // Tampilkan pilihan kargo logistik
            new clist[350];
            format(clist, sizeof(clist),
                "Jenis Muatan Kargo\tDestinasi & Upah\n"\
                "1. Pangan & Sembako (Benson/Yankee)\t{00FF00}$650 (Toko 24/7 & Resto)\n"\
                "2. Gadget & Elektronik (Yankee/Flatbed)\t{00FF00}$850 (Toko Elektronik LS)\n"\
                "3. Material Kontainer Berat (Flatbed/Benson)\t{00FF00}$1,150 (Pabrik Industri & Pelabuhan)"
            );
            ShowPlayerDialog(playerid, DIALOG_TRUCKER_CARGO, DIALOG_STYLE_TABLIST_HEADERS, "{00AAFF}Pilih Muatan Pengiriman Kargo", clist, "Pilih", "Batal");
            return 1;
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda belum memiliki pekerjaan! Lamar di Balai Kota (/job).");
            return 1;
        }
    }

    // Perintah: /stopjob
    if (strcmp(cmd, "/stopjob", true) == 0)
    {
        if (!PlayerData[playerid][pWorking])
        {
            SendClientMessage(playerid, COLOR_RED, "[PEKERJAAN] Anda sedang tidak menjalankan tugas pekerjaan.");
            return 1;
        }

        PlayerData[playerid][pWorking] = false;
        PlayerData[playerid][pJobCheckpoint] = 0;
        PlayerData[playerid][pTruckerCargo] = 0;
        DisablePlayerCheckpoint(playerid);
        SendClientMessage(playerid, COLOR_ORANGE, "[PEKERJAAN] Anda telah membatalkan tugas rute pekerjaan saat ini.");
        return 1;
    }

    // Perintah: /atm
    if (strcmp(cmd, "/atm", true) == 0)
    {
        if (!IsPlayerNearATM(playerid))
        {
            SendClientMessage(playerid, COLOR_RED, "[ATM] Anda tidak berada di dekat mesin ATM!");
            return 1;
        }
        OpenATMMenu(playerid);
        return 1;
    }

    // Perintah: /buyfood
    if (strcmp(cmd, "/buyfood", true) == 0)
    {
        if (!IsPlayerNearFood(playerid))
        {
            SendClientMessage(playerid, COLOR_RED, "[RESTORAN] Anda tidak berada di restoran atau toko makanan!");
            return 1;
        }
        OpenFoodMenu(playerid);
        return 1;
    }

    // Perintah: /pay
    if (strcmp(cmd, "/pay", true) == 0)
    {
        new target_str[32], amount_str[32];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, amount_str);

        if (target_str[0] == '\0' || amount_str[0] == '\0')
        {
            SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /pay [playerid/target] [jumlah uang]");
            return 1;
        }

        new targetid = strval(target_str);
        new amount = strval(amount_str);

        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            SendClientMessage(playerid, COLOR_RED, "[PAY] Pemain target tidak ditemukan atau belum login!");
            return 1;
        }
        if (targetid == playerid)
        {
            SendClientMessage(playerid, COLOR_RED, "[PAY] Anda tidak dapat memberikan uang kepada diri sendiri!");
            return 1;
        }

        new Float:x, Float:y, Float:z;
        GetPlayerPos(targetid, x, y, z);
        if (!IsPlayerInRangeOfPoint(playerid, 4.0, x, y, z))
        {
            SendClientMessage(playerid, COLOR_RED, "[PAY] Anda harus berada di dekat pemain tersebut untuk memberikan uang!");
            return 1;
        }

        if (amount <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "[PAY] Jumlah uang harus lebih dari $0!");
            return 1;
        }

        if (GetPlayerMoney(playerid) < amount)
        {
            SendClientMessage(playerid, COLOR_RED, "[PAY] Anda tidak memiliki cukup uang tunai di dompet!");
            return 1;
        }

        GivePlayerMoney(playerid, -amount);
        GivePlayerMoney(targetid, amount);

        new rpmsg[144];
        format(rpmsg, sizeof(rpmsg), "* %s mengeluarkan uang $%d dan memberikannya kepada %s.", GetPlayerNameEx(playerid), amount, GetPlayerNameEx(targetid));
        SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rpmsg);

        new msg1[128], msg2[128];
        format(msg1, sizeof(msg1), "[PAY] Anda memberikan uang tunai $%d kepada %s (ID: %d).", amount, GetPlayerNameEx(targetid), targetid);
        SendClientMessage(playerid, COLOR_GREEN, msg1);

        format(msg2, sizeof(msg2), "[PAY] Anda menerima uang tunai $%d dari %s (ID: %d).", amount, GetPlayerNameEx(playerid), playerid);
        SendClientMessage(targetid, COLOR_LIME, msg2);
        return 1;
    }

    // Perintah: /me
    if (strcmp(cmd, "/me", true) == 0)
    {
        if (cmdtext[3] == '\0' || cmdtext[4] == '\0')
        {
            SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /me [tindakan karakter]");
            return 1;
        }
        new msg[256];
        format(msg, sizeof(msg), "* %s %s", GetPlayerNameEx(playerid), cmdtext[4]);
        SendLocalMessage(playerid, 20.0, COLOR_PURPLE, msg);
        return 1;
    }

    // Perintah: /do
    if (strcmp(cmd, "/do", true) == 0)
    {
        if (cmdtext[3] == '\0' || cmdtext[4] == '\0')
        {
            SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /do [keadaan sekitar / deskripsi]");
            return 1;
        }
        new msg[256];
        format(msg, sizeof(msg), "* %s (( %s ))", cmdtext[4], GetPlayerNameEx(playerid));
        SendLocalMessage(playerid, 20.0, COLOR_PURPLE, msg);
        return 1;
    }

    // Perintah: /b
    if (strcmp(cmd, "/b", true) == 0)
    {
        if (cmdtext[2] == '\0' || cmdtext[3] == '\0')
        {
            SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /b [pesan OOC]");
            return 1;
        }
        new msg[256];
        format(msg, sizeof(msg), "(( %s: %s ))", GetPlayerNameEx(playerid), cmdtext[3]);
        SendLocalMessage(playerid, 20.0, COLOR_GREY, msg);
        return 1;
    }

    // Perintah: /ooc
    if (strcmp(cmd, "/ooc", true) == 0)
    {
        if (cmdtext[4] == '\0' || cmdtext[5] == '\0')
        {
            SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /ooc [pesan]");
            return 1;
        }
        new msg[256];
        format(msg, sizeof(msg), "[OOC] %s: %s", GetPlayerNameEx(playerid), cmdtext[5]);
        SendClientMessageToAll(COLOR_CYAN, msg);
        return 1;
    }

    // =========================================================================
    // PERINTAH FACTION (SAPD & SAMD) & PELAYANAN PUBLIK (TAHAP 8)
    // =========================================================================

    // Perintah: /duty (On-Duty / Off-Duty Faksi SAPD & SAMD)
    if (strcmp(cmd, "/duty", true) == 0)
    {
        if (PlayerData[playerid][pFaction] == FACTION_POLICE)
        {
            if (!IsPlayerNearPoliceLocker(playerid) && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[SAPD] Anda harus berada di ruang loker LSPD HQ untuk duty!");
            }
            OpenPoliceDutyMenu(playerid);
            return 1;
        }
        else if (PlayerData[playerid][pFaction] == FACTION_MEDIC)
        {
            if (!IsPlayerNearMedicLocker(playerid) && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[SAMD] Anda harus berada di lobi All Saints Hospital untuk duty!");
            }
            OpenMedicDutyMenu(playerid);
            return 1;
        }
        else if (PlayerData[playerid][pFaction] == FACTION_GROVE)
        {
            if (!IsPlayerNearGroveLocker(playerid) && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[GROVE] Anda harus berada di markas Ganton Grove Street untuk tugas geng!");
            }
            OpenGroveDutyMenu(playerid);
            return 1;
        }
        else if (PlayerData[playerid][pFaction] == FACTION_BALLAS)
        {
            if (!IsPlayerNearBallasLocker(playerid) && PlayerData[playerid][pAdmin] == 0)
            {
                return SendClientMessage(playerid, COLOR_RED, "[BALLAS] Anda harus berada di markas Glen Park Ballas untuk tugas geng!");
            }
            OpenBallasDutyMenu(playerid);
            return 1;
        }
        else
        {
            return SendClientMessage(playerid, COLOR_RED, "[DINAS] Anda bukan anggota faksi kepolisian, medis, atau geng!");
        }
    }

    // Perintah: /r atau /radio (Radio Komunikasi Internal Faksi)
    if (strcmp(cmd, "/r", true) == 0 || strcmp(cmd, "/radio", true) == 0)
    {
        if (PlayerData[playerid][pFaction] == FACTION_NONE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[RADIO] Anda bukan anggota faksi resmi!");
        }
        if (!PlayerData[playerid][pOnDuty] && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[RADIO] Anda harus On-Duty (/duty) untuk menggunakan radio!");
        }

        new radio_msg[128];
        GetNextToken(cmdtext, idx, radio_msg);
        if (radio_msg[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /r [pesan obrolan]");

        new r_name[32], out_msg[200];
        GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));

        if (PlayerData[playerid][pFaction] == FACTION_POLICE)
        {
            format(out_msg, sizeof(out_msg), "[RADIO SAPD] %s %s: ** %s **", r_name, GetPlayerNameEx(playerid), cmdtext[idx - strlen(radio_msg)]);
            for (new i = 0; i < MAX_PLAYERS; i++)
            {
                if (IsPlayerConnected(i) && (PlayerData[i][pFaction] == FACTION_POLICE || PlayerData[i][pAdmin] >= 1))
                {
                    SendClientMessage(i, COLOR_CYAN, out_msg);
                }
            }
        }
        else if (PlayerData[playerid][pFaction] == FACTION_MEDIC)
        {
            format(out_msg, sizeof(out_msg), "[RADIO SAMD] %s %s: ** %s **", r_name, GetPlayerNameEx(playerid), cmdtext[idx - strlen(radio_msg)]);
            for (new i = 0; i < MAX_PLAYERS; i++)
            {
                if (IsPlayerConnected(i) && (PlayerData[i][pFaction] == FACTION_MEDIC || PlayerData[i][pAdmin] >= 1))
                {
                    SendClientMessage(i, COLOR_PINK, out_msg);
                }
            }
        }
        else if (PlayerData[playerid][pFaction] == FACTION_GROVE)
        {
            format(out_msg, sizeof(out_msg), "[RADIO GROVE] %s %s: ** %s **", r_name, GetPlayerNameEx(playerid), cmdtext[idx - strlen(radio_msg)]);
            for (new i = 0; i < MAX_PLAYERS; i++)
            {
                if (IsPlayerConnected(i) && (PlayerData[i][pFaction] == FACTION_GROVE || PlayerData[i][pAdmin] >= 1))
                {
                    SendClientMessage(i, COLOR_GREEN, out_msg);
                }
            }
        }
        else if (PlayerData[playerid][pFaction] == FACTION_BALLAS)
        {
            format(out_msg, sizeof(out_msg), "[RADIO BALLAS] %s %s: ** %s **", r_name, GetPlayerNameEx(playerid), cmdtext[idx - strlen(radio_msg)]);
            for (new i = 0; i < MAX_PLAYERS; i++)
            {
                if (IsPlayerConnected(i) && (PlayerData[i][pFaction] == FACTION_BALLAS || PlayerData[i][pAdmin] >= 1))
                {
                    SendClientMessage(i, 0xAA00FFAA, out_msg);
                }
            }
        }
        return 1;
    }

    // Perintah: /d atau /dept (Radio Antar Departemen Kepolisian & Medis)
    if (strcmp(cmd, "/d", true) == 0 || strcmp(cmd, "/dept", true) == 0)
    {
        if ((PlayerData[playerid][pFaction] == FACTION_NONE || !PlayerData[playerid][pOnDuty]) && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[DEPT] Hanya personel SAPD atau SAMD yang On-Duty yang dapat menggunakan radio ini!");
        }

        new dept_msg[128];
        GetNextToken(cmdtext, idx, dept_msg);
        if (dept_msg[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /d [pesan koordinasi]");

        new f_tag[16], r_name[32], out_msg[220];
        format(f_tag, sizeof(f_tag), (PlayerData[playerid][pFaction] == FACTION_POLICE) ? ("SAPD") : ("SAMD"));
        GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));

        format(out_msg, sizeof(out_msg), "[DEPT RADIO] [%s] %s %s: %s", f_tag, r_name, GetPlayerNameEx(playerid), cmdtext[idx - strlen(dept_msg)]);
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && (PlayerData[i][pFaction] == FACTION_POLICE || PlayerData[i][pFaction] == FACTION_MEDIC || PlayerData[i][pAdmin] >= 1))
            {
                SendClientMessage(i, 0xFF8000FF, out_msg);
            }
        }
        return 1;
    }

    // Perintah: /m atau /megaphone (Pengeras Suara Kendaraan Dinas)
    if (strcmp(cmd, "/m", true) == 0 || strcmp(cmd, "/megaphone", true) == 0)
    {
        if ((PlayerData[playerid][pFaction] == FACTION_NONE || !PlayerData[playerid][pOnDuty]) && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[MEGAPHONE] Anda bukan petugas faksi on-duty!");
        }

        new mega_msg[128];
        GetNextToken(cmdtext, idx, mega_msg);
        if (mega_msg[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /m [pesan pengumuman]");

        new r_name[32], out_msg[220];
        GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));

        format(out_msg, sizeof(out_msg), "[MEGAPHONE] (%s) %s %s: <%s>",
            (PlayerData[playerid][pFaction] == FACTION_POLICE) ? ("POLISI") : ("MEDIS"),
            r_name, GetPlayerNameEx(playerid), cmdtext[idx - strlen(mega_msg)]
        );

        SendLocalMessage(playerid, 50.0, 0xFFFF00FF, out_msg);
        return 1;
    }

    // Perintah: /cuff [targetid]
    if (strcmp(cmd, "/cuff", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Hanya petugas kepolisian yang dapat memborgol tersangka!");
        }

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /cuff [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Pemain tidak ditemukan atau belum login!");
        }

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        if (!IsPlayerInRangeOfPoint(targetid, 4.0, x, y, z))
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Target terlalu jauh! Dekati tersangka untuk memborgol.");
        }

        if (PlayerData[targetid][pCuffed])
        {
            return SendClientMessage(playerid, COLOR_YELLOW, "[SAPD] Tersangka sudah dalam keadaan diborgol!");
        }

        PlayerData[targetid][pCuffed] = true;
        SetPlayerSpecialAction(targetid, SPECIAL_ACTION_CUFFED);

        new msg[144];
        format(msg, sizeof(msg), "* Petugas %s mengambil borgol baja dan mengunci kedua tangan %s.", GetPlayerNameEx(playerid), GetPlayerNameEx(targetid));
        SendLocalMessage(playerid, 20.0, COLOR_PURPLE, msg);
        SendClientMessage(targetid, COLOR_RED, "[BORGOL] Tangan Anda telah diborgol oleh kepolisian. Anda tidak dapat bergerak bebas.");
        return 1;
    }

    // Perintah: /uncuff [targetid]
    if (strcmp(cmd, "/uncuff", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Hanya petugas kepolisian yang dapat membuka borgol!");
        }

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /uncuff [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Pemain tidak ditemukan atau belum login!");
        }

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        if (!IsPlayerInRangeOfPoint(targetid, 4.0, x, y, z))
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Target terlalu jauh! Dekati tersangka.");
        }

        if (!PlayerData[targetid][pCuffed])
        {
            return SendClientMessage(playerid, COLOR_YELLOW, "[SAPD] Tersangka tidak sedang diborgol!");
        }

        PlayerData[targetid][pCuffed] = false;
        SetPlayerSpecialAction(targetid, SPECIAL_ACTION_NONE);

        new msg[144];
        format(msg, sizeof(msg), "* Petugas %s memasukkan kunci dan melepaskan borgol dari tangan %s.", GetPlayerNameEx(playerid), GetPlayerNameEx(targetid));
        SendLocalMessage(playerid, 20.0, COLOR_PURPLE, msg);
        SendClientMessage(targetid, COLOR_GREEN, "[BORGOL] Borgol Anda telah dilepaskan oleh kepolisian.");
        return 1;
    }

    // Perintah: /frisk [targetid] (Menggeledah Tersangka)
    if (strcmp(cmd, "/frisk", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Hanya petugas kepolisian yang dapat menggeledah!");
        }

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /frisk [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Pemain tidak ditemukan!");
        }

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        if (!IsPlayerInRangeOfPoint(targetid, 4.0, x, y, z))
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Target terlalu jauh!");
        }

        new reason_str[64];
        if (PlayerData[targetid][pWantedReason][0] != '\0')
        {
            format(reason_str, sizeof(reason_str), "%s", PlayerData[targetid][pWantedReason]);
        }
        else
        {
            format(reason_str, sizeof(reason_str), "Tidak Ada");
        }

        new frisk_info[450];
        format(frisk_info, sizeof(frisk_info),
            "{00AAFF}=== LAPORAN PENGGELEDAHAN KEPOLISIAN ==={FFFFFF}\n\n\
            {FFFFFF}Nama Tersangka: {FFFF00}%s (ID: %d)\n\
            {FFFFFF}Uang Tunai (Cash): {00FF00}$%d\n\
            {FFFFFF}Senjata yang Digenggam: {FF9900}%d\n\
            {FFFFFF}Barang Terlarang (Pot): {00FF00}%d Gram\n\
            {FFFFFF}Barang Terlarang (Crack): {FF00FF}%d Gram\n\
            {FFFFFF}Tingkat Buronan (Wanted): {FF0000}%d Bintang\n\
            {FFFFFF}Alasan Buronan: {FFFFFF}%s\n\
            {FFFFFF}Status Borgol: %s",
            GetPlayerNameEx(targetid), targetid,
            GetPlayerMoney(targetid),
            GetPlayerWeapon(targetid),
            PlayerData[targetid][pPot],
            PlayerData[targetid][pCrack],
            PlayerData[targetid][pWantedLevel],
            reason_str,
            PlayerData[targetid][pCuffed] ? ("{00FF00}Diborgol") : ("{FF0000}Bebas")
        );
        ShowPlayerDialog(playerid, DIALOG_FRISK_VIEW, DIALOG_STYLE_MSGBOX, "{00AAFF}Laporan Penggeledahan", frisk_info, "Tutup", "");

        new me_msg[144];
        format(me_msg, sizeof(me_msg), "* Petugas %s memeriksa saku dan sekujur tubuh %s dengan teliti.", GetPlayerNameEx(playerid), GetPlayerNameEx(targetid));
        SendLocalMessage(playerid, 20.0, COLOR_PURPLE, me_msg);
        return 1;
    }

    // Perintah: /wanted [targetid] [bintang 1-6] [alasan]
    if (strcmp(cmd, "/wanted", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Hanya petugas kepolisian yang dapat menetapkan buronan!");
        }

        new target_str[16], star_str[16];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, star_str);

        if (target_str[0] == '\0' || star_str[0] == '\0')
        {
            return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /wanted [playerid] [stars 1-6] [alasan]");
        }

        new targetid = strval(target_str);
        new stars = strval(star_str);

        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Pemain tidak ditemukan!");
        }

        if (stars < 1 || stars > 6) return SendClientMessage(playerid, COLOR_RED, "[SAPD] Bintang buronan harus antara 1 sampai 6!");

        new reason[64];
        GetNextToken(cmdtext, idx, reason);
        if (reason[0] == '\0') format(reason, sizeof(reason), "Tindak Kriminal");

        PlayerData[targetid][pWantedLevel] = stars;
        format(PlayerData[targetid][pWantedReason], 64, "%s", reason);
        SetPlayerWantedLevel(targetid, stars);

        new w_msg[160];
        format(w_msg, sizeof(w_msg), "[HQ DISPATCH] %s kini BURONAN (Wanted Level %d)! Alasan: %s (Ditindak oleh: %s).",
            GetPlayerNameEx(targetid), stars, reason, GetPlayerNameEx(playerid)
        );
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && (PlayerData[i][pFaction] == FACTION_POLICE || PlayerData[i][pAdmin] >= 1))
            {
                SendClientMessage(i, COLOR_CYAN, w_msg);
            }
        }

        new target_msg[160];
        format(target_msg, sizeof(target_msg), "[WANTED] Anda ditetapkan sebagai buronan kepolisian (Tingkat: %d Bintang) dengan tuduhan: %s!", stars, reason);
        SendClientMessage(targetid, COLOR_RED, target_msg);
        return 1;
    }

    // Perintah: /clearwanted [targetid]
    if (strcmp(cmd, "/clearwanted", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Hanya petugas kepolisian yang dapat membersihkan buronan!");
        }

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /clearwanted [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn]) return SendClientMessage(playerid, COLOR_RED, "[SAPD] Pemain tidak ditemukan!");

        PlayerData[targetid][pWantedLevel] = 0;
        PlayerData[targetid][pWantedReason][0] = '\0';
        SetPlayerWantedLevel(targetid, 0);

        new msg[128];
        format(msg, sizeof(msg), "[SAPD] Status buronan %s telah dibersihkan oleh petugas %s.", GetPlayerNameEx(targetid), GetPlayerNameEx(playerid));
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SendClientMessage(targetid, COLOR_GREEN, "[SAPD] Status buronan Anda telah dihapus dari database kepolisian.");
        return 1;
    }

    // Perintah: /checkwanted
    if (strcmp(cmd, "/checkwanted", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Hanya petugas kepolisian yang dapat memeriksa buronan!");
        }

        new list[500];
        format(list, sizeof(list), "Nama Buronan\tTingkat Wanted\tTuduhan Kriminal\n");
        new count = 0;

        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn] && PlayerData[i][pWantedLevel] > 0)
            {
                new row[128];
                format(row, sizeof(row), "{FFFFFF}%s (ID: %d)\t{FF0000}%d Bintang\t{FFFF00}%s\n",
                    GetPlayerNameEx(i), i, PlayerData[i][pWantedLevel], PlayerData[i][pWantedReason]
                );
                strcat(list, row);
                count++;
            }
        }

        if (count == 0)
        {
            return SendClientMessage(playerid, COLOR_GREEN, "[SAPD] Saat ini tidak ada warga yang terdaftar sebagai buronan aktif.");
        }
        ShowPlayerDialog(playerid, DIALOG_WANTED_LIST, DIALOG_STYLE_TABLIST_HEADERS, "{00AAFF}Daftar Buronan Aktif (Wanted List)", list, "Tutup", "");
        return 1;
    }

    // Perintah: /jail [targetid] [menit] [alasan]
    if (strcmp(cmd, "/jail", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Hanya petugas kepolisian yang dapat memenjarakan tersangka!");
        }

        if (!IsPlayerNearJail(playerid) && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Anda harus berada di area sel penjara LSPD untuk memenjarakan tersangka!");
        }

        new target_str[16], time_str[16];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, time_str);

        if (target_str[0] == '\0' || time_str[0] == '\0')
        {
            return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /jail [playerid] [durasi (1-60 menit)] [alasan]");
        }

        new targetid = strval(target_str);
        new minutes = strval(time_str);

        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Tersangka tidak ditemukan!");
        }

        if (minutes < 1 || minutes > 60) return SendClientMessage(playerid, COLOR_RED, "[SAPD] Durasi hukuman penjara antara 1 sampai 60 menit!");

        new reason[64];
        GetNextToken(cmdtext, idx, reason);
        if (reason[0] == '\0') format(reason, sizeof(reason), "Pelanggaran Hukum Pidana");

        PlayerData[targetid][pJailTime] = minutes;
        PlayerData[targetid][pWantedLevel] = 0;
        PlayerData[targetid][pWantedReason][0] = '\0';
        PlayerData[targetid][pCuffed] = false;
        SetPlayerSpecialAction(targetid, SPECIAL_ACTION_NONE);
        SetPlayerWantedLevel(targetid, 0);
        ResetPlayerWeapons(targetid);

        SetPlayerPos(targetid, 264.62, 77.57, 1001.03);
        SetPlayerFacingAngle(targetid, 270.0);
        SetPlayerInterior(targetid, 6);
        SetPlayerVirtualWorld(targetid, 0);

        SavePlayerData(targetid);

        new broadcast[160];
        format(broadcast, sizeof(broadcast), "[PENJARA LSPD] %s dijebloskan ke sel penjara oleh %s selama %d menit. Tuduhan: %s.",
            GetPlayerNameEx(targetid), GetPlayerNameEx(playerid), minutes, reason
        );
        SendClientMessageToAll(COLOR_RED, broadcast);
        return 1;
    }

    // Perintah: /unjail [targetid]
    if (strcmp(cmd, "/unjail", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_POLICE && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAPD] Anda tidak memiliki wewenang untuk unjail!");
        }

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /unjail [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn]) return SendClientMessage(playerid, COLOR_RED, "[SAPD] Pemain tidak ditemukan!");

        if (PlayerData[targetid][pJailTime] <= 0) return SendClientMessage(playerid, COLOR_YELLOW, "[SAPD] Pemain tersebut tidak sedang berada di dalam sel penjara!");

        PlayerData[targetid][pJailTime] = 0;
        SetPlayerPos(targetid, 1554.0, -1675.0, 16.20);
        SetPlayerFacingAngle(targetid, 90.0);
        SetPlayerInterior(targetid, 0);
        SetPlayerVirtualWorld(targetid, 0);
        SavePlayerData(targetid);

        new msg[128];
        format(msg, sizeof(msg), "[SAPD] Anda telah membebaskan narapidana %s dari sel penjara.", GetPlayerNameEx(targetid));
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SendClientMessage(targetid, COLOR_GREEN, "[PENJARA] Anda telah dibebaskan lebih awal dari penjara oleh petugas.");
        return 1;
    }

    // Perintah: /heal [targetid] (Pengobatan Paramedis SAMD)
    if (strcmp(cmd, "/heal", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_MEDIC && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAMD] Hanya petugas medis SAMD yang dapat mengobati pasien!");
        }

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /heal [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn]) return SendClientMessage(playerid, COLOR_RED, "[SAMD] Pasien tidak ditemukan!");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        if (!IsPlayerInRangeOfPoint(targetid, 4.0, x, y, z)) return SendClientMessage(playerid, COLOR_RED, "[SAMD] Pasien berada terlalu jauh!");

        SetPlayerHealth(targetid, 100.0);
        PlayerData[targetid][pHealth] = 100.0;

        GivePlayerMoney(targetid, -25);
        GivePlayerMoney(playerid, 25);

        new msg[144];
        format(msg, sizeof(msg), "* Paramedis %s merawat luka dan memberikan obat kepada pasien %s.", GetPlayerNameEx(playerid), GetPlayerNameEx(targetid));
        SendLocalMessage(playerid, 20.0, COLOR_PURPLE, msg);

        SendClientMessage(targetid, COLOR_GREEN, "[SAMD] Kesehatan Anda telah dipulihkan hingga 100% (Biaya pengobatan: $25).");
        SendClientMessage(playerid, COLOR_GREEN, "[SAMD] Anda berhasil mengobati pasien dan menerima jasa pengobatan $25.");
        return 1;
    }

    // Perintah: /revive [targetid] (Menyadarkan Pemain Kritis / Pingsan)
    if (strcmp(cmd, "/revive", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_MEDIC && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[SAMD] Hanya petugas medis SAMD yang dapat melakukan resusitasi / revive!");
        }

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /revive [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn]) return SendClientMessage(playerid, COLOR_RED, "[SAMD] Korban tidak ditemukan!");

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        if (!IsPlayerInRangeOfPoint(targetid, 4.0, x, y, z)) return SendClientMessage(playerid, COLOR_RED, "[SAMD] Korban berada terlalu jauh!");

        if (!PlayerData[targetid][pInjured])
        {
            return SendClientMessage(playerid, COLOR_YELLOW, "[SAMD] Korban tidak dalam kondisi pingsan / kritis! Gunakan /heal untuk mengobati biasa.");
        }

        PlayerData[targetid][pInjured] = false;
        PlayerData[targetid][pInjuredTimer] = 0;
        ClearAnimations(targetid);
        TogglePlayerControllable(targetid, true);
        SetPlayerHealth(targetid, 65.0);
        PlayerData[targetid][pHealth] = 65.0;

        GivePlayerMoney(targetid, -50);
        GivePlayerMoney(playerid, 50);

        new msg[160];
        format(msg, sizeof(msg), "* Paramedis %s melakukan CPR dan resusitasi defibrilator, berhasil menyadarkan %s.", GetPlayerNameEx(playerid), GetPlayerNameEx(targetid));
        SendLocalMessage(playerid, 20.0, COLOR_PURPLE, msg);

        SendClientMessage(targetid, COLOR_GREEN, "[SAMD] Anda telah disadarkan kembali dari kondisi kritis oleh paramedis! (Biaya tindakan: $50).");
        SendClientMessage(playerid, COLOR_GREEN, "[SAMD] Anda berhasil menyelamatkan nyawa korban dan menerima jasa tindakan $50.");
        return 1;
    }

    // Perintah: /call [nomor]
    if (strcmp(cmd, "/call", true) == 0)
    {
        new num_str[16];
        GetNextToken(cmdtext, idx, num_str);

        if (strcmp(num_str, "911", true) == 0 || num_str[0] == '\0')
        {
            Open911Menu(playerid);
            return 1;
        }

        SendClientMessage(playerid, COLOR_YELLOW, "[TELEPON] Nomor darurat yang tersedia: 911 (/call 911).");
        return 1;
    }

    // =========================================================================
    // TAHAP 9: GANG / TURF COMMANDS
    // =========================================================================

    // Perintah: /attackturf [turfid]
    if (strcmp(cmd, "/attackturf", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_GROVE && PlayerData[playerid][pFaction] != FACTION_BALLAS)
            return SendClientMessage(playerid, COLOR_RED, "[GANG] Hanya anggota Grove Street atau Ballas yang dapat menyerang wilayah!");

        if (!PlayerData[playerid][pOnDuty])
            return SendClientMessage(playerid, COLOR_RED, "[GANG] Anda harus sedang bertugas (on-duty) untuk menyerang wilayah!");

        new tid_str[8];
        GetNextToken(cmdtext, idx, tid_str);
        if (tid_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /attackturf [0/1/2] (0=Ganton, 1=Glen Park, 2=Idlewood)");

        new t = strval(tid_str);
        if (t < 0 || t > 2) return SendClientMessage(playerid, COLOR_RED, "[GANG] ID wilayah tidak valid! (0, 1, atau 2)");

        if (g_TurfData[t][turfOwner] == PlayerData[playerid][pFaction])
            return SendClientMessage(playerid, COLOR_RED, "[GANG] Anda tidak bisa menyerang wilayah milik geng Anda sendiri!");

        if (g_TurfData[t][turfUnderAttack])
            return SendClientMessage(playerid, COLOR_RED, "[GANG] Wilayah ini sedang dalam pertempuran! Tunggu hingga selesai.");

        g_TurfData[t][turfUnderAttack] = true;
        g_TurfData[t][turfAttacker] = PlayerData[playerid][pFaction];
        g_TurfData[t][turfWarTimer] = 300;

        new atk_color = (PlayerData[playerid][pFaction] == FACTION_GROVE) ? 0x00FF00FF : 0xAA00AAFF;
        GangZoneFlashForAll(g_TurfData[t][turfZoneID], atk_color);

        new f_name[48], msg[200];
        GetFactionName(PlayerData[playerid][pFaction], f_name, sizeof(f_name));
        format(msg, sizeof(msg), "[GANG WAR] {FF0000}%s menyatakan perang dan menyerang wilayah %s! Perebutan berlangsung 5 menit!", f_name, g_TurfData[t][turfName]);

        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn])
                SendClientMessage(i, COLOR_ORANGE, msg);
        }
        return 1;
    }

    // Perintah: /turfinfo
    if (strcmp(cmd, "/turfinfo", true) == 0)
    {
        new info[600];
        format(info, sizeof(info), "{00AAFF}=== INFORMASI WILAYAH GENG (TURF WAR) ==={FFFFFF}\n\n");

        for (new t = 0; t < 3; t++)
        {
            new owner_name[48];
            GetFactionName(g_TurfData[t][turfOwner], owner_name, sizeof(owner_name));

            new war_status[64];
            if (g_TurfData[t][turfUnderAttack])
            {
                new atk_name[48];
                GetFactionName(g_TurfData[t][turfAttacker], atk_name, sizeof(atk_name));
                format(war_status, sizeof(war_status), "{FF0000}DISERANG oleh %s (%d detik)", atk_name, g_TurfData[t][turfWarTimer]);
            }
            else
            {
                format(war_status, sizeof(war_status), "{00FF00}Aman / Tidak diserang");
            }

            new row[200];
            format(row, sizeof(row), "{FFFF00}Wilayah #%d:{FFFFFF} %s\n  Pemilik: %s | Status: %s\n\n",
                t, g_TurfData[t][turfName], owner_name, war_status);
            strcat(info, row);
        }

        ShowPlayerDialog(playerid, DIALOG_TURF_INFO, DIALOG_STYLE_MSGBOX, "{00AAFF}Peta Wilayah Geng", info, "Tutup", "");
        return 1;
    }

    // Perintah: /g [pesan] (Gang chat)
    if (strcmp(cmd, "/g", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_GROVE && PlayerData[playerid][pFaction] != FACTION_BALLAS)
            return SendClientMessage(playerid, COLOR_RED, "[GANG] Anda tidak terdaftar dalam geng manapun!");

        new msg_str[128];
        GetNextToken(cmdtext, idx, msg_str);
        if (msg_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /g [pesan]");

        new f_name[48], chat_msg[200];
        GetFactionName(PlayerData[playerid][pFaction], f_name, sizeof(f_name));
        format(chat_msg, sizeof(chat_msg), "[%s GANG] %s: %s", f_name, GetPlayerNameEx(playerid), msg_str);

        new gang_color = (PlayerData[playerid][pFaction] == FACTION_GROVE) ? COLOR_LIME : COLOR_PURPLE;

        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn] && PlayerData[i][pFaction] == PlayerData[playerid][pFaction])
                SendClientMessage(i, gang_color, chat_msg);
        }
        return 1;
    }

    // Perintah: /ganginfo
    if (strcmp(cmd, "/ganginfo", true) == 0)
    {
        if (PlayerData[playerid][pFaction] != FACTION_GROVE && PlayerData[playerid][pFaction] != FACTION_BALLAS)
            return SendClientMessage(playerid, COLOR_RED, "[GANG] Anda tidak terdaftar dalam geng manapun!");

        new f_name[48], r_name[32];
        GetFactionName(PlayerData[playerid][pFaction], f_name, sizeof(f_name));
        GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));

        new turf_count = 0;
        for (new t = 0; t < 3; t++)
        {
            if (g_TurfData[t][turfOwner] == PlayerData[playerid][pFaction])
                turf_count++;
        }

        new members = 0;
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn] && PlayerData[i][pFaction] == PlayerData[playerid][pFaction])
                members++;
        }

        new info[500];
        format(info, sizeof(info),
            "{00AAFF}=== INFORMASI GENG ==={FFFFFF}\n\n\
            {FFFF00}Nama Geng:{FFFFFF} %s\n\
            {FFFF00}Pangkat Anda:{FFFFFF} %s (Level %d)\n\
            {FFFF00}Status Dinas:{FFFFFF} %s\n\
            {FFFF00}Anggota Online:{FFFFFF} %d orang\n\
            {FFFF00}Wilayah Dikuasai:{FFFFFF} %d / 3 zona\n\
            {FFFF00}Stok Ganja (Pot):{FFFFFF} %d gram\n\
            {FFFF00}Stok Kokain (Crack):{FFFFFF} %d gram",
            f_name, r_name, PlayerData[playerid][pFactionRank],
            PlayerData[playerid][pOnDuty] ? ("{00FF00}On-Duty") : ("{AFAFAF}Off-Duty"),
            members, turf_count,
            PlayerData[playerid][pPot],
            PlayerData[playerid][pCrack]
        );

        ShowPlayerDialog(playerid, DIALOG_TURF_INFO, DIALOG_STYLE_MSGBOX, "{00AAFF}Info Geng Anda", info, "Tutup", "");
        return 1;
    }

    // Perintah: /usepot (Menggunakan Ganja)
    if (strcmp(cmd, "/usepot", true) == 0)
    {
        if (PlayerData[playerid][pPot] < 1)
            return SendClientMessage(playerid, COLOR_RED, "[DRUG] Anda tidak memiliki ganja! Beli di Black Market (/buyblackmarket).");

        PlayerData[playerid][pPot]--;

        new Float:hp;
        GetPlayerHealth(playerid, hp);
        hp += 20.0;
        if (hp > 100.0) hp = 100.0;
        SetPlayerHealth(playerid, hp);
        PlayerData[playerid][pHealth] = hp;

        SetPlayerDrunkLevel(playerid, 1500);

        SavePlayerData(playerid);

        new msg[100];
        format(msg, sizeof(msg), "[DRUG] Anda mengisap ganja... Efek relaksasi terasa. HP +20. Stok tersisa: %d gram.", PlayerData[playerid][pPot]);
        SendClientMessage(playerid, COLOR_LIME, msg);

        new pub_msg[100];
        format(pub_msg, sizeof(pub_msg), "* %s mengeluarkan sesuatu dari saku dan menghisapnya pelan-pelan.", GetPlayerNameEx(playerid));
        SendLocalMessage(playerid, 10.0, COLOR_PURPLE, pub_msg);
        return 1;
    }

    // Perintah: /usecrack (Menggunakan Kokain)
    if (strcmp(cmd, "/usecrack", true) == 0)
    {
        if (PlayerData[playerid][pCrack] < 1)
            return SendClientMessage(playerid, COLOR_RED, "[DRUG] Anda tidak memiliki kokain! Beli di Black Market (/buyblackmarket).");

        PlayerData[playerid][pCrack]--;

        new Float:hp;
        GetPlayerHealth(playerid, hp);
        hp += 35.0;
        if (hp > 100.0) hp = 100.0;
        SetPlayerHealth(playerid, hp);
        PlayerData[playerid][pHealth] = hp;

        SetPlayerDrunkLevel(playerid, 2500);

        // Tambah 1 wanted star
        PlayerData[playerid][pWantedLevel]++;
        if (PlayerData[playerid][pWantedLevel] > 6) PlayerData[playerid][pWantedLevel] = 6;
        SetPlayerWantedLevel(playerid, PlayerData[playerid][pWantedLevel]);
        format(PlayerData[playerid][pWantedReason], 64, "Penggunaan Narkoba");

        // Alert polisi
        new alert[128];
        format(alert, sizeof(alert), "[DISPATCH] Laporan penggunaan narkoba terdeteksi! Tersangka: %s (ID: %d)", GetPlayerNameEx(playerid), playerid);
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn] && PlayerData[i][pFaction] == FACTION_POLICE && PlayerData[i][pOnDuty])
                SendClientMessage(i, COLOR_RED, alert);
        }

        SavePlayerData(playerid);

        new msg[120];
        format(msg, sizeof(msg), "[DRUG] Anda mengonsumsi kokain... Tubuh terasa terbakar! HP +35. Wanted +1. Stok tersisa: %d gram.", PlayerData[playerid][pCrack]);
        SendClientMessage(playerid, COLOR_ORANGE, msg);

        new pub_msg[100];
        format(pub_msg, sizeof(pub_msg), "* %s tampak gelisah dan bergerak tidak wajar.", GetPlayerNameEx(playerid));
        SendLocalMessage(playerid, 10.0, COLOR_PURPLE, pub_msg);
        return 1;
    }

    // Perintah: /buyblackmarket (Alias untuk buka Black Market)
    if (strcmp(cmd, "/buyblackmarket", true) == 0)
    {
        if (!IsPlayerNearBlackMarket(playerid))
            return SendClientMessage(playerid, COLOR_RED, "[BLACK MARKET] Anda harus berada di dekat Black Market di Ocean Docks!");

        OpenBlackMarketMenu(playerid);
        return 1;
    }

    // Perintah: /rob [targetid] (Merampok pemain)
    if (strcmp(cmd, "/rob", true) == 0)
    {
        if (PlayerData[playerid][pRobCooldown] > 0)
        {
            new msg[80];
            format(msg, sizeof(msg), "[ROB] Anda harus menunggu %d menit lagi sebelum bisa merampok.", PlayerData[playerid][pRobCooldown]);
            return SendClientMessage(playerid, COLOR_RED, msg);
        }

        new target_str[16];
        GetNextToken(cmdtext, idx, target_str);
        if (target_str[0] == '\0') return SendClientMessage(playerid, COLOR_GREY, "PENGGUNAAN: /rob [playerid]");

        new targetid = strval(target_str);
        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn]) return SendClientMessage(playerid, COLOR_RED, "[ROB] Target tidak ditemukan!");
        if (targetid == playerid) return SendClientMessage(playerid, COLOR_RED, "[ROB] Anda tidak bisa merampok diri sendiri!");
        if (PlayerData[targetid][pAdmin] > 0) return SendClientMessage(playerid, COLOR_RED, "[ROB] Anda tidak bisa merampok Admin Server!");
        if (PlayerData[targetid][pCuffed]) return SendClientMessage(playerid, COLOR_RED, "[ROB] Target sudah dalam borgolan polisi!");

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);
        if (!IsPlayerInRangeOfPoint(targetid, 3.0, px, py, pz))
            return SendClientMessage(playerid, COLOR_RED, "[ROB] Anda harus berdiri sangat dekat dengan target!");

        new target_cash = GetPlayerMoney(targetid);
        if (target_cash <= 0)
            return SendClientMessage(playerid, COLOR_RED, "[ROB] Target tidak memiliki uang tunai!");

        new steal_max = target_cash / 4;
        if (steal_max < 50) steal_max = 50;
        if (steal_max > 500) steal_max = 500;
        new stolen = (random(steal_max) + 50);
        if (stolen > target_cash) stolen = target_cash;

        GivePlayerMoney(targetid, -stolen);
        GivePlayerMoney(playerid, stolen);

        PlayerData[playerid][pWantedLevel] += 2;
        if (PlayerData[playerid][pWantedLevel] > 6) PlayerData[playerid][pWantedLevel] = 6;
        SetPlayerWantedLevel(playerid, PlayerData[playerid][pWantedLevel]);
        format(PlayerData[playerid][pWantedReason], 64, "Perampokan");

        PlayerData[playerid][pRobCooldown] = 10;

        new rob_msg[160];
        format(rob_msg, sizeof(rob_msg), "* %s memaksa %s menyerahkan uang di bawah ancaman!", GetPlayerNameEx(playerid), GetPlayerNameEx(targetid));
        SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rob_msg);

        new msg_rob[128];
        format(msg_rob, sizeof(msg_rob), "[ROB] Anda telah merampok $%d dari %s! Wanted +2. Cooldown 10 menit.", stolen, GetPlayerNameEx(targetid));
        SendClientMessage(playerid, COLOR_ORANGE, msg_rob);

        new msg_vic[128];
        format(msg_vic, sizeof(msg_vic), "[ROB] Anda dirampok! %s mengambil $%d dari Anda!", GetPlayerNameEx(playerid), stolen);
        SendClientMessage(targetid, COLOR_RED, msg_vic);

        // Alert SAPD
        new alert[160];
        format(alert, sizeof(alert), "[DISPATCH] Laporan perampokan! Pelaku: %s (ID: %d) di dekat ID: %d. Mohon segera tangani!", GetPlayerNameEx(playerid), playerid, targetid);
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn] && PlayerData[i][pFaction] == FACTION_POLICE && PlayerData[i][pOnDuty])
                SendClientMessage(i, COLOR_RED, alert);
        }
        return 1;
    }

    // Perintah: /stuck (Membebaskan karakter saat tersangkut / bug)
    if (strcmp(cmd, "/stuck", true) == 0)
    {
        if (PlayerData[playerid][pCuffed])
        {
            return SendClientMessage(playerid, COLOR_RED, "[STUCK] Anda tidak dapat menggunakan /stuck saat sedang diborgol polisi!");
        }

        new opt[16];
        GetNextToken(cmdtext, idx, opt);

        // Jika dalam kendaraan, keluarkan terlebih dahulu
        if (IsPlayerInAnyVehicle(playerid))
        {
            RemovePlayerFromVehicle(playerid);
        }

        ClearAnimations(playerid);
        TogglePlayerControllable(playerid, true);
        SetCameraBehindPlayer(playerid);

        if (strcmp(opt, "spawn", true) == 0 || strcmp(opt, "out", true) == 0)
        {
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            PlayerData[playerid][pInterior] = 0;
            PlayerData[playerid][pVirtualWorld] = 0;
            SetPlayerPos(playerid, 1481.04, -1772.31, 15.30); // Balai Kota LS
            SetPlayerFacingAngle(playerid, 0.0);

            SendClientMessage(playerid, COLOR_GREEN, "[STUCK] Posisi dan dimensi Anda berhasil di-reset ke Balai Kota Los Santos (Exterior).");
            return 1;
        }

        new Float:sx, Float:sy, Float:sz;
        GetPlayerPos(playerid, sx, sy, sz);

        if (sz < -10.0 && GetPlayerInterior(playerid) == 0)
        {
            SetPlayerPos(playerid, 1481.04, -1772.31, 15.30);
            SendClientMessage(playerid, COLOR_GREEN, "[STUCK] Terdeteksi jatuh ke bawah map. Posisi di-reset ke daratan Balai Kota.");
        }
        else
        {
            SetPlayerPos(playerid, sx, sy, sz + 2.0);
            SendClientMessage(playerid, COLOR_GREEN, "[STUCK] Karakter Anda telah diangkat +2.0m, animasi di-reset, dan kontrol dipulihkan.");
            SendClientMessage(playerid, COLOR_YELLOW, "[TIP] Jika masih terjebak di dalam interior tertutup, ketik: /stuck spawn");
        }

        new stuck_rp[120];
        format(stuck_rp, sizeof(stuck_rp), "* %s bergerak dan melepaskan diri dari tempat yang tersangkut.", GetPlayerNameEx(playerid));
        SendLocalMessage(playerid, 10.0, COLOR_PURPLE, stuck_rp);
        return 1;
    }

    // =========================================================================
    // TAHAP 11: SISTEM LOGISTIK TRUK, BAGASI KENDARAAN & JUAL-BELI (/VEHSELL)
    // =========================================================================

    // Perintah: /trucker, /tc (Saluran Radio CB Sopir Truk)
    if (strcmp(cmd, "/trucker", true) == 0 || strcmp(cmd, "/tc", true) == 0)
    {
        if (PlayerData[playerid][pJob] != JOB_TRUCKER && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[TRUCKER] Saluran radio CB ini khusus untuk para Sopir Truk!");
        }

        while (cmdtext[idx] == ' ') idx++;
        if (cmdtext[idx] == '\0')
        {
            return SendClientMessage(playerid, COLOR_YELLOW, "[PANDUAN] /trucker [pesan] atau /tc [pesan]");
        }

        new msg[200];
        format(msg, sizeof(msg), "[RADIO CB] Sopir Truk %s: %s", GetPlayerNameEx(playerid), cmdtext[idx]);

        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && PlayerData[i][pLoggedIn])
            {
                if (PlayerData[i][pJob] == JOB_TRUCKER || PlayerData[i][pAdmin] >= 1)
                {
                    SendClientMessage(i, 0xFF9900AA, msg);
                }
            }
        }
        return 1;
    }

    // Perintah: /trunk, /bagasi (Buka & Kelola Bagasi Kendaraan Pribadi)
    if (strcmp(cmd, "/trunk", true) == 0 || strcmp(cmd, "/bagasi", true) == 0)
    {
        new slot = GetNearPlayerVehicle(playerid, 4.5);
        if (slot == -1)
        {
            return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Anda harus berdiri di dekat (sekeliling/belakang) kendaraan pribadi Anda!");
        }

        if (OwnedVehicles[slot][ovOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
        {
            return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Kendaraan ini bukan milik Anda!");
        }

        if (OwnedVehicles[slot][ovLocked])
        {
            return SendClientMessage(playerid, COLOR_RED, "[BAGASI] Pintu bagasi terkunci! Buka kunci kendaraan dengan /lock terlebih dahulu.");
        }

        // Buka visual boot pintu bagasi mobil
        new eng, lgt, alm, drs, bon, boot, obj;
        GetVehicleParamsEx(OwnedVehicles[slot][ovVehicleID], eng, lgt, alm, drs, bon, boot, obj);
        SetVehicleParamsEx(OwnedVehicles[slot][ovVehicleID], eng, lgt, alm, drs, bon, 1, obj);
        OwnedVehicles[slot][ovTrunkOpen] = true;

        new rp[128];
        format(rp, sizeof(rp), "* %s membuka pintu bagasi kendaraan miliknya.", GetPlayerNameEx(playerid));
        SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
        PlayerPlaySound(playerid, 1145, 0.0, 0.0, 0.0);

        OpenTrunkMenu(playerid, slot);
        return 1;
    }

    // Perintah: /vehsell [playerid] [harga] (Jual Kendaraan ke Pemain Lain)
    if (strcmp(cmd, "/vehsell", true) == 0 || strcmp(cmd, "/sellveh", true) == 0)
    {
        new target_str[16], price_str[16];
        GetNextToken(cmdtext, idx, target_str);
        GetNextToken(cmdtext, idx, price_str);

        if (target_str[0] == '\0' || price_str[0] == '\0')
        {
            return SendClientMessage(playerid, COLOR_YELLOW, "[PANDUAN] /vehsell [playerid] [harga]");
        }

        new targetid = strval(target_str);
        new price = strval(price_str);

        if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pLoggedIn])
        {
            return SendClientMessage(playerid, COLOR_RED, "[ERROR] Pemain target tidak ditemukan atau belum login!");
        }

        if (targetid == playerid)
        {
            return SendClientMessage(playerid, COLOR_RED, "[ERROR] Anda tidak dapat menjual kendaraan ke diri sendiri!");
        }

        if (price < 50)
        {
            return SendClientMessage(playerid, COLOR_RED, "[ERROR] Harga jual minimal adalah $50!");
        }

        new slot = -1;
        if (IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
        {
            new veh = GetPlayerVehicleID(playerid);
            for (new i = 0; i < MAX_OWNED_VEHICLES; i++)
            {
                if (OwnedVehicles[i][ovSpawned] && OwnedVehicles[i][ovVehicleID] == veh)
                {
                    slot = i;
                    break;
                }
            }
        }
        else
        {
            slot = GetNearPlayerVehicle(playerid, 4.5);
        }

        if (slot == -1)
        {
            return SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Anda harus berada di dalam atau di dekat kendaraan pribadi yang ingin dijual!");
        }

        if (OwnedVehicles[slot][ovOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] < 3)
        {
            return SendClientMessage(playerid, COLOR_RED, "[KENDARAAN] Anda bukan pemilik resmi kendaraan ini!");
        }

        new Float:tx, Float:ty, Float:tz;
        GetPlayerPos(targetid, tx, ty, tz);
        if (!IsPlayerInRangeOfPoint(playerid, 6.0, tx, ty, tz))
        {
            return SendClientMessage(playerid, COLOR_RED, "[JUAL-BELI] Calon pembeli harus berada di dekat Anda!");
        }

        PlayerData[targetid][pVehSellSlot] = slot;
        PlayerData[targetid][pVehSellPrice] = price;
        PlayerData[targetid][pVehSellSeller] = playerid;

        new confirm_str[350];
        format(confirm_str, sizeof(confirm_str),
            "{FFFFFF}Pemain {FFFF00}%s {FFFFFF}menawarkan penjualan kendaraan kepada Anda:\n\n"\
            "{00AAFF}Plat Nomor:{FFFFFF} %s\n"\
            "{00AAFF}Harga Penawaran:{00FF00} $%d\n\n"\
            "Apakah Anda setuju untuk membeli kendaraan ini sekarang?",
            GetPlayerNameEx(playerid), OwnedVehicles[slot][ovPlate], price
        );
        ShowPlayerDialog(targetid, DIALOG_VEH_SELL_CONFIRM, DIALOG_STYLE_MSGBOX, "{00AAFF}Tawaran Pembelian Kendaraan", confirm_str, "Beli", "Tolak");

        new smsg[128];
        format(smsg, sizeof(smsg), "[JUAL-BELI] Tawaran penjualan kendaraan (Plat: %s) seharga $%d telah dikirim ke %s.", OwnedVehicles[slot][ovPlate], price, GetPlayerNameEx(targetid));
        SendClientMessage(playerid, COLOR_LIME, smsg);
        return 1;
    }

    // =========================================================================
    // TAHAP 10: PERINTAH PROPERTI BISNIS, TOKO & ITEM (24/7, ELEKTRONIK, GPS, TOPENG)
    // =========================================================================

    // Perintah: /buybiz
    if (strcmp(cmd, "/buybiz", true) == 0)
    {
        new b_idx = GetNearBusinessEntrance(playerid);
        if (b_idx == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "[BISNIS] Anda harus berdiri di dekat pickup pintu masuk bisnis yang dijual!");
            return 1;
        }

        if (BizData[b_idx][bOwnerID] != 0)
        {
            SendClientMessage(playerid, COLOR_RED, "[BISNIS] Bisnis ini sudah dimiliki oleh orang lain!");
            return 1;
        }

        if (GetPlayerMoney(playerid) < BizData[b_idx][bPrice])
        {
            new msg[128];
            format(msg, sizeof(msg), "[BISNIS] Uang tunai Anda tidak mencukupi! Harga bisnis: $%d, Uang Anda: $%d.", BizData[b_idx][bPrice], GetPlayerMoney(playerid));
            SendClientMessage(playerid, COLOR_RED, msg);
            return 1;
        }

        GivePlayerMoney(playerid, -BizData[b_idx][bPrice]);
        BizData[b_idx][bOwnerID] = PlayerData[playerid][pID];
        format(BizData[b_idx][bOwnerName], MAX_PLAYER_NAME, "%s", GetPlayerNameEx(playerid));
        BizData[b_idx][bLocked] = false;
        SaveBusinessData(b_idx);
        UpdateBusinessLabel(b_idx);

        new str[256];
        format(str, sizeof(str), "[SELAMAT] Anda resmi membeli properti bisnis '%s' seharga $%d! Gunakan /bizlock untuk mengatur pintu, /bizsafe untuk kas.", BizData[b_idx][bName], BizData[b_idx][bPrice]);
        SendClientMessage(playerid, COLOR_GREEN, str);
        PlayerPlaySound(playerid, 1149, 0.0, 0.0, 0.0);
        return 1;
    }

    // Perintah: /bizlock
    if (strcmp(cmd, "/bizlock", true) == 0 || strcmp(cmd, "/bl", true) == 0)
    {
        new b_idx = GetNearBusinessEntrance(playerid);
        if (b_idx == -1) b_idx = GetCurrentBusinessIndex(playerid);

        if (b_idx == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "[BISNIS] Anda harus berada di pintu atau di dalam bisnis Anda!");
            return 1;
        }

        if (BizData[b_idx][bOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] == 0)
        {
            SendClientMessage(playerid, COLOR_RED, "[BISNIS] Anda bukan pemilik bisnis ini!");
            return 1;
        }

        BizData[b_idx][bLocked] = !BizData[b_idx][bLocked];
        SaveBusinessData(b_idx);
        UpdateBusinessLabel(b_idx);

        PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0);
        if (BizData[b_idx][bLocked])
        {
            SendClientMessage(playerid, COLOR_YELLOW, "[BISNIS] Pintu bisnis telah DIKUNCI / DITUTUP untuk pelanggan.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_GREEN, "[BISNIS] Pintu bisnis telah DIBUKA untuk seluruh pelanggan.");
        }
        return 1;
    }

    // Perintah: /bizinfo
    if (strcmp(cmd, "/bizinfo", true) == 0)
    {
        new b_idx = GetNearBusinessEntrance(playerid);
        if (b_idx == -1) b_idx = GetCurrentBusinessIndex(playerid);

        if (b_idx == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "[BISNIS] Anda harus berada di dekat atau di dalam bisnis!");
            return 1;
        }

        new type_str[32];
        GetBusinessTypeName(BizData[b_idx][bType], type_str, sizeof(type_str));

        new info[400];
        format(info, sizeof(info),
            "{00AAFF}=== INFORMASI PROPERTI BISNIS ==={FFFFFF}\n\n\
            {00AAFF}ID Bisnis:{FFFFFF} %d\n\
            {00AAFF}Nama Bisnis:{FFFFFF} %s\n\
            {00AAFF}Kategori Tipe:{FFFFFF} %s\n\
            {00AAFF}Pemilik Resmi:{FFFFFF} %s (ID Akun: %d)\n\
            {00AAFF}Status Pintu:{FFFFFF} %s\n\
            {00AAFF}Harga Jual:{FFFFFF} $%d\n\
            {00AAFF}Saldo Brankas Kas:{FFFFFF} $%d",
            BizData[b_idx][bID],
            BizData[b_idx][bName],
            type_str,
            BizData[b_idx][bOwnerName], BizData[b_idx][bOwnerID],
            BizData[b_idx][bLocked] ? ("{FF0000}Terkunci / Tutup") : ("{00FF00}Terbuka / Operasional"),
            BizData[b_idx][bPrice],
            (BizData[b_idx][bOwnerID] == PlayerData[playerid][pID] || PlayerData[playerid][pAdmin] >= 3) ? (BizData[b_idx][bVault]) : (0)
        );
        ShowPlayerDialog(playerid, DIALOG_TURF_INFO, DIALOG_STYLE_MSGBOX, "{00AAFF}Detail Bisnis", info, "Tutup", "");
        return 1;
    }

    // Perintah: /mybiz
    if (strcmp(cmd, "/mybiz", true) == 0)
    {
        new count = 0;
        new list[600];
        list[0] = '\0';

        for (new i = 0; i < g_TotalBusinesses; i++)
        {
            if (BizData[i][bOwnerID] == PlayerData[playerid][pID])
            {
                new tname[32];
                GetBusinessTypeName(BizData[i][bType], tname, sizeof(tname));
                new line[128];
                format(line, sizeof(line), "{00AAFF}#%d {FFFFFF}%s ({FFFF00}%s{FFFFFF}) - Kas: {00FF00}$%d\n", BizData[i][bID], BizData[i][bName], tname, BizData[i][bVault]);
                strcat(list, line, sizeof(list));
                count++;
            }
        }

        if (count == 0)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "[BISNIS] Anda belum memiliki bisnis. Cari bisnis berpickup hijau dan ketik /buybiz!");
            return 1;
        }

        ShowPlayerDialog(playerid, DIALOG_TURF_INFO, DIALOG_STYLE_MSGBOX, "{00AAFF}Daftar Bisnis Milik Anda", list, "Tutup", "");
        return 1;
    }

    // Perintah: /bizsafe, /bizvault
    if (strcmp(cmd, "/bizsafe", true) == 0 || strcmp(cmd, "/bizvault", true) == 0)
    {
        new b_idx = GetNearBusinessEntrance(playerid);
        if (b_idx == -1) b_idx = GetCurrentBusinessIndex(playerid);

        if (b_idx == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "[BISNIS] Anda harus berada di pintu atau di dalam bisnis Anda!");
            return 1;
        }

        if (BizData[b_idx][bOwnerID] != PlayerData[playerid][pID] && PlayerData[playerid][pAdmin] < 3)
        {
            SendClientMessage(playerid, COLOR_RED, "[BISNIS] Anda bukan pemilik bisnis ini!");
            return 1;
        }

        ShowPlayerDialog(playerid, DIALOG_BIZ_SAFE_MAIN, DIALOG_STYLE_LIST, "{00AAFF}Brankas Kas Bisnis",
            "1. Setor Uang ke Kas (Deposit)\n2. Tarik Uang dari Kas (Withdraw)\n3. Cek Status Keuangan Bisnis",
            "Pilih", "Tutup");
        return 1;
    }

    // Perintah: /buy
    if (strcmp(cmd, "/buy", true) == 0)
    {
        new b_curr = GetCurrentBusinessIndex(playerid);
        if (b_curr != -1)
        {
            if (BizData[b_curr][bType] == BIZ_TYPE_247)
            {
                ShowPlayerDialog(playerid, DIALOG_247_SHOP, DIALOG_STYLE_TABLIST_HEADERS, "{00AAFF}24/7 Supermarket - Daftar Barang",
                    "Nama Barang\tHarga\n                    GPS Navigasi Satelit\t{00FF00}$500\n                    Topeng / Masker Penyamaran\t{00FF00}$800\n                    Bungkus Rokok (20 Batang)\t{00FF00}$50\n                    Snack & Minuman Energi\t{00FF00}$25",
                    "Beli", "Batal");
                return 1;
            }
            else if (BizData[b_curr][bType] == BIZ_TYPE_ELECTRONIC)
            {
                ShowPlayerDialog(playerid, DIALOG_ELECTRONIC_SHOP, DIALOG_STYLE_TABLIST_HEADERS, "{00AAFF}Toko Elektronik - Gadget & Tools",
                    "Nama Produk\tHarga\n                    GPS Tracker Digital\t{00FF00}$400\n                    Topeng Balaclava Digital\t{00FF00}$600",
                    "Beli", "Batal");
                return 1;
            }
            else if (BizData[b_curr][bType] == BIZ_TYPE_RESTAURANT)
            {
                OpenFoodMenu(playerid);
                return 1;
            }
        }

        if (IsPlayerNearFood(playerid))
        {
            OpenFoodMenu(playerid);
            return 1;
        }

        SendClientMessage(playerid, COLOR_RED, "[TOKO] Anda harus berada di dalam Toko 24/7, Toko Elektronik, atau Restoran untuk berbelanja!");
        return 1;
    }

    // Perintah: /usemask, /mask
    if (strcmp(cmd, "/usemask", true) == 0 || strcmp(cmd, "/mask", true) == 0)
    {
        if (PlayerData[playerid][pHasMask] < 1)
        {
            SendClientMessage(playerid, COLOR_RED, "[TOPENG] Anda tidak memiliki topeng! Beli di Toko 24/7 atau Toko Elektronik.");
            return 1;
        }

        PlayerData[playerid][pMaskActive] = !PlayerData[playerid][pMaskActive];

        new rp[120];
        if (PlayerData[playerid][pMaskActive])
        {
            format(rp, sizeof(rp), "* %s mengenakan masker penutup wajah dan menyembunyikan identitasnya.", GetPlayerNameEx(playerid));
            SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
            SendClientMessage(playerid, COLOR_YELLOW, "[TOPENG] Topeng AKTIF! Nama Anda kini disamarkan di obrolan lokal.");
        }
        else
        {
            format(rp, sizeof(rp), "* %s melepaskan masker penutup wajah dan memperlihatkan identitasnya.", GetPlayerNameEx(playerid));
            SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);
            SendClientMessage(playerid, COLOR_YELLOW, "[TOPENG] Topeng NON-AKTIF! Identitas asli Anda kini terlihat.");
        }
        return 1;
    }

    // Perintah: /usegps, /gps
    if (strcmp(cmd, "/usegps", true) == 0 || strcmp(cmd, "/gps", true) == 0)
    {
        if (PlayerData[playerid][pHasGPS] < 1)
        {
            SendClientMessage(playerid, COLOR_RED, "[GPS] Anda tidak memiliki perangkat GPS! Beli di Toko 24/7 atau Toko Elektronik.");
            return 1;
        }

        ShowPlayerDialog(playerid, DIALOG_GPS_MENU, DIALOG_STYLE_LIST, "{00AAFF}GPS Satelit Los Santos - Tujuan Lokasi",
            "1. Balai Kota & Agen Pekerjaan (City Hall)\n            2. Kantor Polisi Los Santos (SAPD HQ)\n            3. Rumah Sakit All Saints (SAMD Hospital)\n            4. Showroom Kendaraan Los Santos (Commerce)\n            5. Depo Pembersih Jalan (Sweeper Job)\n            6. Halte Bus Kota (Bus Job)\n            7. Bank Los Santos & ATM Utama\n            8. Rumah Milik Saya\n            9. Bisnis Milik Saya\n            10. {FF0000}Nonaktifkan Checkpoint GPS",
            "Pilih", "Tutup");
        return 1;
    }

    // Perintah: /smokecigarette, /smoke, /rokok
    if (strcmp(cmd, "/smokecigarette", true) == 0 || strcmp(cmd, "/smoke", true) == 0 || strcmp(cmd, "/rokok", true) == 0)
    {
        if (PlayerData[playerid][pCigarettes] < 1)
        {
            SendClientMessage(playerid, COLOR_RED, "[ROKOK] Anda tidak memiliki rokok! Beli 1 bungkus di Toko 24/7.");
            return 1;
        }

        PlayerData[playerid][pCigarettes]--;
        SavePlayerData(playerid);

        ApplyAnimation(playerid, "SMOKING", "M_smkstnd_loop", 4.1, false, false, false, false, 4000);

        new rp[128];
        format(rp, sizeof(rp), "* %s menyalakan sebatang rokok dan menghisapnya perlahan.", GetPlayerNameEx(playerid));
        SendLocalMessage(playerid, 15.0, COLOR_PURPLE, rp);

        new msg[100];
        format(msg, sizeof(msg), "[ROKOK] Anda menghisap 1 batang rokok. Sisa rokok: %d batang.", PlayerData[playerid][pCigarettes]);
        SendClientMessage(playerid, COLOR_LIME, msg);
        return 1;
    }

    // Perintah: /createbiz [price] [type:1-3] [name...] (Admin L3+)
    if (strcmp(cmd, "/createbiz", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 3)
        {
            return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini hanya untuk Admin Level 3 ke atas!");
        }

        if (g_TotalBusinesses >= MAX_BUSINESSES)
        {
            return SendClientMessage(playerid, COLOR_RED, "[BISNIS] Batas maksimal bisnis di server telah tercapai!");
        }

        new price_str[16], type_str[16];
        GetNextToken(cmdtext, idx, price_str);
        GetNextToken(cmdtext, idx, type_str);

        if (strlen(price_str) == 0 || strlen(type_str) == 0)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "[PANDUAN] /createbiz [harga] [tipe: 1=24/7, 2=Elektronik, 3=Restoran] [Nama Bisnis]");
            return 1;
        }

        new price = strval(price_str);
        new type = strval(type_str);
        if (price < 100) price = 100;
        if (type < 1 || type > 3) type = 1;

        while (cmdtext[idx] == ' ') idx++;
        new biz_name[48];
        if (cmdtext[idx] != '\0')
        {
            format(biz_name, sizeof(biz_name), "%s", cmdtext[idx]);
        }
        else
        {
            format(biz_name, sizeof(biz_name), "Bisnis Baru");
        }

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        new int_id;
        new Float:ex_x, Float:ex_y, Float:ex_z;
        GetBusinessInteriorPreset(type, int_id, ex_x, ex_y, ex_z);

        new clean_name[96];
        DB_Escape(biz_name, clean_name, sizeof(clean_name));

        new query[512];
        format(query, sizeof(query),
            "INSERT INTO businesses (owner_id, name, type, price, enter_x, enter_y, enter_z, exit_x, exit_y, exit_z, interior, locked, vault)             VALUES (0, '%s', %d, %d, %f, %f, %f, %f, %f, %f, %d, 0, 0);",
            clean_name, type, price, x, y, z, ex_x, ex_y, ex_z, int_id
        );
        DB_FreeResultSet(DB_ExecuteQuery(g_DB, query));

        new new_id = 1;
        new DBResult:id_res = DB_ExecuteQuery(g_DB, "SELECT last_insert_rowid() AS last_id;");
        if (DB_GetRowCount(id_res) > 0)
        {
            new_id = DB_GetFieldIntByName(id_res, "last_id");
        }
        DB_FreeResultSet(id_res);

        new slot = g_TotalBusinesses;
        BizData[slot][bID] = new_id;
        BizData[slot][bOwnerID] = 0;
        format(BizData[slot][bOwnerName], MAX_PLAYER_NAME, "Pemerintah");
        format(BizData[slot][bName], 48, "%s", biz_name);
        BizData[slot][bType] = type;
        BizData[slot][bPrice] = price;
        BizData[slot][bEnterX] = x;
        BizData[slot][bEnterY] = y;
        BizData[slot][bEnterZ] = z;
        BizData[slot][bExitX] = ex_x;
        BizData[slot][bExitY] = ex_y;
        BizData[slot][bExitZ] = ex_z;
        BizData[slot][bInterior] = int_id;
        BizData[slot][bLocked] = false;
        BizData[slot][bVault] = 0;
        BizData[slot][bPickup] = 0;
        BizData[slot][bLabel] = Text3D:INVALID_3DTEXT_ID;
        BizData[slot][bExitPickup] = 0;
        BizData[slot][bExitLabel] = Text3D:INVALID_3DTEXT_ID;
        BizData[slot][bLoaded] = true;

        g_TotalBusinesses++;
        UpdateBusinessLabel(slot);

        new msg[160];
        format(msg, sizeof(msg), "[ADMIN] Berhasil membuat properti bisnis #%d '%s' (Tipe: %d, Harga: $%d) di posisi Anda.", new_id, biz_name, type, price);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        return 1;
    }

    // Perintah: /destroybiz [bizid], /deletebiz [bizid] (Admin L3+)
    if (strcmp(cmd, "/destroybiz", true) == 0 || strcmp(cmd, "/deletebiz", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 3)
        {
            return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini hanya untuk Admin Level 3 ke atas!");
        }

        new id_str[16];
        GetNextToken(cmdtext, idx, id_str);
        if (strlen(id_str) == 0)
        {
            return SendClientMessage(playerid, COLOR_YELLOW, "[PANDUAN] /destroybiz [bizid]");
        }

        new target_id = strval(id_str);
        new b_idx = GetBusinessIndexByID(target_id);
        if (b_idx == -1)
        {
            return SendClientMessage(playerid, COLOR_RED, "[BISNIS] ID Bisnis tersebut tidak ditemukan!");
        }

        new b_name[48];
        format(b_name, sizeof(b_name), "%s", BizData[b_idx][bName]);
        DestroyBusiness(b_idx);

        new msg[128];
        format(msg, sizeof(msg), "[ADMIN] Bisnis ID #%d ('%s') telah berhasil dihapus secara permanen.", target_id, b_name);
        SendClientMessage(playerid, COLOR_LIME, msg);
        return 1;
    }

    // Perintah: /setbiz [subcmd] (Admin L3+)
    if (strcmp(cmd, "/setbiz", true) == 0)
    {
        if (PlayerData[playerid][pAdmin] < 3)
        {
            return SendClientMessage(playerid, COLOR_RED, "[ADMIN] Perintah ini hanya untuk Admin Level 3 ke atas!");
        }

        new subcmd[24];
        GetNextToken(cmdtext, idx, subcmd);

        if (strcmp(subcmd, "list", true) == 0)
        {
            SendClientMessage(playerid, COLOR_CYAN, "=== DAFTAR BISNIS SERVER ===");
            for (new i = 0; i < g_TotalBusinesses; i++)
            {
                new line[140], tname[32];
                GetBusinessTypeName(BizData[i][bType], tname, sizeof(tname));
                format(line, sizeof(line), "ID #%d: '%s' | Tipe: %s | Pemilik: %s | Harga: $%d | Kas: $%d",
                    BizData[i][bID], BizData[i][bName], tname, BizData[i][bOwnerName], BizData[i][bPrice], BizData[i][bVault]);
                SendClientMessage(playerid, COLOR_WHITE, line);
            }
            return 1;
        }
        else if (strcmp(subcmd, "tp", true) == 0)
        {
            new id_str[16];
            GetNextToken(cmdtext, idx, id_str);
            new b_idx = GetBusinessIndexByID(strval(id_str));
            if (b_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] ID Bisnis tidak ditemukan!");

            SetPlayerPos(playerid, BizData[b_idx][bEnterX], BizData[b_idx][bEnterY], BizData[b_idx][bEnterZ] + 1.0);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            PlayerData[playerid][pInterior] = 0;
            PlayerData[playerid][pVirtualWorld] = 0;
            SavePlayerData(playerid);

            new msg[128];
            format(msg, sizeof(msg), "[ADMIN] Teleport ke pintu bisnis ID #%d ('%s').", BizData[b_idx][bID], BizData[b_idx][bName]);
            SendClientMessage(playerid, COLOR_LIME, msg);
            return 1;
        }
        else if (strcmp(subcmd, "price", true) == 0)
        {
            new id_str[16], p_str[16];
            GetNextToken(cmdtext, idx, id_str);
            GetNextToken(cmdtext, idx, p_str);
            new b_idx = GetBusinessIndexByID(strval(id_str));
            if (b_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] ID Bisnis tidak ditemukan!");
            new new_price = strval(p_str);
            if (new_price < 0) new_price = 0;

            BizData[b_idx][bPrice] = new_price;
            SaveBusinessData(b_idx);
            UpdateBusinessLabel(b_idx);

            new msg[128];
            format(msg, sizeof(msg), "[ADMIN] Harga bisnis ID #%d diubah menjadi $%d.", BizData[b_idx][bID], new_price);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }
        else if (strcmp(subcmd, "owner", true) == 0)
        {
            new id_str[16], o_str[16];
            GetNextToken(cmdtext, idx, id_str);
            GetNextToken(cmdtext, idx, o_str);
            new b_idx = GetBusinessIndexByID(strval(id_str));
            if (b_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] ID Bisnis tidak ditemukan!");
            new target_pid = strval(o_str);

            if (target_pid == 0)
            {
                BizData[b_idx][bOwnerID] = 0;
                format(BizData[b_idx][bOwnerName], MAX_PLAYER_NAME, "Pemerintah");
                SendClientMessage(playerid, COLOR_GREEN, "[ADMIN] Kepemilikan bisnis di-reset menjadi dijual.");
            }
            else
            {
                if (!IsPlayerConnected(target_pid)) return SendClientMessage(playerid, COLOR_RED, "[ERROR] Player target tidak aktif!");
                BizData[b_idx][bOwnerID] = PlayerData[target_pid][pID];
                format(BizData[b_idx][bOwnerName], MAX_PLAYER_NAME, "%s", GetPlayerNameEx(target_pid));

                new msg[128];
                format(msg, sizeof(msg), "[ADMIN] Kepemilikan bisnis #%d diserahkan kepada %s.", BizData[b_idx][bID], GetPlayerNameEx(target_pid));
                SendClientMessage(playerid, COLOR_GREEN, msg);
            }
            SaveBusinessData(b_idx);
            UpdateBusinessLabel(b_idx);
            return 1;
        }
        else if (strcmp(subcmd, "name", true) == 0)
        {
            new id_str[16];
            GetNextToken(cmdtext, idx, id_str);
            new b_idx = GetBusinessIndexByID(strval(id_str));
            if (b_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] ID Bisnis tidak ditemukan!");

            while (cmdtext[idx] == ' ') idx++;
            if (cmdtext[idx] == '\0') return SendClientMessage(playerid, COLOR_YELLOW, "[PANDUAN] /setbiz name [bizid] [Nama Baru]");
            new new_n[48];
            format(new_n, sizeof(new_n), "%s", cmdtext[idx]);

            format(BizData[b_idx][bName], 48, "%s", new_n);
            SaveBusinessData(b_idx);
            UpdateBusinessLabel(b_idx);

            new msg[128];
            format(msg, sizeof(msg), "[ADMIN] Nama bisnis ID #%d diubah menjadi '%s'.", BizData[b_idx][bID], new_n);
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }
        else if (strcmp(subcmd, "pos", true) == 0)
        {
            new id_str[16];
            GetNextToken(cmdtext, idx, id_str);
            new b_idx = GetBusinessIndexByID(strval(id_str));
            if (b_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] ID Bisnis tidak ditemukan!");

            new Float:px, Float:py, Float:pz;
            GetPlayerPos(playerid, px, py, pz);
            BizData[b_idx][bEnterX] = px;
            BizData[b_idx][bEnterY] = py;
            BizData[b_idx][bEnterZ] = pz;
            SaveBusinessData(b_idx);
            UpdateBusinessLabel(b_idx);

            SendClientMessage(playerid, COLOR_GREEN, "[ADMIN] Pintu masuk bisnis dipindahkan ke koordinat Anda saat ini.");
            return 1;
        }
        else if (strcmp(subcmd, "lock", true) == 0)
        {
            new id_str[16];
            GetNextToken(cmdtext, idx, id_str);
            new b_idx = GetBusinessIndexByID(strval(id_str));
            if (b_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] ID Bisnis tidak ditemukan!");

            BizData[b_idx][bLocked] = !BizData[b_idx][bLocked];
            SaveBusinessData(b_idx);
            UpdateBusinessLabel(b_idx);

            new msg[100];
            format(msg, sizeof(msg), "[ADMIN] Status bisnis #%d diubah menjadi: %s.", BizData[b_idx][bID], BizData[b_idx][bLocked] ? ("TUTUP") : ("BUKA"));
            SendClientMessage(playerid, COLOR_GREEN, msg);
            return 1;
        }
        else if (strcmp(subcmd, "delete", true) == 0)
        {
            new id_str[16];
            GetNextToken(cmdtext, idx, id_str);
            new b_idx = GetBusinessIndexByID(strval(id_str));
            if (b_idx == -1) return SendClientMessage(playerid, COLOR_RED, "[BISNIS] ID Bisnis tidak ditemukan!");
            DestroyBusiness(b_idx);
            SendClientMessage(playerid, COLOR_LIME, "[ADMIN] Bisnis telah berhasil dihapus.");
            return 1;
        }

        SendClientMessage(playerid, COLOR_YELLOW, "[PANDUAN] /setbiz [list / tp / price / owner / name / pos / lock / delete]");
        return 1;
    }

    // Perintah: /stats
    if (strcmp(cmd, "/stats", true) == 0)
    {
        new f_name[48], r_name[32];
        GetFactionName(PlayerData[playerid][pFaction], f_name, sizeof(f_name));
        GetFactionRankName(PlayerData[playerid][pFaction], PlayerData[playerid][pFactionRank], r_name, sizeof(r_name));

        new stats[900];
        format(stats, sizeof(stats),
            "{00AAFF}=== PROFIL & STATUS KARAKTER ==={FFFFFF}\n\n\
            {00AAFF}Nama Karakter:{FFFFFF} %s (ID: %d)\n\
            {00AAFF}Pangkat Admin:{FFFFFF} %s (Level %d)\n\
            {00AAFF}Status Admin Duty:{FFFFFF} %s\n\
            {00AAFF}Faksi:{FFFFFF} %s (Pangkat: %s)\n\
            {00AAFF}Status Dinas:{FFFFFF} %s\n\
            {00AAFF}Pekerjaan Sampingan:{FFFFFF} %s\n\
            {00AAFF}Jumlah Kendaraan Pribadi:{FFFFFF} %d Unit\n\
            {00AAFF}Level / Skor:{FFFFFF} %d\n\
            {00AAFF}Uang Tunai (Cash):{FFFFFF} $%d\n\
            {00AAFF}Saldo Rekening Bank:{FFFFFF} $%d\n\
            {00AAFF}Tingkat Buronan (Wanted):{FFFFFF} %d Bintang\n\
            {00AAFF}Status Tahanan Penjara:{FFFFFF} %s\n\
            {00AAFF}Tingkat Lapar & Haus:{FFFFFF} %d%% / %d%%\n\
            {00AAFF}Progress Paycheck:{FFFFFF} %d / 60 Menit\n\
            {00AAFF}Kondisi Darah / Armour:{FFFFFF} %.1f / %.1f",
            GetPlayerNameEx(playerid), playerid,
            (PlayerData[playerid][pAdmin] == 5) ? ("Server Owner / Dev") : ((PlayerData[playerid][pAdmin] > 0) ? ("Admin Server") : ("Warga Sipil")),
            PlayerData[playerid][pAdmin],
            (PlayerData[playerid][pAdmin] >= 1) ? (PlayerData[playerid][pAdminDuty] ? ("{00FF00}ON-DUTY (God Mode)") : ("{FF0000}OFF-DUTY (Bisa Mati)")) : ("-"),
            f_name, r_name,
            PlayerData[playerid][pOnDuty] ? ("{00FF00}Sedang Bertugas (On-Duty)") : ("{AFAFAF}Lepas Tugas (Off-Duty)"),
            GetJobName(PlayerData[playerid][pJob]),
            GetPlayerOwnedVehicleCount(playerid),
            GetPlayerScore(playerid),
            GetPlayerMoney(playerid),
            PlayerData[playerid][pBank],
            PlayerData[playerid][pWantedLevel],
            (PlayerData[playerid][pJailTime] > 0) ? ("{FF0000}Di Dalam Penjara") : ("{00FF00}Bebas"),
            PlayerData[playerid][pHunger],
            PlayerData[playerid][pThirst],
            PlayerData[playerid][pPaycheckTime],
            PlayerData[playerid][pHealth],
            PlayerData[playerid][pArmour]
        );
        ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, "{00AAFF}Statistik Karakter", stats, "Tutup", "");
        return 1;
    }

    // Perintah: /savemypos
    if (strcmp(cmd, "/savemypos", true) == 0)
    {
        SavePlayerData(playerid);
        SendClientMessage(playerid, COLOR_GREEN, "Posisi dan data karakter Anda telah tersimpan ke database.");
        return 1;
    }

    // Perintah: /cmds, /commands (Tampilkan langsung ringkasan seluruh perintah)
    if (strcmp(cmd, "/cmds", true) == 0 || strcmp(cmd, "/commands", true) == 0)
    {
        ShowAllCommandsDialog(playerid);
        return 1;
    }

    // Perintah: /help, /bantuan (Buka menu bantuan interaktif 10 kategori)
    if (strcmp(cmd, "/help", true) == 0 || strcmp(cmd, "/bantuan", true) == 0)
    {
        OpenHelpMenu(playerid);
        return 1;
    }

    return 0;
}
