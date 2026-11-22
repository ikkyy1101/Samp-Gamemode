/**
 * File: gamemodes/core/enums.inc
 * Modul: Core Enumerations
 * Deskripsi: Menyimpan seluruh definisi enum global (status autentikasi, ID dialog,
 *            hierarki admin, antrean report, ATM, dan struktur data pemain E_PLAYER_DATA).
 * Dependensi: <open.mp>, <streamer>
 */

#if defined _INC_CORE_ENUMS
    #endinput
#endif
#define _INC_CORE_ENUMS

// ============================================================================
// STATUS AUTENTIKASI & SESI PEMAIN
// ============================================================================
enum E_AUTH_STATE
{
    AUTH_STATE_NONE = 0,
    AUTH_STATE_CHECKING_BAN,
    AUTH_STATE_CHECKING_ACCOUNT,
    AUTH_STATE_REGISTER_PASS,
    AUTH_STATE_REGISTER_CONFIRM,
    AUTH_STATE_REGISTER_EMAIL,
    AUTH_STATE_HASHING,
    AUTH_STATE_LOGIN_PROMPT,
    AUTH_STATE_VERIFYING,
    AUTH_STATE_AUTHENTICATED,
    AUTH_STATE_CHAR_SELECT,
    AUTH_STATE_CHAR_CREATE,
    AUTH_STATE_SPAWN_SELECT,
    AUTH_STATE_TUTORIAL,
    AUTH_STATE_SPAWNED
};

// ============================================================================
// TINGKAT STAFF & ADMIN
// ============================================================================
enum
{
    ADMIN_LEVEL_NONE = 0,
    ADMIN_LEVEL_TRIAL_HELPER = 1,
    ADMIN_LEVEL_HELPER = 2,
    ADMIN_LEVEL_MODERATOR = 3,
    ADMIN_LEVEL_ADMIN = 4,
    ADMIN_LEVEL_SENIOR = 5,
    ADMIN_LEVEL_LEAD = 6,
    ADMIN_LEVEL_OWNER = 7
};

// ============================================================================
// ID DIALOG GLOBAL (TERPUSAT AGAR TIDAK BENTROK ANTAR MODUL)
// ============================================================================
enum
{
    DIALOG_UNUSED = 0,

    // Modul Akun (100 - 199)
    DIALOG_REGISTER_PASS = 100,
    DIALOG_REGISTER_CONFIRM,
    DIALOG_REGISTER_EMAIL,
    DIALOG_LOGIN,
    DIALOG_ACCOUNT_SETTINGS,
    DIALOG_CHANGE_PASS_OLD,
    DIALOG_CHANGE_PASS_NEW,
    DIALOG_CHANGE_PASS_CONFIRM,
    DIALOG_CHANGE_LANGUAGE,

    // Modul Karakter (200 - 299)
    DIALOG_CHAR_SELECT = 200,
    DIALOG_CHAR_ACTION,
    DIALOG_CHAR_DELETE_PASS,
    DIALOG_CHAR_CREATE_NAME,
    DIALOG_CHAR_CREATE_GENDER,
    DIALOG_CHAR_CREATE_AGE,
    DIALOG_CHAR_CREATE_ORIGIN,
    DIALOG_CHAR_CREATE_SKIN,
    DIALOG_CHAR_SPAWN_SELECT,
    DIALOG_CHAR_STATS,

    // Modul Chat & Animasi (300 - 399)
    DIALOG_ANIM_LIST = 300,
    DIALOG_EXAMINE_INFO,

    // Modul Admin & Staff (400 - 499)
    DIALOG_ADMIN_PIN_SETUP = 400,
    DIALOG_ADMIN_PIN_LOGIN,
    DIALOG_ADMIN_CHECK_STATS,
    DIALOG_ADMIN_REPORTS_LIST,
    DIALOG_ADMIN_LOGS_LIST,
    DIALOG_ADMIN_AKA_LIST,

    // Modul Ekonomi & Perbankan (500 - 599)
    DIALOG_BANK_MAIN = 500,
    DIALOG_BANK_DEPOSIT,
    DIALOG_BANK_WITHDRAW,
    DIALOG_BANK_TRANSFER_TARGET,
    DIALOG_BANK_TRANSFER_AMOUNT,
    DIALOG_BANK_MUTASI,
    DIALOG_ATM_MAIN,
    DIALOG_ATM_WITHDRAW,
    DIALOG_ATM_TRANSFER_TARGET,
    DIALOG_ATM_TRANSFER_AMOUNT
};

// ============================================================================
// STRUKTUR ANTREAN REPORT & ASK
// ============================================================================
enum E_REPORT_DATA
{
    bool:repActive,
    repDBID,
    repType, // 1 = Report Pelanggaran, 2 = Ask/Pertanyaan
    repReporterID,
    repReporterCharID,
    repReporterName[MAX_PLAYER_NAME],
    repReportedID,
    repMessage[160],
    repHandledByID,
    repTimestamp
};

// ============================================================================
// STRUKTUR MESIN ATM DINAMIS
// ============================================================================
enum E_ATM_DATA
{
    bool:atmExists,
    atmDBID,
    Float:atmPosX,
    Float:atmPosY,
    Float:atmPosZ,
    Float:atmRotZ,
    atmInterior,
    atmVirtualWorld,
    atmObjectID,
    Text3D:atmLabel
};

// ============================================================================
// STRUKTUR DATA UTAMA PEMAIN
// ============================================================================
enum E_PLAYER_DATA
{
    // Status Koneksi & Sesi
    E_AUTH_STATE:pAuthState,
    bool:pAccountLoaded,
    bool:pCharacterLoaded,
    pLoginTimer,
    pLoginAttempts,

    // Data Akun (Tabel `accounts`)
    pAccountID,
    pUsername[MAX_PLAYER_NAME],
    pPasswordHash[128],
    pTempPassword[36],
    pEmail[128],
    pRegisterIP[46],
    pCurrentIP[46],
    pLastIP[46],
    pLastLogin[32],
    pGPCI[64],
    pAdminLevel,
    pAdminPinHash[128],
    pHelperLevel,
    pVIPLevel,
    pVIPExpire[32],
    pLanguage[8],
    bool:pTogPM,
    bool:pTogOOC,
    bool:pTogHUD,

    // Slot Seleksi & Pembuatan Karakter Sementara
    pCharSlotIDs[3],
    pSelectedSlotIndex,
    pCreateName[MAX_PLAYER_NAME],
    pCreateGender,
    pCreateAge,
    pCreateOrigin[48],
    pCreateSkinIndex,
    pTutorialStep,

    // Data Karakter Aktif (Tabel `characters`)
    pCharacterID,
    pCharName[MAX_PLAYER_NAME],
    pGender,
    pAge,
    pOrigin[48],
    pSkin,
    Float:pPosX,
    Float:pPosY,
    Float:pPosZ,
    Float:pPosA,
    pInterior,
    pVirtualWorld,
    Float:pHealth,
    Float:pArmour,
    pMoney,
    pBankMoney,
    pBankAccountNo[16],
    pLevel,
    pExp,
    pPlayingHours,
    pPaycheckMinutes,
    pJobID,
    pJobContractHours,
    pFactionID,
    pFactionRank,
    pPhoneNumber[16],
    Float:pHunger,
    Float:pThirst,
    Float:pStress,
    bool:pInjured,
    pInjuredTime,
    pJailTime,
    pJailType,
    pWantedLevel,
    pWantedReason[128],
    bool:pLicDriving,
    bool:pLicWeapon,
    bool:pLicFlying,
    bool:pLicBoat,
    pSpawnPoint,
    pSpawnHouseID,
    pAccent[32],
    pDescription[160],
    bool:pTutorialDone,

    // Atribut Chat, Anti-Spam & Animasi (Tahap 5)
    pLastChatTick,
    pLastCmdTick,
    pLastOOCGlobalTick,
    pLastChatText[144],
    pLastPMSenderID,
    pMuteTime,
    pRPStatus[96],
    Text3D:pAdoLabel,
    bool:pUsingAnim,
    bool:pAnimPreloaded,

    // Atribut Admin & Moderasi (Tahap 6)
    bool:pAdminLoggedIn,
    bool:pAdminDuty,
    Text3D:pAdminDutyLabel,
    bool:pFrozen,
    pWarnCount,
    bool:pSpectating,
    pSpecTargetID,
    Float:pSpecOldX,
    Float:pSpecOldY,
    Float:pSpecOldZ,
    Float:pSpecOldA,
    pSpecOldInt,
    pSpecOldVW,
    pAdminVehicleID,

    // Atribut Ekonomi, Bank & Paycheck (Tahap 7)
    pTransferTargetCharID,
    pTransferTargetPlayerID,
    pTransferTargetName[MAX_PLAYER_NAME],
    pTransferTargetAccNo[16],
    pLastActiveTick,
    pPendingPaycheckBonus
};
