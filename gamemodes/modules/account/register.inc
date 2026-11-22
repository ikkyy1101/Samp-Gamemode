/**
 * File: gamemodes/modules/account/register.inc
 * Modul: Account Registration (Bcrypt Cost 12)
 * Deskripsi: Menangani alur registrasi akun baru (password, konfirmasi, email opsional),
 *            validasi panjang & format input, hashing bcrypt async, dan penyimpanan ke DB.
 * Dependensi: <open.mp>, <a_mysql>, <samp_bcrypt>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/utils.inc, core/database.inc,
 *             core/enums.inc, core/variables.inc, modules/account/security.inc
 */

#if defined _INC_ACCOUNT_REGISTER
    #endinput
#endif
#define _INC_ACCOUNT_REGISTER

#include <YSI_Coding\y_hooks>

// ============================================================================
// FUNGSI INTERNAL VALIDASI & DIALOG REGISTRASI
// ============================================================================

/**
 * Validasi format email sederhana (mengandung '@' dan '.' setelah '@').
 */
static bool:Account_IsValidEmail(const email[])
{
    new len = strlen(email);
    if (len < 5 || len > 120)
    {
        return false;
    }

    new atPos = strfind(email, "@", false);
    if (atPos <= 0)
    {
        return false;
    }

    new dotPos = strfind(email, ".", false, atPos + 1);
    if (dotPos <= atPos + 1 || dotPos >= len - 1)
    {
        return false;
    }

    for (new i = 0; i < len; i++)
    {
        if (email[i] == ' ' || email[i] == '%' || email[i] == '\'' || email[i] == '"')
        {
            return false;
        }
    }
    return true;
}

static Account_ShowRegisterPassDialog(playerid, const errorNotice[] = "")
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_REGISTER_PASS;

    new dialogText[512];
    if (errorNotice[0] != EOS)
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FF4D4D}%s\n\n\
            {FFFFFF}Selamat datang di {00D4FF}PARADISE Roleplay{FFFFFF}!\n\
            Akun {FFD166}%s {FFFFFF}belum terdaftar.\n\n\
            Masukkan password baru Anda ({FFD166}%d - %d karakter{FFFFFF}):",
            errorNotice,
            PlayerData[playerid][pUsername],
            ACCOUNT_MIN_PASS_LEN,
            ACCOUNT_MAX_PASS_LEN
        );
    }
    else
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FFFFFF}Selamat datang di {00D4FF}PARADISE Roleplay{FFFFFF}!\n\
            Akun {FFD166}%s {FFFFFF}belum terdaftar.\n\n\
            Masukkan password baru Anda ({FFD166}%d - %d karakter{FFFFFF}):",
            PlayerData[playerid][pUsername],
            ACCOUNT_MIN_PASS_LEN,
            ACCOUNT_MAX_PASS_LEN
        );
    }

    ShowPlayerDialog(playerid, DIALOG_REGISTER_PASS, DIALOG_STYLE_PASSWORD, "{00D4FF}Registrasi Akun - Langkah 1/3", dialogText, "Lanjut", "Keluar");
    return 1;
}

static Account_ShowRegisterConfirmDialog(playerid, const errorNotice[] = "")
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_REGISTER_CONFIRM;

    new dialogText[384];
    if (errorNotice[0] != EOS)
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FF4D4D}%s\n\n\
            {FFFFFF}Masukkan kembali password Anda untuk konfirmasi:",
            errorNotice
        );
    }
    else
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FFFFFF}Masukkan kembali password Anda untuk konfirmasi:"
        );
    }

    ShowPlayerDialog(playerid, DIALOG_REGISTER_CONFIRM, DIALOG_STYLE_PASSWORD, "{00D4FF}Registrasi Akun - Langkah 2/3", dialogText, "Lanjut", "Kembali");
    return 1;
}

static Account_ShowRegisterEmailDialog(playerid, const errorNotice[] = "")
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_REGISTER_EMAIL;

    new dialogText[448];
    if (errorNotice[0] != EOS)
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FF4D4D}%s\n\n\
            {FFFFFF}Masukkan alamat {FFD166}Email {FFFFFF}Anda untuk pemulihan akun.\n\
            {B0B8C1}Klik 'Lewati' jika tidak ingin menambahkan email sekarang.",
            errorNotice
        );
    }
    else
    {
        format(
            dialogText,
            sizeof(dialogText),
            "{FFFFFF}Masukkan alamat {FFD166}Email {FFFFFF}Anda untuk pemulihan akun.\n\
            {B0B8C1}Klik 'Lewati' jika tidak ingin menambahkan email sekarang."
        );
    }

    ShowPlayerDialog(playerid, DIALOG_REGISTER_EMAIL, DIALOG_STYLE_INPUT, "{00D4FF}Registrasi Akun - Langkah 3/3", dialogText, "Daftar", "Lewati");
    return 1;
}

// ============================================================================
// FUNGSI PUBLIK ENTRY REGISTRASI
// ============================================================================
public Account_StartRegister(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    Account_ShowRegisterPassDialog(playerid);
    return 1;
}

// ============================================================================
// HOOK DIALOG RESPONSE REGISTRASI
// ============================================================================
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused listitem

    switch (dialogid)
    {
        case DIALOG_REGISTER_PASS:
        {
            if (!response)
            {
                SendClientMessage(playerid, COLOR_WARNING, "Anda membatalkan proses registrasi.");
                DelayedKick(playerid, 500);
                return 1;
            }

            new len = strlen(inputtext);
            if (len < ACCOUNT_MIN_PASS_LEN || len > ACCOUNT_MAX_PASS_LEN)
            {
                new err[96];
                format(err, sizeof(err), "Panjang password harus antara %d hingga %d karakter!", ACCOUNT_MIN_PASS_LEN, ACCOUNT_MAX_PASS_LEN);
                Account_ShowRegisterPassDialog(playerid, err);
                return 1;
            }

            format(PlayerData[playerid][pTempPassword], 36, "%s", inputtext);
            Account_ShowRegisterConfirmDialog(playerid);
            return 1;
        }

        case DIALOG_REGISTER_CONFIRM:
        {
            if (!response)
            {
                PlayerData[playerid][pTempPassword][0] = EOS;
                Account_ShowRegisterPassDialog(playerid);
                return 1;
            }

            if (strcmp(inputtext, PlayerData[playerid][pTempPassword], false) != 0)
            {
                Account_ShowRegisterConfirmDialog(playerid, "Konfirmasi password tidak cocok! Silakan ulangi.");
                return 1;
            }

            Account_ShowRegisterEmailDialog(playerid);
            return 1;
        }

        case DIALOG_REGISTER_EMAIL:
        {
            if (!response)
            {
                // Pemain memilih "Lewati"
                PlayerData[playerid][pEmail][0] = EOS;
            }
            else
            {
                if (!Account_IsValidEmail(inputtext))
                {
                    Account_ShowRegisterEmailDialog(playerid, "Format email tidak valid! Contoh: nama@domain.com");
                    return 1;
                }
                format(PlayerData[playerid][pEmail], 128, "%s", inputtext);
            }

            PlayerData[playerid][pAuthState] = AUTH_STATE_HASHING;
            SendClientMessage(playerid, COLOR_INFO, "Memproses keamanan akun Anda, mohon tunggu sebentar...");

            new racecheck = Database_GetPlayerRaceCheck(playerid);
            bcrypt_hash(playerid, "OnAccountRegisterHashed", PlayerData[playerid][pTempPassword], ACCOUNT_BCRYPT_COST, "i", racecheck);

            // Hapus password plaintext dari memori segera setelah dikirim ke thread bcrypt
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
// CALLBACKS BCRYPT & INSERT DATABASE
// ============================================================================
forward OnAccountRegisterHashed(playerid, racecheck);
public OnAccountRegisterHashed(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    if (!Database_IsConnected())
    {
        SendClientMessage(playerid, COLOR_ERROR, "[Server] Koneksi database terputus saat registrasi.");
        DelayedKick(playerid, 500);
        return 1;
    }

    new
        hash[128],
        query[640];

    bcrypt_get_hash(hash, sizeof(hash));
    format(PlayerData[playerid][pPasswordHash], 128, "%s", hash);
    format(PlayerData[playerid][pRegisterIP], 46, "%s", PlayerData[playerid][pCurrentIP]);
    format(PlayerData[playerid][pLastIP], 46, "%s", PlayerData[playerid][pCurrentIP]);
    format(PlayerData[playerid][pLastLogin], 32, "Baru terdaftar");

    if (PlayerData[playerid][pEmail][0] != EOS)
    {
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `accounts` (`username`, `password_hash`, `email`, `register_ip`, `last_ip`, `gpci`, `last_login`) \
             VALUES ('%e', '%e', '%e', '%e', '%e', '%e', NOW())",
            PlayerData[playerid][pUsername],
            hash,
            PlayerData[playerid][pEmail],
            PlayerData[playerid][pCurrentIP],
            PlayerData[playerid][pCurrentIP],
            PlayerData[playerid][pGPCI]
        );
    }
    else
    {
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO `accounts` (`username`, `password_hash`, `email`, `register_ip`, `last_ip`, `gpci`, `last_login`) \
             VALUES ('%e', '%e', NULL, '%e', '%e', '%e', NOW())",
            PlayerData[playerid][pUsername],
            hash,
            PlayerData[playerid][pCurrentIP],
            PlayerData[playerid][pCurrentIP],
            PlayerData[playerid][pGPCI]
        );
    }

    mysql_tquery(g_SQL, query, "OnAccountRegisterInserted", "ii", playerid, racecheck);
    return 1;
}

forward OnAccountRegisterInserted(playerid, racecheck);
public OnAccountRegisterInserted(playerid, racecheck)
{
    if (!Database_IsValidRaceCheck(playerid, racecheck))
    {
        return 0;
    }

    new insertId = cache_insert_id();
    if (insertId <= 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Gagal mendaftarkan akun (Username atau Email sudah digunakan). Silakan coba lagi.");
        Account_ShowRegisterEmailDialog(playerid, "Email tersebut sudah terdaftar pada akun lain.");
        return 1;
    }

    new logMsg[160];
    format(logMsg, sizeof(logMsg), "Akun baru terdaftar: %s (AccountID: #%d)", PlayerData[playerid][pUsername], insertId);
    Account_LogAuthEvent(logMsg, PlayerData[playerid][pCurrentIP]);

    SendClientMessage(playerid, COLOR_SUCCESS, "Registrasi berhasil! Akun Anda telah dibuat dan dilindungi enkripsi Bcrypt.");
    Account_OnAuthenticated(playerid, insertId);
    return 1;
}
