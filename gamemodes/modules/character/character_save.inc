// =============================================================================
// File: gamemodes/modules/character/character_save.inc
// Fungsi: Sistem penyimpanan data karakter persisten ke database (koordinat,
//         status fisik, ekonomi, jam terbang, dan kebutuhan).
// Dependensi: <open.mp>, <a_mysql>, core/config.inc, core/enums.inc,
//             core/variables.inc, core/database.inc
// =============================================================================

#if defined _INC_CHAR_SAVE
    #endinput
#endif
#define _INC_CHAR_SAVE

// -----------------------------------------------------------------------------
// Menyimpan Seluruh Data Karakter Aktif ke Database
// -----------------------------------------------------------------------------
stock Character_Save(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded] || PlayerData[playerid][pCharacterID] <= 0)
    {
        return 0;
    }

    // Ambil posisi dan kondisi terkini jika pemain sedang berada di dalam dunia permainan
    if (PlayerData[playerid][pAuthState] == AUTH_STATE_SPAWNED)
    {
        GetPlayerPos(playerid, PlayerData[playerid][pPosX], PlayerData[playerid][pPosY], PlayerData[playerid][pPosZ]);
        GetPlayerFacingAngle(playerid, PlayerData[playerid][pPosA]);
        PlayerData[playerid][pInterior] = GetPlayerInterior(playerid);
        PlayerData[playerid][pVirtualWorld] = GetPlayerVirtualWorld(playerid);

        GetPlayerHealth(playerid, PlayerData[playerid][pHealth]);
        GetPlayerArmour(playerid, PlayerData[playerid][pArmour]);
    }

    new query[768];
    mysql_format(
        g_DB,
        query,
        sizeof(query),
        "UPDATE `characters` SET \
            `skin` = %d, \
            `pos_x` = %.4f, `pos_y` = %.4f, `pos_z` = %.4f, `pos_a` = %.4f, \
            `interior` = %d, `virtual_world` = %d, \
            `health` = %.2f, `armour` = %.2f, \
            `money` = %d, `bank_money` = %d, \
            `level` = %d, `exp` = %d, `playing_hours` = %d, \
            `hunger` = %.2f, `thirst` = %.2f, `stress` = %.2f, \
            `injured` = %d, `jail_time` = %d, `jail_type` = %d, `wanted_level` = %d, \
            `last_played` = NOW() \
         WHERE `id` = %d",
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
        PlayerData[playerid][pHunger],
        PlayerData[playerid][pThirst],
        PlayerData[playerid][pStress],
        PlayerData[playerid][pInjured] ? 1 : 0,
        PlayerData[playerid][pJailTime],
        PlayerData[playerid][pJailType],
        PlayerData[playerid][pWantedLevel],
        PlayerData[playerid][pCharacterID]
    );

    mysql_tquery(g_DB, query);
    return 1;
}

// -----------------------------------------------------------------------------
// Menyimpan Seluruh Karakter yang Sedang Online (Digunakan Saat Autosave & GMX)
// -----------------------------------------------------------------------------
stock Character_SaveAll()
{
    new savedCount = 0;
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerData[i][pCharacterLoaded])
        {
            Character_Save(i);
            savedCount++;
        }
    }
    printf("[DATABASE AUTOSAVE] Menyimpan otomatis %d data karakter aktif ke database.", savedCount);
    return savedCount;
}
