/**
 * File: gamemodes/modules/chat/antispam.inc
 * Modul: Chat Anti-Spam, Anti-Advertisement, Profanity Filter & Chat Logger
 * Deskripsi: Memvalidasi pesan chat/command dari spam cooldown, duplikasi teks,
 *            promosi IP/server luar, kata kasar, serta mencatat riwayat chat ke DB.
 * Dependensi: <open.mp>, <a_mysql>, <Pawn.CMD>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc
 */

#if defined _INC_CHAT_ANTISPAM
    #endinput
#endif
#define _INC_CHAT_ANTISPAM

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA ANTI-SPAM & FILTER
// ============================================================================
#define CHAT_COOLDOWN_MS            (1000)
#define COMMAND_COOLDOWN_MS         (600)
#define OOC_GLOBAL_COOLDOWN_MS      (10000)
#define MAX_CHAT_LINE_LEN           (110)

static const s_BlockedWords[][] = {
    "anjing",
    "bangsat",
    "kontol",
    "memek",
    "ngentot",
    "asu"
};

// ============================================================================
// FUNGSI VALIDASI & FILTER CHAT
// ============================================================================

/**
 * Mengecek apakah teks mengandung pola alamat IP (misal 192.168.1.1:7777) untuk mencegah iklan server.
 */
stock bool:Chat_ContainsAdvertisement(const text[])
{
    new
        dotCount = 0,
        digitRun = 0,
        len = strlen(text);

    for (new i = 0; i < len; i++)
    {
        if (text[i] >= '0' && text[i] <= '9')
        {
            digitRun++;
        }
        else if (text[i] == '.' && digitRun > 0 && digitRun <= 3)
        {
            dotCount++;
            digitRun = 0;
        }
        else
        {
            if (dotCount >= 3 && digitRun > 0)
            {
                return true;
            }
            dotCount = 0;
            digitRun = 0;
        }
    }
    return (dotCount >= 3 && digitRun > 0);
}

/**
 * Menyensor daftar kata kasar di dalam string menggunakan tanda bintang (*).
 */
stock Chat_FilterProfanity(text[])
{
    new pos, wordLen;
    for (new i = 0; i < sizeof(s_BlockedWords); i++)
    {
        wordLen = strlen(s_BlockedWords[i]);
        pos = strfind(text, s_BlockedWords[i], true);
        while (pos != -1)
        {
            for (new j = 0; j < wordLen; j++)
            {
                text[pos + j] = '*';
            }
            pos = strfind(text, s_BlockedWords[i], true, pos + wordLen);
        }
    }
    return 1;
}

/**
 * Validasi terpadu sebelum pesan chat dikirimkan ke publik/pemain lain.
 * Mengembalikan true jika pesan aman untuk diteruskan.
 */
stock bool:Chat_ValidateMessage(playerid, text[], len, bool:checkDuplicate = true)
{
    if (!IsPlayerConnected(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus masuk ke dunia permainan terlebih dahulu untuk berbicara.");
        return false;
    }

    if (PlayerData[playerid][pMuteTime] > 0)
    {
        new msg[96];
        format(msg, sizeof(msg), "Anda sedang dibisukan (mute) selama %d detik lagi.", PlayerData[playerid][pMuteTime]);
        SendClientMessage(playerid, COLOR_ERROR, "%s", msg);
        return false;
    }

    SanitizeString(text);

    // Trim spasi di awal teks
    while (text[0] == ' ')
    {
        strdel(text, 0, 1);
    }

    if (strlen(text) == 0)
    {
        return false;
    }

    // Cek cooldown chat (Admin level 2+ bebas cooldown)
    new now = GetTickCount();
    if (PlayerData[playerid][pAdminLevel] < 2)
    {
        if ((now - PlayerData[playerid][pLastChatTick]) < CHAT_COOLDOWN_MS)
        {
            SendClientMessage(playerid, COLOR_WARNING, "Jangan spam! Tunggu sebentar sebelum mengirim pesan berikutnya.");
            return false;
        }

        if (checkDuplicate && PlayerData[playerid][pLastChatText][0] != EOS && strcmp(text, PlayerData[playerid][pLastChatText], true) == 0)
        {
            SendClientMessage(playerid, COLOR_WARNING, "Jangan mengulang pesan yang sama secara berturut-turut.");
            return false;
        }
    }

    // Deteksi iklan IP server lain
    if (PlayerData[playerid][pAdminLevel] < 4 && Chat_ContainsAdvertisement(text))
    {
        SendClientMessage(playerid, COLOR_ERROR, "[Anti-Iklan] Dilarang mempromosikan alamat IP atau server lain di dalam chat!");
        Chat_LogToDatabase("anticheat", playerid, INVALID_PLAYER_ID, text);
        return false;
    }

    Chat_FilterProfanity(text);

    PlayerData[playerid][pLastChatTick] = now;
    format(PlayerData[playerid][pLastChatText], 144, "%.*s", len, text);
    return true;
}

/**
 * Mengirim pesan panjang dengan memecahnya otomatis menjadi 2 baris jika melebihi batas SA-MP (144 char).
 */
stock Chat_SendSplitMessage(playerid, color, const fullText[])
{
    new len = strlen(fullText);
    if (len <= MAX_CHAT_LINE_LEN)
    {
        SendClientMessage(playerid, color, "%s", fullText);
        return 1;
    }

    new
        splitPos = MAX_CHAT_LINE_LEN,
        firstLine[128],
        secondLine[128];

    // Cari spasi terdekat sebelum batas karakter agar kata tidak terpotong di tengah
    for (new i = MAX_CHAT_LINE_LEN; i > 60; i--)
    {
        if (fullText[i] == ' ')
        {
            splitPos = i;
            break;
        }
    }

    strmid(firstLine, fullText, 0, splitPos, sizeof(firstLine));
    strmid(secondLine, fullText, (fullText[splitPos] == ' ') ? splitPos + 1 : splitPos, len, sizeof(secondLine));

    SendClientMessage(playerid, color, "%s ...", firstLine);
    SendClientMessage(playerid, color, "... %s", secondLine);
    return 1;
}

/**
 * Mencatat percakapan chat / PM / anticheat ke tabel `logs`.
 */
stock Chat_LogToDatabase(const logType[], playerid, targetid, const message[])
{
    if (!Database_IsConnected())
    {
        return 0;
    }

    new
        charId = (IsPlayerConnected(playerid) && PlayerData[playerid][pCharacterLoaded]) ? PlayerData[playerid][pCharacterID] : 0,
        targetCharId = (targetid != INVALID_PLAYER_ID && IsPlayerConnected(targetid) && PlayerData[targetid][pCharacterLoaded]) ? PlayerData[targetid][pCharacterID] : 0,
        query[640];

    if (charId > 0 && targetCharId > 0)
    {
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('%e', %d, %d, '%e', '%e')",
            logType,
            charId,
            targetCharId,
            message,
            PlayerData[playerid][pCurrentIP]
        );
    }
    else if (charId > 0)
    {
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('%e', %d, NULL, '%e', '%e')",
            logType,
            charId,
            message,
            PlayerData[playerid][pCurrentIP]
        );
    }
    else
    {
        new ip[46];
        if (IsPlayerConnected(playerid))
        {
            format(ip, sizeof(ip), "%s", PlayerData[playerid][pCurrentIP]);
        }
        else
        {
            format(ip, sizeof(ip), "0.0.0.0");
        }

        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('%e', NULL, NULL, '%e', '%e')",
            logType,
            message,
            ip
        );
    }

    mysql_tquery(g_SQL, query);
    return 1;
}

// ============================================================================
// HOOK ANTI-FLOOD COMMAND
// ============================================================================
public OnPlayerCommandReceived(playerid, cmd[], params[], flags)
{
    #pragma unused cmd, params, flags

    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    if (PlayerData[playerid][pAdminLevel] < 2)
    {
        new now = GetTickCount();
        if ((now - PlayerData[playerid][pLastCmdTick]) < COMMAND_COOLDOWN_MS)
        {
            SendClientMessage(playerid, COLOR_WARNING, "Perintah terlalu cepat! Tunggu sebentar sebelum mengetik perintah lagi.");
            return 0;
        }
        PlayerData[playerid][pLastCmdTick] = now;
    }
    return 1;
}
