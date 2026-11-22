// =============================================================================
// File: gamemodes/modules/account/account.inc
// Fungsi: Induk modul sistem akun (Keamanan, Registrasi, Login & Pengaturan).
// Dependensi: <open.mp>, <a_mysql>, <samp_bcrypt>, sub-modul account/*
// =============================================================================

#if defined _INC_MODULE_ACCOUNT
    #endinput
#endif
#define _INC_MODULE_ACCOUNT

// Forward deklarasi dari modul karakter
forward Character_ShowSelectionMenu(playerid);

// -----------------------------------------------------------------------------
// Menangani Sukses Autentikasi Akun -> Membuka Menu Pemilihan Karakter
// -----------------------------------------------------------------------------
stock Account_OnAuthenticated(playerid, accountId)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    PlayerData[playerid][pAccountID] = accountId;
    PlayerData[playerid][pAuthState] = AUTH_STATE_AUTHENTICATED;
    PlayerData[playerid][pLoginAttempts] = 0;

    new racecheck = Database_GetRaceCheck(playerid);
    new query[512];
    mysql_format(
        g_DB,
        query,
        sizeof(query),
        "SELECT COALESCE(`email`, '') AS `email`, `register_ip`, `admin_level`, `helper_level`, \
                `vip_level`, COALESCE(DATE_FORMAT(`vip_expire`, '%%d/%%m/%%Y %%H:%%i'), '-') AS `vip_expire_str`, \
                `language` \
         FROM `accounts` WHERE `id` = %d LIMIT 1",
        accountId
    );
    mysql_tquery(g_DB, query, "OnAccountProfileLoaded", "ii", playerid, racecheck);

    // Update timestamp login terakhir dan IP
    new curIp[46];
    GetPlayerIp(playerid, curIp, sizeof(curIp));
    mysql_format(
        g_DB,
        query,
        sizeof(query),
        "UPDATE `accounts` SET `login_attempts` = 0, `last_ip` = '%e', `last_login` = NOW() WHERE `id` = %d",
        curIp,
        accountId
    );
    mysql_tquery(g_DB, query);
    return 1;
}

forward OnAccountProfileLoaded(playerid, racecheck);
public OnAccountProfileLoaded(playerid, racecheck)
{
    if (!Database_IsRaceCheckValid(playerid, racecheck))
    {
        return 0;
    }

    new rows;
    cache_get_row_count(rows);
    if (rows == 0)
    {
        SendErrorMessage(playerid, "Terjadi kesalahan saat memuat data profil akun.");
        Kick(playerid);
        return 0;
    }

    cache_get_value_name(0, "email", PlayerData[playerid][pEmail], 128);
    cache_get_value_name(0, "register_ip", PlayerData[playerid][pRegisterIP], 46);
    cache_get_value_name_int(0, "admin_level", PlayerData[playerid][pAdminLevel]);
    cache_get_value_name_int(0, "helper_level", PlayerData[playerid][pHelperLevel]);
    cache_get_value_name_int(0, "vip_level", PlayerData[playerid][pVIPLevel]);
    cache_get_value_name(0, "vip_expire_str", PlayerData[playerid][pVIPExpire], 32);
    cache_get_value_name(0, "language", PlayerData[playerid][pLanguage], 8);

    PlayerData[playerid][pAccountLoaded] = true;

    new welcomeMsg[192];
    format(
        welcomeMsg,
        sizeof(welcomeMsg),
        "Autentikasi berhasil! Akun: %s (ID: #%d). Login terakhir dari IP %s.",
        PlayerData[playerid][pUsername],
        PlayerData[playerid][pAccountID],
        PlayerData[playerid][pLastIP]
    );
    SendSuccessMessage(playerid, welcomeMsg);

    if (PlayerData[playerid][pAdminLevel] > 0 || PlayerData[playerid][pHelperLevel] > 0)
    {
        format(welcomeMsg, sizeof(welcomeMsg), "[STAFF] Terdeteksi hak akses Helper Level %d | Admin Level %d.", PlayerData[playerid][pHelperLevel], PlayerData[playerid][pAdminLevel]);
        SendInfoMessage(playerid, welcomeMsg);
    }

    // Arahkan pemain ke sistem pemilihan karakter (Tahap 4)
    Character_ShowSelectionMenu(playerid);
    return 1;
}

// Sub-modul akun
#include "modules/account/security.inc"
#include "modules/account/register.inc"
#include "modules/account/login.inc"
#include "modules/account/settings.inc"

// -----------------------------------------------------------------------------
// Router Terpusat Respon Dialog Modul Akun (ID 100 - 199)
// -----------------------------------------------------------------------------
stock Account_OnDialogResponse(playerid, dialogid, response, listitem, const inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_REGISTER_PASS, DIALOG_REGISTER_CONFIRM, DIALOG_REGISTER_EMAIL:
        {
            return Account_OnRegisterDialogResponse(playerid, dialogid, response, inputtext);
        }
        case DIALOG_LOGIN:
        {
            return Account_OnLoginDialogResponse(playerid, response, inputtext);
        }
        case DIALOG_ACCOUNT_SETTINGS, DIALOG_CHANGE_LANGUAGE,
             DIALOG_CHANGE_PASS_OLD, DIALOG_CHANGE_PASS_NEW, DIALOG_CHANGE_PASS_CONFIRM:
        {
            return Account_OnSettingsDialogResponse(playerid, dialogid, response, listitem, inputtext);
        }
    }
    return 0;
}
