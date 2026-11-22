/**
 * File: gamemodes/modules/economy/bank.inc
 * Modul: Banking System & Dynamic ATM Network
 * Deskripsi: Mengelola layanan Bank Utama Los Santos, pembukaan nomor rekening
 *            unik (PR-XXXXXX), setor tunai (/deposit), tarik tunai (/withdraw),
 *            transfer antar rekening (/transfer), cek saldo (/balance), mutasi
 *            rekening (/mutasi), serta manajemen mesin ATM dinamis dari database.
 * Dependensi: <open.mp>, <a_mysql>, <streamer>, <Pawn.CMD>, <sscanf2>,
 *             <YSI_Coding\y_hooks>, <YSI_Coding\y_iterate>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/economy/money.inc,
 *             modules/admin/levels.inc
 */

#if defined _INC_ECONOMY_BANK
    #endinput
#endif
#define _INC_ECONOMY_BANK

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA LOKASI BANK UTAMA & ATURAN TRANSAKSI
// ============================================================================
#define BANK_MAIN_EXT_X             (1462.3958)
#define BANK_MAIN_EXT_Y             (-1012.3912)
#define BANK_MAIN_EXT_Z             (26.8438)
#define BANK_MAIN_EXT_A             (180.0)

#define BANK_MAIN_INT_X             (2305.6890)
#define BANK_MAIN_INT_Y             (-16.1200)
#define BANK_MAIN_INT_Z             (26.7496)
#define BANK_MAIN_INT_A             (270.0)
#define BANK_MAIN_INTERIOR          (0)
#define BANK_MAIN_VW                (10)

#define BANK_TELLER_X               (2316.6184)
#define BANK_TELLER_Y               (-7.3260)
#define BANK_TELLER_Z               (26.7422)

#define ATM_INTERACT_RADIUS         (2.5)
#define BANK_TELLER_RADIUS          (3.5)
#define BANK_MIN_TX_AMOUNT          (1)
#define BANK_MAX_TX_AMOUNT          (1000000)
#define ATM_MAX_WITHDRAW_AMOUNT     (25000)
#define ATM_ADMIN_FEE               (5)

static
    STREAMER_TAG_PICKUP:s_BankExtPickup = STREAMER_TAG_PICKUP:-1,
    STREAMER_TAG_PICKUP:s_BankIntExitPickup = STREAMER_TAG_PICKUP:-1,
    STREAMER_TAG_PICKUP:s_BankTellerPickup = STREAMER_TAG_PICKUP:-1;

// ============================================================================
// FUNGSI HELPER LOKASI BANK / ATM & PEMBUATAN REKENING
// ============================================================================

/**
 * Memastikan karakter sudah memiliki nomor rekening unik berformat PR-XXXXXX.
 */
stock Bank_EnsureAccountNumber(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    if (PlayerData[playerid][pBankAccountNo][0] != EOS && strcmp(PlayerData[playerid][pBankAccountNo], "NONE", true) != 0)
    {
        return 1;
    }

    format(
        PlayerData[playerid][pBankAccountNo],
        16,
        "PR-%06d",
        100000 + (PlayerData[playerid][pCharacterID] % 899999)
    );

    if (Database_IsConnected())
    {
        new query[200];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "UPDATE `characters` SET `bank_account_no` = '%e' WHERE `id` = %d",
            PlayerData[playerid][pBankAccountNo],
            PlayerData[playerid][pCharacterID]
        );
        mysql_tquery(g_SQL, query);
    }
    return 1;
}

stock bool:Bank_IsPlayerAtTeller(playerid)
{
    if (!IsPlayerConnected(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return false;
    }

    return (
        GetPlayerInterior(playerid) == BANK_MAIN_INTERIOR &&
        GetPlayerVirtualWorld(playerid) == BANK_MAIN_VW &&
        IsPlayerInRangeOfPoint(playerid, BANK_TELLER_RADIUS, BANK_TELLER_X, BANK_TELLER_Y, BANK_TELLER_Z)
    );
}

stock Bank_GetNearbyATM(playerid)
{
    if (!IsPlayerConnected(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return -1;
    }

    new
        interior = GetPlayerInterior(playerid),
        vw = GetPlayerVirtualWorld(playerid);

    foreach (new i : ActiveATMs)
    {
        if (ATMData[i][atmInterior] == interior && ATMData[i][atmVirtualWorld] == vw)
        {
            if (IsPlayerInRangeOfPoint(playerid, ATM_INTERACT_RADIUS, ATMData[i][atmPosX], ATMData[i][atmPosY], ATMData[i][atmPosZ]))
            {
                return i;
            }
        }
    }
    return -1;
}

// ============================================================================
// PEMUATAN & SPAWN MESIN ATM DINAMIS DARI DATABASE
// ============================================================================
static Bank_SpawnATMObject(slot)
{
    if (slot < 0 || slot >= MAX_SERVER_ATMS || !ATMData[slot][atmExists])
    {
        return 0;
    }

    ATMData[slot][atmObjectID] = CreateDynamicObject(
        2942,
        ATMData[slot][atmPosX],
        ATMData[slot][atmPosY],
        ATMData[slot][atmPosZ] - 0.35,
        0.0, 0.0, ATMData[slot][atmRotZ],
        ATMData[slot][atmVirtualWorld],
        ATMData[slot][atmInterior]
    );

    new labelText[128];
    format(labelText, sizeof(labelText), "{00D4FF}[MESIN ATM #%d]\n{FFFFFF}Gunakan {FFD166}/atm {FFFFFF}untuk bertransaksi", ATMData[slot][atmDBID]);
    ATMData[slot][atmLabel] = CreateDynamic3DTextLabel(
        labelText,
        0x00D4FFFF,
        ATMData[slot][atmPosX],
        ATMData[slot][atmPosY],
        ATMData[slot][atmPosZ] + 0.45,
        12.0,
        INVALID_PLAYER_ID,
        INVALID_VEHICLE_ID,
        1,
        ATMData[slot][atmVirtualWorld],
        ATMData[slot][atmInterior]
    );

    Iter_Add(ActiveATMs, slot);
    return 1;
}

static Bank_LoadATMsFromDatabase()
{
    if (!Database_IsConnected())
    {
        return 0;
    }

    mysql_tquery(g_SQL, "SELECT * FROM `atms` ORDER BY `id` ASC LIMIT 60", "OnATMsLoaded");
    return 1;
}

forward OnATMsLoaded();
public OnATMsLoaded()
{
    new rows = cache_num_rows();
    if (rows == 0)
    {
        // Masukkan 4 titik ATM bawaan jika tabel `atms` masih kosong
        mysql_tquery(
            g_SQL,
            "INSERT INTO `atms` (`pos_x`, `pos_y`, `pos_z`, `rot_z`, `interior`, `virtual_world`) VALUES \
            (1748.5500, -1863.2000, 13.5784, 90.0, 0, 0), \
            (1480.9500, -1769.1000, 18.7958, 0.0, 0, 0), \
            (1154.2200, -1440.1500, 15.7969, 270.0, 0, 0), \
            (1178.9000, -1323.8500, 14.1200, 180.0, 0, 0)"
        );
        mysql_tquery(g_SQL, "SELECT * FROM `atms` ORDER BY `id` ASC LIMIT 60", "OnATMsLoaded");
        return 1;
    }

    for (new i = 0; i < rows && i < MAX_SERVER_ATMS; i++)
    {
        ATMData[i][atmExists] = true;
        cache_get_value_name_int(i, "id", ATMData[i][atmDBID]);
        cache_get_value_name_float(i, "pos_x", ATMData[i][atmPosX]);
        cache_get_value_name_float(i, "pos_y", ATMData[i][atmPosY]);
        cache_get_value_name_float(i, "pos_z", ATMData[i][atmPosZ]);
        cache_get_value_name_float(i, "rot_z", ATMData[i][atmRotZ]);
        cache_get_value_name_int(i, "interior", ATMData[i][atmInterior]);
        cache_get_value_name_int(i, "virtual_world", ATMData[i][atmVirtualWorld]);

        Bank_SpawnATMObject(i);
    }

    printf("[Economy] Berhasil memuat %d mesin ATM aktif dari database.", rows);
    return 1;
}

// ============================================================================
// DIALOG MENU BANK & ATM
// ============================================================================
static Bank_ShowMainMenu(playerid, bool:isATM)
{
    Bank_EnsureAccountNumber(playerid);

    new
        cashStr[32],
        bankStr[32],
        title[72],
        body[320];

    FormatMoney(Money_Get(playerid), cashStr, sizeof(cashStr));
    FormatMoney(Bank_Get(playerid), bankStr, sizeof(bankStr));

    if (isATM)
    {
        format(title, sizeof(title), "{00D4FF}Mesin ATM — Rekening %s", PlayerData[playerid][pBankAccountNo]);
        format(
            body,
            sizeof(body),
            "Informasi Saldo (Saldo: %s | Tunai: %s)\n\
            Tarik Tunai (Maks $25,000 | Biaya Admin $5)\n\
            Transfer Antar Rekening\n\
            Riwayat Mutasi Rekening",
            bankStr,
            cashStr
        );
        ShowPlayerDialog(playerid, DIALOG_ATM_MAIN, DIALOG_STYLE_LIST, title, body, "Pilih", "Tutup");
    }
    else
    {
        format(title, sizeof(title), "{00D4FF}Bank Utama Los Santos — %s", PlayerData[playerid][pBankAccountNo]);
        format(
            body,
            sizeof(body),
            "Informasi Rekening (Saldo: %s | Tunai: %s)\n\
            Setor Tunai (Deposit)\n\
            Tarik Tunai (Withdraw)\n\
            Transfer Antar Rekening\n\
            Riwayat Mutasi Rekening",
            bankStr,
            cashStr
        );
        ShowPlayerDialog(playerid, DIALOG_BANK_MAIN, DIALOG_STYLE_LIST, title, body, "Pilih", "Tutup");
    }
    return 1;
}

// ============================================================================
// PROSES TRANSAKSI BANK & TRANSFER ASINKRON
// ============================================================================
static Bank_ProcessDeposit(playerid, amount)
{
    if (amount < BANK_MIN_TX_AMOUNT || amount > BANK_MAX_TX_AMOUNT)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Nominal setor tunai harus antara $1 hingga $1,000,000!");
        return 0;
    }

    if (!Money_Has(playerid, amount))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Uang tunai di dompet Anda tidak mencukupi!");
        return 0;
    }

    Bank_EnsureAccountNumber(playerid);
    Money_Give(playerid, -amount, "Setor Tunai Bank");
    Bank_Give(playerid, amount, "Setor Tunai");

    new amountStr[32], balStr[32];
    FormatMoney(amount, amountStr, sizeof(amountStr));
    FormatMoney(Bank_Get(playerid), balStr, sizeof(balStr));

    SendClientMessage(playerid, COLOR_SUCCESS, "[Bank] Setor tunai sebesar %s berhasil. Saldo rekening sekarang: %s.", amountStr, balStr);
    Character_Save(playerid);
    return 1;
}

static Bank_ProcessWithdraw(playerid, amount, bool:isATM)
{
    new maxLimit = isATM ? ATM_MAX_WITHDRAW_AMOUNT : BANK_MAX_TX_AMOUNT;
    new adminFee = isATM ? ATM_ADMIN_FEE : 0;

    if (amount < BANK_MIN_TX_AMOUNT || amount > maxLimit)
    {
        new err[128];
        format(err, sizeof(err), "Nominal penarikan harus antara $1 hingga $%d!", maxLimit);
        SendClientMessage(playerid, COLOR_ERROR, "%s", err);
        return 0;
    }

    new totalDeduction = amount + adminFee;
    if (!Bank_Has(playerid, totalDeduction))
    {
        if (isATM)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Saldo bank tidak mencukupi (termasuk biaya admin ATM sebesar $5)!");
        }
        else
        {
            SendClientMessage(playerid, COLOR_ERROR, "Saldo rekening bank Anda tidak mencukupi!");
        }
        return 0;
    }

    Bank_EnsureAccountNumber(playerid);
    new txDesc[24];
    format(txDesc, sizeof(txDesc), isATM ? "Tarik Tunai ATM" : "Tarik Tunai Teller");
    Bank_Give(playerid, -totalDeduction, txDesc);
    Money_Give(playerid, amount, txDesc);

    new amountStr[32], balStr[32];
    FormatMoney(amount, amountStr, sizeof(amountStr));
    FormatMoney(Bank_Get(playerid), balStr, sizeof(balStr));

    if (isATM)
    {
        SendClientMessage(playerid, COLOR_SUCCESS, "[ATM] Tarik tunai %s berhasil (Biaya admin $5). Sisa saldo: %s.", amountStr, balStr);
    }
    else
    {
        SendClientMessage(playerid, COLOR_SUCCESS, "[Bank] Tarik tunai %s berhasil. Sisa saldo: %s.", amountStr, balStr);
    }

    Character_Save(playerid);
    return 1;
}

static Bank_StartTransferLookup(playerid, const targetInput[], bool:isATM)
{
    new cleanTarget[32];
    format(cleanTarget, sizeof(cleanTarget), "%s", targetInput);
    SanitizeString(cleanTarget);

    if (strlen(cleanTarget) == 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Masukkan ID pemain, Nama Karakter, atau Nomor Rekening tujuan!");
        return 0;
    }

    // Cek apakah input berupa ID/Nama pemain yang sedang online
    new onlineTarget = INVALID_PLAYER_ID;
    if (sscanf(cleanTarget, "u", onlineTarget) == 0 && IsPlayerConnected(onlineTarget) && PlayerData[onlineTarget][pCharacterLoaded])
    {
        if (onlineTarget == playerid)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat mentransfer uang ke rekening Anda sendiri!");
            return 0;
        }

        Bank_EnsureAccountNumber(onlineTarget);
        PlayerData[playerid][pTransferTargetCharID] = PlayerData[onlineTarget][pCharacterID];
        PlayerData[playerid][pTransferTargetPlayerID] = onlineTarget;
        format(PlayerData[playerid][pTransferTargetName], MAX_PLAYER_NAME, "%s", PlayerData[onlineTarget][pCharName]);
        format(PlayerData[playerid][pTransferTargetAccNo], 16, "%s", PlayerData[onlineTarget][pBankAccountNo]);

        new prompt[192];
        format(
            prompt,
            sizeof(prompt),
            "{FFFFFF}Tujuan Transfer: {FFD166}%s {FFFFFF}(Rek: {00D4FF}%s{FFFFFF})\n\
            Masukkan nominal uang yang ingin ditransfer ($1 - $1,000,000):",
            PlayerData[playerid][pTransferTargetName],
            PlayerData[playerid][pTransferTargetAccNo]
        );
        ShowPlayerDialog(
            playerid,
            isATM ? DIALOG_ATM_TRANSFER_AMOUNT : DIALOG_BANK_TRANSFER_AMOUNT,
            DIALOG_STYLE_INPUT,
            "{00D4FF}Nominal Transfer Rekening",
            prompt,
            "Transfer",
            "Batal"
        );
        return 1;
    }

    // Jika tidak sedang online, cari berdasarkan Nama Karakter atau Nomor Rekening di database
    if (!Database_IsConnected())
    {
        SendClientMessage(playerid, COLOR_ERROR, "Database sedang tidak terhubung!");
        return 0;
    }

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[320];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT `id`, `name`, COALESCE(`bank_account_no`, '') AS `acc_no` \
         FROM `characters` WHERE `name` = '%e' OR `bank_account_no` = '%e' LIMIT 1",
        cleanTarget,
        cleanTarget
    );
    mysql_tquery(g_SQL, query, "OnBankTransferTargetLookup", "iii", playerid, racecheck, isATM ? 1 : 0);
    return 1;
}

forward OnBankTransferTargetLookup(playerid, racecheck, isATM);
public OnBankTransferTargetLookup(playerid, racecheck, isATM)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (cache_num_rows() == 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Rekening atau nama karakter tujuan tidak ditemukan!");
        return 1;
    }

    new targetCharId;
    cache_get_value_name_int(0, "id", targetCharId);

    if (targetCharId == PlayerData[playerid][pCharacterID])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat mentransfer uang ke rekening Anda sendiri!");
        return 1;
    }

    PlayerData[playerid][pTransferTargetCharID] = targetCharId;
    PlayerData[playerid][pTransferTargetPlayerID] = INVALID_PLAYER_ID;
    cache_get_value_name(0, "name", PlayerData[playerid][pTransferTargetName], MAX_PLAYER_NAME);
    cache_get_value_name(0, "acc_no", PlayerData[playerid][pTransferTargetAccNo], 16);

    new prompt[192];
    format(
        prompt,
        sizeof(prompt),
        "{FFFFFF}Tujuan Transfer (Offline): {FFD166}%s {FFFFFF}(Rek: {00D4FF}%s{FFFFFF})\n\
        Masukkan nominal uang yang ingin ditransfer ($1 - $1,000,000):",
        PlayerData[playerid][pTransferTargetName],
        PlayerData[playerid][pTransferTargetAccNo]
    );
    ShowPlayerDialog(
        playerid,
        isATM ? DIALOG_ATM_TRANSFER_AMOUNT : DIALOG_BANK_TRANSFER_AMOUNT,
        DIALOG_STYLE_INPUT,
        "{00D4FF}Nominal Transfer Rekening",
        prompt,
        "Transfer",
        "Batal"
    );
    return 1;
}

static Bank_ExecuteTransfer(playerid, amount)
{
    if (PlayerData[playerid][pTransferTargetCharID] <= 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Sesi transfer tidak valid. Silakan ulangi dari menu utama.");
        return 0;
    }

    if (amount < BANK_MIN_TX_AMOUNT || amount > BANK_MAX_TX_AMOUNT)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Nominal transfer harus antara $1 hingga $1,000,000!");
        return 0;
    }

    if (!Bank_Has(playerid, amount))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Saldo rekening bank Anda tidak mencukupi untuk transfer ini!");
        return 0;
    }

    Bank_EnsureAccountNumber(playerid);

    new
        targetCharId = PlayerData[playerid][pTransferTargetCharID],
        targetOnlineId = INVALID_PLAYER_ID,
        amountStr[32],
        logMsg[220];

    FormatMoney(amount, amountStr, sizeof(amountStr));

    // Pastikan apakah target masih/sedang online di server
    foreach (new i : SpawnedPlayers)
    {
        if (PlayerData[i][pCharacterID] == targetCharId)
        {
            targetOnlineId = i;
            break;
        }
    }

    Bank_Give(playerid, -amount, "Transfer Keluar");

    if (targetOnlineId != INVALID_PLAYER_ID)
    {
        Bank_Give(targetOnlineId, amount, "Transfer Masuk");
        SendClientMessage(
            targetOnlineId,
            COLOR_SUCCESS,
            "[Bank] Anda menerima transfer masuk sebesar %s dari %s (Rek: %s).",
            amountStr,
            PlayerData[playerid][pCharName],
            PlayerData[playerid][pBankAccountNo]
        );
        Character_Save(targetOnlineId);
    }
    else if (Database_IsConnected())
    {
        new query[220];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "UPDATE `characters` SET `bank_money` = `bank_money` + %d WHERE `id` = %d",
            amount,
            targetCharId
        );
        mysql_tquery(g_SQL, query);
    }

    format(
        logMsg,
        sizeof(logMsg),
        "[Transfer] %s (%s) -> %s (%s): %s",
        PlayerData[playerid][pCharName],
        PlayerData[playerid][pBankAccountNo],
        PlayerData[playerid][pTransferTargetName],
        PlayerData[playerid][pTransferTargetAccNo],
        amountStr
    );
    Economy_LogTransaction(playerid, targetOnlineId, logMsg);

    SendClientMessage(
        playerid,
        COLOR_SUCCESS,
        "[Bank] Transfer sebesar %s ke %s (%s) berhasil diproses.",
        amountStr,
        PlayerData[playerid][pTransferTargetName],
        PlayerData[playerid][pTransferTargetAccNo]
    );

    PlayerData[playerid][pTransferTargetCharID] = 0;
    PlayerData[playerid][pTransferTargetPlayerID] = INVALID_PLAYER_ID;
    Character_Save(playerid);
    return 1;
}

static Bank_ShowAccountHistory(playerid)
{
    if (!Database_IsConnected())
    {
        SendClientMessage(playerid, COLOR_ERROR, "Database sedang tidak terhubung!");
        return 0;
    }

    new
        racecheck = Database_GetPlayerRaceCheck(playerid),
        query[360];

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT DATE_FORMAT(`created_at`, '%%d/%%m %%H:%%i') AS `waktu`, `message` \
         FROM `logs` WHERE `type` = 'economy' AND (`char_id` = %d OR `target_id` = %d) \
         ORDER BY `id` DESC LIMIT 12",
        PlayerData[playerid][pCharacterID],
        PlayerData[playerid][pCharacterID]
    );
    mysql_tquery(g_SQL, query, "OnBankHistoryLoaded", "ii", playerid, racecheck);
    return 1;
}

forward OnBankHistoryLoaded(playerid, racecheck);
public OnBankHistoryLoaded(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    new rows = cache_num_rows();
    if (rows == 0)
    {
        SendClientMessage(playerid, COLOR_INFO, "Belum ada catatan mutasi transaksi pada rekening Anda.");
        return 1;
    }

    new
        dialogBody[1280],
        line[160],
        waktu[24],
        msg[128];

    format(dialogBody, sizeof(dialogBody), "Waktu\tKeterangan Mutasi\n");
    for (new i = 0; i < rows; i++)
    {
        cache_get_value_name(i, "waktu", waktu, sizeof(waktu));
        cache_get_value_name(i, "message", msg, sizeof(msg));

        format(line, sizeof(line), "%s\t%s\n", waktu, msg);
        strcat(dialogBody, line);
    }

    ShowPlayerDialog(playerid, DIALOG_BANK_MUTASI, DIALOG_STYLE_TABLIST_HEADERS, "{00D4FF}Mutasi Rekening Terbaru", dialogBody, "Tutup", "");
    return 1;
}

// ============================================================================
// PERINTAH WARGA & ADMIN PERBANKAN (/bank, /atm, /balance, /deposit, /withdraw, /transfer, /mutasi)
// ============================================================================
CMD:bank(playerid, params[])
{
    #pragma unused params
    if (!Bank_IsPlayerAtTeller(playerid))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berada di depan Teller Bank Utama Los Santos untuk membuka menu ini!");
        return 1;
    }

    Bank_ShowMainMenu(playerid, false);
    return 1;
}

CMD:atm(playerid, params[])
{
    #pragma unused params
    if (Bank_GetNearbyATM(playerid) == -1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Tidak ada mesin ATM di dekat Anda!");
        return 1;
    }

    Bank_ShowMainMenu(playerid, true);
    return 1;
}

stock Bank_ShowBalanceInfo(playerid)
{
    Bank_EnsureAccountNumber(playerid);

    new bankStr[32], cashStr[32];
    FormatMoney(Bank_Get(playerid), bankStr, sizeof(bankStr));
    FormatMoney(Money_Get(playerid), cashStr, sizeof(cashStr));

    SendClientMessage(
        playerid,
        COLOR_INFO,
        "[Rekening %s] Saldo Bank: %s | Uang Tunai di Dompet: %s",
        PlayerData[playerid][pBankAccountNo],
        bankStr,
        cashStr
    );
    return 1;
}

CMD:balance(playerid, params[])
{
    #pragma unused params
    if (!Bank_IsPlayerAtTeller(playerid) && Bank_GetNearbyATM(playerid) == -1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berada di Bank atau dekat mesin ATM untuk mengecek saldo!");
        return 1;
    }

    Bank_ShowBalanceInfo(playerid);
    return 1;
}
alias:balance("saldo", "cekbank")

CMD:deposit(playerid, params[])
{
    if (!Bank_IsPlayerAtTeller(playerid))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Setor tunai hanya dapat dilakukan di Teller Bank Utama Los Santos!");
        return 1;
    }

    new amount;
    if (sscanf(params, "i", amount))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /deposit [jumlah]");
        return 1;
    }

    Bank_ProcessDeposit(playerid, amount);
    return 1;
}
alias:deposit("setor")

CMD:withdraw(playerid, params[])
{
    new bool:atTeller = Bank_IsPlayerAtTeller(playerid);
    new bool:atATM = (Bank_GetNearbyATM(playerid) != -1);

    if (!atTeller && !atATM)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berada di Teller Bank atau dekat mesin ATM!");
        return 1;
    }

    new amount;
    if (sscanf(params, "i", amount))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /withdraw [jumlah]");
        return 1;
    }

    Bank_ProcessWithdraw(playerid, amount, !atTeller);
    return 1;
}
alias:withdraw("tarik")

CMD:transfer(playerid, params[])
{
    new bool:atTeller = Bank_IsPlayerAtTeller(playerid);
    new bool:atATM = (Bank_GetNearbyATM(playerid) != -1);

    if (!atTeller && !atATM)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berada di Teller Bank atau dekat mesin ATM untuk mentransfer dana!");
        return 1;
    }

    if (isnull(params))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /transfer [ID / Nama Karakter / Nomor Rekening PR-XXXXXX]");
        return 1;
    }

    Bank_StartTransferLookup(playerid, params, !atTeller);
    return 1;
}

CMD:mutasi(playerid, params[])
{
    #pragma unused params
    if (!Bank_IsPlayerAtTeller(playerid) && Bank_GetNearbyATM(playerid) == -1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berada di Teller Bank atau dekat mesin ATM!");
        return 1;
    }

    Bank_ShowAccountHistory(playerid);
    return 1;
}

CMD:createatm(playerid, params[])
{
    #pragma unused params
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_SENIOR, true))
    {
        return 1;
    }

    new slot = Iter_Free(ActiveATMs);
    if (slot == ITER_NONE)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Kapasitas maksimal mesin ATM server (60) telah tercapai!");
        return 1;
    }

    new
        Float:x, Float:y, Float:z, Float:a,
        interior = GetPlayerInterior(playerid),
        vw = GetPlayerVirtualWorld(playerid),
        query[320];

    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    // Geser sedikit ke depan admin agar tidak menimpa karakter
    x += (1.2 * floatsin(-a, degrees));
    y += (1.2 * floatcos(-a, degrees));

    ATMData[slot][atmExists] = true;
    ATMData[slot][atmPosX] = x;
    ATMData[slot][atmPosY] = y;
    ATMData[slot][atmPosZ] = z;
    ATMData[slot][atmRotZ] = a + 180.0;
    ATMData[slot][atmInterior] = interior;
    ATMData[slot][atmVirtualWorld] = vw;

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "INSERT INTO `atms` (`pos_x`, `pos_y`, `pos_z`, `rot_z`, `interior`, `virtual_world`) \
         VALUES (%f, %f, %f, %f, %d, %d)",
        x, y, z, a + 180.0, interior, vw
    );
    mysql_tquery(g_SQL, query, "OnATMCreated", "ii", playerid, slot);
    return 1;
}

forward OnATMCreated(playerid, slot);
public OnATMCreated(playerid, slot)
{
    ATMData[slot][atmDBID] = cache_insert_id();
    Bank_SpawnATMObject(slot);

    if (IsPlayerConnected(playerid))
    {
        new logMsg[144];
        format(logMsg, sizeof(logMsg), "[AdminCmd] %s membuat mesin ATM baru (#%d).", PlayerData[playerid][pUsername], ATMData[slot][atmDBID]);
        Admin_LogAction(playerid, INVALID_PLAYER_ID, logMsg);
        SendClientMessage(playerid, COLOR_SUCCESS, "Mesin ATM #%d berhasil dipasang dan disimpan ke database.", ATMData[slot][atmDBID]);
    }
    return 1;
}

CMD:deleteatm(playerid, params[])
{
    #pragma unused params
    if (!Admin_HasAccess(playerid, ADMIN_LEVEL_SENIOR, true))
    {
        return 1;
    }

    new slot = Bank_GetNearbyATM(playerid);
    if (slot == -1)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Berdirilah tepat di depan mesin ATM yang ingin dihapus!");
        return 1;
    }

    new dbId = ATMData[slot][atmDBID];
    if (IsValidDynamicObject(ATMData[slot][atmObjectID]))
    {
        DestroyDynamicObject(ATMData[slot][atmObjectID]);
    }
    if (IsValidDynamic3DTextLabel(ATMData[slot][atmLabel]))
    {
        DestroyDynamic3DTextLabel(ATMData[slot][atmLabel]);
    }

    ATMData[slot][atmExists] = false;
    Iter_Remove(ActiveATMs, slot);

    if (Database_IsConnected() && dbId > 0)
    {
        new query[128];
        mysql_format(g_SQL, query, sizeof(query), "DELETE FROM `atms` WHERE `id` = %d", dbId);
        mysql_tquery(g_SQL, query);
    }

    new logMsg[144];
    format(logMsg, sizeof(logMsg), "[AdminCmd] %s menghapus mesin ATM #%d.", PlayerData[playerid][pUsername], dbId);
    Admin_LogAction(playerid, INVALID_PLAYER_ID, logMsg);
    SendClientMessage(playerid, COLOR_SUCCESS, "Mesin ATM #%d telah dihapus secara permanen.", dbId);
    return 1;
}

// ============================================================================
// HOOKS INISIALISASI BANK, PICKUP & DIALOG RESPONSE
// ============================================================================
hook OnGameModeInit()
{
    // Pickup pintu masuk & keluar Gedung Bank Utama Los Santos
    s_BankExtPickup = CreateDynamicPickup(1274, 1, BANK_MAIN_EXT_X, BANK_MAIN_EXT_Y, BANK_MAIN_EXT_Z, 0, 0);
    CreateDynamic3DTextLabel(
        "{00D4FF}[BANK UTAMA LOS SANTOS]\n{FFFFFF}Masuk untuk layanan Teller & Rekening",
        0x00D4FFFF,
        BANK_MAIN_EXT_X, BANK_MAIN_EXT_Y, BANK_MAIN_EXT_Z + 0.6,
        15.0,
        INVALID_PLAYER_ID,
        INVALID_VEHICLE_ID,
        1, 0, 0
    );

    s_BankIntExitPickup = CreateDynamicPickup(1318, 1, BANK_MAIN_INT_X, BANK_MAIN_INT_Y, BANK_MAIN_INT_Z, BANK_MAIN_VW, BANK_MAIN_INTERIOR);
    CreateDynamic3DTextLabel(
        "{FFD166}[PINTU KELUAR BANK]\n{FFFFFF}Menuju Jalan Utama Los Santos",
        0xFFD166FF,
        BANK_MAIN_INT_X, BANK_MAIN_INT_Y, BANK_MAIN_INT_Z + 0.6,
        12.0,
        INVALID_PLAYER_ID,
        INVALID_VEHICLE_ID,
        1, BANK_MAIN_VW, BANK_MAIN_INTERIOR
    );

    s_BankTellerPickup = CreateDynamicPickup(1274, 1, BANK_TELLER_X, BANK_TELLER_Y, BANK_TELLER_Z, BANK_MAIN_VW, BANK_MAIN_INTERIOR);
    CreateDynamic3DTextLabel(
        "{2EC4B6}[TELLER BANK UTAMA]\n{FFFFFF}Gunakan {FFD166}/bank {FFFFFF}untuk layanan perbankan lengkap",
        0x2EC4B6FF,
        BANK_TELLER_X, BANK_TELLER_Y, BANK_TELLER_Z + 0.6,
        12.0,
        INVALID_PLAYER_ID,
        INVALID_VEHICLE_ID,
        1, BANK_MAIN_VW, BANK_MAIN_INTERIOR
    );

    Bank_LoadATMsFromDatabase();
    return 1;
}

hook OnPlayerPickUpDynamicPickup(playerid, STREAMER_TAG_PICKUP:pickupid)
{
    if (pickupid == s_BankExtPickup)
    {
        SetPlayerInterior(playerid, BANK_MAIN_INTERIOR);
        SetPlayerVirtualWorld(playerid, BANK_MAIN_VW);
        SetPlayerPos(playerid, BANK_MAIN_INT_X + 1.5, BANK_MAIN_INT_Y, BANK_MAIN_INT_Z);
        SetPlayerFacingAngle(playerid, BANK_MAIN_INT_A);
        SetCameraBehindPlayer(playerid);
        SendClientMessage(playerid, COLOR_INFO, "Selamat datang di Bank Utama Los Santos. Hampiri meja Teller dan ketik /bank.");
        return 1;
    }

    if (pickupid == s_BankIntExitPickup)
    {
        SetPlayerInterior(playerid, 0);
        SetPlayerVirtualWorld(playerid, 0);
        SetPlayerPos(playerid, BANK_MAIN_EXT_X, BANK_MAIN_EXT_Y - 2.0, BANK_MAIN_EXT_Z);
        SetPlayerFacingAngle(playerid, BANK_MAIN_EXT_A);
        SetCameraBehindPlayer(playerid);
        return 1;
    }

    if (pickupid == s_BankTellerPickup)
    {
        GameTextForPlayer(playerid, "~g~Teller Bank~n~~w~Ketik ~y~/bank", 2500, 3);
        return 1;
    }
    return 0;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_BANK_MAIN:
        {
            if (!response)
            {
                return 1;
            }

            switch (listitem)
            {
                case 0: // Info Saldo
                {
                    Bank_ShowBalanceInfo(playerid);
                }
                case 1: // Setor Tunai
                {
                    ShowPlayerDialog(
                        playerid,
                        DIALOG_BANK_DEPOSIT,
                        DIALOG_STYLE_INPUT,
                        "{00D4FF}Setor Tunai (Deposit)",
                        "{FFFFFF}Masukkan jumlah uang tunai yang ingin disetorkan ke rekening bank Anda:",
                        "Setor",
                        "Kembali"
                    );
                }
                case 2: // Tarik Tunai
                {
                    ShowPlayerDialog(
                        playerid,
                        DIALOG_BANK_WITHDRAW,
                        DIALOG_STYLE_INPUT,
                        "{00D4FF}Tarik Tunai (Withdraw)",
                        "{FFFFFF}Masukkan jumlah uang yang ingin ditarik dari rekening bank Anda:",
                        "Tarik",
                        "Kembali"
                    );
                }
                case 3: // Transfer
                {
                    ShowPlayerDialog(
                        playerid,
                        DIALOG_BANK_TRANSFER_TARGET,
                        DIALOG_STYLE_INPUT,
                        "{00D4FF}Transfer Antar Rekening",
                        "{FFFFFF}Masukkan {FFD166}ID Pemain{FFFFFF}, {FFD166}Nama Karakter{FFFFFF}, atau {FFD166}Nomor Rekening (PR-XXXXXX){FFFFFF} tujuan:",
                        "Lanjut",
                        "Kembali"
                    );
                }
                case 4: // Mutasi
                {
                    Bank_ShowAccountHistory(playerid);
                }
            }
            return 1;
        }

        case DIALOG_ATM_MAIN:
        {
            if (!response)
            {
                return 1;
            }

            switch (listitem)
            {
                case 0: // Info Saldo
                {
                    Bank_ShowBalanceInfo(playerid);
                }
                case 1: // Tarik Tunai ATM
                {
                    ShowPlayerDialog(
                        playerid,
                        DIALOG_ATM_WITHDRAW,
                        DIALOG_STYLE_INPUT,
                        "{00D4FF}Tarik Tunai Mesin ATM",
                        "{FFFFFF}Masukkan jumlah penarikan (Maksimal {FFD166}$25,000{FFFFFF}, biaya admin {FF4D4D}$5{FFFFFF}):",
                        "Tarik",
                        "Kembali"
                    );
                }
                case 2: // Transfer ATM
                {
                    ShowPlayerDialog(
                        playerid,
                        DIALOG_ATM_TRANSFER_TARGET,
                        DIALOG_STYLE_INPUT,
                        "{00D4FF}Transfer via Mesin ATM",
                        "{FFFFFF}Masukkan {FFD166}ID Pemain{FFFFFF}, {FFD166}Nama Karakter{FFFFFF}, atau {FFD166}Nomor Rekening (PR-XXXXXX){FFFFFF} tujuan:",
                        "Lanjut",
                        "Kembali"
                    );
                }
                case 3: // Mutasi
                {
                    Bank_ShowAccountHistory(playerid);
                }
            }
            return 1;
        }

        case DIALOG_BANK_DEPOSIT:
        {
            if (!response)
            {
                Bank_ShowMainMenu(playerid, false);
                return 1;
            }

            Bank_ProcessDeposit(playerid, strval(inputtext));
            return 1;
        }

        case DIALOG_BANK_WITHDRAW:
        {
            if (!response)
            {
                Bank_ShowMainMenu(playerid, false);
                return 1;
            }

            Bank_ProcessWithdraw(playerid, strval(inputtext), false);
            return 1;
        }

        case DIALOG_ATM_WITHDRAW:
        {
            if (!response)
            {
                Bank_ShowMainMenu(playerid, true);
                return 1;
            }

            Bank_ProcessWithdraw(playerid, strval(inputtext), true);
            return 1;
        }

        case DIALOG_BANK_TRANSFER_TARGET, DIALOG_ATM_TRANSFER_TARGET:
        {
            new bool:isATM = (dialogid == DIALOG_ATM_TRANSFER_TARGET);
            if (!response)
            {
                Bank_ShowMainMenu(playerid, isATM);
                return 1;
            }

            Bank_StartTransferLookup(playerid, inputtext, isATM);
            return 1;
        }

        case DIALOG_BANK_TRANSFER_AMOUNT, DIALOG_ATM_TRANSFER_AMOUNT:
        {
            new bool:isATM = (dialogid == DIALOG_ATM_TRANSFER_AMOUNT);
            if (!response)
            {
                Bank_ShowMainMenu(playerid, isATM);
                return 1;
            }

            Bank_ExecuteTransfer(playerid, strval(inputtext));
            return 1;
        }
    }
    return 0;
}
