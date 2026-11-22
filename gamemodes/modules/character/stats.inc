/**
 * File: gamemodes/modules/character/stats.inc
 * Modul: Character Persistence (Save/Load), Autosave & Profile Stats
 * Deskripsi: Menyimpan seluruh data karakter ke tabel `characters` secara aman
 *            (saat disconnect, autosave 5 menit, dan shutdown/GMX), serta menyediakan
 *            perintah /stats dan /gantikarakter (/switchchar).
 * Dependensi: <open.mp>, <a_mysql>, <Pawn.CMD>, <YSI_Coding\y_hooks>,
 *             <YSI_Data\y_iterate>, <YSI_Coding\y_timers>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/character/select.inc
 */

#if defined _INC_CHARACTER_STATS
    #endinput
#endif
#define _INC_CHARACTER_STATS

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA PERSISTENCE KARAKTER
// ============================================================================
#define CHAR_AUTOSAVE_INTERVAL_MS   (300000) // 5 menit

// ============================================================================
// FUNGSI PUBLIK MODUL (CHARACTER_*)
// ============================================================================

/**
 * Menyimpan seluruh progres dan posisi terkini karakter pemain ke database.
 */
stock Character_Save(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded] || PlayerData[playerid][pCharacterID] <= 0)
    {
        return 0;
    }

    if (!Database_IsConnected())
    {
        return 0;
    }

    // Perbarui koordinat & HP terkini hanya jika pemain sedang spawn aktif di dunia RP
    if (PlayerData[playerid][pAuthState] == AUTH_STATE_SPAWNED)
    {
        GetPlayerPos(playerid, PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ]);
        GetPlayerFacingAngle(playerid, PlayerData[playerid][pPosA]);
        PlayerData[playerid][pInterior] = GetPlayerInterior(playerid);
        PlayerData[playerid][pVirtualWorld] = GetPlayerVirtualWorld(playerid);
        GetPlayerHealth(playerid, PlayerData[playerid][pHealth]);
        GetPlayerArmour(playerid, PlayerData[playerid][pArmour]);
    }

    new query[1024];
    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "UPDATE `characters` SET \
            `skin` = %d, `pos_x` = %f, `pos_y` = %f, `pos_z` = %f, `pos_a` = %f, \
            `interior` = %d, `virtual_world` = %d, `health` = %f, `armour` = %f, \
            `money` = %d, `bank_money` = %d, `level` = %d, `exp` = %d, \
            `playing_hours` = %d, `paycheck_minutes` = %d, `job_id` = %d, `job_contract_hours` = %d, \
            `faction_id` = %s, `faction_rank` = %d, `hunger` = %f, `thirst` = %f, `stress` = %f, \
            `injured` = %d, `injured_time` = %d, `jail_time` = %d, `jail_type` = %d, \
            `wanted_level` = %d, `wanted_reason` = '%e', \
            `lic_driving` = %d, `lic_weapon` = %d, `lic_flying` = %d, `lic_boat` = %d, \
            `spawn_point` = %d, `accent` = '%e', `description` = '%e', `last_played` = NOW() \
         WHERE `id` = %d LIMIT 1",
        PlayerData[playerid][pSkin],
        PlayerData[playerid][pPosX],
        PlayerData[playerid][pPosY],
        PlayerData[playerid][pPosZ],
        PlayerData[playerid][pPosA],
        PlayerData[playerid][pInterior],
        PlayerData[playerid][pVirtualWorld],
        PlayerData[playerid][pHealth],
        PlayerData[playerid][pArmour],
        PlayerData[playerid][pMoney],
        PlayerData[playerid][pBankMoney],
        PlayerData[playerid][pLevel],
        PlayerData[playerid][pExp],
        PlayerData[playerid][pPlayingHours],
        PlayerData[playerid][pPaycheckMinutes],
        PlayerData[playerid][pJobID],
        PlayerData[playerid][pJobContractHours],
        (PlayerData[playerid][pFactionID] > 0) ? ("NULL") : ("NULL"), // Diperbarui lewat modul faksi pada Tahap 13
        PlayerData[playerid][pFactionRank],
        PlayerData[playerid][pHunger],
        PlayerData[playerid][pThirst],
        PlayerData[playerid][pStress],
        PlayerData[playerid][pInjured] ? 1 : 0,
        PlayerData[playerid][pInjuredTime],
        PlayerData[playerid][pJailTime],
        PlayerData[playerid][pJailType],
        PlayerData[playerid][pWantedLevel],
        PlayerData[playerid][pWantedReason],
        PlayerData[playerid][pLicDriving] ? 1 : 0,
        PlayerData[playerid][pLicWeapon] ? 1 : 0,
        PlayerData[playerid][pLicFlying] ? 1 : 0,
        PlayerData[playerid][pLicBoat] ? 1 : 0,
        PlayerData[playerid][pSpawnPoint],
        PlayerData[playerid][pAccent],
        PlayerData[playerid][pDescription],
        PlayerData[playerid][pCharacterID]
    );
    mysql_tquery(g_SQL, query);
    return 1;
}

/**
 * Menyimpan seluruh karakter pemain yang sedang online (dipanggil saat autosave & GMX).
 */
stock Character_SaveAll()
{
    new count = 0;
    foreach (new i : SpawnedPlayers)
    {
        if (Character_Save(i))
        {
            count++;
        }
    }
    return count;
}

/**
 * Menampilkan dialog statistik lengkap karakter pemain.
 */
stock Character_ShowStats(playerid, targetid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerConnected(targetid) || !PlayerData[targetid][pCharacterLoaded])
    {
        return 0;
    }

    new
        rpName[MAX_PLAYER_NAME],
        cashStr[32],
        bankStr[32],
        dialogBody[768],
        title[96];

    GetPlayerRoleplayName(targetid, rpName, sizeof(rpName));
    FormatMoney(PlayerData[targetid][pMoney], cashStr, sizeof(cashStr));
    FormatMoney(PlayerData[targetid][pBankMoney], bankStr, sizeof(bankStr));

    format(title, sizeof(title), "{00D4FF}Profil Warga: %s (ID: %d)", rpName, targetid);
    format(
        dialogBody,
        sizeof(dialogBody),
        "{FFD166}=== IDENTITAS WARGA ===\n\
        {FFFFFF}Nama Lengkap: {00D4FF}%s {B0B8C1}(Akun: %s)\n\
        {FFFFFF}Jenis Kelamin: {FFD166}%s {FFFFFF}| Usia: {FFD166}%d Tahun {FFFFFF}| Asal: {FFD166}%s\n\
        {FFFFFF}Nomor Ponsel: {FFD166}%s {FFFFFF}| No. Rekening: {FFD166}%s\n\n\
        {FFD166}=== PROGRES & KEUANGAN ===\n\
        {FFFFFF}Level: {2EC4B6}%d {FFFFFF}(EXP: %d/%d) | Jam Bermain: {2EC4B6}%d Jam\n\
        {FFFFFF}Uang Tunai: {2EC4B6}%s {FFFFFF}| Saldo Bank: {2EC4B6}%s\n\
        {FFFFFF}Wanted Level: {FF4D4D}%d Bintang\n\n\
        {FFD166}=== KONDISI & LISENSI ===\n\
        {FFFFFF}Lapar: {FFD166}%.0f%% {FFFFFF}| Haus: {FFD166}%.0f%% {FFFFFF}| Stres: {FFD166}%.0f%%\n\
        {FFFFFF}SIM Mengemudi: %s {FFFFFF}| Lisensi Senjata: %s\n\
        {FFFFFF}Lisensi Terbang: %s {FFFFFF}| Lisensi Kapal: %s",
        rpName,
        PlayerData[targetid][pUsername],
        (PlayerData[targetid][pGender] == 2) ? ("Perempuan") : ("Laki-laki"),
        PlayerData[targetid][pAge],
        PlayerData[targetid][pOrigin],
        PlayerData[targetid][pPhoneNumber],
        PlayerData[targetid][pBankAccountNo],
        PlayerData[targetid][pLevel],
        PlayerData[targetid][pExp],
        PlayerData[targetid][pLevel] * 4,
        PlayerData[targetid][pPlayingHours],
        cashStr,
        bankStr,
        PlayerData[targetid][pWantedLevel],
        PlayerData[targetid][pHunger],
        PlayerData[targetid][pThirst],
        PlayerData[targetid][pStress],
        PlayerData[targetid][pLicDriving] ? ("{2EC4B6}Ada") : ("{FF4D4D}Tidak"),
        PlayerData[targetid][pLicWeapon] ? ("{2EC4B6}Ada") : ("{FF4D4D}Tidak"),
        PlayerData[targetid][pLicFlying] ? ("{2EC4B6}Ada") : ("{FF4D4D}Tidak"),
        PlayerData[targetid][pLicBoat] ? ("{2EC4B6}Ada") : ("{FF4D4D}Tidak")
    );

    ShowPlayerDialog(playerid, DIALOG_CHAR_STATS, DIALOG_STYLE_MSGBOX, title, dialogBody, "Tutup", "");
    return 1;
}

// ============================================================================
// PERINTAH PEMAIN
// ============================================================================
CMD:stats(playerid, params[])
{
    #pragma unused params
    if (!PlayerData[playerid][pCharacterLoaded])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda belum memilih karakter!");
        return 1;
    }

    Character_ShowStats(playerid, playerid);
    return 1;
}

CMD:gantikarakter(playerid, params[])
{
    #pragma unused params
    if (!PlayerData[playerid][pAccountLoaded] || !PlayerData[playerid][pCharacterLoaded])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak sedang memainkan karakter!");
        return 1;
    }

    if (PlayerData[playerid][pInjured] || PlayerData[playerid][pJailTime] > 0 || PlayerData[playerid][pWantedLevel] > 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat berganti karakter saat sedang terluka, dipenjara, atau berstatus buronan!");
        return 1;
    }

    Character_Save(playerid);
    Variables_ResetCharacterData(playerid);

    // Kembalikan nama ke nama akun asal dan buka kembali menu pilih karakter
    SetPlayerName(playerid, PlayerData[playerid][pUsername]);
    Database_IncrementRaceCheck(playerid);
    Account_SetupLoginCamera(playerid);
    Character_ShowSelection(playerid);

    SendClientMessage(playerid, COLOR_INFO, "Data karakter sebelumnya telah disimpan. Silakan pilih karakter lain.");
    return 1;
}
alias:gantikarakter("switchchar", "changechar")

// ============================================================================
// HOOKS & TIMER AUTOSAVE
// ============================================================================
hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    // Simpan progres karakter sebelum Variables_ResetPlayerData dijalankan oleh modul account
    if (PlayerData[playerid][pCharacterLoaded])
    {
        Character_Save(playerid);
    }
    return 1;
}

task Character_AutosaveTask[CHAR_AUTOSAVE_INTERVAL_MS]()
{
    new saved = Character_SaveAll();
    if (saved > 0)
    {
        printf("[Autosave] Berhasil menyimpan data %d karakter aktif.", saved);
    }
}

/**
 * Timer 1 detik per pemain untuk menghitung mundur durasi mute & jail (IC/OOC).
 */
ptask Character_SanctionTimerTask[1000](playerid)
{
    if (!IsPlayerConnected(playerid) || IsPlayerNPC(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return;
    }

    if (PlayerData[playerid][pMuteTime] > 0)
    {
        PlayerData[playerid][pMuteTime]--;
        if (PlayerData[playerid][pMuteTime] == 0)
        {
            SendClientMessage(playerid, COLOR_SUCCESS, "Masa hukuman bisu (mute) Anda telah berakhir.");
        }
    }

    if (PlayerData[playerid][pJailTime] > 0)
    {
        PlayerData[playerid][pJailTime]--;
        if (PlayerData[playerid][pJailTime] == 0)
        {
            PlayerData[playerid][pJailType] = 0;
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            SetPlayerPos(playerid, 1742.9962, -1860.6310, 13.5784);
            SendClientMessage(playerid, COLOR_SUCCESS, "Masa hukuman penjara Anda telah selesai! Anda dibebaskan di Unity Station.");
            Character_Save(playerid);
        }
    }
}
