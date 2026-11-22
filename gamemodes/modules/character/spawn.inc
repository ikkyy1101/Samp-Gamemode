/**
 * File: gamemodes/modules/character/spawn.inc
 * Modul: Character Spawn & State Restoration
 * Deskripsi: Menangani pilihan titik spawn (Posisi Terakhir, Rumah, Faksi, Bandara),
 *            pemulihan HP, Armour, skin, interior, VW, uang, wanted level, serta
 *            mengarahkan pemain baru ke tutorial kota.
 * Dependensi: <open.mp>, <YSI_Coding\y_hooks>, <YSI_Data\y_iterate>,
 *             core/colors.inc, core/utils.inc, core/enums.inc,
 *             core/variables.inc, modules/character/select.inc
 */

#if defined _INC_CHARACTER_SPAWN
    #endinput
#endif
#define _INC_CHARACTER_SPAWN

#include <YSI_Coding\y_hooks>

// Forward menuju modul tutorial (Tahap 4)
forward Character_StartTutorial(playerid);

// ============================================================================
// FUNGSI PUBLIK MODUL (CHARACTER_*)
// ============================================================================

/**
 * Menampilkan dialog pilihan titik spawn setelah data karakter selesai dimuat.
 */
public Character_OnLoaded(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    // Jika karakter baru belum menyelesaikan tutorial -> langsung jalankan tutorial
    if (!PlayerData[playerid][pTutorialDone])
    {
        Character_StartTutorial(playerid);
        return 1;
    }

    // Jika karakter sedang dalam status penjara -> langsung spawn ke sel penjara
    if (PlayerData[playerid][pJailTime] > 0)
    {
        Character_SpawnToWorld(playerid, 0);
        return 1;
    }

    PlayerData[playerid][pAuthState] = AUTH_STATE_SPAWN_SELECT;

    new
        dialogBody[384],
        houseText[64],
        factionText[64];

    if (PlayerData[playerid][pSpawnHouseID] > 0)
    {
        format(houseText, sizeof(houseText), "{2EC4B6}Rumah Pribadi (ID #%d)", PlayerData[playerid][pSpawnHouseID]);
    }
    else
    {
        format(houseText, sizeof(houseText), "{B0B8C1}Rumah Pribadi (Tidak tersedia)");
    }

    if (PlayerData[playerid][pFactionID] > 0)
    {
        format(factionText, sizeof(factionText), "{2EC4B6}Markas Faksi (ID #%d)", PlayerData[playerid][pFactionID]);
    }
    else
    {
        format(factionText, sizeof(factionText), "{B0B8C1}Markas Faksi (Bukan anggota)");
    }

    format(
        dialogBody,
        sizeof(dialogBody),
        "{00D4FF}1. Posisi Terakhir Keluar\n\
        %s\n\
        %s\n\
        {FFFFFF}4. Bandara Internasional Los Santos\n\
        {FFFFFF}5. Stasiun Kereta Unity Station",
        houseText,
        factionText
    );

    ShowPlayerDialog(playerid, DIALOG_CHAR_SPAWN_SELECT, DIALOG_STYLE_LIST, "{00D4FF}Pilih Lokasi Spawn", dialogBody, "Spawn", "Ganti Karakter");
    return 1;
}

/**
 * Menempatkan karakter ke dunia Roleplay dan memulihkan seluruh statusnya.
 * spawnChoice: 0 = LastPos, 1 = House, 2 = Faction, 3 = Airport, 4 = Unity Station
 */
stock Character_SpawnToWorld(playerid, spawnChoice = 0)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    new
        Float:x = PlayerData[playerid][pPosX],
        Float:y = PlayerData[playerid][pPosY],
        Float:z = PlayerData[playerid][pPosZ],
        Float:a = PlayerData[playerid][pPosA],
        interior = PlayerData[playerid][pInterior],
        vw = PlayerData[playerid][pVirtualWorld];

    switch (spawnChoice)
    {
        case 3: // Bandara Internasional Los Santos
        {
            x = 1642.1500;
            y = -2333.4200;
            z = 13.5469;
            a = 0.0;
            interior = 0;
            vw = 0;
        }
        case 4: // Unity Station
        {
            x = 1742.9962;
            y = -1860.6310;
            z = 13.5784;
            a = 0.0;
            interior = 0;
            vw = 0;
        }
    }

    // Pastikan koordinat valid (tidak jatuh di 0,0,0)
    if (x == 0.0 && y == 0.0 && z == 0.0)
    {
        x = 1742.9962;
        y = -1860.6310;
        z = 13.5784;
        a = 0.0;
        interior = 0;
        vw = 0;
    }

    TogglePlayerSpectating(playerid, false);
    SetSpawnInfo(playerid, NO_TEAM, PlayerData[playerid][pSkin], x, y, z, a, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    SpawnPlayer(playerid);

    SetPlayerPos(playerid, x, y, z);
    SetPlayerFacingAngle(playerid, a);
    SetPlayerInterior(playerid, interior);
    SetPlayerVirtualWorld(playerid, vw);
    SetPlayerSkin(playerid, PlayerData[playerid][pSkin]);
    SetCameraBehindPlayer(playerid);
    TogglePlayerControllable(playerid, true);

    // Pulihkan HP, Armour, Uang & Wanted Level
    new Float:hp = (PlayerData[playerid][pHealth] < 10.0) ? 10.0 : PlayerData[playerid][pHealth];
    SetPlayerHealth(playerid, hp);
    SetPlayerArmour(playerid, PlayerData[playerid][pArmour]);

    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerData[playerid][pMoney]);
    SetPlayerScore(playerid, PlayerData[playerid][pLevel]);
    SetPlayerWantedLevel(playerid, PlayerData[playerid][pWantedLevel]);

    PlayerData[playerid][pAuthState] = AUTH_STATE_SPAWNED;
    Iter_Add(SpawnedPlayers, playerid);

    new
        rpName[MAX_PLAYER_NAME],
        cashStr[32],
        msg[160];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    FormatMoney(PlayerData[playerid][pMoney], cashStr, sizeof(cashStr));

    format(
        msg,
        sizeof(msg),
        "Selamat datang di kota Los Santos, %s! (Level: %d | Tunai: %s | No. HP: %s)",
        rpName,
        PlayerData[playerid][pLevel],
        cashStr,
        PlayerData[playerid][pPhoneNumber]
    );
    SendClientMessage(playerid, COLOR_SUCCESS, "%s", msg);
    SendClientMessage(playerid, COLOR_INFO, "Gunakan /stats untuk melihat profil karakter atau /gantikarakter untuk berpindah karakter.");
    return 1;
}

// ============================================================================
// HOOK DIALOG RESPONSE PILIHAN SPAWN
// ============================================================================
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    if (dialogid == DIALOG_CHAR_SPAWN_SELECT)
    {
        if (!response)
        {
            Variables_ResetCharacterData(playerid);
            SetPlayerName(playerid, PlayerData[playerid][pUsername]);
            Account_SetupLoginCamera(playerid);
            Character_ShowSelection(playerid);
            return 1;
        }

        switch (listitem)
        {
            case 0: // Posisi Terakhir
            {
                Character_SpawnToWorld(playerid, 0);
            }
            case 1: // Rumah Pribadi (Query koordinat rumah akan disambungkan penuh di Tahap 10)
            {
                if (PlayerData[playerid][pSpawnHouseID] <= 0)
                {
                    SendClientMessage(playerid, COLOR_ERROR, "Anda belum memiliki rumah pribadi!");
                    Character_OnLoaded(playerid);
                    return 1;
                }
                Character_SpawnToWorld(playerid, 0);
            }
            case 2: // Markas Faksi (Query koordinat faksi akan disambungkan penuh di Tahap 13)
            {
                if (PlayerData[playerid][pFactionID] <= 0)
                {
                    SendClientMessage(playerid, COLOR_ERROR, "Anda tidak tergabung dalam faksi manapun!");
                    Character_OnLoaded(playerid);
                    return 1;
                }
                Character_SpawnToWorld(playerid, 0);
            }
            case 3: // Bandara Internasional Los Santos
            {
                Character_SpawnToWorld(playerid, 3);
            }
            case 4: // Unity Station
            {
                Character_SpawnToWorld(playerid, 4);
            }
        }
        return 1;
    }
    return 0;
}
