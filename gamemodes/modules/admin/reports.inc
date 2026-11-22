/**
 * File: gamemodes/modules/admin/reports.inc
 * Modul: Player Report & Help Ask System (/report, /ask, /reports, /ar, /tr, /answer)
 * Deskripsi: Mengelola antrean laporan pelanggaran dan pertanyaan warga secara
 *            real-time di memori serta sinkronisasi ke tabel `reports` database.
 * Dependensi: <open.mp>, <a_mysql>, <Pawn.CMD>, <sscanf2>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/admin/levels.inc
 */

#if defined _INC_ADMIN_REPORTS
    #endinput
#endif
#define _INC_ADMIN_REPORTS

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA REPORT & ASK
// ============================================================================
#define REPORT_COOLDOWN_SEC         (45)
#define REPORT_TYPE_VIOLATION       (1)
#define REPORT_TYPE_ASK             (2)

static s_LastReportTime[MAX_PLAYERS];

// ============================================================================
// FUNGSI INTERNAL MANAJEMEN ANTREAN REPORT
// ============================================================================
static Report_FindFreeSlot()
{
    for (new i = 0; i < MAX_ACTIVE_REPORTS; i++)
    {
        if (!ReportData[i][repActive])
        {
            return i;
        }
    }
    return -1;
}

static bool:Report_PlayerHasActiveTicket(playerid, type)
{
    for (new i = 0; i < MAX_ACTIVE_REPORTS; i++)
    {
        if (ReportData[i][repActive] && ReportData[i][repReporterID] == playerid && ReportData[i][repType] == type)
        {
            return true;
        }
    }
    return false;
}

static Report_ClearSlot(slot)
{
    if (slot < 0 || slot >= MAX_ACTIVE_REPORTS)
    {
        return 0;
    }

    static const emptyReport[E_REPORT_DATA];
    ReportData[slot] = emptyReport;
    ReportData[slot][repActive] = false;
    ReportData[slot][repReporterID] = INVALID_PLAYER_ID;
    ReportData[slot][repReportedID] = INVALID_PLAYER_ID;
    ReportData[slot][repHandledByID] = INVALID_PLAYER_ID;
    return 1;
}

// ============================================================================
// PERINTAH WARGA (/report & /ask)
// ============================================================================
CMD:report(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    if (Report_PlayerHasActiveTicket(playerid, REPORT_TYPE_VIOLATION))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda masih memiliki laporan pelanggaran yang sedang menunggu ditangani staff!");
        return 1;
    }

    if ((gettime() - s_LastReportTime[playerid]) < REPORT_COOLDOWN_SEC)
    {
        SendClientMessage(playerid, COLOR_WARNING, "Tunggu 45 detik sebelum mengirim laporan berikutnya.");
        return 1;
    }

    new
        targetid,
        reason[128];

    if (sscanf(params, "us[128]", targetid, reason))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /report [ID/Nama Terlapor] [detail pelanggaran]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain yang dilaporkan tidak ditemukan!");
        return 1;
    }

    new slot = Report_FindFreeSlot();
    if (slot == -1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Antrean laporan sedang penuh! Coba beberapa saat lagi.");
        return 1;
    }

    SanitizeString(reason);
    s_LastReportTime[playerid] = gettime();

    ReportData[slot][repActive] = true;
    ReportData[slot][repType] = REPORT_TYPE_VIOLATION;
    ReportData[slot][repReporterID] = playerid;
    ReportData[slot][repReporterCharID] = PlayerData[playerid][pCharacterID];
    format(ReportData[slot][repReporterName], MAX_PLAYER_NAME, "%s", PlayerData[playerid][pCharName]);
    ReportData[slot][repReportedID] = targetid;
    format(ReportData[slot][repMessage], 160, "%s", reason);
    ReportData[slot][repHandledByID] = INVALID_PLAYER_ID;
    ReportData[slot][repTimestamp] = gettime();

    if (Database_IsConnected())
    {
        new query[512];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `reports` (`reporter_char_id`, `reported_char_id`, `category`, `message`, `status`) \
             VALUES (%d, %d, 'report', '%e', 'open')",
            PlayerData[playerid][pCharacterID],
            PlayerData[targetid][pCharacterID],
            reason
        );
        mysql_tquery(g_SQL, query, "OnReportInserted", "i", slot);
    }

    new staffNotice[220];
    format(
        staffNotice,
        sizeof(staffNotice),
        "[REPORT #%d] Pelapor: %s (ID %d) -> Terlapor: %s (ID %d) | Alasan: %s (/ar %d | /tr %d)",
        slot,
        PlayerData[playerid][pCharName],
        playerid,
        PlayerData[targetid][pCharName],
        targetid,
        reason,
        slot,
        slot
    );
    Admin_SendStaffMessage(COLOR_ADMIN_ALERT, staffNotice);
    SendClientMessage(playerid, COLOR_SUCCESS, "Laporan Anda (#%d) telah dikirim ke staff yang bertugas.", slot);
    return 1;
}

CMD:ask(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    if (Report_PlayerHasActiveTicket(playerid, REPORT_TYPE_ASK))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda masih memiliki pertanyaan (/ask) yang belum dijawab!");
        return 1;
    }

    if ((gettime() - s_LastReportTime[playerid]) < REPORT_COOLDOWN_SEC)
    {
        SendClientMessage(playerid, COLOR_WARNING, "Tunggu 45 detik sebelum mengirim pertanyaan berikutnya.");
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /ask [pertanyaan seputar gameplay/aturan server]");
        return 1;
    }

    new slot = Report_FindFreeSlot();
    if (slot == -1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Antrean bantuan sedang penuh! Coba beberapa saat lagi.");
        return 1;
    }

    new cleanQuestion[144];
    format(cleanQuestion, sizeof(cleanQuestion), "%s", params);
    SanitizeString(cleanQuestion);
    s_LastReportTime[playerid] = gettime();

    ReportData[slot][repActive] = true;
    ReportData[slot][repType] = REPORT_TYPE_ASK;
    ReportData[slot][repReporterID] = playerid;
    ReportData[slot][repReporterCharID] = PlayerData[playerid][pCharacterID];
    format(ReportData[slot][repReporterName], MAX_PLAYER_NAME, "%s", PlayerData[playerid][pCharName]);
    ReportData[slot][repReportedID] = INVALID_PLAYER_ID;
    format(ReportData[slot][repMessage], 160, "%s", cleanQuestion);
    ReportData[slot][repHandledByID] = INVALID_PLAYER_ID;
    ReportData[slot][repTimestamp] = gettime();

    if (Database_IsConnected())
    {
        new query[512];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `reports` (`reporter_char_id`, `reported_char_id`, `category`, `message`, `status`) \
             VALUES (%d, NULL, 'ask', '%e', 'open')",
            PlayerData[playerid][pCharacterID],
            cleanQuestion
        );
        mysql_tquery(g_SQL, query, "OnReportInserted", "i", slot);
    }

    new staffNotice[220];
    format(
        staffNotice,
        sizeof(staffNotice),
        "[ASK #%d] Dari %s (ID %d): %s (Gunakan /answer %d [jawaban])",
        slot,
        PlayerData[playerid][pCharName],
        playerid,
        cleanQuestion,
        slot
    );
    Admin_SendStaffMessage(0xFFD166FF, staffNotice);
    SendClientMessage(playerid, COLOR_SUCCESS, "Pertanyaan Anda (#%d) telah diteruskan ke Helper/Admin.", slot);
    return 1;
}

forward OnReportInserted(slot);
public OnReportInserted(slot)
{
    if (slot >= 0 && slot < MAX_ACTIVE_REPORTS && ReportData[slot][repActive])
    {
        ReportData[slot][repDBID] = cache_insert_id();
    }
    return 1;
}

// ============================================================================
// PERINTAH STAFF PENANGANAN REPORT & ASK (/reports, /ar, /tr, /answer)
// ============================================================================
CMD:reports(playerid, params[])
{
    #pragma unused params
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, false))
    {
        return 1;
    }

    new
        count = 0,
        dialogBody[1536],
        line[180];

    format(dialogBody, sizeof(dialogBody), "Slot & Kategori\tPengirim\tIsi Laporan / Pertanyaan\n");

    for (new i = 0; i < MAX_ACTIVE_REPORTS; i++)
    {
        if (!ReportData[i][repActive])
        {
            continue;
        }

        format(
            line,
            sizeof(line),
            "#%d [%s]\t%s (ID %d)\t%s\n",
            i,
            (ReportData[i][repType] == REPORT_TYPE_VIOLATION) ? ("{FF4D4D}REPORT") : ("{FFD166}ASK"),
            ReportData[i][repReporterName],
            ReportData[i][repReporterID],
            ReportData[i][repMessage]
        );
        strcat(dialogBody, line);
        count++;
    }

    if (count == 0)
    {
        SendClientMessage(playerid, COLOR_INFO, "Tidak ada antrean /report maupun /ask yang aktif saat ini.");
        return 1;
    }

    ShowPlayerDialog(playerid, DIALOG_ADMIN_REPORTS_LIST, DIALOG_STYLE_TABLIST_HEADERS, "{00D4FF}Antrean Report & Ask Aktif", dialogBody, "Tutup", "");
    return 1;
}

CMD:ar(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, true))
    {
        return 1;
    }

    new slot;
    if (sscanf(params, "i", slot) || slot < 0 || slot >= MAX_ACTIVE_REPORTS || !ReportData[slot][repActive])
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /ar [Nomor Slot Report] (Cek daftar di /reports)");
        return 1;
    }

    new
        reporterid = ReportData[slot][repReporterID],
        dbId = ReportData[slot][repDBID],
        staffNotice[160];

    if (IsPlayerConnected(reporterid))
    {
        SendClientMessage(reporterid, COLOR_SUCCESS, "[Report] Laporan Anda (#%d) telah diterima dan sedang ditangani oleh staff %s.", slot, PlayerData[playerid][pUsername]);
    }

    format(staffNotice, sizeof(staffNotice), "[Report] %s menerima dan menutup tiket #%d (%s).", PlayerData[playerid][pUsername], slot, ReportData[slot][repReporterName]);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, staffNotice);

    if (Database_IsConnected() && dbId > 0)
    {
        new query[220];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "UPDATE `reports` SET `status` = 'accepted', `handled_by_account_id` = %d, `closed_at` = NOW() WHERE `id` = %d",
            PlayerData[playerid][pAccountID],
            dbId
        );
        mysql_tquery(g_SQL, query);
    }

    Report_ClearSlot(slot);
    return 1;
}
alias:ar("acceptreport")

CMD:tr(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, true))
    {
        return 1;
    }

    new slot;
    if (sscanf(params, "i", slot) || slot < 0 || slot >= MAX_ACTIVE_REPORTS || !ReportData[slot][repActive])
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /tr [Nomor Slot Report] (Cek daftar di /reports)");
        return 1;
    }

    new
        reporterid = ReportData[slot][repReporterID],
        dbId = ReportData[slot][repDBID],
        staffNotice[160];

    if (IsPlayerConnected(reporterid))
    {
        SendClientMessage(reporterid, COLOR_WARNING, "[Report] Laporan/pertanyaan Anda (#%d) ditutup oleh staff %s.", slot, PlayerData[playerid][pUsername]);
    }

    format(staffNotice, sizeof(staffNotice), "[Report] %s menutup/menolak tiket #%d (%s).", PlayerData[playerid][pUsername], slot, ReportData[slot][repReporterName]);
    Admin_SendStaffMessage(COLOR_ADMIN_CHAT, staffNotice);

    if (Database_IsConnected() && dbId > 0)
    {
        new query[220];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "UPDATE `reports` SET `status` = 'closed', `handled_by_account_id` = %d, `closed_at` = NOW() WHERE `id` = %d",
            PlayerData[playerid][pAccountID],
            dbId
        );
        mysql_tquery(g_SQL, query);
    }

    Report_ClearSlot(slot);
    return 1;
}
alias:tr("trashreport", "closereport")

CMD:answer(playerid, params[])
{
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_TRIAL_HELPER, false))
    {
        return 1;
    }

    new
        slot,
        replyText[144];

    if (sscanf(params, "is[144]", slot, replyText))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /answer [Nomor Slot Ask] [jawaban]");
        return 1;
    }

    if (slot < 0 || slot >= MAX_ACTIVE_REPORTS || !ReportData[slot][repActive] || ReportData[slot][repType] != REPORT_TYPE_ASK)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Nomor slot /ask tidak valid atau sudah dijawab!");
        return 1;
    }

    SanitizeString(replyText);

    new
        reporterid = ReportData[slot][repReporterID],
        dbId = ReportData[slot][repDBID],
        staffNotice[220],
        playerReply[220];

    if (IsPlayerConnected(reporterid))
    {
        format(playerReply, sizeof(playerReply), "[Jawaban Staff %s]: %s", PlayerData[playerid][pUsername], replyText);
        SendClientMessage(reporterid, COLOR_SUCCESS, "%s", playerReply);
    }

    format(staffNotice, sizeof(staffNotice), "[ASK #%d Dijawab] %s -> %s: %s", slot, PlayerData[playerid][pUsername], ReportData[slot][repReporterName], replyText);
    Admin_SendStaffMessage(0xFFD166FF, staffNotice);

    if (Database_IsConnected() && dbId > 0)
    {
        new query[220];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "UPDATE `reports` SET `status` = 'accepted', `handled_by_account_id` = %d, `closed_at` = NOW() WHERE `id` = %d",
            PlayerData[playerid][pAccountID],
            dbId
        );
        mysql_tquery(g_SQL, query);
    }

    Report_ClearSlot(slot);
    return 1;
}
alias:answer("ans")

// ============================================================================
// HOOK PEMBERSIHAN TIKET SAAT PENGIRIM DISCONNECT
// ============================================================================
hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    s_LastReportTime[playerid] = 0;

    for (new i = 0; i < MAX_ACTIVE_REPORTS; i++)
    {
        if (ReportData[i][repActive] && ReportData[i][repReporterID] == playerid)
        {
            Report_ClearSlot(i);
        }
    }
    return 1;
}
