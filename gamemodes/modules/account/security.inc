/**
 * File: gamemodes/modules/account/security.inc
 * Modul: Account Security, Cinematic Login Camera & Ban Verification
 * Deskripsi: Menangani layar koneksi sinematik, pengecekan ban IP/GPCI/Akun,
 *            batas waktu login 60 detik, dan pencatatan log autentikasi.
 * Dependensi: <open.mp>, <a_mysql>, <YSI_Coding\y_hooks>, <YSI_Coding\y_timers>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc
 */

#if defined _INC_ACCOUNT_SECURITY
    #endinput
#endif
#define _INC_ACCOUNT_SECURITY

#include <YSI_Coding\y_hooks>
#include <YSI_Coding\y_timers>

// ============================================================================
// KONSTANTA KEAMANAN AKUN
// ============================================================================
#define ACCOUNT_BCRYPT_COST         (12)
#define ACCOUNT_MIN_PASS_LEN        (6)
#define ACCOUNT_MAX_PASS_LEN        (32)
#define ACCOUNT_MAX_LOGIN_ATTEMPTS  (3)
#define ACCOUNT_LOGIN_TIMEOUT_SEC   (60)
#define ACCOUNT_CAMERA_MOVE_MS      (25000)

// Forward deklarasi lintas sub-modul akun
forward Account_StartRegister(playerid);
forward Account_StartLogin(playerid, accountId, const passwordHash[], loginAttempts, const lastIp[], const lastLogin[]);
forward Account_OnAuthenticated(playerid, accountId);

// ============================================================================
// FUNGSI PUBLIK MODUL (ACCOUNT_*)
// ============================================================================

/**
 * Mengatur kamera sinematik saat pemain berada di layar login/registrasi.
 */
stock Account_SetupLoginCamera(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    TogglePlayerSpectating(playerid, true);
    SetPlayerVirtualWorld(playerid, playerid + 100);
    SetPlayerInterior(playerid, 0);

    // Interpolasi kamera menyusuri pusat kota Los Santos (Pershing Square -> Vinewood)
    InterpolateCameraPos(
        playerid,
        1480.5000, -1740.2000, 55.0000,
        1420.8000, -1350.6000, 75.0000,
        ACCOUNT_CAMERA_MOVE_MS,
        CAMERA_MOVE
    );
    InterpolateCameraLookAt(
        playerid,
        1481.0300, -1650.0000, 20.0000,
        1415.0000, -1250.0000, 25.0000,
        ACCOUNT_CAMERA_MOVE_MS,
        CAMERA_MOVE
    );
    return 1;
}

/**
 * Mencatat aktivitas autentikasi (login/register/kick/ban) ke tabel `logs`.
 */
stock Account_LogAuthEvent(const message[], const ip[])
{
    if (!Database_IsConnected())
    {
        return 0;
    }

    new query[512];
    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('auth', NULL, NULL, '%e', '%e')",
        message,
        ip
    );
    mysql_tquery(g_SQL, query);
    return 1;
}

/**
 * Memulai pengecekan ban berlapis (IP, GPCI/Serial, dan Username) secara asynchronous.
 */
stock Account_CheckBan(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    if (!Database_IsConnected())
    {
        SendClientMessage(playerid, COLOR_ERROR, "[Server] Database sedang tidak tersedia. Silakan coba beberapa saat lagi.");
        DelayedKick(playerid, 500);
        return 0;
    }

    PlayerData[playerid][pAuthState] = AUTH_STATE_CHECKING_BAN;

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[512];

    // Nonaktifkan ban sementara yang sudah melewati tanggal expire_at
    mysql_tquery(g_SQL, "UPDATE `bans` SET `active` = 0 WHERE `active` = 1 AND `expire_at` IS NOT NULL AND `expire_at` <= NOW()");

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT b.`id`, b.`reason`, b.`admin_name`, b.`banned_at`, COALESCE(b.`expire_at`, 'Permanen') AS `expire_str` \
         FROM `bans` b \
         LEFT JOIN `accounts` a ON a.`id` = b.`account_id` \
         WHERE b.`active` = 1 AND (b.`ip` = '%e' OR (b.`serial` <> '' AND b.`serial` = '%e') OR a.`username` = '%e') \
         ORDER BY b.`id` DESC LIMIT 1",
        PlayerData[playerid][pCurrentIP],
        PlayerData[playerid][pGPCI],
        PlayerData[playerid][pUsername]
    );

    mysql_tquery(g_SQL, query, "OnAccountBanCheckResult", "ii", playerid, racecheck);
    return 1;
}

/**
 * Mengecek apakah username sudah terdaftar di tabel `accounts`.
 */
static Account_LookupUsername(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    PlayerData[playerid][pAuthState] = AUTH_STATE_CHECKING_ACCOUNT;

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[384];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT `id`, `password_hash`, `login_attempts`, `banned`, \
                COALESCE(`last_ip`, '-') AS `last_ip`, \
                COALESCE(DATE_FORMAT(`last_login`, '%%d/%%m/%%Y %%H:%%i'), 'Belum pernah') AS `last_login_str` \
         FROM `accounts` WHERE `username` = '%e' LIMIT 1",
        PlayerData[playerid][pUsername]
    );

    mysql_tquery(g_SQL, query, "OnAccountLookupResult", "ii", playerid, racecheck);
    return 1;
}

// ============================================================================
// CALLBACKS MYSQL KEAMANAN AKUN
// ============================================================================
forward OnAccountBanCheckResult(playerid, racecheck);
public OnAccountBanCheckResult(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (cache_num_rows() > 0)
    {
        new
            banId,
            reason[255],
            adminName[32],
            bannedAt[32],
            expireStr[32],
            dialogBody[512],
            logMsg[256];

        cache_get_value_name_int(0, "id", banId);
        cache_get_value_name(0, "reason", reason, sizeof(reason));
        cache_get_value_name(0, "admin_name", adminName, sizeof(adminName));
        cache_get_value_name(0, "banned_at", bannedAt, sizeof(bannedAt));
        cache_get_value_name(0, "expire_str", expireStr, sizeof(expireStr));

        format(
            dialogBody,
            sizeof(dialogBody),
            "{FF4D4D}Akses Anda ke PARADISE Roleplay telah diblokir!\n\n\
            {FFFFFF}ID Ban: {FFD166}#%d\n\
            {FFFFFF}Akun: {FFD166}%s\n\
            {FFFFFF}Admin: {FFD166}%s\n\
            {FFFFFF}Alasan: {FFD166}%s\n\
            {FFFFFF}Waktu Ban: {FFD166}%s\n\
            {FFFFFF}Berakhir: {FFD166}%s\n\n\
            {B0B8C1}Jika ini merupakan kesalahan, ajukan banding di forum/Discord resmi.",
            banId,
            PlayerData[playerid][pUsername],
            adminName,
            reason,
            bannedAt,
            expireStr
        );

        ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "{FF4D4D}Akun / Koneksi Diblokir", dialogBody, "Tutup", "");

        format(logMsg, sizeof(logMsg), "Koneksi diblokir oleh sistem ban (#%d) untuk %s", banId, PlayerData[playerid][pUsername]);
        Account_LogAuthEvent(logMsg, PlayerData[playerid][pCurrentIP]);

        DelayedKick(playerid, 500);
        return 1;
    }

    Account_LookupUsername(playerid);
    return 1;
}

forward OnAccountLookupResult(playerid, racecheck);
public OnAccountLookupResult(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (cache_num_rows() == 0)
    {
        // Akun belum terdaftar -> arahkan ke registrasi
        Account_StartRegister(playerid);
        return 1;
    }

    new
        accountId,
        bannedFlag,
        loginAttempts,
        passwordHash[128],
        lastIp[46],
        lastLogin[32];

    cache_get_value_name_int(0, "id", accountId);
    cache_get_value_name_int(0, "banned", bannedFlag);
    cache_get_value_name_int(0, "login_attempts", loginAttempts);
    cache_get_value_name(0, "password_hash", passwordHash, sizeof(passwordHash));
    cache_get_value_name(0, "last_ip", lastIp, sizeof(lastIp));
    cache_get_value_name(0, "last_login_str", lastLogin, sizeof(lastLogin));

    if (bannedFlag == 1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Akun Anda berstatus diblokir permanen. Hubungi staf server untuk informasi.");
        DelayedKick(playerid, 500);
        return 1;
    }

    Account_StartLogin(playerid, accountId, passwordHash, loginAttempts, lastIp, lastLogin);
    return 1;
}

// ============================================================================
// HOOKS & TIMER KEAMANAN SESI
// ============================================================================
hook OnPlayerConnect(playerid)
{
    Variables_ResetPlayerData(playerid);

    new
        playerName[MAX_PLAYER_NAME],
        playerIp[46],
        playerSerial[64];

    GetPlayerNameString(playerid, playerName, sizeof(playerName));
    GetPlayerIp(playerid, playerIp, sizeof(playerIp));
    GPCI(playerid, playerSerial, sizeof(playerSerial));

    format(PlayerData[playerid][pUsername], MAX_PLAYER_NAME, "%s", playerName);
    format(PlayerData[playerid][pCurrentIP], 46, "%s", playerIp);
    format(PlayerData[playerid][pGPCI], 64, "%s", playerSerial);

    if (!IsValidRoleplayName(playerName))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Nama Anda bukan nama Roleplay! Gunakan format Nama_Marga (contoh: Budi_Santoso).");
        DelayedKick(playerid, 500);
        return 1;
    }

    // Bersihkan chat layar saat masuk
    for (new i = 0; i < 15; i++)
    {
        SendClientMessage(playerid, -1, "");
    }

    SendClientMessage(playerid, COLOR_PRIMARY, "Selamat datang di PARADISE Roleplay! Memeriksa status akun Anda...");
    Account_SetupLoginCamera(playerid);
    Account_CheckBan(playerid);
    return 1;
}

forward Character_Save(playerid);

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    if (PlayerData[playerid][pCharacterLoaded])
    {
        Character_Save(playerid);
    }
    Variables_ResetPlayerData(playerid);
    return 1;
}

/**
 * Timer 1 detik per pemain untuk membatasi waktu autentikasi maksimal 60 detik.
 */
ptask Account_LoginTimeoutTask[1000](playerid)
{
    if (!IsPlayerConnected(playerid) || IsPlayerNPC(playerid))
    {
        return;
    }

    if (PlayerData[playerid][pAuthState] != AUTH_STATE_NONE && PlayerData[playerid][pAuthState] < AUTH_STATE_AUTHENTICATED)
    {
        PlayerData[playerid][pLoginTimer]++;
        if (PlayerData[playerid][pLoginTimer] >= ACCOUNT_LOGIN_TIMEOUT_SEC)
        {
            new logMsg[160];
            format(logMsg, sizeof(logMsg), "Kick otomatis (login timeout %d detik) pada akun %s", ACCOUNT_LOGIN_TIMEOUT_SEC, PlayerData[playerid][pUsername]);
            Account_LogAuthEvent(logMsg, PlayerData[playerid][pCurrentIP]);

            SendClientMessage(playerid, COLOR_ERROR, "Waktu autentikasi habis (60 detik). Anda dikeluarkan dari server.");
            DelayedKick(playerid, 500);
        }
    }
}
