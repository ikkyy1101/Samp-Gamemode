/**
 * File: gamemodes/modules/economy/money.inc
 * Modul: Server-Side Money & Financial Security
 * Deskripsi: Mengelola seluruh mutasi uang tunai & saldo bank secara aman melalui
 *            variabel server-side, sinkronisasi HUD uang GTA, audit log transaksi
 *            ekonomi ke database, serta perintah serah-terima uang tunai (/pay).
 * Dependensi: <open.mp>, <a_mysql>, <Pawn.CMD>, <sscanf2>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/chat/me_do.inc
 */

#if defined _INC_ECONOMY_MONEY
    #endinput
#endif
#define _INC_ECONOMY_MONEY

// ============================================================================
// KONSTANTA EKONOMI & KEAMANAN TRANSAKSI
// ============================================================================
#define ECONOMY_LARGE_TX_THRESHOLD  (5000)
#define PAY_MAX_DISTANCE            (4.0)
#define PAY_MIN_AMOUNT              (1)
#define PAY_MAX_AMOUNT              (50000)

// ============================================================================
// FUNGSI PUBLIK MANAJEMEN UANG TUNAI & BANK (MONEY_* / BANK_*)
// ============================================================================

/**
 * Menyelaraskan tampilan uang GTA client dengan nilai sah di server (PlayerData[playerid][pMoney]).
 */
stock Money_SyncClientHUD(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    if (GetPlayerMoney(playerid) != PlayerData[playerid][pMoney])
    {
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, PlayerData[playerid][pMoney]);
    }
    return 1;
}

/**
 * Mengembalikan jumlah uang tunai sah milik karakter.
 */
stock Money_Get(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }
    return PlayerData[playerid][pMoney];
}

/**
 * Memeriksa apakah uang tunai karakter mencukupi untuk nominal tertentu.
 */
stock bool:Money_Has(playerid, amount)
{
    if (amount < 0)
    {
        return false;
    }
    return (Money_Get(playerid) >= amount);
}

/**
 * Menambah atau mengurangi uang tunai karakter secara aman dan mencatat transaksi besar.
 */
stock bool:Money_Give(playerid, amount, const reason[] = "Transaksi")
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return false;
    }

    if (amount < 0 && PlayerData[playerid][pMoney] < -amount)
    {
        return false;
    }

    PlayerData[playerid][pMoney] += amount;
    if (PlayerData[playerid][pMoney] < 0)
    {
        PlayerData[playerid][pMoney] = 0;
    }

    Money_SyncClientHUD(playerid);

    if (amount >= ECONOMY_LARGE_TX_THRESHOLD || amount <= -ECONOMY_LARGE_TX_THRESHOLD)
    {
        new moneyStr[32], logMsg[200];
        FormatMoney(amount, moneyStr, sizeof(moneyStr));
        format(logMsg, sizeof(logMsg), "[Tunai] %s: %s (Alasan: %s | Sisa: $%d)", PlayerData[playerid][pCharName], moneyStr, reason, PlayerData[playerid][pMoney]);
        Economy_LogTransaction(playerid, INVALID_PLAYER_ID, logMsg);
    }
    return true;
}

/**
 * Mengatur nominal pasti uang tunai karakter.
 */
stock bool:Money_Set(playerid, amount, const reason[] = "Penyesuaian")
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded] || amount < 0)
    {
        return false;
    }

    PlayerData[playerid][pMoney] = amount;
    Money_SyncClientHUD(playerid);

    new moneyStr[32], logMsg[200];
    FormatMoney(amount, moneyStr, sizeof(moneyStr));
    format(logMsg, sizeof(logMsg), "[Set Tunai] %s diatur menjadi %s (Alasan: %s)", PlayerData[playerid][pCharName], moneyStr, reason);
    Economy_LogTransaction(playerid, INVALID_PLAYER_ID, logMsg);
    return true;
}

/**
 * Mengembalikan saldo rekening bank milik karakter.
 */
stock Bank_Get(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }
    return PlayerData[playerid][pBankMoney];
}

/**
 * Memeriksa apakah saldo rekening bank karakter mencukupi.
 */
stock bool:Bank_Has(playerid, amount)
{
    if (amount < 0)
    {
        return false;
    }
    return (Bank_Get(playerid) >= amount);
}

/**
 * Menambah atau mengurangi saldo rekening bank karakter secara aman.
 */
stock bool:Bank_Give(playerid, amount, const reason[] = "Transaksi Bank")
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return false;
    }

    if (amount < 0 && PlayerData[playerid][pBankMoney] < -amount)
    {
        return false;
    }

    PlayerData[playerid][pBankMoney] += amount;
    if (PlayerData[playerid][pBankMoney] < 0)
    {
        PlayerData[playerid][pBankMoney] = 0;
    }

    new moneyStr[32], logMsg[200];
    FormatMoney(amount, moneyStr, sizeof(moneyStr));
    format(logMsg, sizeof(logMsg), "[Bank] %s (%s): %s (Keterangan: %s | Saldo: $%d)", PlayerData[playerid][pCharName], PlayerData[playerid][pBankAccountNo], moneyStr, reason, PlayerData[playerid][pBankMoney]);
    Economy_LogTransaction(playerid, INVALID_PLAYER_ID, logMsg);
    return true;
}

/**
 * Mencatat transaksi ekonomi ke tabel `logs` (type = 'economy').
 */
stock Economy_LogTransaction(playerid, targetid, const message[])
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
            "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('economy', %d, %d, '%e', '%e')",
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
            "INSERT INTO `logs` (`type`, `char_id`, `target_id`, `message`, `ip`) VALUES ('economy', %d, NULL, '%e', '%e')",
            charId,
            message,
            PlayerData[playerid][pCurrentIP]
        );
    }
    else
    {
        return 0;
    }

    mysql_tquery(g_SQL, query);
    return 1;
}

// ============================================================================
// PERINTAH TRANSAKSI TUNAI ANTAR WARGA (/pay)
// ============================================================================
CMD:pay(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    if (PlayerData[playerid][pInjured] || PlayerData[playerid][pJailTime] > 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat menyerahkan uang saat sedang terluka atau dipenjara!");
        return 1;
    }

    new
        targetid,
        amount;

    if (sscanf(params, "ui", targetid, amount))
    {
        SendClientMessage(playerid, COLOR_WARNING, "Penggunaan: /pay [ID/Nama Pemain] [jumlah ($1 - $50,000)]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || PlayerData[targetid][pAuthState] != AUTH_STATE_SPAWNED || targetid == playerid)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Pemain tujuan tidak valid!");
        return 1;
    }

    if (amount < PAY_MIN_AMOUNT || amount > PAY_MAX_AMOUNT)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Nominal pemberian uang tunai harus antara $1 hingga $50,000!");
        return 1;
    }

    if (!Money_Has(playerid, amount))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Uang tunai di dompet Anda tidak mencukupi!");
        return 1;
    }

    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(targetid, tx, ty, tz);

    if (GetPlayerInterior(playerid) != GetPlayerInterior(targetid) ||
        GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(targetid) ||
        GetPlayerDistanceFromPoint(playerid, tx, ty, tz) > PAY_MAX_DISTANCE)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berada dekat dengan warga tersebut untuk menyerahkan uang!");
        return 1;
    }

    Money_Give(playerid, -amount, "Serah Tunai (/pay)");
    Money_Give(targetid, amount, "Terima Tunai (/pay)");

    new
        senderName[MAX_PLAYER_NAME],
        targetName[MAX_PLAYER_NAME],
        moneyStr[32],
        meText[128],
        logMsg[180];

    GetPlayerRoleplayName(playerid, senderName, sizeof(senderName));
    GetPlayerRoleplayName(targetid, targetName, sizeof(targetName));
    FormatMoney(amount, moneyStr, sizeof(moneyStr));

    format(meText, sizeof(meText), "mengeluarkan sejumlah uang tunai dan menyerahkannya kepada %s.", targetName);
    RP_SendAutomaticMe(playerid, meText);

    SendClientMessage(playerid, COLOR_SUCCESS, "Anda menyerahkan uang tunai sebesar %s kepada %s.", moneyStr, targetName);
    SendClientMessage(targetid, COLOR_SUCCESS, "Anda menerima uang tunai sebesar %s dari %s.", moneyStr, senderName);

    format(logMsg, sizeof(logMsg), "[/pay] %s menyerahkan %s kepada %s", senderName, moneyStr, targetName);
    Economy_LogTransaction(playerid, targetid, logMsg);
    return 1;
}

// ============================================================================
// TIMER SINKRONISASI HUD UANG KLIEN
// ============================================================================
ptask Money_SyncTask[1000](playerid)
{
    if (!IsPlayerConnected(playerid) || IsPlayerNPC(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return;
    }

    Money_SyncClientHUD(playerid);
}
