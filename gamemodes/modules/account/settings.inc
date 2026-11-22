/**
 * File: gamemodes/modules/account/settings.inc
 * Modul: Account Settings & Password Management
 * Deskripsi: Menyediakan menu interaktif /pengaturan (/settings) untuk mengganti
 *            password dengan verifikasi bcrypt, mengatur toggle PM/OOC/HUD,
 *            serta mengganti bahasa antarmuka.
 * Dependensi: <open.mp>, <a_mysql>, <samp_bcrypt>, <Pawn.CMD>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/account/security.inc
 */

#if defined _INC_ACCOUNT_SETTINGS
    #endinput
#endif
#define _INC_ACCOUNT_SETTINGS

#include <Pawn.CMD>
#include <YSI_Coding\y_hooks>

// ============================================================================
// FUNGSI PUBLIK MODUL (ACCOUNT_*)
// ============================================================================

/**
 * Menampilkan dialog utama pengaturan akun pemain.
 */
stock Account_ShowSettingsMenu(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus login ke akun terlebih dahulu!");
        return 0;
    }

    new
        dialogBody[512],
        emailDisplay[128];

    if (PlayerData[playerid][pEmail][0] != EOS)
    {
        format(emailDisplay, sizeof(emailDisplay), "%s", PlayerData[playerid][pEmail]);
    }
    else
    {
        format(emailDisplay, sizeof(emailDisplay), "Belum diatur");
    }

    format(
        dialogBody,
        sizeof(dialogBody),
        "Pengaturan\tStatus\n\
        Ganti Password Akun\t{FFD166}Ubah\n\
        Private Message (PM)\t%s\n\
        Global OOC Chat\t%s\n\
        Tampilan HUD Layar\t%s\n\
        Bahasa Antarmuka\t{00D4FF}%s\n\
        Info Akun (ID #%d | Email: %s)\t{B0B8C1}Lihat",
        PlayerData[playerid][pTogPM] ? ("{2EC4B6}Aktif") : ("{FF4D4D}Nonaktif"),
        PlayerData[playerid][pTogOOC] ? ("{2EC4B6}Aktif") : ("{FF4D4D}Nonaktif"),
        PlayerData[playerid][pTogHUD] ? ("{2EC4B6}Aktif") : ("{FF4D4D}Nonaktif"),
        (strcmp(PlayerData[playerid][pLanguage], "en", true) == 0) ? ("English") : ("Bahasa Indonesia"),
        PlayerData[playerid][pAccountID],
        emailDisplay
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_ACCOUNT_SETTINGS,
        DIALOG_STYLE_TABLIST_HEADERS,
        "{00D4FF}Pengaturan Akun - PARADISE Roleplay",
        dialogBody,
        "Pilih",
        "Tutup"
    );
    return 1;
}

/**
 * Menyimpan perubahan pengaturan toggle/bahasa pemain ke database.
 */
static Account_SavePreferences(playerid)
{
    if (!Database_IsConnected() || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    new query[256];
    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "UPDATE `accounts` SET `tog_pm` = %d, `tog_ooc` = %d, `tog_hud` = %d, `language` = '%e' WHERE `id` = %d",
        PlayerData[playerid][pTogPM] ? 1 : 0,
        PlayerData[playerid][pTogOOC] ? 1 : 0,
        PlayerData[playerid][pTogHUD] ? 1 : 0,
        PlayerData[playerid][pLanguage],
        PlayerData[playerid][pAccountID]
    );
    mysql_tquery(g_SQL, query);
    return 1;
}

// ============================================================================
// PERINTAH PEMAIN
// ============================================================================
CMD:pengaturan(playerid, params[])
{
    #pragma unused params
    Account_ShowSettingsMenu(playerid);
    return 1;
}
alias:pengaturan("settings", "account")

// ============================================================================
// HOOK DIALOG RESPONSE PENGATURAN AKUN
// ============================================================================
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_ACCOUNT_SETTINGS:
        {
            if (!response || !PlayerData[playerid][pAccountLoaded])
            {
                return 1;
            }

            switch (listitem)
            {
                case 0: // Ganti Password
                {
                    ShowPlayerDialog(
                        playerid,
                        DIALOG_CHANGE_PASS_OLD,
                        DIALOG_STYLE_PASSWORD,
                        "{00D4FF}Ganti Password - Verifikasi",
                        "{FFFFFF}Masukkan password akun Anda saat ini:",
                        "Lanjut",
                        "Batal"
                    );
                }
                case 1: // Toggle PM
                {
                    PlayerData[playerid][pTogPM] = !PlayerData[playerid][pTogPM];
                    Account_SavePreferences(playerid);
                    SendClientMessage(
                        playerid,
                        COLOR_INFO,
                        PlayerData[playerid][pTogPM] ? ("Private Message (PM) diaktifkan.") : ("Private Message (PM) dinonaktifkan.")
                    );
                    Account_ShowSettingsMenu(playerid);
                }
                case 2: // Toggle OOC
                {
                    PlayerData[playerid][pTogOOC] = !PlayerData[playerid][pTogOOC];
                    Account_SavePreferences(playerid);
                    SendClientMessage(
                        playerid,
                        COLOR_INFO,
                        PlayerData[playerid][pTogOOC] ? ("Global OOC Chat diaktifkan.") : ("Global OOC Chat dinonaktifkan.")
                    );
                    Account_ShowSettingsMenu(playerid);
                }
                case 3: // Toggle HUD
                {
                    PlayerData[playerid][pTogHUD] = !PlayerData[playerid][pTogHUD];
                    Account_SavePreferences(playerid);
                    SendClientMessage(
                        playerid,
                        COLOR_INFO,
                        PlayerData[playerid][pTogHUD] ? ("Tampilan HUD layar diaktifkan.") : ("Tampilan HUD layar dinonaktifkan.")
                    );
                    Account_ShowSettingsMenu(playerid);
                }
                case 4: // Bahasa
                {
                    ShowPlayerDialog(
                        playerid,
                        DIALOG_CHANGE_LANGUAGE,
                        DIALOG_STYLE_LIST,
                        "{00D4FF}Pilih Bahasa Antarmuka",
                        "Bahasa Indonesia (ID)\nEnglish (EN)",
                        "Simpan",
                        "Kembali"
                    );
                }
                case 5: // Info Akun
                {
                    new infoMsg[256];
                    format(
                        infoMsg,
                        sizeof(infoMsg),
                        "[Info Akun] ID: #%d | Username: %s | VIP Level: %d (Exp: %s) | IP Daftar: %s",
                        PlayerData[playerid][pAccountID],
                        PlayerData[playerid][pUsername],
                        PlayerData[playerid][pVIPLevel],
                        PlayerData[playerid][pVIPExpire],
                        PlayerData[playerid][pRegisterIP]
                    );
                    SendClientMessage(playerid, COLOR_INFO, "%s", infoMsg);
                    Account_ShowSettingsMenu(playerid);
                }
            }
            return 1;
        }

        case DIALOG_CHANGE_LANGUAGE:
        {
            if (!response)
            {
                Account_ShowSettingsMenu(playerid);
                return 1;
            }

            if (listitem == 1)
            {
                format(PlayerData[playerid][pLanguage], 8, "en");
                SendClientMessage(playerid, COLOR_SUCCESS, "Language preference updated to English.");
            }
            else
            {
                format(PlayerData[playerid][pLanguage], 8, "id");
                SendClientMessage(playerid, COLOR_SUCCESS, "Preferensi bahasa diubah ke Bahasa Indonesia.");
            }

            Account_SavePreferences(playerid);
            Account_ShowSettingsMenu(playerid);
            return 1;
        }

        case DIALOG_CHANGE_PASS_OLD:
        {
            if (!response)
            {
                Account_ShowSettingsMenu(playerid);
                return 1;
            }

            if (strlen(inputtext) == 0)
            {
                SendClientMessage(playerid, COLOR_ERROR, "Password lama tidak boleh kosong!");
                Account_ShowSettingsMenu(playerid);
                return 1;
            }

            SendClientMessage(playerid, COLOR_INFO, "Memverifikasi password lama...");
            bcrypt_verify(playerid, "OnAccountOldPassVerified", inputtext, PlayerData[playerid][pPasswordHash]);
            return 1;
        }

        case DIALOG_CHANGE_PASS_NEW:
        {
            if (!response)
            {
                Account_ShowSettingsMenu(playerid);
                return 1;
            }

            new len = strlen(inputtext);
            if (len < ACCOUNT_MIN_PASS_LEN || len > ACCOUNT_MAX_PASS_LEN)
            {
                new err[128];
                format(
                    err,
                    sizeof(err),
                    "{FF4D4D}Password baru harus %d - %d karakter!\n\n{FFFFFF}Masukkan password baru Anda:",
                    ACCOUNT_MIN_PASS_LEN,
                    ACCOUNT_MAX_PASS_LEN
                );
                ShowPlayerDialog(playerid, DIALOG_CHANGE_PASS_NEW, DIALOG_STYLE_PASSWORD, "{00D4FF}Ganti Password - Baru", err, "Lanjut", "Batal");
                return 1;
            }

            format(PlayerData[playerid][pTempPassword], 36, "%s", inputtext);
            ShowPlayerDialog(
                playerid,
                DIALOG_CHANGE_PASS_CONFIRM,
                DIALOG_STYLE_PASSWORD,
                "{00D4FF}Ganti Password - Konfirmasi",
                "{FFFFFF}Masukkan kembali password baru Anda untuk konfirmasi:",
                "Simpan",
                "Batal"
            );
            return 1;
        }

        case DIALOG_CHANGE_PASS_CONFIRM:
        {
            if (!response)
            {
                for (new i = 0; i < 36; i++)
                {
                    PlayerData[playerid][pTempPassword][i] = 0;
                }
                Account_ShowSettingsMenu(playerid);
                return 1;
            }

            if (strcmp(inputtext, PlayerData[playerid][pTempPassword], false) != 0)
            {
                for (new i = 0; i < 36; i++)
                {
                    PlayerData[playerid][pTempPassword][i] = 0;
                }
                SendClientMessage(playerid, COLOR_ERROR, "Konfirmasi password baru tidak cocok!");
                Account_ShowSettingsMenu(playerid);
                return 1;
            }

            new racecheck = Database_GetPlayerRaceCheck(playerid);
            SendClientMessage(playerid, COLOR_INFO, "Menyimpan password baru Anda...");
            bcrypt_hash(playerid, "OnAccountNewPassHashed", PlayerData[playerid][pTempPassword], ACCOUNT_BCRYPT_COST, "i", racecheck);

            for (new i = 0; i < 36; i++)
            {
                PlayerData[playerid][pTempPassword][i] = 0;
            }
            return 1;
        }
    }
    return 0;
}

// ============================================================================
// CALLBACKS BCRYPT GANTI PASSWORD
// ============================================================================
forward OnAccountOldPassVerified(playerid, bool:success);
public OnAccountOldPassVerified(playerid, bool:success)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    if (!success)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Password lama yang Anda masukkan salah!");
        Account_ShowSettingsMenu(playerid);
        return 1;
    }

    new prompt[160];
    format(
        prompt,
        sizeof(prompt),
        "{FFFFFF}Masukkan password baru Anda ({FFD166}%d - %d karakter{FFFFFF}):",
        ACCOUNT_MIN_PASS_LEN,
        ACCOUNT_MAX_PASS_LEN
    );
    ShowPlayerDialog(playerid, DIALOG_CHANGE_PASS_NEW, DIALOG_STYLE_PASSWORD, "{00D4FF}Ganti Password - Baru", prompt, "Lanjut", "Batal");
    return 1;
}

forward OnAccountNewPassHashed(playerid, racecheck);
public OnAccountNewPassHashed(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    new
        newHash[128],
        query[320],
        logMsg[160];

    bcrypt_get_hash(newHash, sizeof(newHash));
    format(PlayerData[playerid][pPasswordHash], 128, "%s", newHash);

    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "UPDATE `accounts` SET `password_hash` = '%e' WHERE `id` = %d",
        newHash,
        PlayerData[playerid][pAccountID]
    );
    mysql_tquery(g_SQL, query);

    format(logMsg, sizeof(logMsg), "Perubahan password akun: %s (AccountID: #%d)", PlayerData[playerid][pUsername], PlayerData[playerid][pAccountID]);
    Account_LogAuthEvent(logMsg, PlayerData[playerid][pCurrentIP]);

    SendClientMessage(playerid, COLOR_SUCCESS, "Password akun Anda berhasil diperbarui!");
    return 1;
}
