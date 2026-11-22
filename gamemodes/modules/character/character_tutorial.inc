// =============================================================================
// File: gamemodes/modules/character/character_tutorial.inc
// Fungsi: Sistem tur pengenalan kota interaktif & edukasi roleplay bagi
//         karakter baru sebelum pertama kali spawn ke dalam dunia permainan.
// Dependensi: <open.mp>, core/config.inc, core/colors.inc, core/utils.inc,
//             core/enums.inc, core/variables.inc
// =============================================================================

#if defined _INC_CHAR_TUTORIAL
    #endinput
#endif
#define _INC_CHAR_TUTORIAL

// Forward deklarasi lintas modul
forward Character_Spawn(playerid, spawnType);

// -----------------------------------------------------------------------------
// Memulai Tur Tutorial untuk Karakter Baru
// -----------------------------------------------------------------------------
stock Character_StartTutorial(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    PlayerData[playerid][pAuthState] = AUTH_STATE_CHAR_TUTORIAL;
    PlayerData[playerid][pTutorialStep] = 1;

    TogglePlayerSpectating(playerid, true);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, playerid + 100);

    Character_ShowTutorialStep(playerid);
    return 1;
}

// -----------------------------------------------------------------------------
// Menampilkan Langkah Tur Sinematik Berdasarkan Langkah Progres
// -----------------------------------------------------------------------------
stock Character_ShowTutorialStep(playerid)
{
    new step = PlayerData[playerid][pTutorialStep];
    new title[64], body[640], btn[16];

    switch (step)
    {
        case 1: // Lokasi: Balai Kota Los Santos (City Hall)
        {
            InterpolateCameraPos(playerid, 1481.04, -1820.50, 45.0, 1481.04, -1770.00, 25.0, 15000, CAMERA_MOVE);
            InterpolateCameraLookAt(playerid, 1481.04, -1750.00, 16.0, 1481.04, -1750.00, 16.0, 15000, CAMERA_MOVE);

            format(title, sizeof(title), "{00AAFF}Tur Kota [1/4]: Balai Kota (City Hall)");
            format(
                body,
                sizeof(body),
                "{FFFFFF}Selamat datang di {00AAFF}Kota Los Santos{FFFFFF}, %s!\n\n\
                Ini adalah {FFFF00}Balai Kota Los Santos (City Hall){FFFFFF}.\n\
                Di tempat ini, Anda dapat:\n\
                - Melamar pekerjaan legal (Pembersih Jalan, Supir Bus, Supir Truk, dll).\n\
                - Mengurus berkas kependudukan dan surat izin.\n\n\
                {B0B8C1}Tips: Gunakan perintah /job di dalam gedung untuk memilih pekerjaan pertama Anda.",
                PlayerData[playerid][pCharName]
            );
            format(btn, sizeof(btn), "Lanjut (2/4)");
        }

        case 2: // Lokasi: Kantor Polisi SAPD Pershing Square
        {
            InterpolateCameraPos(playerid, 1530.00, -1700.00, 35.0, 1553.30, -1675.60, 22.0, 15000, CAMERA_MOVE);
            InterpolateCameraLookAt(playerid, 1553.30, -1675.60, 16.2, 1540.00, -1650.00, 14.0, 15000, CAMERA_MOVE);

            format(title, sizeof(title), "{00AAFF}Tur Kota [2/4]: Kantor Polisi SAPD");
            format(
                body,
                sizeof(body),
                "{FFFFFF}Ini adalah {0078D7}Markas Besar Kepolisian SAPD (Pershing Square){FFFFFF}.\n\n\
                Aparat kepolisian menjaga ketertiban kota dari aksi kriminal dan geng.\n\
                - Jika Anda menjadi korban kejahatan, hubungi {FFFF00}/call 911{FFFFFF}.\n\
                - Taati hukum lalu lintas dan jangan membawa senjata api ilegal.\n\n\
                {FF0000}Peringatan: {FFFFFF}Melanggar hukum akan membuat Anda menjadi buronan ({FFFF00}Wanted Level{FFFFFF}) dan dipenjara."
            );
            format(btn, sizeof(btn), "Lanjut (3/4)");
        }

        case 3: // Lokasi: All Saints General Hospital
        {
            InterpolateCameraPos(playerid, 1150.00, -1350.00, 35.0, 1172.80, -1323.30, 24.0, 15000, CAMERA_MOVE);
            InterpolateCameraLookAt(playerid, 1172.80, -1323.30, 14.1, 1190.00, -1300.00, 13.5, 15000, CAMERA_MOVE);

            format(title, sizeof(title), "{00AAFF}Tur Kota [3/4]: Rumah Sakit SAMD");
            format(
                body,
                sizeof(body),
                "{FFFFFF}Ini adalah {FF6347}All Saints General Hospital (SAMD){FFFFFF}.\n\n\
                Paramedis dan dokter bertugas menyelamatkan nyawa warga yang terluka parah.\n\
                - Karakter Anda membutuhkan {00FF00}Makanan & Minuman{FFFFFF} agar tidak kelaparan.\n\
                - Jika darah Anda habis, Anda akan terkapar ({FF6347}Injured{FFFFFF}) dan membutuhkan pertolongan medis.\n\n\
                {B0B8C1}Tips: Makanan dan perban medis dapat dibeli di restoran atau toko 24/7 terdekat."
            );
            format(btn, sizeof(btn), "Lanjut (4/4)");
        }

        case 4: // Lokasi: Bank Pusat Los Santos
        {
            InterpolateCameraPos(playerid, 1480.00, -1720.00, 30.0, 1502.50, -1703.80, 20.0, 15000, CAMERA_MOVE);
            InterpolateCameraLookAt(playerid, 1502.50, -1703.80, 14.04, 1502.50, -1680.00, 14.0, 15000, CAMERA_MOVE);

            format(title, sizeof(title), "{00AAFF}Tur Kota [4/4]: Bank & Ekonomi Warga");
            format(
                body,
                sizeof(body),
                "{FFFFFF}Ini adalah {FFFF00}Bank Pusat Los Santos{FFFFFF}.\n\n\
                Pusat transaksi finansial dan penyimpanan kekayaan Anda:\n\
                - Simpan uang Anda di bank agar aman dari aksi perampokan.\n\
                - Setiap 1 jam bermain, Anda akan menerima {00FF00}Paycheck (Gaji Pokok & Bunga Bank){FFFFFF}.\n\
                - Anda dibekali modal awal sebesar {00FF00}$500 Uang Tunai {FFFFFF}dan {00FF00}$2,500 di Rekening Bank{FFFFFF}.\n\n\
                {00AAFF}Selamat menikmati kehidupan baru Anda di " SERVER_NAME "!{FFFFFF}"
            );
            format(btn, sizeof(btn), "Mulai Bermain");
        }
    }

    ShowPlayerDialog(playerid, DIALOG_CHAR_TUTORIAL, DIALOG_STYLE_MSGBOX, title, body, btn, "Lewati");
    return 1;
}

// -----------------------------------------------------------------------------
// Menyelesaikan Tutorial & Membawa Pemain ke Titik Spawn Resmi
// -----------------------------------------------------------------------------
stock Character_CompleteTutorial(playerid)
{
    SendSuccessMessage(playerid, "Tutorial pengenalan kota selesai. Selamat bermain!");
    SendInfoMessage(playerid, "Bantuan perintah dapat dilihat sewaktu-waktu melalui /help atau /cmds.");

    // Spawn tipe 0: Balai Kota Los Santos (Default Spawn)
    Character_Spawn(playerid, 0);
    return 1;
}

// -----------------------------------------------------------------------------
// Respon Dialog Tutorial
// -----------------------------------------------------------------------------
stock Character_OnTutorialDialogResponse(playerid, response)
{
    if (!response)
    {
        // Pemain menekan tombol "Lewati"
        Character_CompleteTutorial(playerid);
        return 1;
    }

    PlayerData[playerid][pTutorialStep]++;
    if (PlayerData[playerid][pTutorialStep] > 4)
    {
        Character_CompleteTutorial(playerid);
    }
    else
    {
        Character_ShowTutorialStep(playerid);
    }
    return 1;
}
