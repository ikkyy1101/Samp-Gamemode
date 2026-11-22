/**
 * File: gamemodes/modules/character/create.inc
 * Modul: Character Creation & Skin Preview
 * Deskripsi: Menangani alur pembuatan karakter baru (nama RP unik, gender, umur 18-80,
 *            kota asal, pratinjau pakaian/skin di depan kamera), pembuatan nomor HP
 *            dan rekening bank unik, serta insert ke tabel `characters`.
 * Dependensi: <open.mp>, <a_mysql>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/character/select.inc
 */

#if defined _INC_CHARACTER_CREATE
    #endinput
#endif
#define _INC_CHARACTER_CREATE

#include <YSI_Coding\y_hooks>

// ============================================================================
// KONSTANTA PEMBUATAN KARAKTER & DAFTAR SKIN AWAL
// ============================================================================
#define CHAR_MIN_AGE            (18)
#define CHAR_MAX_AGE            (80)
#define CHAR_DEFAULT_CASH       (500)
#define CHAR_DEFAULT_BANK       (2500)
#define MAX_STARTER_SKINS       (8)

static const s_MaleStarterSkins[MAX_STARTER_SKINS] = {
    29, 21, 22, 23, 60, 170, 188, 250
};

static const s_FemaleStarterSkins[MAX_STARTER_SKINS] = {
    12, 13, 41, 56, 91, 141, 192, 233
};

// ============================================================================
// FUNGSI INTERNAL DIALOG & PREVIEW KAMERA
// ============================================================================
static Character_ShowCreateNameDialog(playerid, const errorNotice[] = "")
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_CREATE;

    new dialogText[448];
    if (errorNotice[0] != EOS)
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FF4D4D}%s\n\n\
            {FFFFFF}Masukkan nama karakter Roleplay Anda dengan format {FFD166}Nama_Marga{FFFFFF}.\n\
            Contoh: {2EC4B6}Andi_Wijaya {FFFFFF}atau {2EC4B6}Siti_Rahmawati\n\
            {B0B8C1}Dilarang menggunakan nama tokoh terkenal, artis, atau singkatan.",
            errorNotice
        );
    }
    else
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FFFFFF}Masukkan nama karakter Roleplay Anda dengan format {FFD166}Nama_Marga{FFFFFF}.\n\
            Contoh: {2EC4B6}Andi_Wijaya {FFFFFF}atau {2EC4B6}Siti_Rahmawati\n\
            {B0B8C1}Dilarang menggunakan nama tokoh terkenal, artis, atau singkatan."
        );
    }

    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_NAME, DIALOG_STYLE_INPUT, "{00D4FF}Buat Karakter - Langkah 1/5 (Nama)", dialogText, "Lanjut", "Batal");
    return 1;
}

static Character_ShowCreateGenderDialog(playerid)
{
    ShowPlayerDialog(
        playerid,
        DIALOG_CHAR_CREATE_GENDER,
        DIALOG_STYLE_LIST,
        "{00D4FF}Buat Karakter - Langkah 2/5 (Jenis Kelamin)",
        "Laki-laki (Pria)\nPerempuan (Wanita)",
        "Lanjut",
        "Kembali"
    );
    return 1;
}

static Character_ShowCreateAgeDialog(playerid, const errorNotice[] = "")
{
    new dialogText[320];
    if (errorNotice[0] != EOS)
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FF4D4D}%s\n\n\
            {FFFFFF}Masukkan usia karakter Anda ({FFD166}%d - %d tahun{FFFFFF}):",
            errorNotice,
            CHAR_MIN_AGE,
            CHAR_MAX_AGE
        );
    }
    else
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FFFFFF}Masukkan usia karakter Anda ({FFD166}%d - %d tahun{FFFFFF}):",
            CHAR_MIN_AGE,
            CHAR_MAX_AGE
        );
    }

    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_AGE, DIALOG_STYLE_INPUT, "{00D4FF}Buat Karakter - Langkah 3/5 (Usia)", dialogText, "Lanjut", "Kembali");
    return 1;
}

static Character_ShowCreateOriginDialog(playerid, const errorNotice[] = "")
{
    new dialogText[384];
    if (errorNotice[0] != EOS)
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FF4D4D}%s\n\n\
            {FFFFFF}Masukkan kota/negara asal karakter Anda (3 - 32 huruf):\n\
            Contoh: {2EC4B6}Los Santos, Jakarta, Liberty City, Tokyo",
            errorNotice
        );
    }
    else
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FFFFFF}Masukkan kota/negara asal karakter Anda (3 - 32 huruf):\n\
            Contoh: {2EC4B6}Los Santos, Jakarta, Liberty City, Tokyo"
        );
    }

    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_ORIGIN, DIALOG_STYLE_INPUT, "{00D4FF}Buat Karakter - Langkah 4/5 (Asal)", dialogText, "Lanjut", "Kembali");
    return 1;
}

/**
 * Menampilkan preview model skin karakter secara langsung di pantai Santa Maria
 * dengan dialog kontrol ganti pakaian (Sebelumnya / Berikutnya / Selesai).
 */
static Character_ShowSkinPreview(playerid)
{
    new
        idx = PlayerData[playerid][pCreateSkinIndex],
        skinId = (PlayerData[playerid][pCreateGender] == 2) ? s_FemaleStarterSkins[idx] : s_MaleStarterSkins[idx],
        vw = playerid + 500;

    TogglePlayerSpectating(playerid, false);
    SetSpawnInfo(playerid, NO_TEAM, skinId, 384.6500, -2060.5000, 7.8359, 90.0, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    SpawnPlayer(playerid);

    SetPlayerVirtualWorld(playerid, vw);
    SetPlayerInterior(playerid, 0);
    SetPlayerPos(playerid, 384.6500, -2060.5000, 7.8359);
    SetPlayerFacingAngle(playerid, 90.0);
    SetPlayerSkin(playerid, skinId);
    TogglePlayerControllable(playerid, false);

    // Kamera menghadap tepat ke depan karakter
    SetPlayerCameraPos(playerid, 381.2000, -2060.5000, 8.4000);
    SetPlayerCameraLookAt(playerid, 384.6500, -2060.5000, 8.1000);

    new dialogBody[384];
    format(
        dialogBody,
        sizeof(dialogBody),
        "{FFFFFF}Nama: {FFD166}%s\n\
        {FFFFFF}Gender: {FFD166}%s {FFFFFF}| Usia: {FFD166}%d thn {FFFFFF}| Asal: {FFD166}%s\n\
        {FFFFFF}Pakaian Saat Ini: {00D4FF}Pilihan %d/%d (Skin ID: %d)\n\n\
        {2EC4B6}>> Pakaian Berikutnya\n\
        {FFD166}<< Pakaian Sebelumnya\n\
        {00D4FF}[Selesai & Buat Karakter]",
        PlayerData[playerid][pCreateName],
        (PlayerData[playerid][pCreateGender] == 2) ? ("Perempuan") : ("Laki-laki"),
        PlayerData[playerid][pCreateAge],
        PlayerData[playerid][pCreateOrigin],
        idx + 1,
        MAX_STARTER_SKINS,
        skinId
    );

    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_SKIN, DIALOG_STYLE_LIST, "{00D4FF}Buat Karakter - Langkah 5/5 (Pakaian)", dialogBody, "Pilih", "Kembali");
    return 1;
}

static bool:Character_IsValidOrigin(const str[])
{
    new len = strlen(str);
    if (len < 3 || len > 32)
    {
        return false;
    }

    for (new i = 0; i < len; i++)
    {
        new c = str[i];
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == ' ' || c == '-'))
        {
            return false;
        }
    }
    return true;
}

// ============================================================================
// FUNGSI PUBLIK ENTRY PEMBUATAN KARAKTER
// ============================================================================
public Character_StartCreation(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    PlayerData[playerid][pCreateName][0] = EOS;
    PlayerData[playerid][pCreateGender] = 1;
    PlayerData[playerid][pCreateAge] = 21;
    PlayerData[playerid][pCreateOrigin][0] = EOS;
    PlayerData[playerid][pCreateSkinIndex] = 0;

    Character_ShowCreateNameDialog(playerid);
    return 1;
}

// ============================================================================
// HOOK DIALOG RESPONSE PEMBUATAN KARAKTER
// ============================================================================
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_CHAR_CREATE_NAME:
        {
            if (!response)
            {
                Character_ShowSelection(playerid);
                return 1;
            }

            if (!IsValidRoleplayName(inputtext))
            {
                Character_ShowCreateNameDialog(playerid, "Format nama tidak valid! Gunakan Nama_Marga (huruf saja, 3-24 karakter).");
                return 1;
            }

            format(PlayerData[playerid][pCreateName], MAX_PLAYER_NAME, "%s", inputtext);

            new
                racecheck = Database_GetPlayerRaceCheck(playerid),
                query[256];

            mysql_format(
                g_SQL,
                query,
                sizeof(query),
                "SELECT `id` FROM `characters` WHERE `name` = '%e' LIMIT 1",
                PlayerData[playerid][pCreateName]
            );
            mysql_tquery(g_SQL, query, "OnCharacterNameCheckResult", "ii", playerid, racecheck);
            return 1;
        }

        case DIALOG_CHAR_CREATE_GENDER:
        {
            if (!response)
            {
                Character_ShowCreateNameDialog(playerid);
                return 1;
            }

            PlayerData[playerid][pCreateGender] = (listitem == 1) ? 2 : 1;
            PlayerData[playerid][pCreateSkinIndex] = 0;
            Character_ShowCreateAgeDialog(playerid);
            return 1;
        }

        case DIALOG_CHAR_CREATE_AGE:
        {
            if (!response)
            {
                Character_ShowCreateGenderDialog(playerid);
                return 1;
            }

            new age = strval(inputtext);
            if (age < CHAR_MIN_AGE || age > CHAR_MAX_AGE)
            {
                new err[96];
                format(err, sizeof(err), "Usia karakter harus di antara %d hingga %d tahun!", CHAR_MIN_AGE, CHAR_MAX_AGE);
                Character_ShowCreateAgeDialog(playerid, err);
                return 1;
            }

            PlayerData[playerid][pCreateAge] = age;
            Character_ShowCreateOriginDialog(playerid);
            return 1;
        }

        case DIALOG_CHAR_CREATE_ORIGIN:
        {
            if (!response)
            {
                Character_ShowCreateAgeDialog(playerid);
                return 1;
            }

            if (!Character_IsValidOrigin(inputtext))
            {
                Character_ShowCreateOriginDialog(playerid, "Asal kota tidak valid! Gunakan 3-32 karakter huruf.");
                return 1;
            }

            format(PlayerData[playerid][pCreateOrigin], 48, "%s", inputtext);
            PlayerData[playerid][pCreateSkinIndex] = 0;
            Character_ShowSkinPreview(playerid);
            return 1;
        }

        case DIALOG_CHAR_CREATE_SKIN:
        {
            if (!response)
            {
                TogglePlayerControllable(playerid, true);
                Account_SetupLoginCamera(playerid);
                Character_ShowCreateOriginDialog(playerid);
                return 1;
            }

            // Baris 0-2 pada dialog adalah info teks, baris 3 = Next, 4 = Prev, 5 = Selesai
            switch (listitem)
            {
                case 3: // Pakaian Berikutnya
                {
                    PlayerData[playerid][pCreateSkinIndex] = (PlayerData[playerid][pCreateSkinIndex] + 1) % MAX_STARTER_SKINS;
                    Character_ShowSkinPreview(playerid);
                }
                case 4: // Pakaian Sebelumnya
                {
                    PlayerData[playerid][pCreateSkinIndex] = (PlayerData[playerid][pCreateSkinIndex] - 1 + MAX_STARTER_SKINS) % MAX_STARTER_SKINS;
                    Character_ShowSkinPreview(playerid);
                }
                case 5: // Selesai & Simpan ke Database
                {
                    TogglePlayerControllable(playerid, true);

                    new
                        idx = PlayerData[playerid][pCreateSkinIndex],
                        skinId = (PlayerData[playerid][pCreateGender] == 2) ? s_FemaleStarterSkins[idx] : s_MaleStarterSkins[idx],
                        phoneNum[16],
                        bankNo[16],
                        racecheck = Database_GetPlayerRaceCheck(playerid),
                        query[768];

                    // Generate nomor ponsel & rekening bank acak unik
                    format(phoneNum, sizeof(phoneNum), "555%04d", random(9000) + 1000);
                    format(bankNo, sizeof(bankNo), "PRD-%06d", random(900000) + 100000);

                    mysql_format(
                        g_SQL,
                        query,
                        sizeof(query),
                        "INSERT INTO `characters` (`account_id`, `name`, `gender`, `age`, `origin`, `skin`, \
                         `money`, `bank_money`, `bank_account_no`, `phone_number`, `tutorial_done`, `last_played`) \
                         VALUES (%d, '%e', %d, %d, '%e', %d, %d, %d, '%e', '%e', 0, NOW())",
                        PlayerData[playerid][pAccountID],
                        PlayerData[playerid][pCreateName],
                        PlayerData[playerid][pCreateGender],
                        PlayerData[playerid][pCreateAge],
                        PlayerData[playerid][pCreateOrigin],
                        skinId,
                        CHAR_DEFAULT_CASH,
                        CHAR_DEFAULT_BANK,
                        bankNo,
                        phoneNum
                    );
                    mysql_tquery(g_SQL, query, "OnCharacterCreated", "ii", playerid, racecheck);
                }
                default:
                {
                    Character_ShowSkinPreview(playerid);
                }
            }
            return 1;
        }
    }
    return 0;
}

// ============================================================================
// CALLBACKS MYSQL PEMBUATAN KARAKTER
// ============================================================================
forward OnCharacterNameCheckResult(playerid, racecheck);
public OnCharacterNameCheckResult(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (cache_num_rows() > 0)
    {
        Character_ShowCreateNameDialog(playerid, "Nama karakter tersebut sudah digunakan warga lain! Pilih nama lain.");
        return 1;
    }

    Character_ShowCreateGenderDialog(playerid);
    return 1;
}

forward OnCharacterCreated(playerid, racecheck);
public OnCharacterCreated(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    new newCharId = cache_insert_id();
    if (newCharId <= 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Gagal membuat karakter (terjadi bentrok data). Silakan coba lagi.");
        Account_SetupLoginCamera(playerid);
        Character_ShowSelection(playerid);
        return 1;
    }

    new logMsg[192];
    format(
        logMsg,
        sizeof(logMsg),
        "Karakter baru dibuat: %s (CharID: #%d) pada akun %s (#%d)",
        PlayerData[playerid][pCreateName],
        newCharId,
        PlayerData[playerid][pUsername],
        PlayerData[playerid][pAccountID]
    );
    Account_LogAuthEvent(logMsg, PlayerData[playerid][pCurrentIP]);

    SendClientMessage(playerid, COLOR_SUCCESS, "Karakter baru berhasil dibuat! Memuat karakter Anda...");
    Character_LoadByID(playerid, newCharId);
    return 1;
}
