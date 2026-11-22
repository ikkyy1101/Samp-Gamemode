/**
 * File: gamemodes/modules/economy/paycheck.inc
 * Modul: Hourly Paycheck, Tax, Bank Interest & Level Progression
 * Deskripsi: Menghitung akumulasi menit bermain warga secara adil, mencairkan
 *            slip gaji setiap 60 menit aktif langsung ke rekening bank, menghitung
 *            bunga tabungan, pajak kekayaan, serta EXP & kenaikan level otomatis.
 * Dependensi: <open.mp>, <Pawn.CMD>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/enums.inc,
 *             core/variables.inc, modules/economy/money.inc, modules/economy/bank.inc
 */

#if defined _INC_ECONOMY_PAYCHECK
    #endinput
#endif
#define _INC_ECONOMY_PAYCHECK

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA PAYCHECK, PAJAK & EXP
// ============================================================================
#define PAYCHECK_INTERVAL_MINUTES   (60)
#define PAYCHECK_BASE_CITIZEN_PAY   (250)
#define PAYCHECK_LEVEL_MULTIPLIER   (35)
#define PAYCHECK_VIP_BONUS_PER_LV   (150)
#define PAYCHECK_BANK_INTEREST_PCT  (Float:0.002) // 0.2% bunga bank per paycheck
#define PAYCHECK_MAX_INTEREST       (2500)
#define PAYCHECK_AFK_THRESHOLD_MS   (300000) // 5 menit tanpa aktivitas dianggap AFK

// ============================================================================
// FUNGSI PERHITUNGAN EXP & PENCAIRAN PAYCHECK
// ============================================================================

/**
 * Mengembalikan kebutuhan total EXP untuk naik ke level berikutnya.
 */
stock Paycheck_GetRequiredEXP(level)
{
    if (level < 1)
    {
        return 4;
    }
    return level * 4;
}

/**
 * Menambahkan bonus gaji pekerjaan/faksi yang akan dicairkan pada Paycheck berikutnya.
 */
stock Paycheck_AddPendingBonus(playerid, amount)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded] || amount <= 0)
    {
        return 0;
    }

    PlayerData[playerid][pPendingPaycheckBonus] += amount;
    return 1;
}

/**
 * Mencairkan slip gaji lengkap (Gaji Warga + Bonus Kerja + VIP + Bunga Bank - Pajak)
 * ke rekening bank karakter.
 */
stock Paycheck_DeliverSalary(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    Bank_EnsureAccountNumber(playerid);

    new
        basePay = PAYCHECK_BASE_CITIZEN_PAY + (PlayerData[playerid][pLevel] * PAYCHECK_LEVEL_MULTIPLIER),
        jobBonus = PlayerData[playerid][pPendingPaycheckBonus],
        vipBonus = PlayerData[playerid][pVIPLevel] * PAYCHECK_VIP_BONUS_PER_LV,
        currentBank = Bank_Get(playerid),
        interest = floatround(float(currentBank) * PAYCHECK_BANK_INTEREST_PCT, floatround_floor),
        tax = 0;

    if (interest > PAYCHECK_MAX_INTEREST)
    {
        interest = PAYCHECK_MAX_INTEREST;
    }

    // Pajak kekayaan progresif untuk warga dengan total saldo bank > $50.000
    if (currentBank > 250000)
    {
        tax = floatround(float(currentBank) * 0.003, floatround_floor);
        if (tax > 3000) tax = 3000;
    }
    else if (currentBank > 50000)
    {
        tax = floatround(float(currentBank) * 0.0015, floatround_floor);
    }

    new netPaycheck = (basePay + jobBonus + vipBonus + interest) - tax;
    if (netPaycheck < 100)
    {
        netPaycheck = 100;
    }

    PlayerData[playerid][pPendingPaycheckBonus] = 0;
    PlayerData[playerid][pPlayingHours]++;
    PlayerData[playerid][pExp]++;

    Bank_Give(playerid, netPaycheck, "Pencairan Paycheck Jam");

    new
        baseStr[24],
        bonusStr[24],
        interestStr[24],
        taxStr[24],
        netStr[24],
        balStr[32];

    FormatMoney(basePay + vipBonus, baseStr, sizeof(baseStr));
    FormatMoney(jobBonus, bonusStr, sizeof(bonusStr));
    FormatMoney(interest, interestStr, sizeof(interestStr));
    FormatMoney(tax, taxStr, sizeof(taxStr));
    FormatMoney(netPaycheck, netStr, sizeof(netStr));
    FormatMoney(Bank_Get(playerid), balStr, sizeof(balStr));

    SendClientMessage(playerid, COLOR_PRIMARY, "================ [ SLIP GAJI / PAYCHECK PARADISE RP ] ================");
    SendClientMessage(playerid, COLOR_INFO, "Tunjangan Warga & VIP: %s | Bonus Kerja/Faksi: %s", baseStr, bonusStr);
    SendClientMessage(playerid, COLOR_INFO, "Bunga Tabungan Bank: +%s | Pajak Kekayaan: -%s", interestStr, taxStr);
    SendClientMessage(playerid, COLOR_SUCCESS, "Total Ditransfer ke Rekening (%s): +%s | Saldo Baru: %s", PlayerData[playerid][pBankAccountNo], netStr, balStr);

    // Cek apakah EXP sudah mencukupi untuk naik level otomatis
    new reqExp = Paycheck_GetRequiredEXP(PlayerData[playerid][pLevel]);
    if (PlayerData[playerid][pExp] >= reqExp)
    {
        PlayerData[playerid][pExp] -= reqExp;
        PlayerData[playerid][pLevel]++;
        SetPlayerScore(playerid, PlayerData[playerid][pLevel]);

        SendClientMessage(
            playerid,
            COLOR_SUCCESS,
            "[LEVEL UP] Selamat! Karakter Anda naik ke Level %d (Total Jam Bermain: %d Jam).",
            PlayerData[playerid][pLevel],
            PlayerData[playerid][pPlayingHours]
        );
    }
    else
    {
        SendClientMessage(
            playerid,
            COLOR_INFO,
            "Progres Level %d: %d / %d EXP (Total Jam Bermain: %d Jam).",
            PlayerData[playerid][pLevel],
            PlayerData[playerid][pExp],
            reqExp,
            PlayerData[playerid][pPlayingHours]
        );
    }

    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
    Character_Save(playerid);
    return 1;
}

/**
 * Dipanggil setiap 1 menit oleh timer karakter untuk menghitung progres menuju Paycheck.
 */
stock Paycheck_ProcessMinute(playerid)
{
    if (!IsPlayerConnected(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 0;
    }

    // Tidak menghitung waktu gaji jika pemain sedang di dalam Admin Jail OOC
    if (PlayerData[playerid][pJailTime] > 0 && PlayerData[playerid][pJailType] == 2)
    {
        return 0;
    }

    // Tidak menghitung menit gaji jika pemain AFK lebih dari 5 menit
    if (PlayerData[playerid][pLastActiveTick] > 0 && (GetTickCount() - PlayerData[playerid][pLastActiveTick]) > PAYCHECK_AFK_THRESHOLD_MS)
    {
        return 0;
    }

    PlayerData[playerid][pPaycheckMinutes]++;
    if (PlayerData[playerid][pPaycheckMinutes] >= PAYCHECK_INTERVAL_MINUTES)
    {
        PlayerData[playerid][pPaycheckMinutes] = 0;
        Paycheck_DeliverSalary(playerid);
    }
    return 1;
}

// ============================================================================
// PERINTAH WARGA (/paycheck) & HOOK DETEKSI AKTIVITAS ANTI-AFK
// ============================================================================
CMD:paycheck(playerid, params[])
{
    #pragma unused params
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    new
        sisaMenit = PAYCHECK_INTERVAL_MINUTES - PlayerData[playerid][pPaycheckMinutes],
        bonusStr[32];

    FormatMoney(PlayerData[playerid][pPendingPaycheckBonus], bonusStr, sizeof(bonusStr));

    SendClientMessage(
        playerid,
        COLOR_INFO,
        "[Paycheck] Progres waktu gaji: %d / %d menit (Tersisa %d menit lagi) | Bonus Kerja Tertampung: %s.",
        PlayerData[playerid][pPaycheckMinutes],
        PAYCHECK_INTERVAL_MINUTES,
        sisaMenit,
        bonusStr
    );
    return 1;
}
alias:paycheck("gaji", "waktu")

hook OnPlayerUpdate(playerid)
{
    if (PlayerData[playerid][pAuthState] == AUTH_STATE_SPAWNED)
    {
        PlayerData[playerid][pLastActiveTick] = GetTickCount();
    }
    return 1;
}

// ============================================================================
// TIMER 1 MENIT PER KARAKTER UNTUK HITUNGAN PAYCHECK
// ============================================================================
ptask Character_MinuteTickTask[60000](playerid)
{
    if (!IsPlayerConnected(playerid) || IsPlayerNPC(playerid) || PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return;
    }

    Paycheck_ProcessMinute(playerid);
}
