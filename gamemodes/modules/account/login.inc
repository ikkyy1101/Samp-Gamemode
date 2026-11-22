/**
 * File: gamemodes/modules/account/login.inc
 * Modul: Account Login & Session Loader
 * Deskripsi: Menangani dialog login, verifikasi bcrypt async, pembatasan 3 kali
 *            percobaan gagal, pemuatan profil akun, dan meneruskan pemain
 *            ke layar pemilihan karakter.
 * Dependensi: <open.mp>, <a_mysql>, <samp_bcrypt>, <YSI_Coding\y_hooks>,
 *             <YSI_Data\y_iterate>, core/colors.inc, core/utils.inc,
 *             core/database.inc, core/enums.inc, core/variables.inc,
 *             modules/account/security.inc
 */

#if defined _INC_ACCOUNT_LOGIN
    #endinput
#endif
#define _INC_ACCOUNT_LOGIN

#include <YSI_Coding\y_hooks>

// Forward menuju modul karakter (Tahap 4)
forward Character_ShowSelection(playerid);

// ============================================================================
// FUNGSI INTERNAL DIALOG LOGIN
// ============================================================================
static Account_ShowLoginDialog(playerid, const errorNotice[] = "")
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_LOGIN_PROMPT;

    new
        sisaPercobaan = ACCOUNT_MAX_LOGIN_ATTEMPTS - PlayerData[playerid][pLoginAttempts],
        dialogText[448];

    if (errorNotice[0] != EOS)
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FF4D4D}%s\n\n\
            {FFFFFF}Selamat datang kembali di {00D4FF}PARADISE Roleplay{FFFFFF}!\n\
            Akun: {FFD166}%s\n\
            {FFFFFF}Sisa percobaan: {FFD166}%d/%d\n\n\
            {FFFFFF}Masukkan password akun Anda:",
            errorNotice,
            PlayerData[playerid][pUsername],
            sisaPercobaan,
            ACCOUNT_MAX_LOGIN_ATTEMPTS
        );
    }
    else
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FFFFFF}Selamat datang kembali di {00D4FF}PARADISE Roleplay{FFFFFF}!\n\
            Akun: {FFD166}%s\n\
            {FFFFFF}Sisa percobaan: {FFD166}%d/%d\n\n\
            {FFFFFF}Masukkan password akun Anda:",
            PlayerData[playerid][pUsername],
            sisaPercobaan,
            ACCOUNT_MAX_LOGIN_ATTEMPTS
        );
    }

    ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{00D4FF}Login Akun - PARADISE Roleplay", dialogText, "Masuk", "Keluar");
    return 1;
}

// ============================================================================
// FUNGSI PUBLIK ENTRY LOGIN & AUTENTIKASI SUKSES
// ============================================================================
public Account_StartLogin(playerid, accountId, const passwordHash[], loginAttempts, const lastIp[], const lastLogin[])
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    PlayerData[playerid][pAccountID] = accountId;
    PlayerData[playerid][pLoginAttempts] = (loginAttempts >= ACCOUNT_MAX_LOGIN_ATTEMPTS) ? 0 : loginAttempts;
    format(PlayerData[playerid][pPasswordHash], 128, "%s", passwordHash);
    format(PlayerData[playerid][pLastIP], 46, "%s", lastIp);
    format(PlayerData[playerid][pLastLogin], 32, "%s", lastLogin);

    Account_ShowLoginDialog(playerid);
    return 1;
}

public Account_OnAuthenticated(playerid, accountId)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    PlayerData[playerid][pAccountID] = accountId;
    PlayerData[playerid][pAuthState] = AUTH_STATE_AUTHENTICATED;
    PlayerData[playerid][pLoginAttempts] = 0;

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[512];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT COALESCE(`email`, '') AS `email`, `register_ip`, `admin_level`, `helper_level`, \
                `vip_level`, COALESCE(DATE_FORMAT(`vip_expire`, '%%d/%%m/%%Y %%H:%%i'), '-') AS `vip_expire_str`, \
                `language`, `tog_pm`, `tog_ooc`, `tog_hud` \
         FROM `accounts` WHERE `id` = %d LIMIT 1",
        accountId
    );
    mysql_tquery(g_SQL, query, "OnAccountProfileLoaded", "ii", playerid, racecheck);

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "UPDATE `accounts` SET `login_attempts` = 0, `last_ip` = '%e', `gpci` = '%e', `last_login` = NOW() WHERE `id` = %d",
        PlayerData[playerid][pCurrentIP],
        PlayerData[playerid][pGPCI],
        accountId
    );
    mysql_tquery(g_SQL, query);
    return 1;
}

// ============================================================================
// HOOK DIALOG RESPONSE LOGIN
// ============================================================================
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused listitem

    if (dialogid == DIALOG_LOGIN)
    {
        if (!response)
        {
            SendClientMessage(playerid, COLOR_WARNING, "Anda keluar dari layar login.");
            DelayedKick(playerid, 500);
            return 1;
        }

        if (strlen(inputtext) == 0)
        {
            Account_ShowLoginDialog(playerid, "Password tidak boleh kosong!");
            return 1;
        }

        PlayerData[playerid][pAuthState] = AUTH_STATE_VERIFYING;
        SendClientMessage(playerid, COLOR_INFO, "Memverifikasi kredensial akun...");

        bcrypt_verify(playerid, "OnAccountPasswordVerified", inputtext, PlayerData[playerid][pPasswordHash]);
        return 1;
    }
    return 0;
}

// ============================================================================
// CALLBACKS BCRYPT & PEMUATAN PROFIL AKUN
// ============================================================================
forward OnAccountPasswordVerified(playerid, bool:success);
public OnAccountPasswordVerified(playerid, bool:success)
{
    if (!IsPlayerConnected(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_VERIFYING)
    {
        return 0;
    }

    if (!success)
    {
        PlayerData[playerid][pLoginAttempts]++;

        new query[160];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "UPDATE `accounts` SET `login_attempts` = %d WHERE `id` = %d",
            PlayerData[playerid][pLoginAttempts],
            PlayerData[playerid][pAccountID]
        );
        mysql_tquery(g_SQL, query);

        if (PlayerData[playerid][pLoginAttempts] >= ACCOUNT_MAX_LOGIN_ATTEMPTS)
        {
            new logMsg[192];
            format(
                logMsg,
                sizeof(logMsg),
                "Kick otomatis: %dx gagal login pada akun %s (ID: #%d)",
                ACCOUNT_MAX_LOGIN_ATTEMPTS,
                PlayerData[playerid][pUsername],
                PlayerData[playerid][pAccountID]
            );
            Account_LogAuthEvent(logMsg, PlayerData[playerid][pCurrentIP]);

            SendClientMessage(playerid, COLOR_ERROR, "Anda telah salah memasukkan password sebanyak 3 kali!");
            DelayedKick(playerid, 500);
            return 1;
        }

        Account_ShowLoginDialog(playerid, "Password yang Anda masukkan salah!");
        return 1;
    }

    new logMsg[160];
    format(logMsg, sizeof(logMsg), "Login berhasil: %s (AccountID: #%d)", PlayerData[playerid][pUsername], PlayerData[playerid][pAccountID]);
    Account_LogAuthEvent(logMsg, PlayerData[playerid][pCurrentIP]);

    Account_OnAuthenticated(playerid, PlayerData[playerid][pAccountID]);
    return 1;
}

forward OnAccountProfileLoaded(playerid, racecheck);
public OnAccountProfileLoaded(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (cache_num_rows() == 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Terjadi kesalahan saat memuat data akun Anda.");
        DelayedKick(playerid, 500);
        return 1;
    }

    new
        togPm,
        togOoc,
        togHud,
        welcomeMsg[160];

    cache_get_value_name(0, "email", PlayerData[playerid][pEmail], 128);
    cache_get_value_name(0, "register_ip", PlayerData[playerid][pRegisterIP], 46);
    cache_get_value_name_int(0, "admin_level", PlayerData[playerid][pAdminLevel]);
    cache_get_value_name_int(0, "helper_level", PlayerData[playerid][pHelperLevel]);
    cache_get_value_name_int(0, "vip_level", PlayerData[playerid][pVIPLevel]);
    cache_get_value_name(0, "vip_expire_str", PlayerData[playerid][pVIPExpire], 32);
    cache_get_value_name(0, "language", PlayerData[playerid][pLanguage], 8);
    cache_get_value_name_int(0, "tog_pm", togPm);
    cache_get_value_name_int(0, "tog_ooc", togOoc);
    cache_get_value_name_int(0, "tog_hud", togHud);

    PlayerData[playerid][pTogPM] = (togPm == 1);
    PlayerData[playerid][pTogOOC] = (togOoc == 1);
    PlayerData[playerid][pTogHUD] = (togHud == 1);
    PlayerData[playerid][pAccountLoaded] = true;

    Iter_Add(LoggedInPlayers, playerid);

    format(
        welcomeMsg,
        sizeof(welcomeMsg),
        "Berhasil masuk ke akun %s (#%d). Login terakhir dari IP %s pada %s.",
        PlayerData[playerid][pUsername],
        PlayerData[playerid][pAccountID],
        PlayerData[playerid][pLastIP],
        PlayerData[playerid][pLastLogin]
    );
    SendClientMessage(playerid, COLOR_SUCCESS, "%s", welcomeMsg);

    if (PlayerData[playerid][pAdminLevel] > 0 || PlayerData[playerid][pHelperLevel] > 0)
    {
        format(
            welcomeMsg,
            sizeof(welcomeMsg),
            "[Staff] Anda login dengan akses Helper Level %d | Admin Level %d.",
            PlayerData[playerid][pHelperLevel],
            PlayerData[playerid][pAdminLevel]
        );
        SendClientMessage(playerid, COLOR_INFO, "%s", welcomeMsg);
    }

    // Lanjutkan ke layar pemilihan karakter (Tahap 4)
    Character_ShowSelection(playerid);
    return 1;
}
