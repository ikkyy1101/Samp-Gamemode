/**
 * File: gamemodes/main.pwn
 * Modul: Entry Point Utama Gamemode PARADISE Roleplay
 * Deskripsi: Mengatur urutan include library & modul gamemode.
 * Dependensi: open.mp, YSI 5.x, a_mysql, Pawn.CMD, sscanf2, streamer, samp_bcrypt
 */

#include <open.mp>

#define YSI_NO_HEAP_MALLOC
#define YSI_NO_VERSION_CHECK
#include <YSI_Coding\y_hooks>
#include <YSI_Data\y_iterate>
#include <YSI_Coding\y_timers>
#include <YSI_Coding\y_inline>
#include <YSI_Coding\y_va>

#include <a_mysql>
#include <Pawn.CMD>
#include <sscanf2>
#include <streamer>
#include <samp_bcrypt>

// Core Modules (Urutan wajib dipertahankan)
#include "core/config.inc"
#include "core/colors.inc"
#include "core/enums.inc"
#include "core/variables.inc"
#include "core/utils.inc"
#include "core/database.inc"

// Gameplay Modules - Account
#include "modules/account/security.inc"
#include "modules/account/register.inc"
#include "modules/account/login.inc"
#include "modules/account/settings.inc"

// Gameplay Modules - Character
#include "modules/character/select.inc"
#include "modules/character/create.inc"
#include "modules/character/spawn.inc"
#include "modules/character/tutorial.inc"
#include "modules/character/stats.inc"

// Gameplay Modules - Chat & Roleplay
#include "modules/chat/antispam.inc"
#include "modules/chat/local.inc"
#include "modules/chat/me_do.inc"
#include "modules/chat/ooc_pm.inc"
#include "modules/chat/animations.inc"

// Gameplay Modules - Admin & Staff
#include "modules/admin/levels.inc"
#include "modules/admin/commands.inc"
#include "modules/admin/spectate.inc"
#include "modules/admin/bans.inc"
#include "modules/admin/reports.inc"

// Gameplay Modules - Economy & Banking (Tahap 7)
#include "modules/economy/money.inc"
#include "modules/economy/bank.inc"
#include "modules/economy/paycheck.inc"

main()
{
    print("====================================================");
    print("  PARADISE Roleplay - Gamemode Berhasil Dimuat");
    print("====================================================");
}

public OnGameModeInit()
{
    SetGameModeText("PARADISE RP v0.7");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
    ShowNameTags(true);
    SetNameTagDrawDistance(20.0);
    DisableInteriorEnterExits();
    EnableStuntBonusForAll(false);
    ManualVehicleEngineAndLights();

    Database_Init();
    return 1;
}

public OnGameModeExit()
{
    new saved = Character_SaveAll();
    printf("[Shutdown] Menyimpan %d karakter sebelum server berhenti...", saved);
    Database_Exit();
    return 1;
}

public OnPlayerCommandPerformed(playerid, cmd[], params[], result, flags)
{
    #pragma unused params, flags
    if (result == -1)
    {
        new msg[128];
        format(msg, sizeof(msg), "Perintah \"/%s\" tidak ada. Gunakan /help untuk bantuan.", cmd);
        SendClientMessage(playerid, COLOR_ERROR, "%s", msg);
        return 0;
    }
    return 1;
}

CMD:versi(playerid, params[])
{
    #pragma unused params
    SendClientMessage(playerid, COLOR_INFO, "PARADISE Roleplay - Versi Tahap 7 (Sistem Ekonomi, Perbankan & Paycheck Aktif).");
    return 1;
}

CMD:help(playerid, params[])
{
    #pragma unused params
    new helpMsg[900];
    format(helpMsg, sizeof(helpMsg),
        "{FFD166}=== PANDUAN PERINTAH SERVER PARADISE ROLEPLAY ===\n\n\
        {00D4FF}/b, /o, /pm, /re, /togpm, /togooc        {FFFFFF}: Perintah Chat OOC\n\
        {00D4FF}/me, /do, /ame, /ado, /my                {FFFFFF}: Perintah Roleplay Deskriptif\n\
        {00D4FF}/try, /roll, /coin, /setstatus, /setdesc {FFFFFF}: Perintah Interaksi & Status RP\n\
        {00D4FF}/anim, /stopanim                         {FFFFFF}: Animasi Karakter\n\
        {00D4FF}/stats, /gantikarakter, /pengaturan      {FFFFFF}: Manajemen Karakter & Akun\n\
        {00D4FF}/pay, /bank, /atm, /balance, /paycheck   {FFFFFF}: Keuangan, Bank, ATM & Gaji\n\
        {00D4FF}/deposit, /withdraw, /transfer, /mutasi  {FFFFFF}: Transaksi Rekening Bank\n\
        {00D4FF}/report, /ask                            {FFFFFF}: Laporan & Bantuan Staff\n\
        {00D4FF}/admins, /versi                          {FFFFFF}: Informasi Server & Staff"
    );
    ShowPlayerDialog(playerid, 399, DIALOG_STYLE_MSGBOX, "{00D4FF}Pusat Bantuan PARADISE RP", helpMsg, "Tutup", "");
    return 1;
}
alias:help("bantuan")

CMD:ujiutil(playerid, params[])
{
    #pragma unused params
    new rpName[MAX_PLAYER_NAME], moneyPos[32], moneyNeg[32], timeStr[32], durStr[64], msg[160];
    GetPlayerRoleplayName(playerid, rpName, sizeof(rpName));
    FormatMoney(1500000, moneyPos, sizeof(moneyPos));
    FormatMoney(-250, moneyNeg, sizeof(moneyNeg));
    GetFormattedServerTime(timeStr, sizeof(timeStr));
    FormatDuration(3725, durStr, sizeof(durStr));

    format(msg, sizeof(msg), "[Uji Util] Nama RP: %s | Positif: %s | Negatif: %s", rpName, moneyPos, moneyNeg);
    SendClientMessage(playerid, COLOR_INFO, "%s", msg);
    format(msg, sizeof(msg), "[Uji Util] Waktu: %s | Durasi: %s", timeStr, durStr);
    SendClientMessage(playerid, COLOR_INFO, "%s", msg);
    return 1;
}
