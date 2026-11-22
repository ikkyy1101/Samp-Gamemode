// =============================================================================
// File: gamemodes/core/utils.inc
// Fungsi: Kumpulan fungsi utilitas (format uang, kalkulasi jarak, validasi nama RP,
//         delayed kick, format waktu & durasi)
// Dependensi: <open.mp>, <string>, <float>, <time>, core/config.inc, core/colors.inc
// =============================================================================

#if defined _INC_CORE_UTILS
    #endinput
#endif
#define _INC_CORE_UTILS

#include <string>
#include <float>
#include <time>

forward OnDelayedKickTimer(playerid);

// -----------------------------------------------------------------------------
// Format Uang dengan Pemisah Koma Ribuan
// -----------------------------------------------------------------------------
stock FormatMoney(amount, destination[], max_len = sizeof(destination))
{
    new output[32], buffer[32];
    new bool:is_negative = false;

    if (amount < 0)
    {
        is_negative = true;
        amount = -amount;
    }

    format(buffer, sizeof(buffer), "%d", amount);
    new len = strlen(buffer);
    new comma_count = (len - 1) / 3;
    new out_len = len + comma_count + (is_negative ? 2 : 1);

    output[0] = (is_negative ? '-' : '$');
    if (is_negative) output[1] = '$';

    new write_pos = out_len - 1;
    new step = 0;

    for (new read_pos = len - 1; read_pos >= 0; read_pos--)
    {
        output[write_pos--] = buffer[read_pos];
        step++;
        if (step == 3 && read_pos > 0)
        {
            output[write_pos--] = ',';
            step = 0;
        }
    }
    output[out_len] = '\0';
    format(destination, max_len, "%s", output);
    return 1;
}

// -----------------------------------------------------------------------------
// Ambil Nama Asli Akun Pemain ke Buffer
// -----------------------------------------------------------------------------
stock GetPlayerNameString(playerid, destination[], max_len = sizeof(destination))
{
    new name[MAX_PLAYER_NAME + 1];
    GetPlayerName(playerid, name, sizeof(name));
    format(destination, max_len, "%s", name);
    return 1;
}

// -----------------------------------------------------------------------------
// Ambil Nama Roleplay Pemain (Underscore diganti spasi)
// -----------------------------------------------------------------------------
stock GetPlayerRoleplayName(playerid, destination[], max_len = sizeof(destination))
{
    new name[MAX_PLAYER_NAME + 1];
    GetPlayerName(playerid, name, sizeof(name));
    for (new i = 0, len = strlen(name); i < len; i++)
    {
        if (name[i] == '_') name[i] = ' ';
    }
    format(destination, max_len, "%s", name);
    return 1;
}

// -----------------------------------------------------------------------------
// Validasi Format Nama Roleplay (Nama_Marga)
// -----------------------------------------------------------------------------
stock bool:IsValidRoleplayName(const name[])
{
    new len = strlen(name);
    if (len < MIN_ROLEPLAY_NAME_LEN || len > MAX_ROLEPLAY_NAME_LEN)
    {
        return false;
    }

    new underscore_count = 0;
    new underscore_pos = -1;

    for (new i = 0; i < len; i++)
    {
        if (name[i] == '_')
        {
            underscore_count++;
            underscore_pos = i;
        }
        else if (!((name[i] >= 'a' && name[i] <= 'z') || (name[i] >= 'A' && name[i] <= 'Z')))
        {
            return false;
        }
    }

    if (underscore_count != 1 || underscore_pos < 2 || underscore_pos > (len - 3))
    {
        return false;
    }

    if (name[0] < 'A' || name[0] > 'Z') return false;
    if (name[underscore_pos + 1] < 'A' || name[underscore_pos + 1] > 'Z') return false;

    return true;
}

// -----------------------------------------------------------------------------
// Waktu & Durasi Server
// -----------------------------------------------------------------------------
stock GetFormattedServerTime(destination[], max_len = sizeof(destination))
{
    new year, month, day, hour, minute, second;
    getdate(year, month, day);
    gettime(hour, minute, second);
    format(destination, max_len, "%02d/%02d/%04d %02d:%02d:%02d", day, month, year, hour, minute, second);
    return 1;
}

stock FormatDuration(seconds, destination[], max_len = sizeof(destination))
{
    new hours = seconds / 3600;
    new minutes = (seconds % 3600) / 60;
    new secs = seconds % 60;

    if (hours > 0)
    {
        format(destination, max_len, "%d jam %d menit %d detik", hours, minutes, secs);
    }
    else if (minutes > 0)
    {
        format(destination, max_len, "%d menit %d detik", minutes, secs);
    }
    else
    {
        format(destination, max_len, "%d detik", secs);
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Kick Tertunda (Delayed Kick)
// -----------------------------------------------------------------------------
stock DelayedKick(playerid, delay_ms = 500)
{
    SetTimerEx("OnDelayedKickTimer", delay_ms, false, "i", playerid);
    return 1;
}

public OnDelayedKickTimer(playerid)
{
    if (IsPlayerConnected(playerid))
    {
        Kick(playerid);
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Sanitasi String (Mencegah Format String Vulnerability)
// -----------------------------------------------------------------------------
stock SanitizeString(string[])
{
    for (new i = 0, len = strlen(string); i < len; i++)
    {
        if (string[i] == '%')
        {
            string[i] = '#';
        }
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Pesan Standar Notifikasi Server
// -----------------------------------------------------------------------------
stock SendErrorMessage(playerid, const message[])
{
    new str[144];
    format(str, sizeof(str), "{FF4D4D}[ERROR] {FFFFFF}%s", message);
    return SendClientMessage(playerid, COLOR_ERROR, str);
}

stock SendSuccessMessage(playerid, const message[])
{
    new str[144];
    format(str, sizeof(str), "{2EC4B6}[SUCCESS] {FFFFFF}%s", message);
    return SendClientMessage(playerid, COLOR_SUCCESS, str);
}

stock SendInfoMessage(playerid, const message[])
{
    new str[144];
    format(str, sizeof(str), "{00AAFF}[INFO] {FFFFFF}%s", message);
    return SendClientMessage(playerid, COLOR_INFO, str);
}

stock SendUsageMessage(playerid, const usage[])
{
    new str[144];
    format(str, sizeof(str), "{FFD166}[PETUNJUK] {FFFFFF}Gunakan: %s", usage);
    return SendClientMessage(playerid, COLOR_WARNING, str);
}
