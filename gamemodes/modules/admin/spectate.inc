/**
 * File: gamemodes/modules/admin/spectate.inc
 * Modul: Admin Remote Spectate System (/spec & /specoff)
 * Deskripsi: Memungkinkan staff memantau pemain lain secara jarak jauh (baik berjalan
 *            kaki maupun di dalam kendaraan), menyimpan posisi asli admin sebelum
 *            spectate, dan mengembalikannya dengan aman saat selesai.
 * Dependensi: <open.mp>, <Pawn.CMD>, <sscanf2>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/enums.inc, core/variables.inc,
 *             modules/admin/levels.inc
 */

#if defined _INC_ADMIN_SPECTATE
    #endinput
#endif
#define _INC_ADMIN_SPECTATE

#include <YSI_Coding\y_hooks>

// ============================================================================
// FUNGSI INTERNAL SINKRONISASI KAMERA SPECTATE
// ============================================================================
static Admin_SyncSpectateTarget(playerid, targetid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerConnected(targetid))
    {
        return 0;
    }

    SetPlayerInterior(playerid, GetPlayerInterior(targetid));
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));

    if (IsPlayerInAnyVehicle(targetid))
    {
        PlayerSpectateVehicle(playerid, GetPlayerVehicleID(targetid));
    }
    else
    {
        PlayerSpectatePlayer(playerid, targetid);
    }
    return 1;
}

stock Admin_StopSpectate(playerid, bool:restorePos = true)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pSpectating])
    {
        return 0;
    }

    PlayerData[playerid][pSpectating] = false;
    PlayerData[playerid][pSpecTargetID] = INVALID_PLAYER_ID;

    if (restorePos)
    {
        TogglePlayerSpectating(playerid, false);
        SetSpawnInfo(
            playerid,
            NO_TEAM,
            PlayerData[playerid][pSkin],
            PlayerData[playerid][pSpecOldX],
            PlayerData[playerid][pSpecOldY],
            PlayerData[playerid][pSpecOldZ],
            PlayerData[playerid][pSpecOldA],
            WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0
        );
        SpawnPlayer(playerid);
        SetPlayerPos(playerid, PlayerData[playerid][pSpecOldX], PlayerData[playerid][pSpecOldY], PlayerData[playerid][pSpecOldZ]);
        SetPlayerFacingAngle(playerid, PlayerData[playerid][pSpecOldA]);
        SetPlayerInterior(playerid, PlayerData[playerid][pSpecOldInt]);
        SetPlayerVirtualWorld(playerid, PlayerData[playerid][pSpecOldVW]);
        SetCameraBehindPlayer(playerid);
    }
    return 1;
}

// ============================================================================
// PERINTAH SPECTATE (/spec, /specoff)
// ============================================================================
CMD:spec(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /spec [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || targetid == playerid)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain yang ingin dipantau tidak valid!");
        return 1;
    }

    if (PlayerData[targetid][pSpectating])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Staff tersebut juga sedang memantau pemain lain!");
        return 1;
    }

    // Simpan posisi asli admin jika baru pertama kali memulai spectate
    if (!PlayerData[playerid][pSpectating])
    {
        GetPlayerPos(playerid, PlayerData[playerid][pSpecOldX], PlayerData[playerid][pSpecOldY], PlayerData[playerid][pSpecOldZ]);
        GetPlayerFacingAngle(playerid, PlayerData[playerid][pSpecOldA]);
        PlayerData[playerid][pSpecOldInt] = GetPlayerInterior(playerid);
        PlayerData[playerid][pSpecOldVW] = GetPlayerVirtualWorld(playerid);
    }

    PlayerData[playerid][pSpectating] = true;
    PlayerData[playerid][pSpecTargetID] = targetid;

    TogglePlayerSpectating(playerid, true);
    Admin_SyncSpectateTarget(playerid, targetid);

    new msg[128];
    format(msg, sizeof(msg), "[Spectate] Memantau %s (ID: %d). Ketik /specoff untuk berhenti memantau.", PlayerData[targetid][pCharName], targetid);
    SendClientMessage(playerid, COLOR_INFO, "%s", msg);
    return 1;
}
alias:spec("spectate")

CMD:specoff(playerid, params[])
{
    #pragma unused params
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, false))
    {
        return 1;
    }

    if (!PlayerData[playerid][pSpectating])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak sedang dalam mode spectate!");
        return 1;
    }

    Admin_StopSpectate(playerid, true);
    SendClientMessage(playerid, COLOR_INFO, "[Spectate] Anda keluar dari mode pemantauan dan dikembalikan ke posisi semula.");
    return 1;
}
alias:specoff("stopspec")

// ============================================================================
// HOOKS SINKRONISASI PERPINDAHAN KENDARAAN/INTERIOR & DISCONNECT TARGET
// ============================================================================
hook OnPlayerStateChange(playerid, PLAYER_STATE:newstate, PLAYER_STATE:oldstate)
{
    #pragma unused oldstate
    if (newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER || newstate == PLAYER_STATE_ONFOOT)
    {
        foreach (new i : OnlineStaff)
        {
            if (PlayerData[i][pSpectating] && PlayerData[i][pSpecTargetID] == playerid)
            {
                Admin_SyncSpectateTarget(i, playerid);
            }
        }
    }
    return 1;
}

hook OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
    #pragma unused newinteriorid, oldinteriorid
    foreach (new i : OnlineStaff)
    {
        if (PlayerData[i][pSpectating] && PlayerData[i][pSpecTargetID] == playerid)
        {
            Admin_SyncSpectateTarget(i, playerid);
        }
    }
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    foreach (new i : OnlineStaff)
    {
        if (PlayerData[i][pSpectating] && PlayerData[i][pSpecTargetID] == playerid)
        {
            SendClientMessage(i, COLOR_WARNING, "[Spectate] Target yang Anda pantau telah keluar dari server.");
            Admin_StopSpectate(i, true);
        }
    }
    return 1;
}
