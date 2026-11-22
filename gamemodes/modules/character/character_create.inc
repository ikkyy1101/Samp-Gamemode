// =============================================================================
// File: gamemodes/modules/character/character_create.inc
// Fungsi: Alur wizard pembuatan karakter baru (Nama RP unik, Gender, Umur,
//         Asal/Origin, dan Pilihan Skin) serta penyimpanan ke database.
// Dependensi: <open.mp>, <a_mysql>, core/config.inc, core/colors.inc,
//             core/utils.inc, core/enums.inc, core/variables.inc, core/database.inc
// =============================================================================

#if defined _INC_CHAR_CREATE
    #endinput
#endif
#define _INC_CHAR_CREATE

// Daftar model skin default yang disediakan untuk karakter baru
static const g_MaleStarterSkins[] = {26, 29, 72, 73, 101, 170, 250};
static const g_FemaleStarterSkins[] = {12, 40, 56, 91, 151, 192};

// Forward deklarasi lintas modul
forward Character_StartTutorial(playerid);

// -----------------------------------------------------------------------------
// Memulai Wizard Pembuatan Karakter Baru
// -----------------------------------------------------------------------------
stock Character_StartCreate(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pAccountLoaded])
    {
        return 0;
    }

    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_CREATE_NAME;
    PlayerData[playerid][pTempCharName][0] = '\0';
    PlayerData[playerid][pTempGender] = 0;
    PlayerData[playerid][pTempAge] = 0;
    PlayerData[playerid][pTempOrigin][0] = '\0';
    PlayerData[playerid][pTempSkin] = 0;

    new prompt[384];
    format(
        prompt,
        sizeof(prompt),
        "{FFFFFF}Selamat datang di pembuatan karakter {00AAFF}" SERVER_NAME "{FFFFFF}!\n\n\
        Silakan masukkan {FFFF00}Nama Karakter{FFFFFF} Anda.\n\
        Format nama wajib: {00FF00}Nama_Marga {FFFFFF}(Contoh: {AFAFAF}Arthur_Morgan{FFFFFF}):"
    );

    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_NAME, DIALOG_STYLE_INPUT, "{00AAFF}Buat Karakter - Langkah 1/5: Nama", prompt, "Lanjut", "Batal");
    return 1;
}

// -----------------------------------------------------------------------------
// Menampilkan Dialog Pemilihan Gender
// -----------------------------------------------------------------------------
stock Character_ShowGenderDialog(playerid)
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_CREATE_GENDER;
    new list[128];
    format(list, sizeof(list), "1. Laki-laki (Male)\n2. Perempuan (Female)");
    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_GENDER, DIALOG_STYLE_LIST, "{00AAFF}Buat Karakter - Langkah 2/5: Jenis Kelamin", list, "Pilih", "Batal");
    return 1;
}

// -----------------------------------------------------------------------------
// Menampilkan Dialog Input Umur
// -----------------------------------------------------------------------------
stock Character_ShowAgeDialog(playerid, const errorNotice[] = "")
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_CREATE_AGE;
    new prompt[384];
    if (errorNotice[0] != '\0')
    {
        format(
            prompt,
            sizeof(prompt),
            "{FF0000}%s\n\n{FFFFFF}Masukkan usia karakter Anda ({FFFF00}%d - %d Tahun{FFFFFF}):",
            errorNotice,
            MIN_CHARACTER_AGE,
            MAX_CHARACTER_AGE
        );
    }
    else
    {
        format(
            prompt,
            sizeof(prompt),
            "{FFFFFF}Masukkan usia karakter Anda ({FFFF00}%d - %d Tahun{FFFFFF}):",
            MIN_CHARACTER_AGE,
            MAX_CHARACTER_AGE
        );
    }
    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_AGE, DIALOG_STYLE_INPUT, "{00AAFF}Buat Karakter - Langkah 3/5: Usia", prompt, "Lanjut", "Batal");
    return 1;
}

// -----------------------------------------------------------------------------
// Menampilkan Dialog Pemilihan Asal / Origin
// -----------------------------------------------------------------------------
stock Character_ShowOriginDialog(playerid)
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_CREATE_ORIGIN;
    new list[256];
    format(
        list,
        sizeof(list),
        "1. Los Santos, San Andreas\n\
        2. San Fierro, San Andreas\n\
        3. Las Venturas, San Andreas\n\
        4. Liberty City\n\
        5. Vice City\n\
        6. Luar Negeri (Imigran Internasional)"
    );
    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_ORIGIN, DIALOG_STYLE_LIST, "{00AAFF}Buat Karakter - Langkah 4/5: Asal Karakter", list, "Pilih", "Batal");
    return 1;
}

// -----------------------------------------------------------------------------
// Menampilkan Dialog Pemilihan Skin
// -----------------------------------------------------------------------------
stock Character_ShowSkinDialog(playerid)
{
    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_CREATE_SKIN;
    new list[512];

    if (PlayerData[playerid][pTempGender] == 1) // Laki-laki
    {
        format(
            list,
            sizeof(list),
            "Skin 26 - Pria Kasual Santai\n\
            Skin 29 - Pemuda Kota Urban\n\
            Skin 72 - Pria Berkaos Biru\n\
            Skin 73 - Pria Kemeja Kotak-kotak\n\
            Skin 101 - Pemuda Jaket Streetwear\n\
            Skin 170 - Pria Dewasa Rapi\n\
            Skin 250 - Pria Setelan Jas Elegan"
        );
    }
    else // Perempuan
    {
        format(
            list,
            sizeof(list),
            "Skin 12 - Wanita Gaun Modis\n\
            Skin 40 - Gadis Kasual Trendi\n\
            Skin 56 - Wanita Dewasa Anggun\n\
            Skin 91 - Wanita Kemeja Kantor\n\
            Skin 151 - Gadis Gaya Sporty\n\
            Skin 192 - Wanita Blazer Formal"
        );
    }

    ShowPlayerDialog(playerid, DIALOG_CHAR_CREATE_SKIN, DIALOG_STYLE_LIST, "{00AAFF}Buat Karakter - Langkah 5/5: Pakaian & Skin", list, "Selesai", "Batal");
    return 1;
}

// -----------------------------------------------------------------------------
// Callback Pengecekan Keunikan Nama Karakter
// -----------------------------------------------------------------------------
forward OnCharacterNameCheck(playerid, racecheck, const name[]);
public OnCharacterNameCheck(playerid, racecheck, const name[])
{
    if (!Database_IsRaceCheckValid(playerid, racecheck))
    {
        return 0;
    }

    new rows;
    cache_get_row_count(rows);

    if (rows > 0)
    {
        SendErrorMessage(playerid, "Nama karakter tersebut sudah terdaftar oleh warga lain! Pilih nama lain.");
        Character_StartCreate(playerid);
        return 1;
    }

    // Nama unik dan valid, simpan ke penampung sementara
    format(PlayerData[playerid][pTempCharName], MAX_PLAYER_NAME, "%s", name);
    SendSuccessMessage(playerid, "Nama karakter diterima.");
    Character_ShowGenderDialog(playerid);
    return 1;
}

// -----------------------------------------------------------------------------
// Callback Selesai Pembuatan Karakter & Insert ke Database
// -----------------------------------------------------------------------------
forward OnCharacterCreated(playerid, racecheck);
public OnCharacterCreated(playerid, racecheck)
{
    if (!Database_IsRaceCheckValid(playerid, racecheck))
    {
        return 0;
    }

    new charId = cache_insert_id();
    if (charId <= 0)
    {
        SendErrorMessage(playerid, "Terjadi kesalahan internal saat membuat karakter di database.");
        Character_ShowSelectionMenu(playerid);
        return 0;
    }

    // Sinkronkan data karakter baru ke memori aktif
    PlayerData[playerid][pCharacterID] = charId;
    format(PlayerData[playerid][pCharName], MAX_PLAYER_NAME, "%s", PlayerData[playerid][pTempCharName]);
    PlayerData[playerid][pGender] = PlayerData[playerid][pTempGender];
    PlayerData[playerid][pAge] = PlayerData[playerid][pTempAge];
    format(PlayerData[playerid][pOrigin], 32, "%s", PlayerData[playerid][pTempOrigin]);
    PlayerData[playerid][pSkin] = PlayerData[playerid][pTempSkin];
    PlayerData[playerid][pPosX] = DEFAULT_SPAWN_X;
    PlayerData[playerid][pPosY] = DEFAULT_SPAWN_Y;
    PlayerData[playerid][pPosZ] = DEFAULT_SPAWN_Z;
    PlayerData[playerid][pPosA] = DEFAULT_SPAWN_ANGLE;
    PlayerData[playerid][pInterior] = DEFAULT_SPAWN_INTERIOR;
    PlayerData[playerid][pVirtualWorld] = DEFAULT_SPAWN_VW;
    PlayerData[playerid][pHealth] = 100.0;
    PlayerData[playerid][pArmour] = 0.0;
    PlayerData[playerid][pMoney] = DEFAULT_STARTER_CASH;
    PlayerData[playerid][pBankMoney] = DEFAULT_STARTER_BANK;
    PlayerData[playerid][pLevel] = 1;
    PlayerData[playerid][pExp] = 0;
    PlayerData[playerid][pPlayingHours] = 0;
    PlayerData[playerid][pHunger] = 100.0;
    PlayerData[playerid][pThirst] = 100.0;
    PlayerData[playerid][pStress] = 0.0;
    PlayerData[playerid][pCharacterLoaded] = true;

    // Ubah nama pemain di game menjadi nama karakter yang baru dibuat
    SetPlayerName(playerid, PlayerData[playerid][pCharName]);

    new logMsg[160];
    format(logMsg, sizeof(logMsg), "Karakter baru dibuat: %s (#%d) pada akun #%d", PlayerData[playerid][pCharName], charId, PlayerData[playerid][pAccountID]);
    new curIp[46];
    GetPlayerIp(playerid, curIp, sizeof(curIp));
    new qlog[320];
    mysql_format(g_DB, qlog, sizeof(qlog), "INSERT INTO `logs` (`type`, `char_id`, `message`, `ip`) VALUES ('character', %d, '%e', '%e')", charId, logMsg, curIp);
    mysql_tquery(g_DB, qlog);

    SendSuccessMessage(playerid, "Karakter Anda berhasil dibuat!");

    // Arahkan ke tutorial pendatang baru
    Character_StartTutorial(playerid);
    return 1;
}

// -----------------------------------------------------------------------------
// Penanganan Respon Dialog Pembuatan Karakter
// -----------------------------------------------------------------------------
stock Character_OnCreateDialogResponse(playerid, dialogid, response, listitem, const inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_CHAR_CREATE_NAME:
        {
            if (!response)
            {
                Character_ShowSelectionMenu(playerid);
                return 1;
            }

            new nameClean[MAX_PLAYER_NAME];
            format(nameClean, sizeof(nameClean), "%s", inputtext);

            if (!IsValidRoleplayName(nameClean))
            {
                SendErrorMessage(playerid, "Nama tidak memenuhi standar! Gunakan format Nama_Marga (huruf kapital di awal, min 3 huruf per kata).");
                Character_StartCreate(playerid);
                return 1;
            }

            // Periksa keunikan nama di tabel characters secara asinkron
            new racecheck = Database_GetRaceCheck(playerid);
            new query[256];
            mysql_format(g_DB, query, sizeof(query), "SELECT `id` FROM `characters` WHERE `name` = '%e' LIMIT 1", nameClean);
            mysql_tquery(g_DB, query, "OnCharacterNameCheck", "iis", playerid, racecheck, nameClean);
            return 1;
        }

        case DIALOG_CHAR_CREATE_GENDER:
        {
            if (!response)
            {
                Character_StartCreate(playerid);
                return 1;
            }

            PlayerData[playerid][pTempGender] = (listitem == 0) ? 1 : 2;
            Character_ShowAgeDialog(playerid);
            return 1;
        }

        case DIALOG_CHAR_CREATE_AGE:
        {
            if (!response)
            {
                Character_ShowGenderDialog(playerid);
                return 1;
            }

            new age = strval(inputtext);
            if (age < MIN_CHARACTER_AGE || age > MAX_CHARACTER_AGE)
            {
                Character_ShowAgeDialog(playerid, "Usia tidak valid! Usia karakter harus antara 18 hingga 80 tahun.");
                return 1;
            }

            PlayerData[playerid][pTempAge] = age;
            Character_ShowOriginDialog(playerid);
            return 1;
        }

        case DIALOG_CHAR_CREATE_ORIGIN:
        {
            if (!response)
            {
                Character_ShowAgeDialog(playerid);
                return 1;
            }

            switch (listitem)
            {
                case 0: format(PlayerData[playerid][pTempOrigin], 32, "Los Santos");
                case 1: format(PlayerData[playerid][pTempOrigin], 32, "San Fierro");
                case 2: format(PlayerData[playerid][pTempOrigin], 32, "Las Venturas");
                case 3: format(PlayerData[playerid][pTempOrigin], 32, "Liberty City");
                case 4: format(PlayerData[playerid][pTempOrigin], 32, "Vice City");
                default: format(PlayerData[playerid][pTempOrigin], 32, "Luar Negeri");
            }

            Character_ShowSkinDialog(playerid);
            return 1;
        }

        case DIALOG_CHAR_CREATE_SKIN:
        {
            if (!response)
            {
                Character_ShowOriginDialog(playerid);
                return 1;
            }

            new chosenSkin;
            if (PlayerData[playerid][pTempGender] == 1) // Pria
            {
                if (listitem >= 0 && listitem < sizeof(g_MaleStarterSkins))
                {
                    chosenSkin = g_MaleStarterSkins[listitem];
                }
                else
                {
                    chosenSkin = g_MaleStarterSkins[0];
                }
            }
            else // Wanita
            {
                if (listitem >= 0 && listitem < sizeof(g_FemaleStarterSkins))
                {
                    chosenSkin = g_FemaleStarterSkins[listitem];
                }
                else
                {
                    chosenSkin = g_FemaleStarterSkins[0];
                }
            }

            PlayerData[playerid][pTempSkin] = chosenSkin;

            // Simpan karakter baru ke tabel characters
            new racecheck = Database_GetRaceCheck(playerid);
            new query[512];
            mysql_format(
                g_DB,
                query,
                sizeof(query),
                "INSERT INTO `characters` \
                (`account_id`, `name`, `gender`, `age`, `origin`, `skin`, `money`, `bank_money`, `pos_x`, `pos_y`, `pos_z`, `pos_a`, `last_played`) \
                VALUES (%d, '%e', %d, %d, '%e', %d, %d, %d, %.4f, %.4f, %.4f, %.4f, NOW())",
                PlayerData[playerid][pAccountID],
                PlayerData[playerid][pTempCharName],
                PlayerData[playerid][pTempGender],
                PlayerData[playerid][pTempAge],
                PlayerData[playerid][pTempOrigin],
                PlayerData[playerid][pTempSkin],
                DEFAULT_STARTER_CASH,
                DEFAULT_STARTER_BANK,
                DEFAULT_SPAWN_X,
                DEFAULT_SPAWN_Y,
                DEFAULT_SPAWN_Z,
                DEFAULT_SPAWN_ANGLE
            );

            mysql_tquery(g_DB, query, "OnCharacterCreated", "ii", playerid, racecheck);
            return 1;
        }
    }
    return 0;
}
