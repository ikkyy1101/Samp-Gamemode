// =============================================================================
// File: gamemodes/core/database.inc
// Fungsi: Abstraksi layer koneksi MySQL/MariaDB, error handler, auto-reconnect,
//         dan proteksi race-condition asynchronous queries.
// Dependensi: <open.mp>, <a_mysql>, core/config.inc, core/colors.inc
// =============================================================================

#if defined _INC_CORE_DATABASE
    #endinput
#endif
#define _INC_CORE_DATABASE

#include <a_mysql>

// --- Handle Koneksi Database Global ---
new MySQL:g_SQL = MYSQL_INVALID_HANDLE;
#define g_DB g_SQL

// --- Proteksi Race Condition ID Antara Koneksi & Disconnect ---
new g_PlayerRaceCheck[MAX_PLAYERS];

// -----------------------------------------------------------------------------
// Inisialisasi Koneksi Database MySQL / MariaDB Saat Startup Server
// -----------------------------------------------------------------------------
stock bool:Database_Init()
{
    // Aktifkan logging driver MySQL untuk level ERROR dan WARNING
    mysql_log(ERROR | WARNING);

    print("[DATABASE] Menghubungkan ke database melalui 'mysql.ini'...");
    g_SQL = mysql_connect_file("mysql.ini");

    if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
    {
        new err_msg[128];
        mysql_error(err_msg, sizeof(err_msg), g_SQL);
        printf("[DATABASE CRITICAL] Gagal terhubung ke MySQL! Kode: %d | Pesan: %s", mysql_errno(g_SQL), err_msg);
        printf("[DATABASE CRITICAL] Periksa file 'mysql.ini' dan pastikan MariaDB/MySQL service aktif.");
        return false;
    }

    // Set karakter encoding ke utf8mb4 agar mendukung karakter internasional & emoji
    mysql_set_charset("utf8mb4", g_SQL);

    printf("[DATABASE SUCCESS] Berhasil terhubung ke database MySQL (Handle: %d)!", _:g_SQL);

    // Reset seluruh race check array
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        g_PlayerRaceCheck[i] = 0;
    }

    return true;
}

// -----------------------------------------------------------------------------
// Cek Status Koneksi Aktif Database
// -----------------------------------------------------------------------------
stock bool:Database_IsConnected()
{
    return (g_SQL != MYSQL_INVALID_HANDLE);
}

// -----------------------------------------------------------------------------
// Tutup Koneksi Database Saat Gamemode Berakhir (GMX / Server Shutdown)
// -----------------------------------------------------------------------------
stock Database_Exit()
{
    if (g_SQL != MYSQL_INVALID_HANDLE)
    {
        print("[DATABASE] Menutup handle koneksi MySQL...");
        mysql_close(g_SQL);
        g_SQL = MYSQL_INVALID_HANDLE;
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Periksa Status Koneksi & Auto-Keepalive Ping Berkala
// -----------------------------------------------------------------------------
forward OnDatabaseKeepAlive();
public OnDatabaseKeepAlive()
{
    return 1;
}

stock Database_Ping()
{
    if (g_SQL == MYSQL_INVALID_HANDLE)
    {
        print("[DATABASE WARNING] Handle database tidak valid. Mencoba inisialisasi ulang...");
        return Database_Init();
    }

    mysql_tquery(g_SQL, "SELECT 1;", "OnDatabaseKeepAlive", "");
    return 1;
}

// -----------------------------------------------------------------------------
// Callback Otomatis Penanganan Query Error dari Driver MySQL
// -----------------------------------------------------------------------------
public OnQueryError(errorid, const error[], const callback[], const query[], MySQL:handle)
{
    printf("=================================================================");
    printf("[MYSQL QUERY ERROR]");
    printf("Kode Error  : %d", errorid);
    printf("Pesan Error : %s", error);
    printf("Callback    : %s", callback);
    printf("Query Teks  : %s", query);
    printf("Handle ID   : %d", _:handle);
    printf("=================================================================");
    return 1;
}

// -----------------------------------------------------------------------------
// Helper Proteksi Race Condition ID
// -----------------------------------------------------------------------------
stock Database_GetPlayerRaceCheck(playerid)
{
    if (playerid < 0 || playerid >= MAX_PLAYERS) return -1;
    return g_PlayerRaceCheck[playerid];
}

stock Database_GetRaceCheck(playerid)
{
    return Database_GetPlayerRaceCheck(playerid);
}

stock Database_IncrementRaceCheck(playerid)
{
    if (playerid < 0 || playerid >= MAX_PLAYERS) return -1;
    return ++g_PlayerRaceCheck[playerid];
}

stock bool:Database_IsValidRaceCheck(playerid, race_id)
{
    if (playerid < 0 || playerid >= MAX_PLAYERS) return false;
    return (g_PlayerRaceCheck[playerid] == race_id);
}

stock bool:Database_IsRaceCheckValid(playerid, race_id)
{
    return Database_IsValidRaceCheck(playerid, race_id);
}
