/**
 * File: gamemodes/modules/chat/local.inc
 * Modul: Local In-Character (IC) Chat, Distance Fading, Accent & Speech Volumes
 * Deskripsi: Menangani percakapan lokal OnPlayerText dengan gradasi warna 5 tingkat
 *            berdasarkan jarak, chat bubble di atas kepala, /accent, /low (/l),
 *            /shout (/s), dan /whisper (/w).
 * Dependensi: <open.mp>, <Pawn.CMD>, <sscanf2>, <YSI_Coding\y_hooks>,
 *             <YSI_Data\y_iterate>, core/colors.inc, core/utils.inc,
 *             core/enums.inc, core/variables.inc, modules/chat/antispam.inc
 */

#if defined _INC_CHAT_LOCAL
    #endinput
#endif
#define _INC_CHAT_LOCAL

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA RADIUS SUARA IC
// ============================================================================
#if !defined CHAT_RADIUS_NORMAL
    #define CHAT_RADIUS_NORMAL          (20.0)
#endif
#if !defined CHAT_RADIUS_LOW
    #define CHAT_RADIUS_LOW             (6.0)
#endif
#if !defined CHAT_RADIUS_SHOUT
    #define CHAT_RADIUS_SHOUT           (40.0)
#endif
#if !defined CHAT_RADIUS_WHISPER
    #define CHAT_RADIUS_WHISPER         (3.0)
#endif
#define CHAT_BUBBLE_DURATION_MS     (5000)

// ============================================================================
// FUNGSI PUBLIK BROADCAST JARAK (PROXIMITY CHAT)
// ============================================================================

/**
 * Mengirim pesan lokal ke semua pemain di sekitar senderid dengan gradasi warna
 * berdasarkan rasio jarak (100% terang di dekat sumber -> redup di tepi radius).
 */
stock Chat_SendLocalProximity(senderid, Float:maxRadius, const message[], bool:fadeColor = true, baseColor = 0xE6E6E6FF)
{
    if (!IsPlayerConnected(senderid))
    {
        return 0;
    }

    new
        Float:sx, Float:sy, Float:sz,
        interior = GetPlayerInterior(senderid),
        vw = GetPlayerVirtualWorld(senderid),
        Float:dist,
        Float:ratio,
        color;

    GetPlayerPos(senderid, sx, sy, sz);

    foreach (new i : SpawnedPlayers)
    {
        if (GetPlayerInterior(i) != interior || GetPlayerVirtualWorld(i) != vw)
        {
            continue;
        }

        dist = GetPlayerDistanceFromPoint(i, sx, sy, sz);
        if (dist > maxRadius)
        {
            continue;
        }

        if (!fadeColor)
        {
            color = baseColor;
        }
        else
        {
            ratio = dist / maxRadius;
            if (ratio <= 0.25)
            {
                color = 0xFFFFFFFF; // Sangat dekat
            }
            else if (ratio <= 0.50)
            {
                color = 0xD8D8D8FF; // Dekat
            }
            else if (ratio <= 0.75)
            {
                color = 0xB0B0B0FF; // Sedang
            }
            else
            {
                color = 0x888888FF; // Jauh (samar)
            }
        }

        Chat_SendSplitMessage(i, color, message);
    }
    return 1;
}

// ============================================================================
// HOOK ONPLAYERTEXT (PERCAKAPAN IC NORMAL)
// ============================================================================
hook OnPlayerText(playerid, text[])
{
    new cleanText[144];
    format(cleanText, sizeof(cleanText), "%s", text);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), true))
    {
        return 0;
    }

    if (PlayerData[playerid][pInjured])
    {
        SendClientMessage(playerid, COLOR_WARNING, "Anda sedang terluka parah! Gunakan /low untuk berbicara pelan.");
        return 0;
    }

    new
        rpName[MAX_PLAYER_NAME],
        formatted[220];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));

    if (PlayerData[playerid][pAccent][0] != EOS)
    {
        format(formatted, sizeof(formatted), "[Aksen %s] %s berkata: %s", PlayerData[playerid][pAccent], rpName, cleanText);
    }
    else
    {
        format(formatted, sizeof(formatted), "%s berkata: %s", rpName, cleanText);
    }

    Chat_SendLocalProximity(playerid, CHAT_RADIUS_NORMAL, formatted, true);
    SetPlayerChatBubble(playerid, cleanText, 0xFFFFFFFF, CHAT_RADIUS_NORMAL, CHAT_BUBBLE_DURATION_MS);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, formatted);
    return 0; // Return 0 agar Open.MP tidak mengirim chat global bawaan GTA
}

// ============================================================================
// PERINTAH PERCAKAPAN IC (/accent, /low, /shout, /whisper)
// ============================================================================
CMD:accent(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    if (isnull(params) || strcmp(params, "hapus", true) == 0 || strcmp(params, "none", true) == 0)
    {
        PlayerData[playerid][pAccent][0] = EOS;
        SendClientMessage(playerid, COLOR_INFO, "Aksen bicara karakter Anda telah dihapus.");
        return 1;
    }

    new cleanAccent[32];
    format(cleanAccent, sizeof(cleanAccent), "%s", params);
    SanitizeString(cleanAccent);

    if (strlen(cleanAccent) < 2 || strlen(cleanAccent) > 24)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Panjang aksen harus antara 2 hingga 24 karakter. Gunakan /accent hapus untuk menghapus.");
        return 1;
    }

    format(PlayerData[playerid][pAccent], 32, "%s", cleanAccent);

    new msg[96];
    format(msg, sizeof(msg), "Aksen bicara karakter diatur menjadi: [Aksen %s]", PlayerData[playerid][pAccent]);
    SendClientMessage(playerid, COLOR_SUCCESS, "%s", msg);
    return 1;
}

CMD:low(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /low [teks percakapan pelan]");
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
    format(formatted, sizeof(formatted), "%s berkata pelan: %s", rpName, cleanText);

    Chat_SendLocalProximity(playerid, CHAT_RADIUS_LOW, formatted, false, 0xB8B8B8FF);
    SetPlayerChatBubble(playerid, cleanText, 0xB8B8B8FF, CHAT_RADIUS_LOW, CHAT_BUBBLE_DURATION_MS);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, formatted);
    return 1;
}
alias:low("l")

CMD:shout(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /shout [teks teriakan]");
        return 1;
    }

    if (PlayerData[playerid][pInjured])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak bisa berteriak saat sedang terluka parah!");
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
    format(formatted, sizeof(formatted), "%s berteriak: %s!", rpName, cleanText);

    Chat_SendLocalProximity(playerid, CHAT_RADIUS_SHOUT, formatted, false, 0xFFFFFFFF);
    SetPlayerChatBubble(playerid, cleanText, 0xFFFFFFFF, CHAT_RADIUS_SHOUT, CHAT_BUBBLE_DURATION_MS);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, formatted);
    return 1;
}
alias:shout("s")

CMD:whisper(playerid, params[])
{
    new
        targetid,
        whisperText[128];

    if (sscanf(params, "us[128]", targetid, whisperText))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /whisper [ID/Nama Pemain] [pesan bisikan]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || targetid == playerid)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tujuan tidak valid!");
        return 1;
    }

    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(targetid, tx, ty, tz);

    if (GetPlayerInterior(playerid) != GetPlayerInterior(targetid) ||
        GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(targetid) ||
        GetPlayerDistanceFromPoint(playerid, tx, ty, tz) > CHAT_RADIUS_WHISPER)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tersebut terlalu jauh untuk dibisiki!");
        return 1;
    }

    if (!Chat_ValidateMessage(playerid, whisperText, sizeof(whisperText), false))
    {
        return 1;
    }

    new
        senderName[MAX_PLAYER_NAME],
        targetName[MAX_PLAYER_NAME],
        msgToSender[200],
        msgToTarget[200],
        meNotice[96];

    GetPlayerRoleplayName(playerid, senderName, sizeof(senderName));
    GetPlayerRoleplayName(targetid, targetName, sizeof(targetName));

    format(msgToSender, sizeof(msgToSender), "[Bisik ke %s] %s", targetName, whisperText);
    format(msgToTarget, sizeof(msgToTarget), "[Bisik dari %s] %s", senderName, whisperText);
    format(meNotice, sizeof(meNotice), "* %s membisikkan sesuatu kepada %s.", senderName, targetName);

    SendClientMessage(playerid, 0xFFD166FF, "%s", msgToSender);
    SendClientMessage(targetid, 0xFFD166FF, "%s", msgToTarget);
    Chat_SendLocalProximity(playerid, 10.0, meNotice, false, 0xC2A2DAFF);
    Chat_LogToDatabase("chat", playerid, targetid, msgToSender);
    return 1;
}
alias:whisper("w")
