/**
 * File: gamemodes/core/variables.inc
 * Modul: Core Global Variables & Iterators
 * Deskripsi: Menyimpan array data global pemain, iterator pemain aktif,
 *            antrean report, data ATM dinamis, serta fungsi reset data.
 * Dependensi: <open.mp>, <streamer>, <YSI_Coding\y_iterate>, core/enums.inc
 */

#if defined _INC_CORE_VARIABLES
    #endinput
#endif
#define _INC_CORE_VARIABLES

#include <streamer>

// ============================================================================
// KONSTANTA ARRAY GLOBAL
// ============================================================================
#define MAX_ACTIVE_REPORTS          (30)
#define MAX_SERVER_ATMS             (60)

// ============================================================================
// VARIABEL & ITERATOR GLOBAL
// ============================================================================
new PlayerData[MAX_PLAYERS][E_PLAYER_DATA];
new ReportData[MAX_ACTIVE_REPORTS][E_REPORT_DATA];
new ATMData[MAX_SERVER_ATMS][E_ATM_DATA];

// Buffer nama slot karakter (maks 3 per akun)
new g_CharSlotNames[MAX_PLAYERS][3][MAX_PLAYER_NAME];
#define PlayerData[%0][pCharSlotNames][%1] g_CharSlotNames[%0][%1]

// Status global OOC (/o) yang dapat diubah oleh Admin
new bool:g_GlobalOOCEnabled = true;

// Hitung mundur restart server (/gmx), 0 = tidak aktif
new g_GMXCountdown = 0;

// Iterator khusus pemain yang sudah berhasil login ke akun
new Iterator:LoggedInPlayers<MAX_PLAYERS>;

// Iterator khusus pemain yang sudah spawn ke dalam dunia RP
new Iterator:SpawnedPlayers<MAX_PLAYERS>;

// Iterator khusus staff yang aktif bertugas
new Iterator:OnlineStaff<MAX_PLAYERS>;

// Iterator khusus mesin ATM aktif
new Iterator:ActiveATMs<MAX_SERVER_ATMS>;

// ============================================================================
// FUNGSI PEMBERSIHAN DATA PEMAIN
// ============================================================================

/**
 * Mereset seluruh slot memori PlayerData untuk playerid tertentu.
 * Wajib dipanggil pada OnPlayerConnect dan OnPlayerDisconnect.
 */
stock Variables_ResetPlayerData(playerid)
{
    if (playerid < 0 || playerid >= MAX_PLAYERS)
    {
        return 0;
    }

    if (IsValidDynamic3DTextLabel(PlayerData[playerid][pAdoLabel]))
    {
        DestroyDynamic3DTextLabel(PlayerData[playerid][pAdoLabel]);
    }

    if (IsValidDynamic3DTextLabel(PlayerData[playerid][pAdminDutyLabel]))
    {
        DestroyDynamic3DTextLabel(PlayerData[playerid][pAdminDutyLabel]);
    }

    if (PlayerData[playerid][pAdminVehicleID] != INVALID_VEHICLE_ID && IsValidVehicle(PlayerData[playerid][pAdminVehicleID]))
    {
        DestroyVehicle(PlayerData[playerid][pAdminVehicleID]);
    }

    static const emptyData[E_PLAYER_DATA];
    PlayerData[playerid] = emptyData;

    PlayerData[playerid][pAuthState] = AUTH_STATE_NONE;
    PlayerData[playerid][pAccountLoaded] = false;
    PlayerData[playerid][pCharacterLoaded] = false;
    PlayerData[playerid][pLoginTimer] = 0;
    PlayerData[playerid][pLoginAttempts] = 0;
    PlayerData[playerid][pAccountID] = 0;
    PlayerData[playerid][pCharacterID] = 0;
    PlayerData[playerid][pSelectedSlotIndex] = -1;
    PlayerData[playerid][pLastPMSenderID] = INVALID_PLAYER_ID;
    PlayerData[playerid][pSpecTargetID] = INVALID_PLAYER_ID;
    PlayerData[playerid][pTransferTargetPlayerID] = INVALID_PLAYER_ID;
    PlayerData[playerid][pAdminVehicleID] = INVALID_VEHICLE_ID;
    PlayerData[playerid][pAdoLabel] = Text3D:INVALID_3DTEXT_ID;
    PlayerData[playerid][pAdminDutyLabel] = Text3D:INVALID_3DTEXT_ID;
    PlayerData[playerid][pTogPM] = true;
    PlayerData[playerid][pTogOOC] = true;
    PlayerData[playerid][pTogHUD] = true;
    PlayerData[playerid][pHealth] = 100.0;
    PlayerData[playerid][pHunger] = 100.0;
    PlayerData[playerid][pThirst] = 100.0;
    PlayerData[playerid][pLevel] = 1;
    format(PlayerData[playerid][pLanguage], 8, "id");

    for (new i = 0; i < 3; i++)
    {
        g_CharSlotNames[playerid][i][0] = EOS;
    }

    Iter_Remove(LoggedInPlayers, playerid);
    Iter_Remove(SpawnedPlayers, playerid);
    Iter_Remove(OnlineStaff, playerid);
    return 1;
}

/**
 * Mereset khusus data karakter tanpa mengeluarkan pemain dari sesi akun.
 * Digunakan saat pemain berpindah karakter (/gantikarakter).
 */
stock Variables_ResetCharacterData(playerid)
{
    if (playerid < 0 || playerid >= MAX_PLAYERS)
    {
        return 0;
    }

    if (IsValidDynamic3DTextLabel(PlayerData[playerid][pAdoLabel]))
    {
        DestroyDynamic3DTextLabel(PlayerData[playerid][pAdoLabel]);
    }

    if (IsValidDynamic3DTextLabel(PlayerData[playerid][pAdminDutyLabel]))
    {
        DestroyDynamic3DTextLabel(PlayerData[playerid][pAdminDutyLabel]);
    }

    PlayerData[playerid][pCharacterLoaded] = false;
    PlayerData[playerid][pCharacterID] = 0;
    PlayerData[playerid][pCharName][0] = EOS;
    PlayerData[playerid][pGender] = 1;
    PlayerData[playerid][pAge] = 21;
    PlayerData[playerid][pOrigin][0] = EOS;
    PlayerData[playerid][pSkin] = 29;
    PlayerData[playerid][pPosX] = 1742.9962;
    PlayerData[playerid][pPosY] = -1860.6310;
    PlayerData[playerid][pPosZ] = 13.5784;
    PlayerData[playerid][pPosA] = 0.0;
    PlayerData[playerid][pInterior] = 0;
    PlayerData[playerid][pVirtualWorld] = 0;
    PlayerData[playerid][pHealth] = 100.0;
    PlayerData[playerid][pArmour] = 0.0;
    PlayerData[playerid][pMoney] = 0;
    PlayerData[playerid][pBankMoney] = 0;
    PlayerData[playerid][pBankAccountNo][0] = EOS;
    PlayerData[playerid][pLevel] = 1;
    PlayerData[playerid][pExp] = 0;
    PlayerData[playerid][pPlayingHours] = 0;
    PlayerData[playerid][pPaycheckMinutes] = 0;
    PlayerData[playerid][pJobID] = 0;
    PlayerData[playerid][pJobContractHours] = 0;
    PlayerData[playerid][pFactionID] = 0;
    PlayerData[playerid][pFactionRank] = 0;
    PlayerData[playerid][pPhoneNumber][0] = EOS;
    PlayerData[playerid][pHunger] = 100.0;
    PlayerData[playerid][pThirst] = 100.0;
    PlayerData[playerid][pStress] = 0.0;
    PlayerData[playerid][pInjured] = false;
    PlayerData[playerid][pInjuredTime] = 0;
    PlayerData[playerid][pJailTime] = 0;
    PlayerData[playerid][pJailType] = 0;
    PlayerData[playerid][pWantedLevel] = 0;
    PlayerData[playerid][pWantedReason][0] = EOS;
    PlayerData[playerid][pLicDriving] = false;
    PlayerData[playerid][pLicWeapon] = false;
    PlayerData[playerid][pLicFlying] = false;
    PlayerData[playerid][pLicBoat] = false;
    PlayerData[playerid][pSpawnPoint] = 0;
    PlayerData[playerid][pSpawnHouseID] = 0;
    PlayerData[playerid][pAccent][0] = EOS;
    PlayerData[playerid][pDescription][0] = EOS;
    PlayerData[playerid][pTutorialDone] = false;

    PlayerData[playerid][pLastChatTick] = 0;
    PlayerData[playerid][pLastCmdTick] = 0;
    PlayerData[playerid][pLastOOCGlobalTick] = 0;
    PlayerData[playerid][pLastChatText][0] = EOS;
    PlayerData[playerid][pLastPMSenderID] = INVALID_PLAYER_ID;
    PlayerData[playerid][pMuteTime] = 0;
    PlayerData[playerid][pRPStatus][0] = EOS;
    PlayerData[playerid][pAdoLabel] = Text3D:INVALID_3DTEXT_ID;
    PlayerData[playerid][pAdminDuty] = false;
    PlayerData[playerid][pAdminDutyLabel] = Text3D:INVALID_3DTEXT_ID;
    PlayerData[playerid][pFrozen] = false;
    PlayerData[playerid][pSpectating] = false;
    PlayerData[playerid][pSpecTargetID] = INVALID_PLAYER_ID;
    PlayerData[playerid][pUsingAnim] = false;

    PlayerData[playerid][pTransferTargetCharID] = 0;
    PlayerData[playerid][pTransferTargetPlayerID] = INVALID_PLAYER_ID;
    PlayerData[playerid][pTransferTargetName][0] = EOS;
    PlayerData[playerid][pTransferTargetAccNo][0] = EOS;
    PlayerData[playerid][pLastActiveTick] = 0;
    PlayerData[playerid][pPendingPaycheckBonus] = 0;

    Iter_Remove(SpawnedPlayers, playerid);
    return 1;
}
