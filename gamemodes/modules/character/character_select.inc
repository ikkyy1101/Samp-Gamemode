// =============================================================================
// File: gamemodes/modules/character/character_select.inc
// Fungsi: Sistem pemilihan karakter akun, penentuan slot karakter (maks 3),
//         dan navigasi ke pembuatan / penghapusan karakter.
// Dependensi: <open.mp>, <a_mysql>, core/config.inc, core/colors.inc,
//             core/utils.inc, core/enums.inc, core/variables.inc, core/database.inc
// =============================================================================

#if defined _INC_CHAR_SELECT
    #endinput
#endif
#define _INC_CHAR_SELECT

// Array penampung ID karakter yang sedang ditampilkan di dialog per pemain
static s_CharSlotID[MAX_PLAYERS][MAX_CHARACTERS_PER_ACCOUNT];
static s_CharSlotCount[MAX_PLAYERS];

// Forward deklarasi lintas modul
forward Character_StartCreate(playerid);
forward Character_Load(playerid, charid);
forward Character_ShowDeleteMenu(playerid);

// -----------------------------------------------------------------------------
// Menampilkan Menu Dialog Pemilihan Karakter
// -----------------------------------------------------------------------------
stock Character_ShowSelectionMenu(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_SELECT;
    Variables_ResetCharacterData(playerid);

    // Pastikan pemain dalam mode kamera sinematik
    TogglePlayerSpectating(playerid, true);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, playerid + 100);

    new racecheck = Database_GetRaceCheck(playerid);
    new query[256];
    mysql_format(
        g_DB,
        query,
        sizeof(query),
        "SELECT `id`, `name`, `level`, `money`, `bank_money`, `playing_hours`, `skin` \
         FROM `characters` WHERE `account_id` = %d ORDER BY `id` ASC LIMIT %d",
        PlayerData[playerid][pAccountID],
        MAX_CHARACTERS_PER_ACCOUNT
    );
    mysql_tquery(g_DB, query, "OnCharacterListLoaded", "ii", playerid, racecheck);
    return 1;
}

// -----------------------------------------------------------------------------
// Callback Pemuatan Daftar Karakter dari Database
// -----------------------------------------------------------------------------
forward OnCharacterListLoaded(playerid, racecheck);
public OnCharacterListLoaded(playerid, racecheck)
{
    if (!Database_IsRaceCheckValid(playerid, racecheck))
    {
        return 0;
    }

    new rows;
    cache_get_row_count(rows);
    s_CharSlotCount[playerid] = rows;

    for (new i = 0; i < MAX_CHARACTERS_PER_ACCOUNT; i++)
    {
        s_CharSlotID[playerid][i] = 0;
    }

    // Jika belum memiliki karakter sama sekali, langsung arahkan ke pembuatan karakter pertama
    if (rows == 0)
    {
        SendInfoMessage(playerid, "Anda belum memiliki karakter. Silakan buat karakter pertama Anda!");
        Character_StartCreate(playerid);
        return 1;
    }

    new dialogBody[768];
    format(dialogBody, sizeof(dialogBody), "Slot / Nama Karakter\tLevel\tKekayaan Total\tJam Main\n");

    for (new i = 0; i < rows; i++)
    {
        new cid, cname[MAX_PLAYER_NAME], clevel, cmoney, cbank, chours, cskin;
        cache_get_value_name_int(i, "id", cid);
        cache_get_value_name(i, "name", cname, sizeof(cname));
        cache_get_value_name_int(i, "level", clevel);
        cache_get_value_name_int(i, "money", cmoney);
        cache_get_value_name_int(i, "bank_money", cbank);
        cache_get_value_name_int(i, "playing_hours", chours);
        cache_get_value_name_int(i, "skin", cskin);

        s_CharSlotID[playerid][i] = cid;

        new totalWealth = cmoney + cbank;
        format(
            dialogBody,
            sizeof(dialogBody),
            "%s{FFFFFF}%d. %s\t{FFFF00}Lvl %d\t{00FF00}%s\t{AFAFAF}%d Jam\n",
            dialogBody,
            i + 1,
            cname,
            clevel,
            FormatMoney(totalWealth),
            chours
        );
    }

    // Opsi Tambah Karakter Baru jika slot masih tersedia (< 3)
    if (rows < MAX_CHARACTERS_PER_ACCOUNT)
    {
        format(dialogBody, sizeof(dialogBody), "%s{00FF00}[+ Buat Karakter Baru (%d/%d Slot)]\t{AFAFAF}-\t{AFAFAF}-\t{AFAFAF}-\n", dialogBody, rows, MAX_CHARACTERS_PER_ACCOUNT);
    }

    // Opsi Hapus Karakter
    format(dialogBody, sizeof(dialogBody), "%s{FF0000}[- Hapus Karakter]\t{AFAFAF}-\t{AFAFAF}-\t{AFAFAF}-\n", dialogBody);

    new dialogTitle[64];
    format(dialogTitle, sizeof(dialogTitle), "{00AAFF}Pilih Karakter (%d/%d)", rows, MAX_CHARACTERS_PER_ACCOUNT);
    ShowPlayerDialog(playerid, DIALOG_CHAR_SELECT, DIALOG_STYLE_TABLIST_HEADERS, dialogTitle, dialogBody, "Pilih", "Keluar");
    return 1;
}

// -----------------------------------------------------------------------------
// Penanganan Respon Dialog Pemilihan Karakter
// -----------------------------------------------------------------------------
stock Character_OnSelectDialogResponse(playerid, response, listitem)
{
    if (!response)
    {
        SendInfoMessage(playerid, "Anda membatalkan pemilihan karakter dan keluar dari server.");
        Kick(playerid);
        return 1;
    }

    new rows = s_CharSlotCount[playerid];

    // Pemain memilih salah satu karakter yang sudah ada
    if (listitem < rows)
    {
        new selectedCharID = s_CharSlotID[playerid][listitem];
        if (selectedCharID > 0)
        {
            Character_Load(playerid, selectedCharID);
        }
        return 1;
    }

    // Pemain memilih opsi buat karakter baru (jika slot < 3)
    if (rows < MAX_CHARACTERS_PER_ACCOUNT && listitem == rows)
    {
        Character_StartCreate(playerid);
        return 1;
    }

    // Pemain memilih opsi hapus karakter
    new deleteIndex = (rows < MAX_CHARACTERS_PER_ACCOUNT) ? (rows + 1) : rows;
    if (listitem == deleteIndex)
    {
        Character_ShowDeleteMenu(playerid);
        return 1;
    }

    return 1;
}
