// =============================================================================
// File: gamemodes/modules/character/character_delete.inc
// Fungsi: Sistem penghapusan karakter permanen dengan verifikasi keamanan
//         password akun (Bcrypt).
// Dependensi: <open.mp>, <a_mysql>, <samp_bcrypt>, core/config.inc,
//             core/colors.inc, core/utils.inc, core/enums.inc,
//             core/variables.inc, core/database.inc
// =============================================================================

#if defined _INC_CHAR_DELETE
    #endinput
#endif
#define _INC_CHAR_DELETE

// Forward deklarasi lintas modul
forward Character_ShowSelectionMenu(playerid);

// Array sementara penampung list ID karakter untuk dihapus
static s_DeleteCharListID[MAX_PLAYERS][MAX_CHARACTERS_PER_ACCOUNT];
static s_DeleteCharListCount[MAX_PLAYERS];

// -----------------------------------------------------------------------------
// Menampilkan Daftar Karakter yang Dapat Dihapus
// -----------------------------------------------------------------------------
stock Character_ShowDeleteMenu(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    new racecheck = Database_GetRaceCheck(playerid);
    new query[256];
    mysql_format(
        g_DB,
        query,
        sizeof(query),
        "SELECT `id`, `name`, `level` FROM `characters` WHERE `account_id` = %d ORDER BY `id` ASC",
        PlayerData[playerid][pAccountID]
    );

    mysql_tquery(g_DB, query, "OnCharacterDeleteListLoaded", "ii", playerid, racecheck);
    return 1;
}

// -----------------------------------------------------------------------------
// Callback Pemuatan Karakter untuk Menu Hapus
// -----------------------------------------------------------------------------
forward OnCharacterDeleteListLoaded(playerid, racecheck);
public OnCharacterDeleteListLoaded(playerid, racecheck)
{
    if (!Database_IsRaceCheckValid(playerid, racecheck))
    {
        return 0;
    }

    new rows;
    cache_get_row_count(rows);
    s_DeleteCharListCount[playerid] = rows;

    if (rows == 0)
    {
        SendErrorMessage(playerid, "Anda tidak memiliki karakter untuk dihapus!");
        Character_ShowSelectionMenu(playerid);
        return 0;
    }

    new list[384];
    for (new i = 0; i < rows; i++)
    {
        new cid, cname[MAX_PLAYER_NAME], clevel;
        cache_get_value_name_int(i, "id", cid);
        cache_get_value_name(i, "name", cname, sizeof(cname));
        cache_get_value_name_int(i, "level", clevel);

        s_DeleteCharListID[playerid][i] = cid;

        if (i == 0)
        {
            format(list, sizeof(list), "{FFFFFF}%s (Level %d)", cname, clevel);
        }
        else
        {
            format(list, sizeof(list), "%s\n{FFFFFF}%s (Level %d)", list, cname, clevel);
        }
    }

    ShowPlayerDialog(playerid, DIALOG_CHAR_DELETE_SELECT, DIALOG_STYLE_LIST, "{FF0000}Pilih Karakter yang Ingin Dihapus", list, "Lanjut", "Batal");
    return 1;
}

// -----------------------------------------------------------------------------
// Callback Hasil Verifikasi Password Penghapusan Karakter (Bcrypt)
// -----------------------------------------------------------------------------
forward OnCharacterDeleteVerified(playerid, bool:success);
public OnCharacterDeleteVerified(playerid, bool:success)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    if (!success)
    {
        SendErrorMessage(playerid, "Password akun yang Anda masukkan salah! Penghapusan karakter dibatalkan demi keamanan.");
        Character_ShowSelectionMenu(playerid);
        return 1;
    }

    // Password benar, eksekusi query hapus karakter secara aman
    new targetCharId = PlayerData[playerid][pDeleteCharID];
    new query[256];
    mysql_format(
        g_DB,
        query,
        sizeof(query),
        "DELETE FROM `characters` WHERE `id` = %d AND `account_id` = %d",
        targetCharId,
        PlayerData[playerid][pAccountID]
    );
    mysql_tquery(g_DB, query);

    new msg[160];
    format(msg, sizeof(msg), "Karakter %s (#%d) berhasil dihapus secara permanen dari akun Anda.", PlayerData[playerid][pDeleteCharName], targetCharId);
    SendSuccessMessage(playerid, msg);

    // Catat log penghapusan
    new logMsg[192];
    format(logMsg, sizeof(logMsg), "Penghapusan karakter: %s (#%d) pada akun #%d", PlayerData[playerid][pDeleteCharName], targetCharId, PlayerData[playerid][pAccountID]);
    new curIp[46];
    GetPlayerIp(playerid, curIp, sizeof(curIp));
    new qlog[320];
    mysql_format(g_DB, qlog, sizeof(qlog), "INSERT INTO `logs` (`type`, `char_id`, `message`, `ip`) VALUES ('character', %d, '%e', '%e')", targetCharId, logMsg, curIp);
    mysql_tquery(g_DB, qlog);

    // Reset variabel penampung
    PlayerData[playerid][pDeleteCharID] = 0;
    PlayerData[playerid][pDeleteCharName][0] = '\0';

    // Tampilkan kembali menu pilihan karakter
    Character_ShowSelectionMenu(playerid);
    return 1;
}

// -----------------------------------------------------------------------------
// Respon Dialog Penghapusan Karakter
// -----------------------------------------------------------------------------
stock Character_OnDeleteDialogResponse(playerid, dialogid, response, listitem, const inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_CHAR_DELETE_SELECT:
        {
            if (!response)
            {
                Character_ShowSelectionMenu(playerid);
                return 1;
            }

            if (listitem >= 0 && listitem < s_DeleteCharListCount[playerid])
            {
                new selectedCharID = s_DeleteCharListID[playerid][listitem];
                PlayerData[playerid][pDeleteCharID] = selectedCharID;

                new prompt[512];
                format(
                    prompt,
                    sizeof(prompt),
                    "{FF0000}PERINGATAN KESELAMATAN DATA!\n\n\
                    {FFFFFF}Anda akan menghapus karakter ID: {FFFF00}#%d{FFFFFF}.\n\
                    Seluruh progres level, uang, kendaraan, dan kepemilikan karakter ini\n\
                    akan {FF0000}DIHAPUS PERMANEN{FFFFFF} dan tidak dapat dikembalikan!\n\n\
                    Untuk melanjutkan, masukkan {FFFF00}Password Akun{FFFFFF} Anda sebagai konfirmasi:",
                    selectedCharID
                );

                ShowPlayerDialog(playerid, DIALOG_CHAR_DELETE_CONFIRM, DIALOG_STYLE_PASSWORD, "{FF0000}Konfirmasi Hapus Karakter", prompt, "Hapus!", "Batal");
            }
            return 1;
        }

        case DIALOG_CHAR_DELETE_CONFIRM:
        {
            if (!response)
            {
                Character_ShowSelectionMenu(playerid);
                return 1;
            }

            if (strlen(inputtext) == 0)
            {
                SendErrorMessage(playerid, "Password konfirmasi tidak boleh kosong!");
                Character_ShowSelectionMenu(playerid);
                return 1;
            }

            SendInfoMessage(playerid, "Memverifikasi password akun Anda...");
            bcrypt_verify(playerid, "OnCharacterDeleteVerified", inputtext, PlayerData[playerid][pPasswordHash]);
            return 1;
        }
    }
    return 0;
}
