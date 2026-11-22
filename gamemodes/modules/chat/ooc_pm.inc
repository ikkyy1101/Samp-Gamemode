/**
 * File: gamemodes/modules/chat/ooc_pm.inc
 * Modul: Out-Of-Character (OOC), Private Message (PM), Radio & Megaphone
 * Deskripsi: Menangani OOC lokal (/b), OOC global (/o, /togooc), Private Message
 *            (/pm, /re, /togpm), serta komunikasi radio faksi (/r, /d, /f) dan
 *            megafon (/m).
 * Dependensi: <open.mp>, <Pawn.CMD>, <sscanf2>, <YSI_Data\y_iterate>,
 *             core/colors.inc, core/utils.inc, core/enums.inc,
 *             core/variables.inc, modules/chat/antispam.inc, modules/chat/local.inc
 */

#if defined _INC_CHAT_OOC_PM
    #endinput
#endif
#define _INC_CHAT_OOC_PM

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA OOC & RADIO
// ============================================================================
#define OOC_LOCAL_RADIUS            (20.0)
#define MEGAPHONE_RADIUS            (45.0)
#define COLOR_OOC_LOCAL             (0xA8B2BDFF)
#define COLOR_OOC_GLOBAL            (0x72EFDDFF)
#define COLOR_PM_OUT                (0xFFD166FF)
#define COLOR_PM_IN                 (0xF4A261FF)
#define COLOR_FACTION_RADIO         (0x4EA8DEFF)
#define COLOR_DEPT_RADIO            (0xFF6B6BFF)
#define COLOR_FACTION_OOC           (0x48BFE3FF)
#define COLOR_MEGAPHONE             (0xFFE66DFF)

// ============================================================================
// PERINTAH OOC LOKAL & GLOBAL (/b, /o, /togooc)
// ============================================================================
CMD:b(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /b [pesan OOC lokal]");
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
    format(formatted, sizeof(formatted), "(( [%d] %s: %s ))", playerid, rpName, cleanText);

    Chat_SendLocalProximity(playerid, OOC_LOCAL_RADIUS, formatted, false, COLOR_OOC_LOCAL);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, formatted);
    return 1;
}

CMD:o(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    if (!g_GlobalOOCEnabled && PlayerData[playerid][pAdminLevel] < 1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Chat Global OOC (/o) sedang dinonaktifkan oleh Admin.");
        return 1;
    }

    if (!PlayerData[playerid][pTogOOC] && PlayerData[playerid][pAdminLevel] < 1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda menonaktifkan Global OOC! Aktifkan kembali lewat /pengaturan.");
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /o [pesan OOC global]");
        return 1;
    }

    // Cooldown khusus Global OOC (10 detik untuk pemain biasa)
    if (PlayerData[playerid][pAdminLevel] < 1)
    {
        new now = GetTickCount();
        if ((now - PlayerData[playerid][pLastOOCGlobalTick]) < OOC_GLOBAL_COOLDOWN_MS)
        {
            SendClientMessage(playerid, COLOR_WARNING, "Global OOC (/o) memiliki jeda 10 detik antar pesan.");
            return 1;
        }
        PlayerData[playerid][pLastOOCGlobalTick] = now;
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

    if (PlayerData[playerid][pAdminLevel] > 0)
    {
        format(formatted, sizeof(formatted), "(( [OOC] {FF4D4D}[Admin] {72EFDD}%s (%d): %s ))", rpName, playerid, cleanText);
    }
    else
    {
        format(formatted, sizeof(formatted), "(( [OOC] %s (%d): %s ))", rpName, playerid, cleanText);
    }

    foreach (new i : SpawnedPlayers)
    {
        if (PlayerData[i][pTogOOC] || PlayerData[i][pAdminLevel] > 0)
        {
            Chat_SendSplitMessage(i, COLOR_OOC_GLOBAL, formatted);
        }
    }

    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, formatted);
    return 1;
}

CMD:togooc(playerid, params[])
{
    #pragma unused params
    if (PlayerData[playerid][pAdminLevel] < 2)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak memiliki akses untuk menggunakan perintah ini!");
        return 1;
    }

    g_GlobalOOCEnabled = !g_GlobalOOCEnabled;

    new
        adminName[MAX_PLAYER_NAME],
        notice[144];

    GetPlayerRoleplayName(playerid, adminName, sizeof(adminName));
    format(
        notice,
        sizeof(notice),
        "[Admin] %s telah %s saluran Global OOC (/o).",
        adminName,
        g_GlobalOOCEnabled ? ("mengaktifkan") : ("menonaktifkan")
    );
    SendClientMessageToAll(COLOR_INFO, "%s", notice);
    return 1;
}

// ============================================================================
// PERINTAH PRIVATE MESSAGE (/pm, /re, /togpm)
// ============================================================================
static Chat_SendPrivateMessage(playerid, targetid, const rawText[])
{
    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tujuan sedang tidak berada di dalam permainan!");
        return 0;
    }

    if (targetid == playerid)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat mengirim PM ke diri sendiri!");
        return 0;
    }

    if (!PlayerData[targetid][pTogPM] && PlayerData[playerid][pAdminLevel] < 1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tersebut sedang menonaktifkan Private Message (PM).");
        return 0;
    }

    new cleanText[144];
    format(cleanText, sizeof(cleanText), "%s", rawText);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), false))
    {
        return 0;
    }

    new
        senderName[MAX_PLAYER_NAME],
        targetName[MAX_PLAYER_NAME],
        outMsg[200],
        inMsg[200];

    GetPlayerRoleplayName(playerid, senderName, sizeof(senderName));
    GetPlayerRoleplayName(targetid, targetName, sizeof(targetName));

    format(outMsg, sizeof(outMsg), "(( PM terkirim ke %s (ID %d): %s ))", targetName, targetid, cleanText);
    format(inMsg, sizeof(inMsg), "(( PM dari %s (ID %d): %s ))", senderName, playerid, cleanText);

    Chat_SendSplitMessage(playerid, COLOR_PM_OUT, outMsg);
    Chat_SendSplitMessage(targetid, COLOR_PM_IN, inMsg);

    PlayerData[targetid][pLastPMSenderID] = playerid;
    Chat_LogToDatabase("pm", playerid, targetid, cleanText);
    return 1;
}

CMD:pm(playerid, params[])
{
    new
        targetid,
        pmText[128];

    if (sscanf(params, "us[128]", targetid, pmText))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /pm [ID/Nama Pemain] [pesan]");
        return 1;
    }

    Chat_SendPrivateMessage(playerid, targetid, pmText);
    return 1;
}

CMD:re(playerid, params[])
{
    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /re [pesan balasan PM]");
        return 1;
    }

    new targetid = PlayerData[playerid][pLastPMSenderID];
    if (targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Tidak ada pengirim PM terakhir yang dapat dibalas!");
        return 1;
    }

    Chat_SendPrivateMessage(playerid, targetid, params);
    return 1;
}
alias:re("reply")

CMD:togpm(playerid, params[])
{
    #pragma unused params
    if (!PlayerData[playerid][pAccountLoaded])
    {
        return 1;
    }

    PlayerData[playerid][pTogPM] = !PlayerData[playerid][pTogPM];
    SendClientMessage(
        playerid,
        COLOR_INFO,
        PlayerData[playerid][pTogPM] ? ("Private Message (PM) sekarang diaktifkan.") : ("Private Message (PM) sekarang dinonaktifkan.")
    );
    return 1;
}

// ============================================================================
// KOMUNIKASI FAKSI & MEGAFON (/r, /d, /f, /m)
// ============================================================================
CMD:r(playerid, params[])
{
    if (PlayerData[playerid][pFactionID] <= 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak tergabung dalam faksi manapun!");
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /r [pesan radio IC faksi]");
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
        radioMsg[220],
        localEcho[220];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(radioMsg, sizeof(radioMsg), "** [Radio Faksi | Rank %d] %s: %s, over. **", PlayerData[playerid][pFactionRank], rpName, cleanText);
    format(localEcho, sizeof(localEcho), "%s (radio): %s", rpName, cleanText);

    foreach (new i : SpawnedPlayers)
    {
        if (PlayerData[i][pFactionID] == PlayerData[playerid][pFactionID])
        {
            Chat_SendSplitMessage(i, COLOR_FACTION_RADIO, radioMsg);
        }
    }

    // Pemain di sekitar tetap mendengar karakter berbicara ke radionya
    Chat_SendLocalProximity(playerid, 12.0, localEcho, true);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, radioMsg);
    return 1;
}

CMD:d(playerid, params[])
{
    // Faksi 1 = LSPD, 2 = LSFD/EMS, 3 = GOV
    if (PlayerData[playerid][pFactionID] < 1 || PlayerData[playerid][pFactionID] > 3)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Hanya anggota instansi pemerintah (LSPD/LSFD/GOV) yang memiliki akses radio departemen!");
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /d [pesan radio antar departemen]");
        return 1;
    }

    new cleanText[144];
    format(cleanText, sizeof(cleanText), "%s", params);

    if (!Chat_ValidateMessage(playerid, cleanText, sizeof(cleanText), true))
    {
        return 1;
    }

    new
        deptTag[12],
        rpName[MAX_PLAYER_NAME],
        deptMsg[220];

    switch (PlayerData[playerid][pFactionID])
    {
        case 1: format(deptTag, sizeof(deptTag), "LSPD");
        case 2: format(deptTag, sizeof(deptTag), "LSFD");
        case 3: format(deptTag, sizeof(deptTag), "GOV");
    }

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(deptMsg, sizeof(deptMsg), "** [Departemen %s] %s: %s **", deptTag, rpName, cleanText);

    foreach (new i : SpawnedPlayers)
    {
        if (PlayerData[i][pFactionID] >= 1 && PlayerData[i][pFactionID] <= 3)
        {
            Chat_SendSplitMessage(i, COLOR_DEPT_RADIO, deptMsg);
        }
    }

    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, deptMsg);
    return 1;
}

CMD:f(playerid, params[])
{
    if (PlayerData[playerid][pFactionID] <= 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak tergabung dalam faksi manapun!");
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /f [pesan OOC faksi]");
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
        factionOoc[220];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(factionOoc, sizeof(factionOoc), "(( [Faksi OOC | Rank %d] %s: %s ))", PlayerData[playerid][pFactionRank], rpName, cleanText);

    foreach (new i : SpawnedPlayers)
    {
        if (PlayerData[i][pFactionID] == PlayerData[playerid][pFactionID])
        {
            Chat_SendSplitMessage(i, COLOR_FACTION_OOC, factionOoc);
        }
    }

    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, factionOoc);
    return 1;
}

CMD:m(playerid, params[])
{
    if (PlayerData[playerid][pFactionID] < 1 || PlayerData[playerid][pFactionID] > 3)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak memiliki akses menggunakan megafon!");
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /m [pengumuman megafon]");
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
        megaMsg[220];

    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    format(megaMsg, sizeof(megaMsg), "[%s Megafon] %s: %s!", (PlayerData[playerid][pFactionID] == 1) ? ("LSPD") : ("Petugas"), rpName, cleanText);

    Chat_SendLocalProximity(playerid, MEGAPHONE_RADIUS, megaMsg, false, COLOR_MEGAPHONE);
    Chat_LogToDatabase("chat", playerid, INVALID_PLAYER_ID, megaMsg);
    return 1;
}
alias:m("megaphone")
