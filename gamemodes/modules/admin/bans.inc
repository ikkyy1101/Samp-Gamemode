/**
 * File: gamemodes/modules/admin/bans.inc
 * Modul: Admin Ban System (/ban, /oban, /unban)
 * Deskripsi: Menangani pemblokiran pemain secara online (sementara maupun permanen),
 *            pemblokiran akun secara offline (/oban), serta pencabutan ban (/unban).
 * Dependensi: <open.mp>, <a_mysql>, <Pawn.CMD>, <sscanf2>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/admin/levels.inc
 */

#if defined _INC_ADMIN_BANS
    #endinput
#endif
#define _INC_ADMIN_BANS

#include <YSI_Coding\y_hooks>

// ============================================================================
// PERINTAH BAN ONLINE (/ban)
// ============================================================================
CMD:ban(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_MODERATOR, true))
    {
        return 1;
    }

    new
        targetid,
        days,
        reason[128];

    if (sscanf(params, "uis[128]", targetid, days, reason))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /ban [ID/Nama Pemain] [hari (0 = Permanen)] [alasan]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || !PlayerData[targetid][pAccountLoaded] || !Admin_CanTarget(playerid, targetid))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Target tidak valid atau tidak dapat diblokir!");
        return 1;
    }

    if (days < 0 || days > 3650)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Durasi ban harus 0 (Permanen) hingga 3650 hari!");
        return 1;
    }

    SanitizeString(reason);

    new
        query[640],
        durationStr[32],
        announceMsg[220];

    if (days == 0)
    {
        format(durationStr, sizeof(durationStr), "Permanen");
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `bans` (`account_id`, `ip`, `serial`, `admin_id`, `admin_name`, `reason`, `active`, `expire_at`) \
             VALUES (%d, '%e', '%e', %d, '%e', '%e', 1, NULL)",
            PlayerData[targetid][pAccountID],
            PlayerData[targetid][pCurrentIP],
            PlayerData[targetid][pGPCI],
            PlayerData[playerid][pAccountID],
            PlayerData[playerid][pUsername],
            reason
        );
    }
    else
    {
        format(durationStr, sizeof(durationStr), "%d hari", days);
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `bans` (`account_id`, `ip`, `serial`, `admin_id`, `admin_name`, `reason`, `active`, `expire_at`) \
             VALUES (%d, '%e', '%e', %d, '%e', '%e', 1, DATE_ADD(NOW(), INTERVAL %d DAY))",
            PlayerData[targetid][pAccountID],
            PlayerData[targetid][pCurrentIP],
            PlayerData[targetid][pGPCI],
            PlayerData[playerid][pAccountID],
            PlayerData[playerid][pUsername],
            reason,
            days
        );
    }
    mysql_tquery(g_SQL, query);

    if (days == 0)
    {
        mysql_format(g_SQL, query, sizeof(query), "UPDATE `accounts` SET `banned` = 1 WHERE `id` = %d", PlayerData[targetid][pAccountID]);
        mysql_tquery(g_SQL, query);
    }

    format(
        announceMsg,
        sizeof(announceMsg),
        "[AdminCmd] %s (Akun: %s) diblokir (%s) oleh %s. Alasan: %s",
        PlayerData[targetid][pCharName][0] != EOS ? PlayerData[targetid][pCharName] : PlayerData[targetid][pUsername],
        PlayerData[targetid][pUsername],
        durationStr,
        PlayerData[playerid][pUsername],
        reason
    );

    SendClientMessageToAll(COLOR_ADMIN_ALERT, "%s", announceMsg);
    Admin_LogAction(playerid, targetid, announceMsg);
    DelayedKick(targetid, 500);
    return 1;
}

// ============================================================================
// PERINTAH OFFLINE BAN (/oban)
// ============================================================================
CMD:oban(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    new
        targetName[MAX_PLAYER_NAME],
        days,
        reason[128];

    if (sscanf(params, "s[24]is[128]", targetName, days, reason))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /oban [Nama_Akun_atau_Karakter] [hari (0 = Permanen)] [alasan]");
        return 1;
    }

    if (days < 0 || days > 3650)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Durasi ban harus 0 (Permanen) hingga 3650 hari!");
        return 1;
    }

    SanitizeString(reason);

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[512];

    // Cari akun berdasarkan username langsung atau lewat nama karakter
    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT a.`id`, a.`username`, a.`last_ip`, a.`gpci`, a.`admin_level`, a.`helper_level` \
         FROM `accounts` a \
         LEFT JOIN `characters` c ON c.`account_id` = a.`id` \
         WHERE a.`username` = '%e' OR c.`name` = '%e' \
         LIMIT 1",
        targetName,
        targetName
    );
    mysql_tquery(g_SQL, query, "OnAdminOfflineBanLookup", "iiis", playerid, racecheck, days, reason);
    return 1;
}

forward OnAdminOfflineBanLookup(playerid, racecheck, days, const reason[]);
public OnAdminOfflineBanLookup(playerid, racecheck, days, const reason[])
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (cache_num_rows() == 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Akun atau karakter dengan nama tersebut tidak ditemukan di database!");
        return 1;
    }

    new
        accId,
        accUser[MAX_PLAYER_NAME],
        lastIp[46],
        serial[64],
        targetAdmLv,
        targetHlpLv;

    cache_get_value_name_int(0, "id", accId);
    cache_get_value_name(0, "username", accUser, sizeof(accUser));
    cache_get_value_name(0, "last_ip", lastIp, sizeof(lastIp));
    cache_get_value_name(0, "gpci", serial, sizeof(serial));
    cache_get_value_name_int(0, "admin_level", targetAdmLv);
    cache_get_value_name_int(0, "helper_level", targetHlpLv);

    new targetEff = (targetAdmLv >= targetHlpLv) ? targetAdmLv : targetHlpLv;
    if (targetEff >= Admin_GetEffectiveLevel(playerid) && Admin_GetEffectiveLevel(playerid) < ADMIN_LEVEL_OWNER)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat memblokir akun staff dengan level sama atau lebih tinggi!");
        return 1;
    }

    new query[640], announceMsg[220];
    if (days == 0)
    {
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `bans` (`account_id`, `ip`, `serial`, `admin_id`, `admin_name`, `reason`, `active`, `expire_at`) \
             VALUES (%d, '%e', '%e', %d, '%e', '%e', 1, NULL)",
            accId,
            lastIp,
            serial,
            PlayerData[playerid][pAccountID],
            PlayerData[playerid][pUsername],
            reason
        );
        mysql_tquery(g_SQL, query);

        mysql_format(g_SQL, query, sizeof(query), "UPDATE `accounts` SET `banned` = 1 WHERE `id` = %d", accId);
        mysql_tquery(g_SQL, query);
    }
    else
    {
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `bans` (`account_id`, `ip`, `serial`, `admin_id`, `admin_name`, `reason`, `active`, `expire_at`) \
             VALUES (%d, '%e', '%e', %d, '%e', '%e', 1, DATE_ADD(NOW(), INTERVAL %d DAY))",
            accId,
            lastIp,
            serial,
            PlayerData[playerid][pAccountID],
            PlayerData[playerid][pUsername],
            reason,
            days
        );
        mysql_tquery(g_SQL, query);
    }

    format(
        announceMsg,
        sizeof(announceMsg),
        "[AdminCmd] Akun %s (#%d) diblokir secara offline (%s) oleh %s. Alasan: %s",
        accUser,
        accId,
        (days == 0) ? ("Permanen") : ("Sementara"),
        PlayerData[playerid][pUsername],
        reason
    );
    SendClientMessageToAll(COLOR_ADMIN_ALERT, "%s", announceMsg);
    Admin_LogAction(playerid, INVALID_PLAYER_ID, announceMsg);
    return 1;
}

// ============================================================================
// PERINTAH CABUT BAN (/unban)
// ============================================================================
CMD:unban(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_ADMIN, true))
    {
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /unban [Username_Akun atau Alamat_IP]");
        return 1;
    }

    new cleanTarget[48], query[384], logMsg[160];
    format(cleanTarget, sizeof(cleanTarget), "%s", params);
    SanitizeString(cleanTarget);

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "UPDATE `bans` b \
         LEFT JOIN `accounts` a ON a.`id` = b.`account_id` \
         SET b.`active` = 0, a.`banned` = 0 \
         WHERE b.`active` = 1 AND (b.`ip` = '%e' OR a.`username` = '%e')",
        cleanTarget,
        cleanTarget
    );
    mysql_tquery(g_SQL, query);

    format(logMsg, sizeof(logMsg), "[AdminCmd] %s mencabut status ban untuk target '%s'.", PlayerData[playerid][pUsername], cleanTarget);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, logMsg);
    Admin_LogAction(playerid, INVALID_PLAYER_ID, logMsg);
    return 1;
}
