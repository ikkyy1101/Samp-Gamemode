/**
 * File: gamemodes/modules/admin/commands.inc
 * Modul: Admin Operational & Moderation Commands
 * Deskripsi: Menyediakan seluruh perintah administrasi dan moderasi server:
 *            teleportasi, kick, warn, mute, admin jail, freeze, slap, manipulasi
 *            HP/armour/skin/uang/kendaraan, inspeksi /check, /ip, /aka, /logs,
 *            pengaturan cuaca/waktu, dan /gmx dengan hitung mundur.
 * Dependensi: <open.mp>, <a_mysql>, <Pawn.CMD>, <sscanf2>, <YSI_Coding\y_iterate>,
 *             <YSI_Coding\y_timers>, core/colors.inc, core/utils.inc,
 *             core/database.inc, core/enums.inc, core/variables.inc,
 *             modules/admin/levels.inc, modules/character/stats.inc
 */

#if defined _INC_ADMIN_COMMANDS
    #endinput
#endif
#define _INC_ADMIN_COMMANDS

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA ADMIN JAIL & GMX
// ============================================================================
#define ADMIN_JAIL_X                (264.6288)
#define ADMIN_JAIL_Y                (77.5742)
#define ADMIN_JAIL_Z                (1001.0391)
#define ADMIN_JAIL_INTERIOR         (6)
#define ADMIN_JAIL_BASE_VW          (9000)
#define MAX_WARNINGS_BEFORE_KICK    (3)

// ============================================================================
// TELEPORTASI & POSISI (/goto, /gethere)
// ============================================================================
CMD:goto(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_HELPER, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /goto [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || targetid == playerid)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tujuan tidak valid!");
        return 1;
    }

    new
        Float:x, Float:y, Float:z,
        interior = GetPlayerInterior(targetid),
        vw = GetPlayerVirtualWorld(targetid),
        msg[128];

    GetPlayerPos(targetid, x, y, z);
    SetPlayerInterior(playerid, interior);
    SetPlayerVirtualWorld(playerid, vw);

    if (IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
    {
        new vehid = GetPlayerVehicleID(playerid);
        SetVehiclePos(vehid, x + 2.0, y, z);
        LinkVehicleToInterior(vehid, interior);
        SetVehicleVirtualWorld(vehid, vw);
    }
    else
    {
        SetPlayerPos(playerid, x + 1.2, y, z);
    }

    format(msg, sizeof(msg), "[Admin] Anda berteleportasi ke lokasi %s (ID: %d).", PlayerData[targetid][pCharName], targetid);
    SendClientMessage(playerid, COLOR_INFO, "%s", msg);
    return 1;
}

CMD:gethere(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /gethere [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || targetid == playerid)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tujuan tidak valid!");
        return 1;
    }

    if (!Admin_CanTarget(playerid, targetid))
    {
        return 1;
    }

    new
        Float:x, Float:y, Float:z,
        interior = GetPlayerInterior(playerid),
        vw = GetPlayerVirtualWorld(playerid),
        msg[128];

    GetPlayerPos(playerid, x, y, z);
    SetPlayerInterior(targetid, interior);
    SetPlayerVirtualWorld(targetid, vw);

    if (IsPlayerInAnyVehicle(targetid) && GetPlayerState(targetid) == PLAYER_STATE_DRIVER)
    {
        new vehid = GetPlayerVehicleID(targetid);
        SetVehiclePos(vehid, x + 2.0, y, z);
        LinkVehicleToInterior(vehid, interior);
        SetVehicleVirtualWorld(vehid, vw);
    }
    else
    {
        SetPlayerPos(targetid, x + 1.2, y, z);
    }

    format(msg, sizeof(msg), "[Admin] Anda menarik %s (ID: %d) ke lokasi Anda.", PlayerData[targetid][pCharName], targetid);
    SendClientMessage(playerid, COLOR_INFO, "%s", msg);
    SendClientMessage(targetid, COLOR_INFO, "Anda telah dipindahkan oleh Admin ke lokasi mereka.");
    return 1;
}

// ============================================================================
// MODERASI PEMAIN (/kick, /warn, /mute, /unmute, /jail, /unjail, /freeze, /slap)
// ============================================================================
CMD:kick(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_HELPER, true))
    {
        return 1;
    }

    new
        targetid,
        reason[96];

    if (sscanf(params, "us[96]", targetid, reason))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /kick [ID/Nama Pemain] [alasan]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || !Admin_CanTarget(playerid, targetid))
    {
        return 1;
    }

    SanitizeString(reason);

    new announceMsg[192];
    format(
        announceMsg,
        sizeof(announceMsg),
        "[AdminCmd] %s dikeluarkan dari server oleh %s. Alasan: %s",
        PlayerData[targetid][pCharName][0] != EOS ? PlayerData[targetid][pCharName] : PlayerData[targetid][pUsername],
        PlayerData[playerid][pUsername],
        reason
    );

    SendClientMessageToAll(COLOR_ADMIN_ALERT, "%s", announceMsg);
    Admin_LogAction(playerid, targetid, announceMsg);
    DelayedKick(targetid, 500);
    return 1;
}

CMD:warn(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new
        targetid,
        reason[96];

    if (sscanf(params, "us[96]", targetid, reason))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /warn [ID/Nama Pemain] [alasan]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || !Admin_CanTarget(playerid, targetid))
    {
        return 1;
    }

    SanitizeString(reason);
    PlayerData[targetid][pWarnCount]++;

    new announceMsg[200];
    format(
        announceMsg,
        sizeof(announceMsg),
        "[AdminCmd] %s diberikan peringatan (%d/%d) oleh %s. Alasan: %s",
        PlayerData[targetid][pCharName],
        PlayerData[targetid][pWarnCount],
        MAX_WARNINGS_BEFORE_KICK,
        PlayerData[playerid][pUsername],
        reason
    );
    SendClientMessageToAll(COLOR_ADMIN_ALERT, "%s", announceMsg);
    Admin_LogAction(playerid, targetid, announceMsg);

    if (PlayerData[targetid][pWarnCount] >= MAX_WARNINGS_BEFORE_KICK)
    {
        SendClientMessage(targetid, COLOR_ERROR, "Anda dikeluarkan otomatis karena mencapai batas 3 peringatan!");
        DelayedKick(targetid, 500);
    }
    return 1;
}

CMD:mute(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_HELPER, true))
    {
        return 1;
    }

    new
        targetid,
        minutes,
        reason[80];

    if (sscanf(params, "uis[80]", targetid, minutes, reason))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /mute [ID/Nama Pemain] [menit (1-120)] [alasan]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || !Admin_CanTarget(playerid, targetid))
    {
        return 1;
    }

    if (minutes < 1 || minutes > 120)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Durasi mute harus antara 1 hingga 120 menit!");
        return 1;
    }

    SanitizeString(reason);
    PlayerData[targetid][pMuteTime] = minutes * 60;

    new announceMsg[200];
    format(
        announceMsg,
        sizeof(announceMsg),
        "[AdminCmd] %s dibisukan (mute) selama %d menit oleh %s. Alasan: %s",
        PlayerData[targetid][pCharName],
        minutes,
        PlayerData[playerid][pUsername],
        reason
    );
    SendClientMessageToAll(COLOR_ADMIN_ALERT, "%s", announceMsg);
    Admin_LogAction(playerid, targetid, announceMsg);
    return 1;
}

CMD:unmute(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_HELPER, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /unmute [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tidak valid!");
        return 1;
    }

    PlayerData[targetid][pMuteTime] = 0;

    new logMsg[144];
    format(logMsg, sizeof(logMsg), "[AdminCmd] %s mencabut status mute pada %s.", PlayerData[playerid][pUsername], PlayerData[targetid][pCharName]);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, logMsg);
    Admin_LogAction(playerid, targetid, logMsg);
    SendClientMessage(targetid, COLOR_SUCCESS, "Status bisu (mute) Anda telah dicabut oleh staff.");
    return 1;
}

CMD:jail(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new
        targetid,
        minutes,
        reason[80];

    if (sscanf(params, "uis[80]", targetid, minutes, reason))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /jail [ID/Nama Pemain] [menit (1-300)] [alasan OOC]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || !Admin_CanTarget(playerid, targetid))
    {
        return 1;
    }

    if (minutes < 1 || minutes > 300)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Durasi Admin Jail harus antara 1 hingga 300 menit!");
        return 1;
    }

    SanitizeString(reason);

    if (IsPlayerInAnyVehicle(targetid))
    {
        RemovePlayerFromVehicle(targetid);
    }

    PlayerData[targetid][pJailTime] = minutes * 60;
    PlayerData[targetid][pJailType] = 2; // 2 = OOC Admin Jail

    SetPlayerInterior(targetid, ADMIN_JAIL_INTERIOR);
    SetPlayerVirtualWorld(targetid, ADMIN_JAIL_BASE_VW + targetid);
    SetPlayerPos(targetid, ADMIN_JAIL_X, ADMIN_JAIL_Y, ADMIN_JAIL_Z);
    ResetPlayerWeapons(targetid);

    new announceMsg[200];
    format(
        announceMsg,
        sizeof(announceMsg),
        "[AdminCmd] %s dimasukkan ke Admin Jail selama %d menit oleh %s. Alasan: %s",
        PlayerData[targetid][pCharName],
        minutes,
        PlayerData[playerid][pUsername],
        reason
    );
    SendClientMessageToAll(COLOR_ADMIN_ALERT, "%s", announceMsg);
    Admin_LogAction(playerid, targetid, announceMsg);
    Character_Save(targetid);
    return 1;
}
alias:jail("ajail")

CMD:unjail(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /unjail [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pJailTime] <= 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tersebut tidak sedang berada di dalam penjara!");
        return 1;
    }

    PlayerData[targetid][pJailTime] = 0;
    PlayerData[targetid][pJailType] = 0;

    SetPlayerInterior(targetid, 0);
    SetPlayerVirtualWorld(targetid, 0);
    SetPlayerPos(targetid, 1742.9962, -1860.6310, 13.5784);

    new logMsg[144];
    format(logMsg, sizeof(logMsg), "[AdminCmd] %s membebaskan %s dari penjara.", PlayerData[playerid][pUsername], PlayerData[targetid][pCharName]);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, logMsg);
    Admin_LogAction(playerid, targetid, logMsg);
    SendClientMessage(targetid, COLOR_SUCCESS, "Anda telah dibebaskan dari penjara oleh Admin.");
    Character_Save(targetid);
    return 1;
}

CMD:freeze(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_HELPER, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /freeze [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || !Admin_CanTarget(playerid, targetid))
    {
        return 1;
    }

    PlayerData[targetid][pFrozen] = true;
    TogglePlayerControllable(targetid, false);
    SendClientMessage(playerid, COLOR_INFO, "Pemain berhasil dibekukan (freeze).");
    SendClientMessage(targetid, COLOR_WARNING, "Anda telah dibekukan sementara oleh staff.");
    return 1;
}

CMD:unfreeze(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_HELPER, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /unfreeze [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    PlayerData[targetid][pFrozen] = false;
    TogglePlayerControllable(targetid, true);
    SendClientMessage(playerid, COLOR_INFO, "Status beku (freeze) pemain telah dilepas.");
    SendClientMessage(targetid, COLOR_SUCCESS, "Anda sudah dapat bergerak kembali.");
    return 1;
}

CMD:slap(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_HELPER, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /slap [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || !Admin_CanTarget(playerid, targetid))
    {
        return 1;
    }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);
    SetPlayerPos(targetid, x, y, z + 4.5);
    PlayerPlaySound(targetid, 1130, 0.0, 0.0, 0.0);

    SendClientMessage(playerid, COLOR_INFO, "Anda telah melakukan /slap pada pemain tersebut.");
    return 1;
}

// ============================================================================
// MANIPULASI ATRIBUT PEMAIN (/sethp, /setarmour, /setskin, /setvw, /setint, /givemoney, /setmoney)
// ============================================================================
CMD:sethp(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    new targetid, Float:hp;
    if (sscanf(params, "uf", targetid, hp))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /sethp [ID/Nama Pemain] [0.0 - 100.0]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || hp < 0.0 || hp > 100.0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Target atau nilai HP tidak valid!");
        return 1;
    }

    SetPlayerHealth(targetid, hp);
    PlayerData[targetid][pHealth] = hp;

    new logMsg[144];
    format(logMsg, sizeof(logMsg), "[AdminCmd] %s mengatur HP %s menjadi %.1f", PlayerData[playerid][pUsername], PlayerData[targetid][pCharName], hp);
    Admin_LogAction(playerid, targetid, logMsg);
    SendClientMessage(playerid, COLOR_SUCCESS, "%s", logMsg);
    return 1;
}

CMD:setarmour(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    new targetid, Float:armour;
    if (sscanf(params, "uf", targetid, armour))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /setarmour [ID/Nama Pemain] [0.0 - 100.0]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || armour < 0.0 || armour > 100.0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Target atau nilai Armour tidak valid!");
        return 1;
    }

    SetPlayerArmour(targetid, armour);
    PlayerData[targetid][pArmour] = armour;

    new logMsg[144];
    format(logMsg, sizeof(logMsg), "[AdminCmd] %s mengatur Armour %s menjadi %.1f", PlayerData[playerid][pUsername], PlayerData[targetid][pCharName], armour);
    Admin_LogAction(playerid, targetid, logMsg);
    SendClientMessage(playerid, COLOR_SUCCESS, "%s", logMsg);
    return 1;
}

CMD:setskin(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new targetid, skinid;
    if (sscanf(params, "ui", targetid, skinid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /setskin [ID/Nama Pemain] [Skin ID (0 - 311)]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || skinid < 0 || skinid > 311 || skinid == 74)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Target atau ID Skin tidak valid!");
        return 1;
    }

    SetPlayerSkin(targetid, skinid);
    PlayerData[targetid][pSkin] = skinid;
    SendClientMessage(playerid, COLOR_SUCCESS, "Skin karakter berhasil diubah.");
    return 1;
}

CMD:setvw(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new targetid, vw;
    if (sscanf(params, "ui", targetid, vw))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /setvw [ID/Nama Pemain] [Virtual World]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    SetPlayerVirtualWorld(targetid, vw);
    PlayerData[targetid][pVirtualWorld] = vw;
    SendClientMessage(playerid, COLOR_SUCCESS, "Virtual World pemain berhasil diperbarui.");
    return 1;
}

CMD:setint(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new targetid, interior;
    if (sscanf(params, "ui", targetid, interior))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /setint [ID/Nama Pemain] [Interior ID]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    SetPlayerInterior(targetid, interior);
    PlayerData[targetid][pInterior] = interior;
    SendClientMessage(playerid, COLOR_SUCCESS, "Interior pemain berhasil diperbarui.");
    return 1;
}

CMD:givemoney(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_SENIOR, true))
    {
        return 1;
    }

    new targetid, amount;
    if (sscanf(params, "ui", targetid, amount))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /givemoney [ID/Nama Pemain] [jumlah (+/-)]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tidak valid!");
        return 1;
    }

    PlayerData[targetid][pMoney] += amount;
    if (PlayerData[targetid][pMoney] < 0)
    {
        PlayerData[targetid][pMoney] = 0;
    }

    ResetPlayerMoney(targetid);
    GivePlayerMoney(targetid, PlayerData[targetid][pMoney]);

    new moneyStr[32], logMsg[160];
    FormatMoney(amount, moneyStr, sizeof(moneyStr));
    format(logMsg, sizeof(logMsg), "[AdminCmd] %s memberikan uang %s kepada %s.", PlayerData[playerid][pUsername], moneyStr, PlayerData[targetid][pCharName]);
    Admin_LogAction(playerid, targetid, logMsg);
    SendClientMessage(playerid, COLOR_SUCCESS, "%s", logMsg);
    Character_Save(targetid);
    return 1;
}

CMD:setmoney(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_SENIOR, true))
    {
        return 1;
    }

    new targetid, amount;
    if (sscanf(params, "ui", targetid, amount))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /setmoney [ID/Nama Pemain] [jumlah >= 0]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || amount < 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Target atau nominal uang tidak valid!");
        return 1;
    }

    PlayerData[targetid][pMoney] = amount;
    ResetPlayerMoney(targetid);
    GivePlayerMoney(targetid, PlayerData[targetid][pMoney]);

    new moneyStr[32], logMsg[160];
    FormatMoney(amount, moneyStr, sizeof(moneyStr));
    format(logMsg, sizeof(logMsg), "[AdminCmd] %s mengatur uang tunai %s menjadi %s.", PlayerData[playerid][pUsername], PlayerData[targetid][pCharName], moneyStr);
    Admin_LogAction(playerid, targetid, logMsg);
    SendClientMessage(playerid, COLOR_SUCCESS, "%s", logMsg);
    Character_Save(targetid);
    return 1;
}

// ============================================================================
// KENDARAAN ADMIN (/veh, /destroyveh, /respawnveh, /fixveh)
// ============================================================================
CMD:veh(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    new modelid, color1 = 1, color2 = 1;
    if (sscanf(params, "iI(1)I(1)", modelid, color1, color2))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /veh [Model ID (400-611)] [warna1] [warna2]");
        return 1;
    }

    if (modelid < 400 || modelid > 611)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Model ID kendaraan harus antara 400 hingga 611!");
        return 1;
    }

    if (PlayerData[playerid][pAdminVehicleID] != INVALID_VEHICLE_ID && IsValidVehicle(PlayerData[playerid][pAdminVehicleID]))
    {
        DestroyVehicle(PlayerData[playerid][pAdminVehicleID]);
        PlayerData[playerid][pAdminVehicleID] = INVALID_VEHICLE_ID;
    }

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new vehid = CreateVehicle(modelid, x + 2.0, y, z + 0.5, a, color1, color2, -1);
    if (vehid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Gagal memunculkan kendaraan admin!");
        return 1;
    }

    LinkVehicleToInterior(vehid, GetPlayerInterior(playerid));
    SetVehicleVirtualWorld(vehid, GetPlayerVirtualWorld(playerid));
    SetVehicleNumberPlate(vehid, "ADMIN");
    PutPlayerInVehicle(playerid, vehid, 0);

    // Nyalakan mesin kendaraan admin otomatis
    new engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(vehid, engine, lights, alarm, doors, bonnet, boot, objective);
    SetVehicleParamsEx(vehid, VEHICLE_PARAMS_ON, VEHICLE_PARAMS_ON, alarm, doors, bonnet, boot, objective);

    PlayerData[playerid][pAdminVehicleID] = vehid;
    SendClientMessage(playerid, COLOR_SUCCESS, "Kendaraan admin berhasil dimunculkan. Gunakan /destroyveh untuk menghapusnya.");
    return 1;
}

CMD:destroyveh(playerid, params[])
{
    #pragma unused params
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    if (IsPlayerInAnyVehicle(playerid))
    {
        new vehid = GetPlayerVehicleID(playerid);
        if (vehid == PlayerData[playerid][pAdminVehicleID])
        {
            PlayerData[playerid][pAdminVehicleID] = INVALID_VEHICLE_ID;
        }
        DestroyVehicle(vehid);
        SendClientMessage(playerid, COLOR_INFO, "Kendaraan yang Anda naiki telah dihapus.");
        return 1;
    }

    if (PlayerData[playerid][pAdminVehicleID] != INVALID_VEHICLE_ID && IsValidVehicle(PlayerData[playerid][pAdminVehicleID]))
    {
        DestroyVehicle(PlayerData[playerid][pAdminVehicleID]);
        PlayerData[playerid][pAdminVehicleID] = INVALID_VEHICLE_ID;
        SendClientMessage(playerid, COLOR_INFO, "Kendaraan admin terakhir Anda telah dihapus.");
        return 1;
    }

    SendClientMessage(playerid, COLOR_ERROR, "Anda tidak memiliki kendaraan admin aktif!");
    return 1;
}

CMD:respawnveh(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new vehid = IsPlayerInAnyVehicle(playerid) ? GetPlayerVehicleID(playerid) : 0;
    if (vehid == 0 && sscanf(params, "i", vehid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /respawnveh [Vehicle ID] atau gunakan di dalam kendaraan.");
        return 1;
    }

    if (!IsValidVehicle(vehid))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Vehicle ID tidak valid!");
        return 1;
    }

    SetVehicleToRespawn(vehid);
    SendClientMessage(playerid, COLOR_SUCCESS, "Kendaraan berhasil di-respawn ke posisi awalnya.");
    return 1;
}

CMD:fixveh(playerid, params[])
{
    #pragma unused params
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    if (!IsPlayerInAnyVehicle(playerid))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berada di dalam kendaraan!");
        return 1;
    }

    new vehid = GetPlayerVehicleID(playerid);
    RepairVehicle(vehid);
    SetVehicleHealth(vehid, 1000.0);
    SendClientMessage(playerid, COLOR_SUCCESS, "Kendaraan berhasil diperbaiki sepenuhnya.");
    return 1;
}

// ============================================================================
// MANAJEMEN STAFF, DUNIA & GMX (/makeadmin, /makehelper, /setweather, /settime, /announce, /gmx)
// ============================================================================
CMD:makeadmin(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_LEAD, true))
    {
        return 1;
    }

    new targetid, level;
    if (sscanf(params, "ui", targetid, level))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /makeadmin [ID/Nama Pemain] [Level (0 - 7)]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pAccountLoaded] || level < 0 || level > ADMIN_LEVEL_OWNER)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Target atau level admin (0-7) tidak valid!");
        return 1;
    }

    if (level >= Admin_GetEffectiveLevel(playerid) && Admin_GetEffectiveLevel(playerid) < ADMIN_LEVEL_OWNER)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat memberikan level admin yang sama atau lebih tinggi dari level Anda!");
        return 1;
    }

    PlayerData[targetid][pAdminLevel] = level;
    if (level == 0 && PlayerData[targetid][pHelperLevel] == 0)
    {
        PlayerData[targetid][pAdminLoggedIn] = false;
        Iter_Remove(OnlineStaff, targetid);
    }
    else
    {
        Iter_Add(OnlineStaff, targetid);
    }

    new query[160], rankName[32], logMsg[180];
    mysql_format(g_SQL, query, sizeof(query), "UPDATE `accounts` SET `admin_level` = %d WHERE `id` = %d", level, PlayerData[targetid][pAccountID]);
    mysql_tquery(g_SQL, query);

    Admin_GetRankName(level, rankName, sizeof(rankName));
    format(logMsg, sizeof(logMsg), "[Staff] %s mengatur level admin %s menjadi %s (Lv.%d).", PlayerData[playerid][pUsername], PlayerData[targetid][pUsername], rankName, level);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, logMsg);
    Admin_LogAction(playerid, targetid, logMsg);
    return 1;
}

CMD:makehelper(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_SENIOR, true))
    {
        return 1;
    }

    new targetid, level;
    if (sscanf(params, "ui", targetid, level))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /makehelper [ID/Nama Pemain] [Level (0 - 2)]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pAccountLoaded] || level < 0 || level > ADMIN_LEVEL_HELPER)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Target atau level helper (0-2) tidak valid!");
        return 1;
    }

    PlayerData[targetid][pHelperLevel] = level;
    if (level == 0 && PlayerData[targetid][pAdminLevel] == 0)
    {
        PlayerData[targetid][pAdminLoggedIn] = false;
        Iter_Remove(OnlineStaff, targetid);
    }
    else
    {
        Iter_Add(OnlineStaff, targetid);
    }

    new query[160], logMsg[180];
    mysql_format(g_SQL, query, sizeof(query), "UPDATE `accounts` SET `helper_level` = %d WHERE `id` = %d", level, PlayerData[targetid][pAccountID]);
    mysql_tquery(g_SQL, query);

    format(logMsg, sizeof(logMsg), "[Staff] %s mengatur level helper %s menjadi Level %d.", PlayerData[playerid][pUsername], PlayerData[targetid][pUsername], level);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, logMsg);
    Admin_LogAction(playerid, targetid, logMsg);
    return 1;
}

CMD:setweather(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    new weatherid;
    if (sscanf(params, "i", weatherid) || weatherid < 0 || weatherid > 45)
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /setweather [Weather ID (0 - 45)]");
        return 1;
    }

    SetWeather(weatherid);
    SendClientMessage(playerid, COLOR_SUCCESS, "Cuaca server berhasil diubah.");
    return 1;
}

CMD:settime(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    new hour;
    if (sscanf(params, "i", hour) || hour < 0 || hour > 23)
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /settime [Jam (0 - 23)]");
        return 1;
    }

    SetWorldTime(hour);
    SendClientMessage(playerid, COLOR_SUCCESS, "Jam dunia server berhasil diubah.");
    return 1;
}

CMD:announce(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /announce [pesan pengumuman layar]");
        return 1;
    }

    new cleanText[128], gameText[160], chatMsg[180];
    format(cleanText, sizeof(cleanText), "%s", params);
    SanitizeString(cleanText);

    format(gameText, sizeof(gameText), "~b~PENGUMUMAN SERVER~n~~w~%s", cleanText);
    format(chatMsg, sizeof(chatMsg), "[Pengumuman Admin] %s", cleanText);

    GameTextForAll(gameText, 5000, 3);
    SendClientMessageToAll(COLOR_PRIMARY, "%s", chatMsg);
    Admin_LogAction(playerid, INVALID_PLAYER_ID, chatMsg);
    return 1;
}
alias:announce("ann")

CMD:gmx(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_LEAD, true))
    {
        return 1;
    }

    new seconds = 15;
    if (!isnull(params))
    {
        seconds = strval(params);
        if (seconds < 5 || seconds > 120)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Durasi hitung mundur restart harus 5 - 120 detik!");
            return 1;
        }
    }

    g_GMXCountdown = seconds;

    new logMsg[160];
    format(logMsg, sizeof(logMsg), "[SERVER RESTART] %s memulai hitung mundur GMX (%d detik).", PlayerData[playerid][pUsername], seconds);
    SendClientMessageToAll(COLOR_ADMIN_ALERT, "%s", logMsg);
    Admin_LogAction(playerid, INVALID_PLAYER_ID, logMsg);
    return 1;
}

task Admin_GMXCountdownTask[1000]()
{
    if (g_GMXCountdown <= 0)
    {
        return;
    }

    new msg[128];
    format(msg, sizeof(msg), "~r~SERVER RESTART~n~~w~Dalam %d detik...", g_GMXCountdown);
    GameTextForAll(msg, 1100, 3);

    g_GMXCountdown--;
    if (g_GMXCountdown == 0)
    {
        new saved = Character_SaveAll();
        printf("[GMX] Menyimpan %d data karakter sebelum restart...", saved);
        SendClientMessageToAll(COLOR_ADMIN_ALERT, "[Server] Seluruh data warga telah disimpan. Server melakukan restart sekarang...");
        SendRconCommand("gmx");
    }
}

// ============================================================================
// INSPEKSI DATA & LOG (/check, /ip, /aka, /logs)
// ============================================================================
CMD:check(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /check [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pCharacterLoaded])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tidak ditemukan atau belum memilih karakter!");
        return 1;
    }

    new
        cashStr[32],
        bankStr[32],
        Float:hp,
        Float:armour,
        dialogBody[768],
        title[80];

    FormatMoney(PlayerData[targetid][pMoney], cashStr, sizeof(cashStr));
    FormatMoney(PlayerData[targetid][pBankMoney], bankStr, sizeof(bankStr));
    GetPlayerHealth(targetid, hp);
    GetPlayerArmour(targetid, armour);

    format(title, sizeof(title), "{00D4FF}Inspeksi Admin: %s (ID: %d)", PlayerData[targetid][pCharName], targetid);
    format(
        dialogBody,
        sizeof(dialogBody),
        "{FFD166}=== DATA AKUN & KONEKSI ===\n\
        {FFFFFF}Account ID: {00D4FF}#%d {FFFFFF}| Username: {00D4FF}%s\n\
        {FFFFFF}IP Sekarang: {FFD166}%s {FFFFFF}| IP Daftar: {FFD166}%s\n\
        {FFFFFF}Admin Lv: {2EC4B6}%d {FFFFFF}| Helper Lv: {2EC4B6}%d {FFFFFF}| VIP Lv: {2EC4B6}%d\n\n\
        {FFD166}=== DATA KARAKTER (#%d) ===\n\
        {FFFFFF}Level: {2EC4B6}%d {FFFFFF}(EXP: %d) | Jam Main: {2EC4B6}%d Jam\n\
        {FFFFFF}Tunai: {2EC4B6}%s {FFFFFF}| Bank: {2EC4B6}%s\n\
        {FFFFFF}HP: {FF4D4D}%.1f {FFFFFF}| Armour: {00D4FF}%.1f {FFFFFF}| Wanted: {FF4D4D}%d\n\
        {FFFFFF}Interior: %d | VW: %d | Jail Time: %d dtk | Mute Time: %d dtk",
        PlayerData[targetid][pAccountID],
        PlayerData[targetid][pUsername],
        PlayerData[targetid][pCurrentIP],
        PlayerData[targetid][pRegisterIP],
        PlayerData[targetid][pAdminLevel],
        PlayerData[targetid][pHelperLevel],
        PlayerData[targetid][pVIPLevel],
        PlayerData[targetid][pCharacterID],
        PlayerData[targetid][pLevel],
        PlayerData[targetid][pExp],
        PlayerData[targetid][pPlayingHours],
        cashStr,
        bankStr,
        hp,
        armour,
        PlayerData[targetid][pWantedLevel],
        GetPlayerInterior(targetid),
        GetPlayerVirtualWorld(targetid),
        PlayerData[targetid][pJailTime],
        PlayerData[targetid][pMuteTime]
    );

    ShowPlayerDialog(playerid, DIALOG_ADMIN_CHECK_STATS, DIALOG_STYLE_MSGBOX, title, dialogBody, "Tutup", "");
    return 1;
}

CMD:ip(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /ip [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pAccountLoaded])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tidak valid!");
        return 1;
    }

    new msg[180];
    format(
        msg,
        sizeof(msg),
        "[Admin IP] %s (Akun: %s) | IP Sekarang: %s | IP Daftar: %s | GPCI: %s",
        PlayerData[targetid][pCharName],
        PlayerData[targetid][pUsername],
        PlayerData[targetid][pCurrentIP],
        PlayerData[targetid][pRegisterIP],
        PlayerData[targetid][pGPCI]
    );
    SendClientMessage(playerid, COLOR_INFO, "%s", msg);
    return 1;
}

CMD:aka(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /aka [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pAccountLoaded])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tidak valid!");
        return 1;
    }

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[384];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT a.`id`, a.`username`, a.`last_ip`, a.`banned` \
         FROM `accounts` a \
         WHERE a.`last_ip` = '%e' OR a.`register_ip` = '%e' OR (a.`gpci` <> '' AND a.`gpci` = '%e') \
         LIMIT 15",
        PlayerData[targetid][pCurrentIP],
        PlayerData[targetid][pCurrentIP],
        PlayerData[targetid][pGPCI]
    );
    mysql_tquery(g_SQL, query, "OnAdminAKALookupResult", "ii", playerid, racecheck);
    return 1;
}

forward OnAdminAKALookupResult(playerid, racecheck);
public OnAdminAKALookupResult(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    new
        rows = cache_num_rows(),
        dialogBody[768],
        line[96],
        accId,
        accUser[MAX_PLAYER_NAME],
        accIp[46],
        banned;

    format(dialogBody, sizeof(dialogBody), "ID Akun\tUsername\tIP Terakhir (Status)\n");
    for (new i = 0; i < rows; i++)
    {
        cache_get_value_name_int(i, "id", accId);
        cache_get_value_name(i, "username", accUser, sizeof(accUser));
        cache_get_value_name(i, "last_ip", accIp, sizeof(accIp));
        cache_get_value_name_int(i, "banned", banned);

        format(
            line,
            sizeof(line),
            "#%d\t%s\t%s %s\n",
            accId,
            accUser,
            accIp,
            banned ? ("{FF4D4D}[BANNED]") : ("{2EC4B6}[Aktif]")
        );
        strcat(dialogBody, line);
    }

    ShowPlayerDialog(playerid, DIALOG_ADMIN_AKA_LIST, DIALOG_STYLE_TABLIST_HEADERS, "{00D4FF}Hasil Pengecekan Akun Terkait (/aka)", dialogBody, "Tutup", "");
    return 1;
}

CMD:logs(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    new logType[16];
    if (sscanf(params, "S(admin)[16]", logType))
    {
        format(logType, sizeof(logType), "admin");
    }

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[320];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT `id`, DATE_FORMAT(`created_at`, '%%d/%%m %%H:%%i') AS `waktu`, `message` \
         FROM `logs` WHERE `type` = '%e' ORDER BY `id` DESC LIMIT 12",
        logType
    );
    mysql_tquery(g_SQL, query, "OnAdminLogsLoaded", "ii", playerid, racecheck);
    return 1;
}

forward OnAdminLogsLoaded(playerid, racecheck);
public OnAdminLogsLoaded(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    new
        rows = cache_num_rows(),
        dialogBody[1024],
        line[160],
        waktu[24],
        msg[128];

    if (rows == 0)
    {
        SendClientMessage(playerid, COLOR_WARNING, "Tidak ada data log ditemukan untuk kategori tersebut.");
        return 1;
    }

    format(dialogBody, sizeof(dialogBody), "Waktu\tDetail Aktivitas\n");
    for (new i = 0; i < rows; i++)
    {
        cache_get_value_name(i, "waktu", waktu, sizeof(waktu));
        cache_get_value_name(i, "message", msg, sizeof(msg));

        format(line, sizeof(line), "%s\t%s\n", waktu, msg);
        strcat(dialogBody, line);
    }

    ShowPlayerDialog(playerid, DIALOG_ADMIN_LOGS_LIST, DIALOG_STYLE_TABLIST_HEADERS, "{00D4FF}Riwayat Log Server Terbaru", dialogBody, "Tutup", "");
    return 1;
}
