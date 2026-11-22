/**
 * File: gamemodes/modules/character/select.inc
 * Modul: Character Selection, Loading & Deletion
 * Deskripsi: Menampilkan daftar maksimal 3 karakter milik akun, memuat data lengkap
 *            karakter terpilih ke memori, serta menghapus karakter dengan konfirmasi
 *            password bcrypt.
 * Dependensi: <open.mp>, <a_mysql>, <samp_bcrypt>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/account/security.inc
 */

#if defined _INC_CHARACTER_SELECT
    #endinput
#endif
#define _INC_CHARACTER_SELECT

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA KARAKTER
// ============================================================================
#if !defined MAX_CHARACTERS_PER_ACCOUNT
    #define MAX_CHARACTERS_PER_ACCOUNT  (3)
#endif

// Forward deklarasi lintas sub-modul karakter
forward Character_StartCreation(playerid);
forward Character_OnLoaded(playerid);

// ============================================================================
// FUNGSI PUBLIK MODUL (CHARACTER_*)
// ============================================================================

/**
 * Mengambil daftar karakter milik akun dari tabel `characters` dan membuka dialog pilih.
 */
public Character_ShowSelection(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    if (!Database_IsConnected())
    {
        SendClientMessage(playerid, COLOR_ERROR, "[Server] Koneksi database terputus.");
        DelayedKick(playerid, 500);
        return 0;
    }

    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_SELECT;
    PlayerData[playerid][pSelectedSlotIndex] = -1;

    for (new i = 0; i < MAX_CHARACTERS_PER_ACCOUNT; i++)
    {
        PlayerData[playerid][pCharSlotIDs][i] = 0;
        PlayerData[playerid][pCharSlotNames][i][0] = EOS;
    }

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[384];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT `id`, `name`, `level`, `money`, `bank_money`, `playing_hours`, `jail_time` \
         FROM `characters` WHERE `account_id` = %d ORDER BY `id` ASC LIMIT %d",
        PlayerData[playerid][pAccountID],
        MAX_CHARACTERS_PER_ACCOUNT
    );
    mysql_tquery(g_SQL, query, "OnCharacterListLoaded", "ii", playerid, racecheck);
    return 1;
}

/**
 * Memuat seluruh data kolom karakter terpilih dari tabel `characters`.
 */
stock Character_LoadByID(playerid, characterId)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[896];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT `id`, `name`, `gender`, `age`, `origin`, `skin`, \
                `pos_x`, `pos_y`, `pos_z`, `pos_a`, `interior`, `virtual_world`, \
                `health`, `armour`, `money`, `bank_money`, COALESCE(`bank_account_no`, '') AS `bank_no`, \
                `level`, `exp`, `playing_hours`, `paycheck_minutes`, `job_id`, `job_contract_hours`, \
                COALESCE(`faction_id`, 0) AS `faction_id`, `faction_rank`, \
                COALESCE(`phone_number`, '') AS `phone_number`, `hunger`, `thirst`, `stress`, \
                `injured`, `injured_time`, `jail_time`, `jail_type`, `wanted_level`, \
                COALESCE(`wanted_reason`, '') AS `wanted_reason`, \
                `lic_driving`, `lic_weapon`, `lic_flying`, `lic_boat`, \
                `spawn_point`, COALESCE(`spawn_house_id`, 0) AS `spawn_house_id`, \
                COALESCE(`accent`, '') AS `accent`, COALESCE(`description`, '') AS `description`, \
                `tutorial_done` \
         FROM `characters` WHERE `id` = %d AND `account_id` = %d LIMIT 1",
        characterId,
        PlayerData[playerid][pAccountID]
    );
    mysql_tquery(g_SQL, query, "OnCharacterDataLoaded", "ii", playerid, racecheck);
    return 1;
}

// ============================================================================
// CALLBACKS MYSQL SELEKSI & PEMUATAN KARAKTER
// ============================================================================
forward OnCharacterListLoaded(playerid, racecheck);
public OnCharacterListLoaded(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    new
        rows = cache_num_rows(),
        dialogBody[768],
        line[192],
        charId,
        charName[MAX_PLAYER_NAME],
        level,
        money,
        bankMoney,
        hours,
        jailTime,
        moneyStr[32],
        bankStr[32];

    format(dialogBody, sizeof(dialogBody), "Slot / Nama Karakter\tLevel & Jam Main\tTotal Kekayaan\n");

    for (new i = 0; i < MAX_CHARACTERS_PER_ACCOUNT; i++)
    {
        if (i < rows)
        {
            cache_get_value_name_int(i, "id", charId);
            cache_get_value_name(i, "name", charName, sizeof(charName));
            cache_get_value_name_int(i, "level", level);
            cache_get_value_name_int(i, "money", money);
            cache_get_value_name_int(i, "bank_money", bankMoney);
            cache_get_value_name_int(i, "playing_hours", hours);
            cache_get_value_name_int(i, "jail_time", jailTime);

            PlayerData[playerid][pCharSlotIDs][i] = charId;
            format(PlayerData[playerid][pCharSlotNames][i], MAX_PLAYER_NAME, "%s", charName);

            FormatMoney(money, moneyStr, sizeof(moneyStr));
            FormatMoney(bankMoney, bankStr, sizeof(bankStr));

            if (jailTime > 0)
            {
                format(
                    line,
                    sizeof(line),
                    "{00D4FF}%d. %s {FF4D4D}[PENJARA]\t{FFFFFF}Lv.%d (%d jam)\t{2EC4B6}%s {B0B8C1}(Bank: %s)\n",
                    i + 1,
                    charName,
                    level,
                    hours,
                    moneyStr,
                    bankStr
                );
            }
            else
            {
                format(
                    line,
                    sizeof(line),
                    "{00D4FF}%d. %s\t{FFFFFF}Lv.%d (%d jam)\t{2EC4B6}%s {B0B8C1}(Bank: %s)\n",
                    i + 1,
                    charName,
                    level,
                    hours,
                    moneyStr,
                    bankStr
                );
            }
            strcat(dialogBody, line);
        }
        else
        {
            PlayerData[playerid][pCharSlotIDs][i] = 0;
            PlayerData[playerid][pCharSlotNames][i][0] = EOS;

            format(line, sizeof(line), "{FFD166}%d. [+ Buat Karakter Baru]\t{B0B8C1}Slot Kosong\t{B0B8C1}-\n", i + 1);
            strcat(dialogBody, line);
        }
    }

    new title[96];
    format(title, sizeof(title), "{00D4FF}Pilih Karakter - Akun %s", PlayerData[playerid][pUsername]);
    ShowPlayerDialog(playerid, DIALOG_CHAR_SELECT, DIALOG_STYLE_TABLIST_HEADERS, title, dialogBody, "Pilih", "Keluar");
    return 1;
}

forward OnCharacterDataLoaded(playerid, racecheck);
public OnCharacterDataLoaded(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (cache_num_rows() == 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Gagal memuat data karakter. Silakan pilih kembali.");
        Character_ShowSelection(playerid);
        return 1;
    }

    Variables_ResetCharacterData(playerid);

    new
        injuredFlag,
        licDrv,
        licWep,
        licFly,
        licBoat,
        tutDone,
        query[160];

    cache_get_value_name_int(0, "id", PlayerData[playerid][pCharacterID]);
    cache_get_value_name(0, "name", PlayerData[playerid][pCharName], MAX_PLAYER_NAME);
    cache_get_value_name_int(0, "gender", PlayerData[playerid][pGender]);
    cache_get_value_name_int(0, "age", PlayerData[playerid][pAge]);
    cache_get_value_name(0, "origin", PlayerData[playerid][pOrigin], 48);
    cache_get_value_name_int(0, "skin", PlayerData[playerid][pSkin]);

    cache_get_value_name_float(0, "pos_x", PlayerData[playerid][pPosX]);
    cache_get_value_name_float(0, "pos_y", PlayerData[playerid][pPosY]);
    cache_get_value_name_float(0, "pos_z", PlayerData[playerid][pPosZ]);
    cache_get_value_name_float(0, "pos_a", PlayerData[playerid][pPosA]);
    cache_get_value_name_int(0, "interior", PlayerData[playerid][pInterior]);
    cache_get_value_name_int(0, "virtual_world", PlayerData[playerid][pVirtualWorld]);

    cache_get_value_name_float(0, "health", PlayerData[playerid][pHealth]);
    cache_get_value_name_float(0, "armour", PlayerData[playerid][pArmour]);
    cache_get_value_name_int(0, "money", PlayerData[playerid][pMoney]);
    cache_get_value_name_int(0, "bank_money", PlayerData[playerid][pBankMoney]);
    cache_get_value_name(0, "bank_no", PlayerData[playerid][pBankAccountNo], 16);

    cache_get_value_name_int(0, "level", PlayerData[playerid][pLevel]);
    cache_get_value_name_int(0, "exp", PlayerData[playerid][pExp]);
    cache_get_value_name_int(0, "playing_hours", PlayerData[playerid][pPlayingHours]);
    cache_get_value_name_int(0, "paycheck_minutes", PlayerData[playerid][pPaycheckMinutes]);
    cache_get_value_name_int(0, "job_id", PlayerData[playerid][pJobID]);
    cache_get_value_name_int(0, "job_contract_hours", PlayerData[playerid][pJobContractHours]);
    cache_get_value_name_int(0, "faction_id", PlayerData[playerid][pFactionID]);
    cache_get_value_name_int(0, "faction_rank", PlayerData[playerid][pFactionRank]);

    cache_get_value_name(0, "phone_number", PlayerData[playerid][pPhoneNumber], 16);
    cache_get_value_name_float(0, "hunger", PlayerData[playerid][pHunger]);
    cache_get_value_name_float(0, "thirst", PlayerData[playerid][pThirst]);
    cache_get_value_name_float(0, "stress", PlayerData[playerid][pStress]);

    cache_get_value_name_int(0, "injured", injuredFlag);
    cache_get_value_name_int(0, "injured_time", PlayerData[playerid][pInjuredTime]);
    cache_get_value_name_int(0, "jail_time", PlayerData[playerid][pJailTime]);
    cache_get_value_name_int(0, "jail_type", PlayerData[playerid][pJailType]);
    cache_get_value_name_int(0, "wanted_level", PlayerData[playerid][pWantedLevel]);
    cache_get_value_name(0, "wanted_reason", PlayerData[playerid][pWantedReason], 128);

    cache_get_value_name_int(0, "lic_driving", licDrv);
    cache_get_value_name_int(0, "lic_weapon", licWep);
    cache_get_value_name_int(0, "lic_flying", licFly);
    cache_get_value_name_int(0, "lic_boat", licBoat);
    cache_get_value_name_int(0, "spawn_point", PlayerData[playerid][pSpawnPoint]);
    cache_get_value_name_int(0, "spawn_house_id", PlayerData[playerid][pSpawnHouseID]);
    cache_get_value_name(0, "accent", PlayerData[playerid][pAccent], 32);
    cache_get_value_name(0, "description", PlayerData[playerid][pDescription], 160);
    cache_get_value_name_int(0, "tutorial_done", tutDone);

    PlayerData[playerid][pInjured] = (injuredFlag == 1);
    PlayerData[playerid][pLicDriving] = (licDrv == 1);
    PlayerData[playerid][pLicWeapon] = (licWep == 1);
    PlayerData[playerid][pLicFlying] = (licFly == 1);
    PlayerData[playerid][pLicBoat] = (licBoat == 1);
    PlayerData[playerid][pTutorialDone] = (tutDone == 1);
    PlayerData[playerid][pCharacterLoaded] = true;

    // Sinkronkan nama in-game pemain dengan nama karakter aktif
    SetPlayerName(playerid, PlayerData[playerid][pCharName]);

    mysql_format(g_SQL, query, sizeof(query), "UPDATE `characters` SET `last_played` = NOW() WHERE `id` = %d", PlayerData[playerid][pCharacterID]);
    mysql_tquery(g_SQL, query);

    Character_OnLoaded(playerid);
    return 1;
}

// ============================================================================
// HOOK DIALOG RESPONSE SELEKSI & HAPUS KARAKTER
// ============================================================================
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_CHAR_SELECT:
        {
            if (!response || !PlayerData[playerid][pAccountLoaded])
            {
                SendClientMessage(playerid, COLOR_WARNING, "Anda keluar dari server pada layar pemilihan karakter.");
                DelayedKick(playerid, 500);
                return 1;
            }

            if (listitem < 0 || listitem >= MAX_CHARACTERS_PER_ACCOUNT)
            {
                Character_ShowSelection(playerid);
                return 1;
            }

            PlayerData[playerid][pSelectedSlotIndex] = listitem;

            if (PlayerData[playerid][pCharSlotIDs][listitem] == 0)
            {
                // Slot kosong -> mulai pembuatan karakter baru
                Character_StartCreation(playerid);
                return 1;
            }

            // Slot berisi karakter -> tampilkan opsi Mainkan atau Hapus
            new
                title[64],
                body[256];

            format(title, sizeof(title), "{00D4FF}Karakter: %s", PlayerData[playerid][pCharSlotNames][listitem]);
            format(
                body,
                sizeof(body),
                "{2EC4B6}Mainkan Karakter Ini\n\
                {FF4D4D}Hapus Karakter Permanen\n\
                {B0B8C1}Kembali ke Daftar Karakter"
            );
            ShowPlayerDialog(playerid, DIALOG_CHAR_ACTION, DIALOG_STYLE_LIST, title, body, "Pilih", "Batal");
            return 1;
        }

        case DIALOG_CHAR_ACTION:
        {
            new slot = PlayerData[playerid][pSelectedSlotIndex];
            if (!response || slot < 0 || slot >= MAX_CHARACTERS_PER_ACCOUNT || PlayerData[playerid][pCharSlotIDs][slot] == 0)
            {
                Character_ShowSelection(playerid);
                return 1;
            }

            switch (listitem)
            {
                case 0: // Mainkan Karakter
                {
                    SendClientMessage(playerid, COLOR_INFO, "Memuat data karakter Anda, mohon tunggu...");
                    Character_LoadByID(playerid, PlayerData[playerid][pCharSlotIDs][slot]);
                }
                case 1: // Hapus Karakter
                {
                    new prompt[320];
                    format(
                        prompt,
                        sizeof(prompt),
                        "{FF4D4D}PERINGATAN: Penghapusan karakter bersifat PERMANEN!\n\
                        {FFFFFF}Semua aset, uang, kendaraan, dan properti milik {FFD166}%s {FFFFFF}akan terhapus.\n\n\
                        Masukkan password akun Anda untuk mengonfirmasi penghapusan:",
                        PlayerData[playerid][pCharSlotNames][slot]
                    );
                    ShowPlayerDialog(playerid, DIALOG_CHAR_DELETE_PASS, DIALOG_STYLE_PASSWORD, "{FF4D4D}Konfirmasi Hapus Karakter", prompt, "Hapus", "Batal");
                }
                default:
                {
                    Character_ShowSelection(playerid);
                }
            }
            return 1;
        }

        case DIALOG_CHAR_DELETE_PASS:
        {
            new slot = PlayerData[playerid][pSelectedSlotIndex];
            if (!response || slot < 0 || slot >= MAX_CHARACTERS_PER_ACCOUNT || PlayerData[playerid][pCharSlotIDs][slot] == 0)
            {
                Character_ShowSelection(playerid);
                return 1;
            }

            if (strlen(inputtext) == 0)
            {
                SendClientMessage(playerid, COLOR_ERROR, "Password tidak boleh kosong!");
                Character_ShowSelection(playerid);
                return 1;
            }

            new racecheck = Database_GetPlayerRaceCheck(playerid);
            SendClientMessage(playerid, COLOR_INFO, "Memverifikasi password untuk menghapus karakter...");
            bcrypt_verify(playerid, "OnCharacterDeletePassVerified", inputtext, PlayerData[playerid][pPasswordHash], "ii", racecheck, slot);
            return 1;
        }
    }
    return 0;
}

forward OnCharacterDeletePassVerified(playerid, bool:success, racecheck, slot);
public OnCharacterDeletePassVerified(playerid, bool:success, racecheck, slot)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    if (!success)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Password salah! Penghapusan karakter dibatalkan.");
        Character_ShowSelection(playerid);
        return 1;
    }

    if (slot < 0 || slot >= MAX_CHARACTERS_PER_ACCOUNT || PlayerData[playerid][pCharSlotIDs][slot] == 0)
    {
        Character_ShowSelection(playerid);
        return 1;
    }

    new
        charId = PlayerData[playerid][pCharSlotIDs][slot],
        query[256],
        logMsg[192];

    format(
        logMsg,
        sizeof(logMsg),
        "Karakter dihapus: %s (CharID: #%d) oleh akun %s (#%d)",
        PlayerData[playerid][pCharSlotNames][slot],
        charId,
        PlayerData[playerid][pUsername],
        PlayerData[playerid][pAccountID]
    );
    Account_LogAuthEvent(logMsg, PlayerData[playerid][pCurrentIP]);

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "DELETE FROM `characters` WHERE `id` = %d AND `account_id` = %d LIMIT 1",
        charId,
        PlayerData[playerid][pAccountID]
    );
    mysql_tquery(g_SQL, query, "OnCharacterDeleted", "ii", playerid, racecheck);
    return 1;
}

forward OnCharacterDeleted(playerid, racecheck);
public OnCharacterDeleted(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    SendClientMessage(playerid, COLOR_SUCCESS, "Karakter berhasil dihapus secara permanen.");
    Character_ShowSelection(playerid);
    return 1;
}
