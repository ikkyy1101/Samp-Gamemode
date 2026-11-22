/**
 * File: gamemodes/modules/admin/levels.inc
 * Modul: Admin Hierarchy, PIN Authentication (/alogin), Duty Mode (/aduty) & Staff Chat (/a)
 * Deskripsi: Mengelola tingkatan level staff (1-7), verifikasi PIN keamanan admin,
 *            mode tugas admin (/aduty dengan kebal damage & label), broadcast pesan
 *            internal staff, serta logging tindakan admin ke database.
 * Dependensi: <open.mp>, <a_mysql>, <samp_bcrypt>, <streamer>, <Pawn.CMD>,
 *             <YSI_Coding\y_hooks>, <YSI_Coding\y_iterate>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/account/security.inc
 */

#if defined _INC_ADMIN_LEVELS
    #endinput
#endif
#define _INC_ADMIN_LEVELS

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA ADMIN & PIN
// ============================================================================
#define ADMIN_MIN_PIN_LEN           (4)
#define ADMIN_MAX_PIN_LEN           (12)
#define COLOR_ADMIN_CHAT            (0x2EC4B6FF)
#define COLOR_ADMIN_ALERT           (0xFF6B6BFF)
#define COLOR_ADMIN_DUTY            (0xFF4D4DFF)

// ============================================================================
// FUNGSI PUBLIK HAK AKSES & UTILITAS ADMIN (ADMIN_*)
// ============================================================================

/**
 * Mengembalikan nama pangkat staff berdasarkan tingkat level.
 */
stock Admin_GetRankName(level, output[], len = sizeof(output))
{
    switch (level)
    {
        case ADMIN_LEVEL_TRIAL_HELPER:  format(output, len, "Trial Helper");
        case ADMIN_LEVEL_HELPER:        format(output, len, "Helper");
        case ADMIN_LEVEL_MODERATOR:     format(output, len, "Moderator");
        case ADMIN_LEVEL_ADMIN:         format(output, len, "Admin");
        case ADMIN_LEVEL_SENIOR:        format(output, len, "Senior Admin");
        case ADMIN_LEVEL_LEAD:          format(output, len, "Lead Admin");
        case ADMIN_LEVEL_OWNER:         format(output, len, "Developer / Owner");
        default:                        format(output, len, "Warga");
    }
    return 1;
}

/**
 * Mengembalikan level efektif staff (mengambil nilai tertinggi antara admin_level & helper_level).
 */
stock Admin_GetEffectiveLevel(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }
    return (PlayerData[playerid][pAdminLevel] >= PlayerData[playerid][pHelperLevel])
        ? PlayerData[playerid][pAdminLevel]
        : PlayerData[playerid][pHelperLevel];
}

/**
 * Memeriksa apakah pemain memenuhi syarat level staff dan sudah melakukan /alogin.
 */
stock bool:Admin_HasAccess(playerid, requiredLevel, bool:requireAlogin = true)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return false;
    }

    new effLevel = Admin_GetEffectiveLevel(playerid);
    if (effLevel < requiredLevel)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak memiliki izin untuk menggunakan perintah ini!");
        return false;
    }

    if (requireAlogin && !PlayerData[playerid][pAdminLoggedIn])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus masuk ke mode staff menggunakan /alogin terlebih dahulu!");
        return false;
    }
    return true;
}

/**
 * Memastikan admin tidak menindak staff lain yang memiliki level sama atau lebih tinggi.
 */
stock bool:Admin_CanTarget(playerid, targetid)
{
    if (!IsPlayerConnected(targetid))
    {
        return false;
    }

    if (playerid == targetid)
    {
        return true;
    }

    new
        actorLevel = Admin_GetEffectiveLevel(playerid),
        targetLevel = Admin_GetEffectiveLevel(targetid);

    if (targetLevel >= actorLevel && actorLevel < ADMIN_LEVEL_OWNER)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat menindak staff dengan tingkat yang sama atau lebih tinggi!");
        return false;
    }
    return true;
}

/**
 * Mengirimkan pesan ke seluruh staff yang sedang online.
 */
stock Admin_SendStaffMessage(color, const message[])
{
    foreach (new i : OnlineStaff)
    {
        SendClientMessage(i, color, "%s", message);
    }
    return 1;
}

/**
 * Mencatat setiap tindakan admin ke dalam tabel `logs` (type = 'admin').
 */
stock Admin_LogAction(playerid, targetid, const actionMessage[])
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
            "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('admin', %d, %d, '%e', '%e')",
            charId,
            targetCharId,
            actionMessage,
            PlayerData[playerid][pCurrentIP]
        );
    }
    else if (charId > 0)
    {
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('admin', %d, NULL, '%e', '%e')",
            charId,
            actionMessage,
            PlayerData[playerid][pCurrentIP]
        );
    }
    else
    {
        new ipStr[46];
        if (IsPlayerConnected(playerid))
        {
            format(ipStr, sizeof(ipStr), "%s", PlayerData[playerid][pCurrentIP]);
        }
        else
        {
            format(ipStr, sizeof(ipStr), "0.0.0.0");
        }

        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('admin', NULL, NULL, '%e', '%e')",
            actionMessage,
            ipStr
        );
    }

    mysql_tquery(g_SQL, query);
    return 1;
}

// ============================================================================
// PERINTAH STAFF DASAR (/alogin, /aduty, /a, /admins)
// ============================================================================
CMD:alogin(playerid, params[])
{
    #pragma unused params
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, false))
    {
        return 1;
    }

    if (PlayerData[playerid][pAdminLoggedIn])
    {
        SendClientMessage(playerid, COLOR_INFO, "Anda sudah masuk ke sesi staff.");
        return 1;
    }

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[256];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT COALESCE(`admin_pin_hash`, '') AS `pin_hash` FROM `accounts` WHERE `id` = %d LIMIT 1",
        PlayerData[playerid][pAccountID]
    );
    mysql_tquery(g_SQL, query, "OnAdminPinLookupResult", "ii", playerid, racecheck);
    return 1;
}

CMD:aduty(playerid, params[])
{
    #pragma unused params
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, true))
    {
        return 1;
    }

    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus spawn ke dunia permainan terlebih dahulu!");
        return 1;
    }

    PlayerData[playerid][pAdminDuty] = !PlayerData[playerid][pAdminDuty];

    new
        rankName[32],
        rpName[MAX_PLAYER_NAME],
        notice[160];

    Admin_GetRankName(Admin_GetEffectiveLevel(playerid), rankName, sizeof(rankName));
    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));

    if (PlayerData[playerid][pAdminDuty])
    {
        SetPlayerColor(playerid, COLOR_ADMIN_DUTY);
        SetPlayerHealth(playerid, 100.0);
        SetPlayerArmour(playerid, 100.0);

        if (IsValidDynamic3DTextLabel(PlayerData[playerid][pAdminDutyLabel]))
        {
            DestroyDynamic3DTextLabel(PlayerData[playerid][pAdminDutyLabel]);
        }

        new labelText[96];
        format(labelText, sizeof(labelText), "{FF4D4D}[ON-DUTY %s]\n{FFFFFF}%s (OOC Mode)", rankName, PlayerData[playerid][pUsername]);
        PlayerData[playerid][pAdminDutyLabel] = CreateDynamic3DTextLabel(
            labelText,
            COLOR_ADMIN_DUTY,
            0.0, 0.0, 0.35,
            25.0,
            playerid,
            INVALID_VEHICLE_ID,
            1
        );

        format(notice, sizeof(notice), "[Staff Duty] %s %s (%s) sekarang ON-DUTY.", rankName, PlayerData[playerid][pUsername], rpName);
        Admin_SendStaffMessage(COLOR_ADMIN_CHAT, notice);
        SendClientMessage(playerid, COLOR_SUCCESS, "Anda sekarang berada dalam mode Admin Duty (Kebal damage & nama merah).");
    }
    else
    {
        SetPlayerColor(playerid, 0xFFFFFF00);

        if (IsValidDynamic3DTextLabel(PlayerData[playerid][pAdminDutyLabel]))
        {
            DestroyDynamic3DTextLabel(PlayerData[playerid][pAdminDutyLabel]);
            PlayerData[playerid][pAdminDutyLabel] = Text3D:INVALID_3DTEXT_ID;
        }

        format(notice, sizeof(notice), "[Staff Duty] %s %s (%s) sekarang OFF-DUTY.", rankName, PlayerData[playerid][pUsername], rpName);
        Admin_SendStaffMessage(COLOR_ADMIN_CHAT, notice);
        SendClientMessage(playerid, COLOR_INFO, "Anda keluar dari mode Admin Duty dan kembali ke mode Roleplay.");
    }
    return 1;
}
alias:aduty("adminduty", "sduty")

CMD:a(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, false))
    {
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /a [pesan chat internal staff]");
        return 1;
    }

    new cleanText[144];
    format(cleanText, sizeof(cleanText), "%s", params);
    SanitizeString(cleanText);

    new
        rankName[32],
        formatted[220];

    Admin_GetRankName(Admin_GetEffectiveLevel(playerid), rankName, sizeof(rankName));
    format(formatted, sizeof(formatted), "[Staff Chat | %s] %s (%d): %s", rankName, PlayerData[playerid][pUsername], playerid, cleanText);

    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, formatted);
    return 1;
}
alias:a("adminchat", "sc")

CMD:admins(playerid, params[])
{
    #pragma unused params
    if (!PlayerData[playerid][pAccountLoaded])
    {
        return 1;
    }

    new
        count = 0,
        rankName[32],
        line[128];

    SendClientMessage(playerid, COLOR_PRIMARY, "=== Daftar Staff & Admin PARADISE Roleplay Online ===");
    foreach (new i : OnlineStaff)
    {
        Admin_GetRankName(Admin_GetEffectiveLevel(i), rankName, sizeof(rankName));
        format(
            line,
            sizeof(line),
            "- [%s] %s (ID: %d) | Status: %s",
            rankName,
            PlayerData[i][pUsername],
            i,
            PlayerData[i][pAdminDuty] ? ("{FF4D4D}On-Duty") : ("{2EC4B6}Roleplay")
        );
        SendClientMessage(playerid, COLOR_INFO, "%s", line);
        count++;
    }

    if (count == 0)
    {
        SendClientMessage(playerid, COLOR_WARNING, "Saat ini tidak ada staff yang sedang online.");
    }
    return 1;
}
alias:admins("staff", "helpers")

// ============================================================================
// CALLBACKS & DIALOG RESPONSE PIN ADMIN
// ============================================================================
forward OnAdminPinLookupResult(playerid, racecheck);
public OnAdminPinLookupResult(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (cache_num_rows() == 0)
    {
        return 1;
    }

    cache_get_value_name(0, "pin_hash", PlayerData[playerid][pAdminPinHash], 128);

    if (PlayerData[playerid][pAdminPinHash][0] == EOS)
    {
        ShowPlayerDialog(
            playerid,
            DIALOG_ADMIN_PIN_SETUP,
            DIALOG_STYLE_PASSWORD,
            "{00D4FF}Buat PIN Keamanan Staff",
            "{FFFFFF}Akun staff Anda belum memiliki PIN keamanan.\n\
            Masukkan PIN baru ({FFD166}4 - 12 karakter{FFFFFF}) untuk melindungi perintah admin:",
            "Simpan",
            "Batal"
        );
    }
    else
    {
        ShowPlayerDialog(
            playerid,
            DIALOG_ADMIN_PIN_LOGIN,
            DIALOG_STYLE_PASSWORD,
            "{00D4FF}Verifikasi PIN Staff (/alogin)",
            "{FFFFFF}Masukkan PIN keamanan staff Anda untuk mengaktifkan akses admin:",
            "Masuk",
            "Batal"
        );
    }
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused listitem

    switch (dialogid)
    {
        case DIALOG_ADMIN_PIN_SETUP:
        {
            if (!response)
            {
                return 1;
            }

            new len = strlen(inputtext);
            if (len < ADMIN_MIN_PIN_LEN || len > ADMIN_MAX_PIN_LEN)
            {
                SendClientMessage(playerid, COLOR_ERROR, "Panjang PIN staff harus antara 4 hingga 12 karakter!");
                return 1;
            }

            new racecheck = Database_GetPlayerRaceCheck(playerid);
            SendClientMessage(playerid, COLOR_INFO, "Mengenkripsi PIN staff Anda...");
            bcrypt_hash(playerid, "OnAdminPinHashed", inputtext, ACCOUNT_BCRYPT_COST, "i", racecheck);
            return 1;
        }

        case DIALOG_ADMIN_PIN_LOGIN:
        {
            if (!response)
            {
                return 1;
            }

            if (strlen(inputtext) == 0)
            {
                SendClientMessage(playerid, COLOR_ERROR, "PIN tidak boleh kosong!");
                return 1;
            }

            bcrypt_verify(playerid, "OnAdminPinVerified", inputtext, PlayerData[playerid][pAdminPinHash]);
            return 1;
        }
    }
    return 0;
}

forward OnAdminPinHashed(playerid, racecheck);
public OnAdminPinHashed(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    new
        pinHash[128],
        query[320],
        rankName[32],
        notice[160];

    bcrypt_get_hash(pinHash, sizeof(pinHash));
    format(PlayerData[playerid][pAdminPinHash], 128, "%s", pinHash);
    PlayerData[playerid][pAdminLoggedIn] = true;

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "UPDATE `accounts` SET `admin_pin_hash` = '%e' WHERE `id` = %d",
        pinHash,
        PlayerData[playerid][pAccountID]
    );
    mysql_tquery(g_SQL, query);

    Admin_GetRankName(Admin_GetEffectiveLevel(playerid), rankName, sizeof(rankName));
    format(notice, sizeof(notice), "[Staff Login] %s %s telah mengatur PIN dan masuk ke sesi staff.", rankName, PlayerData[playerid][pUsername]);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, notice);
    Admin_LogAction(playerid, INVALID_PLAYER_ID, notice);

    SendClientMessage(playerid, COLOR_SUCCESS, "PIN staff berhasil dibuat dan akses admin Anda telah aktif!");
    return 1;
}

forward OnAdminPinVerified(playerid, bool:success);
public OnAdminPinVerified(playerid, bool:success)
{
    if (!IsPlayerConnected(playerid) || Admin_GetEffectiveLevel(playerid) < ADMIN_LEVEL_TRIAL_HELPER)
    {
        return 0;
    }

    if (!success)
    {
        new logMsg[160];
        format(logMsg, sizeof(logMsg), "Percobaan /alogin gagal (PIN salah) oleh %s", PlayerData[playerid][pUsername]);
        Admin_LogAction(playerid, INVALID_PLAYER_ID, logMsg);

        SendClientMessage(playerid, COLOR_ERROR, "PIN staff yang Anda masukkan salah!");
        return 1;
    }

    PlayerData[playerid][pAdminLoggedIn] = true;

    new
        rankName[32],
        notice[160];

    Admin_GetRankName(Admin_GetEffectiveLevel(playerid), rankName, sizeof(rankName));
    format(notice, sizeof(notice), "[Staff Login] %s %s telah masuk ke sesi staff.", rankName, PlayerData[playerid][pUsername]);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, notice);
    Admin_LogAction(playerid, INVALID_PLAYER_ID, notice);

    SendClientMessage(playerid, COLOR_SUCCESS, "Verifikasi berhasil! Seluruh perintah staff sesuai level Anda telah aktif.");
    return 1;
}

// ============================================================================
// HOOKS SINKRONISASI ITERATOR STAFF & ANTI-DAMAGE SAAT ON-DUTY
// ============================================================================
hook OnPlayerSpawn(playerid)
{
    if (Admin_GetEffectiveLevel(playerid) >= ADMIN_LEVEL_TRIAL_HELPER)
    {
        Iter_Add(OnlineStaff, playerid);
    }
    return 1;
}

hook OnPlayerTakeDamage(playerid, issuerid, Float:amount, WEAPON:weaponid, bodypart)
{
    #pragma unused amount, weaponid, bodypart

    // Admin On-Duty kebal terhadap damage
    if (IsPlayerConnected(playerid) && PlayerData[playerid][pAdminDuty])
    {
        SetPlayerHealth(playerid, 100.0);
        SetPlayerArmour(playerid, 100.0);
        return 1;
    }

    // Admin On-Duty tidak boleh melukai pemain lain
    if (issuerid != INVALID_PLAYER_ID && IsPlayerConnected(issuerid) && PlayerData[issuerid][pAdminDuty])
    {
        SendClientMessage(issuerid, COLOR_WARNING, "[Admin Duty] Anda tidak dapat melukai warga saat sedang dalam mode tugas admin!");
        return 1;
    }
    return 0;
}
