// =============================================================================
// File: gamemodes/modules/character/character_spawn.inc
// Fungsi: Pemuatan data lengkap karakter dari database, pemilihan lokasi spawn
//         (Posisi Terakhir, Balai Kota, Rumah Pribadi, Faksi), dan proses spawn.
// Dependensi: <open.mp>, <a_mysql>, core/config.inc, core/colors.inc,
//             core/utils.inc, core/enums.inc, core/variables.inc, core/database.inc
// =============================================================================

#if defined _INC_CHAR_SPAWN
    #endinput
#endif
#define _INC_CHAR_SPAWN

// Forward unfreeze timer
forward OnPlayerSpawnUnfreeze(playerid);

// -----------------------------------------------------------------------------
// Memuat Data Karakter yang Dipilih dari Database
// -----------------------------------------------------------------------------
stock Character_Load(playerid, charid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    new racecheck = Database_GetRaceCheck(playerid);
    new query[320];
    mysql_format(
        g_DB,
        query,
        sizeof(query),
        "SELECT * FROM `characters` WHERE `id` = %d AND `account_id` = %d LIMIT 1",
        charid,
        PlayerData[playerid][pAccountID]
    );

    mysql_tquery(g_DB, query, "OnCharacterDataLoaded", "ii", playerid, racecheck);
    return 1;
}

// -----------------------------------------------------------------------------
// Callback Pemuatan Data Karakter
// -----------------------------------------------------------------------------
forward OnCharacterDataLoaded(playerid, racecheck);
public OnCharacterDataLoaded(playerid, racecheck)
{
    if (!Database_IsRaceCheckValid(playerid, racecheck))
    {
        return 0;
    }

    new rows;
    cache_get_row_count(rows);
    if (rows == 0)
    {
        SendErrorMessage(playerid, "Data karakter tidak ditemukan atau tidak cocok dengan akun Anda!");
        Character_ShowSelectionMenu(playerid);
        return 0;
    }

    // Pemuatan data ke struct PlayerData
    cache_get_value_name_int(0, "id", PlayerData[playerid][pCharacterID]);
    cache_get_value_name(0, "name", PlayerData[playerid][pCharName], MAX_PLAYER_NAME);
    cache_get_value_name_int(0, "gender", PlayerData[playerid][pGender]);
    cache_get_value_name_int(0, "age", PlayerData[playerid][pAge]);
    cache_get_value_name(0, "origin", PlayerData[playerid][pOrigin], 32);
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

    cache_get_value_name_int(0, "level", PlayerData[playerid][pLevel]);
    cache_get_value_name_int(0, "exp", PlayerData[playerid][pExp]);
    cache_get_value_name_int(0, "playing_hours", PlayerData[playerid][pPlayingHours]);

    cache_get_value_name_int(0, "job_id", PlayerData[playerid][pJobID]);
    cache_get_value_name_int(0, "faction_id", PlayerData[playerid][pFactionID]);
    cache_get_value_name_int(0, "faction_rank", PlayerData[playerid][pFactionRank]);

    cache_get_value_name_int(0, "phone_number", PlayerData[playerid][pPhoneNumber]);
    cache_get_value_name_float(0, "hunger", PlayerData[playerid][pHunger]);
    cache_get_value_name_float(0, "thirst", PlayerData[playerid][pThirst]);
    cache_get_value_name_float(0, "stress", PlayerData[playerid][pStress]);

    new inj, jtime, jtype, wlevel, ldrive, lwep, lfly, lboat, spoint;
    cache_get_value_name_int(0, "injured", inj);
    cache_get_value_name_int(0, "jail_time", jtime);
    cache_get_value_name_int(0, "jail_type", jtype);
    cache_get_value_name_int(0, "wanted_level", wlevel);
    cache_get_value_name_int(0, "license_drive", ldrive);
    cache_get_value_name_int(0, "license_weapon", lwep);
    cache_get_value_name_int(0, "license_fly", lfly);
    cache_get_value_name_int(0, "license_boat", lboat);
    cache_get_value_name_int(0, "spawn_point", spoint);

    PlayerData[playerid][pInjured] = (inj == 1);
    PlayerData[playerid][pJailTime] = jtime;
    PlayerData[playerid][pJailType] = jtype;
    PlayerData[playerid][pWantedLevel] = wlevel;
    PlayerData[playerid][pLicenseDrive] = (ldrive == 1);
    PlayerData[playerid][pLicenseWeapon] = (lwep == 1);
    PlayerData[playerid][pLicenseFly] = (lfly == 1);
    PlayerData[playerid][pLicenseBoat] = (lboat == 1);
    PlayerData[playerid][pSpawnPoint] = spoint;

    PlayerData[playerid][pCharacterLoaded] = true;

    // Ganti nama client SA-MP menjadi nama IC karakter
    SetPlayerName(playerid, PlayerData[playerid][pCharName]);

    // Tampilkan menu pilihan titik spawn jika bukan pertama kali bermain
    if (PlayerData[playerid][pPlayingHours] > 0)
    {
        Character_ShowSpawnMenu(playerid);
    }
    else
    {
        // Pemain pertama kali bermain: spawn langsung di Balai Kota
        Character_Spawn(playerid, 0);
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Menampilkan Dialog Pemilihan Lokasi Spawn
// -----------------------------------------------------------------------------
stock Character_ShowSpawnMenu(playerid)
{
    new list[384];
    format(
        list,
        sizeof(list),
        "1. Posisi Terakhir (Terakhir Logout)\n\
        2. Balai Kota Los Santos (City Hall)\n\
        3. Rumah Pribadi (Jika Memiliki Properti)\n\
        4. Kantor / Markas Faksi"
    );

    ShowPlayerDialog(playerid, DIALOG_CHAR_SPAWN_SELECT, DIALOG_STYLE_LIST, "{00AAFF}Pilih Titik Kemunculan (Spawn)", list, "Spawn", "Batal");
    return 1;
}

// -----------------------------------------------------------------------------
// Eksekusi Spawn Karakter ke Dunia Permainan
// -----------------------------------------------------------------------------
public Character_Spawn(playerid, spawnType)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    TogglePlayerSpectating(playerid, false);

    new Float:sx = DEFAULT_SPAWN_X;
    new Float:sy = DEFAULT_SPAWN_Y;
    new Float:sz = DEFAULT_SPAWN_Z;
    new Float:sa = DEFAULT_SPAWN_ANGLE;
    new sint = DEFAULT_SPAWN_INTERIOR;
    new svw = DEFAULT_SPAWN_VW;

    switch (spawnType)
    {
        case 1: // Posisi Terakhir
        {
            if (PlayerData[playerid][pPosZ] > 0.0)
            {
                sx = PlayerData[playerid][pPosX];
                sy = PlayerData[playerid][pPosY];
                sz = PlayerData[playerid][pPosZ];
                sa = PlayerData[playerid][pPosA];
                sint = PlayerData[playerid][pInterior];
                svw = PlayerData[playerid][pVirtualWorld];
            }
        }
        case 2: // Rumah Pribadi (Placeholder logic sampai Tahap Properti)
        {
            // Default kembali ke posisi terakhir bila rumah belum dimuat
            sx = PlayerData[playerid][pPosX];
            sy = PlayerData[playerid][pPosY];
            sz = PlayerData[playerid][pPosZ];
        }
        case 3: // Faksi
        {
            if (PlayerData[playerid][pFactionID] == 1) // SAPD
            {
                sx = 1553.30; sy = -1675.60; sz = 16.20; sa = 90.0; sint = 0; svw = 0;
            }
            else if (PlayerData[playerid][pFactionID] == 2) // SAMD
            {
                sx = 1172.80; sy = -1323.30; sz = 14.10; sa = 270.0; sint = 0; svw = 0;
            }
        }
        default: // 0: Balai Kota (Default City Hall)
        {
            sx = DEFAULT_SPAWN_X;
            sy = DEFAULT_SPAWN_Y;
            sz = DEFAULT_SPAWN_Z;
            sa = DEFAULT_SPAWN_ANGLE;
            sint = DEFAULT_SPAWN_INTERIOR;
            svw = DEFAULT_SPAWN_VW;
        }
    }

    SetSpawnInfo(playerid, NO_TEAM, PlayerData[playerid][pSkin], sx, sy, sz, sa);
    SpawnPlayer(playerid);

    SetPlayerInterior(playerid, sint);
    SetPlayerVirtualWorld(playerid, svw);
    SetPlayerPos(playerid, sx, sy, sz);
    SetPlayerFacingAngle(playerid, sa);

    // Pulihkan atribut fisik
    SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);
    SetPlayerHealth(playerid, PlayerData[playerid][pHealth]);
    SetPlayerArmour(playerid, PlayerData[playerid][pArmour]);

    // Sinkronisasi Uang Server-Side
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerData[playerid][pMoney]);

    // Set kamera di belakang pemain
    SetCameraBehindPlayer(playerid);

    // Freeze pemain sebentar agar tekstur & objek dunia dimuat sempurna
    TogglePlayerControllable(playerid, false);
    SetTimerEx("OnPlayerSpawnUnfreeze", 750, false, "i", playerid);

    PlayerData[playerid][pAuthState] = AUTH_STATE_SPAWNED;

    // Bersihkan chat
    for (new i = 0; i < 10; i++) SendClientMessage(playerid, -1, "");

    new welcomeMsg[160];
    format(welcomeMsg, sizeof(welcomeMsg), "Selamat datang kembali, %s! Anda spawn sebagai karakter: %s.", GetPlayerNameEx(playerid), PlayerData[playerid][pCharName]);
    SendSuccessMessage(playerid, welcomeMsg);

    new statMsg[160];
    format(statMsg, sizeof(statMsg), "Level: %d | Uang Tunai: %s | Saldo Bank: %s", PlayerData[playerid][pLevel], FormatMoney(PlayerData[playerid][pMoney]), FormatMoney(PlayerData[playerid][pBankMoney]));
    SendInfoMessage(playerid, statMsg);

    return 1;
}

// -----------------------------------------------------------------------------
// Unfreeze Pemain Pasca Loading Objek
// -----------------------------------------------------------------------------
public OnPlayerSpawnUnfreeze(playerid)
{
    if (IsPlayerConnected(playerid) && PlayerData[playerid][pCharacterLoaded])
    {
        TogglePlayerControllable(playerid, true);
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Respon Dialog Pemilihan Titik Spawn
// -----------------------------------------------------------------------------
stock Character_OnSpawnDialogResponse(playerid, response, listitem)
{
    if (!response)
    {
        Character_ShowSelectionMenu(playerid);
        return 1;
    }

    switch (listitem)
    {
        case 0: Character_Spawn(playerid, 1); // Posisi Terakhir
        case 1: Character_Spawn(playerid, 0); // Balai Kota
        case 2: Character_Spawn(playerid, 2); // Rumah
        case 3: Character_Spawn(playerid, 3); // Faksi
        default: Character_Spawn(playerid, 0);
    }
    return 1;
}
