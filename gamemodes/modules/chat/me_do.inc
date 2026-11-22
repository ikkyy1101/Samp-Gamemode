/**
 * File: gamemodes/modules/chat/me_do.inc
 * Modul: Roleplay Action & Environment Commands (/me, /do, /ame, /ado, /my, /try, /roll, /coin, /setstatus, /examine)
 * Deskripsi: Menyediakan seluruh perintah aksi Roleplay standar server besar beserta
 *            label 3D sementara (/ado), deskripsi pemeriksaan karakter (/examine),
 *            dan sistem probabilitas (/try, /roll, /coin).
 * Dependensi: <open.mp>, <streamer>, <Pawn.CMD>, <sscanf2>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/enums.inc,
 *             core/variables.inc, modules/chat/antispam.inc, modules/chat/local.inc
 */

#if defined _INC_CHAT_MEDO
    #endinput
#endif
#define _INC_CHAT_MEDO

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA ROLEPLAY ACTIONS
// ============================================================================
#define RP_ACTION_RADIUS            (20.0)
#define COLOR_RP_ACTION             (0xC2A2DAFF) // Ungu pastel standar RP (/me, /do, /my)
#define COLOR_RP_TRY                (0x9B5DE5FF)

// ============================================================================
// FUNGSI HELPER AKSI RP PUBLIK (DAPAT DIPANGGIL MODUL LAIN)
// ============================================================================

/**
 * Mengirimkan aksi /me otomatis dari sistem (misal saat pakai item, mengunci mobil, dll).
 */
stock RP_SendAutomaticMe(playerid, const action[])
{
    if (!IsPlayerConnected(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 0;
    }

    new
        rpName[MAX_PLAYER_NAME],
        formatted[200];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(formatted, sizeof(formatted), "* %s %s", rpName, action);
    Chat_SendLocalProximity(playerid, RP_ACTION_RADIUS, formatted, false, COLOR_RP_ACTION);
    return 1;
}

// ============================================================================
// PERINTAH ROLEPLAY (/me, /do, /ame, /ado, /my)
// ============================================================================
CMD:me(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /me [aksi karakter]");
        return 1;
    }

    new cleanText[144];
    format(cleanText, sizeof(cleanText), "%s", params);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), true))
    {
        return 1;
    }

    new
        rpName[MAX_PLAYER_NAME],
        formatted[220];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(formatted, sizeof(formatted), "* %s %s", rpName, cleanText);

    Chat_SendLocalProximity(playerid, RP_ACTION_RADIUS, formatted, false, COLOR_RP_ACTION);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, formatted);
    return 1;
}

CMD:do(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /do [deskripsi situasi/lingkungan]");
        return 1;
    }

    new cleanText[144];
    format(cleanText, sizeof(cleanText), "%s", params);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), true))
    {
        return 1;
    }

    new
        rpName[MAX_PLAYER_NAME],
        formatted[220];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(formatted, sizeof(formatted), "* %s (( %s ))", cleanText, rpName);

    Chat_SendLocalProximity(playerid, RP_ACTION_RADIUS, formatted, false, COLOR_RP_ACTION);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, formatted);
    return 1;
}

CMD:ame(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /ame [aksi singkat di atas kepala]");
        return 1;
    }

    new cleanText[128];
    format(cleanText, sizeof(cleanText), "%s", params);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), true))
    {
        return 1;
    }

    new
        rpName[MAX_PLAYER_NAME],
        bubbleText[160],
        noticeText[180];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(bubbleText, sizeof(bubbleText), "* %s %s", rpName, cleanText);
    format(noticeText, sizeof(noticeText), "> %s %s", rpName, cleanText);

    SetPlayerChatBubble(playerid, bubbleText, COLOR_RP_ACTION, RP_ACTION_RADIUS, 6000);
    SendClientMessage(playerid, COLOR_RP_ACTION, "%s", noticeText);
    return 1;
}

CMD:ado(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    // Jika parameter kosong atau "hapus", hapus label /ado milik pemain
    if (isnull(params) || strcmp(params, "hapus", true) == 0 || strcmp(params, "off", true) == 0)
    {
        if (IsValidDynamic3DTextLabel(PlayerData[playerid][pAdoLabel]))
        {
            DestroyDynamic3DTextLabel(PlayerData[playerid][pAdoLabel]);
            PlayerData[playerid][pAdoLabel] = Text3D:INVALID_3DTEXT_ID;
            SendClientMessage(playerid, COLOR_INFO, "Deskripsi lingkungan (/ado) Anda telah dihapus.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /ado [deskripsi lingkungan di lokasi Anda] atau /ado hapus");
        }
        return 1;
    }

    new cleanText[128];
    format(cleanText, sizeof(cleanText), "%s", params);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), false))
    {
        return 1;
    }

    if (IsValidDynamic3DTextLabel(PlayerData[playerid][pAdoLabel]))
    {
        DestroyDynamic3DTextLabel(PlayerData[playerid][pAdoLabel]);
        PlayerData[playerid][pAdoLabel] = Text3D:INVALID_3DTEXT_ID;
    }

    new
        Float:x, Float:y, Float:z,
        rpName[MAX_PLAYER_NAME],
        labelText[180];

    GetPlayerPos(playerid, x, y, z);
    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(labelText, sizeof(labelText), "* %s *\n(( %s ))", cleanText, rpName);

    PlayerData[playerid][pAdoLabel] = CreateDynamic3DTextLabel(
        labelText,
        COLOR_RP_ACTION,
        x, y, z - 0.2,
        15.0,
        INVALID_PLAYER_ID,
        INVALID_VEHICLE_ID,
        1,
        GetPlayerVirtualWorld(playerid),
        GetPlayerInterior(playerid)
    );

    SendClientMessage(playerid, COLOR_SUCCESS, "Label deskripsi lingkungan (/ado) dipasang. Ketik /ado hapus untuk menghapusnya.");
    return 1;
}

CMD:my(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /my [deskripsi barang/kondisi milik karakter]");
        return 1;
    }

    new cleanText[144];
    format(cleanText, sizeof(cleanText), "%s", params);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), true))
    {
        return 1;
    }

    new
        rpName[MAX_PLAYER_NAME],
        formatted[220];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(formatted, sizeof(formatted), "* %s's %s", rpName, cleanText);

    Chat_SendLocalProximity(playerid, RP_ACTION_RADIUS, formatted, false, COLOR_RP_ACTION);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, formatted);
    return 1;
}

// ============================================================================
// PERINTAH PROBABILITAS & DESKRIPSI KARAKTER (/try, /roll, /coin, /setstatus, /examine)
// ============================================================================
CMD:try(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /try [aksi percobaan]");
        return 1;
    }

    new cleanText[128];
    format(cleanText, sizeof(cleanText), "%s", params);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), false))
    {
        return 1;
    }

    new
        rpName[MAX_PLAYER_NAME],
        bool:berhasil = (random(2) == 1),
        formatted[220];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(
        formatted,
        sizeof(formatted),
        "* %s mencoba %s, dan %s.",
        rpName,
        cleanText,
        berhasil ? ("{2EC4B6}berhasil") : ("{FF4D4D}gagal")
    );

    Chat_SendLocalProximity(playerid, RP_ACTION_RADIUS, formatted, false, COLOR_RP_TRY);
    return 1;
}

CMD:roll(playerid, params[])
{
    #pragma unused params
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    new
        rpName[MAX_PLAYER_NAME],
        dice = random(6) + 1,
        formatted[144];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(formatted, sizeof(formatted), "* %s melempar sebuah dadu dan mendapatkan angka %d (1-6).", rpName, dice);

    Chat_SendLocalProximity(playerid, RP_ACTION_RADIUS, formatted, false, COLOR_RP_ACTION);
    return 1;
}

CMD:coin(playerid, params[])
{
    #pragma unused params
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    new
        rpName[MAX_PLAYER_NAME],
        bool:heads = (random(2) == 1),
        formatted[144];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(
        formatted,
        sizeof(formatted),
        "* %s melempar koin ke udara dan mendarat pada sisi %s.",
        rpName,
        heads ? ("GAMBAR (Heads)") : ("ANGKA (Tails)")
    );

    Chat_SendLocalProximity(playerid, RP_ACTION_RADIUS, formatted, false, COLOR_RP_ACTION);
    return 1;
}

CMD:setstatus(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    if (isnull(params) || strcmp(params, "hapus", true) == 0 || strcmp(params, "none", true) == 0)
    {
        PlayerData[playerid][pRPStatus][0] = EOS;
        SendClientMessage(playerid, COLOR_INFO, "Status kondisi RP karakter Anda telah dihapus.");
        return 1;
    }

    new cleanStatus[96];
    format(cleanStatus, sizeof(cleanStatus), "%s", params);
    SanitizeString(cleanStatus);

    if (strlen(cleanStatus) < 3 || strlen(cleanStatus) > 85)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Panjang status harus 3 - 85 karakter. Ketik /setstatus hapus untuk menghapus.");
        return 1;
    }

    format(PlayerData[playerid][pRPStatus], 96, "%s", cleanStatus);

    new msg[144];
    format(msg, sizeof(msg), "Status karakter diatur: \"%s\" (dapat dilihat warga lewat /examine).", PlayerData[playerid][pRPStatus]);
    SendClientMessage(playerid, COLOR_SUCCESS, "%s", msg);
    return 1;
}

CMD:setdesc(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    if (isnull(params) || strcmp(params, "hapus", true) == 0)
    {
        PlayerData[playerid][pDescription][0] = EOS;
        SendClientMessage(playerid, COLOR_INFO, "Deskripsi fisik karakter Anda telah dihapus.");
        return 1;
    }

    new cleanDesc[160];
    format(cleanDesc, sizeof(cleanDesc), "%s", params);
    SanitizeString(cleanDesc);

    if (strlen(cleanDesc) < 5 || strlen(cleanDesc) > 150)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Panjang deskripsi fisik harus 5 - 150 karakter.");
        return 1;
    }

    format(PlayerData[playerid][pDescription], 160, "%s", cleanDesc);
    SendClientMessage(playerid, COLOR_SUCCESS, "Deskripsi fisik karakter berhasil diperbarui.");
    return 1;
}

CMD:examine(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /examine [ID/Nama Pemain]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tersebut tidak ditemukan!");
        return 1;
    }

    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(targetid, tx, ty, tz);

    if (GetPlayerInterior(playerid) != GetPlayerInterior(targetid) ||
        GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(targetid) ||
        GetPlayerDistanceFromPoint(playerid, tx, ty, tz) > 10.0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berada lebih dekat dengan warga tersebut untuk memeriksanya!");
        return 1;
    }

    new
        targetName[MAX_PLAYER_NAME],
        Float:hp,
        healthCondition[48],
        dialogBody[512],
        title[80];

    GetPlayerRoleplayName(targetid, targetName, sizeof(targetName));
    GetPlayerHealth(targetid, hp);

    if (PlayerData[targetid][pInjured] || hp <= 20.0)
    {
        format(healthCondition, sizeof(healthCondition), "{FF4D4D}Terluka Parah / Kritis");
    }
    else if (hp <= 60.0)
    {
        format(healthCondition, sizeof(healthCondition), "{FFD166}Tampak Memar / Lelah");
    }
    else
    {
        format(healthCondition, sizeof(healthCondition), "{2EC4B6}Sehat & Bugar");
    }

    new
        genderStr[16],
        descStr[160],
        statusStr[96];

    format(genderStr, sizeof(genderStr), (PlayerData[targetid][pGender] == 2) ? ("Perempuan") : ("Laki-laki"));

    if (PlayerData[targetid][pDescription][0] != EOS)
    {
        format(descStr, sizeof(descStr), "%s", PlayerData[targetid][pDescription]);
    }
    else
    {
        format(descStr, sizeof(descStr), "Tidak ada ciri fisik khusus yang terlihat.");
    }

    if (PlayerData[targetid][pRPStatus][0] != EOS)
    {
        format(statusStr, sizeof(statusStr), "%s", PlayerData[targetid][pRPStatus]);
    }
    else
    {
        format(statusStr, sizeof(statusStr), "Tidak ada status khusus.");
    }

    format(title, sizeof(title), "{00D4FF}Pemeriksaan Fisik: %s", targetName);
    format(
        dialogBody,
        sizeof(dialogBody),
        "{FFFFFF}Nama: {FFD166}%s\n\
        {FFFFFF}Jenis Kelamin: {FFD166}%s {FFFFFF}| Perkiraan Usia: {FFD166}%d Tahun\n\
        {FFFFFF}Kondisi Fisik: %s\n\n\
        {00D4FF}Deskripsi Penampilan:\n\
        {FFFFFF}%s\n\n\
        {00D4FF}Status RP Saat Ini:\n\
        {FFFFFF}%s",
        targetName,
        genderStr,
        PlayerData[targetid][pAge],
        healthCondition,
        descStr,
        statusStr
    );

    ShowPlayerDialog(playerid, DIALOG_EXAMINE_INFO, DIALOG_STYLE_MSGBOX, title, dialogBody, "Tutup", "");
    return 1;
}
