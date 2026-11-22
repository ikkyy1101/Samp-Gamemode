/**
 * File: gamemodes/modules/character/tutorial.inc
 * Modul: New Character City Tutorial
 * Deskripsi: Memberikan tur sinematik otomatis (5 lokasi penting di Los Santos)
 *            untuk karakter yang baru pertama kali masuk ke kota, lalu menyimpan
 *            status tutorial_done ke database dan melakukan spawn awal.
 * Dependensi: <open.mp>, <a_mysql>, <YSI_Coding\y_timers>,
 *             core/colors.inc, core/database.inc, core/enums.inc,
 *             core/variables.inc, modules/character/spawn.inc
 */

#if defined _INC_CHARACTER_TUTORIAL
    #endinput
#endif
#define _INC_CHARACTER_TUTORIAL

// ============================================================================
// KONSTANTA & DATA TITIK TUTORIAL
// ============================================================================
#define TUTORIAL_STEP_DURATION_SEC  (6)
#define MAX_TUTORIAL_STEPS          (5)

enum E_TUTORIAL_POINT
{
    Float:tCamFromX,
    Float:tCamFromY,
    Float:tCamFromZ,
    Float:tCamToX,
    Float:tCamToY,
    Float:tCamToZ,
    Float:tLookX,
    Float:tLookY,
    Float:tLookZ,
    tTitle[64],
    tDesc[160]
};

static const s_TutorialPoints[MAX_TUTORIAL_STEPS][E_TUTORIAL_POINT] = {
    {
        1481.0, -1720.0, 35.0, 1481.0, -1750.0, 28.0, 1481.03, -1771.29, 18.80,
        "1/5 - Balai Kota Los Santos (City Hall)",
        "Tempat mengurus kartu identitas, pembuatan SIM, dan pendaftaran pekerjaan resmi warga."
    },
    {
        1462.3, -985.0, 42.0, 1462.3, -1005.0, 34.0, 1462.35, -1012.48, 26.84,
        "2/5 - Bank Pusat Los Santos",
        "Simpan uang Anda di rekening bank agar aman dari perampokan dan mendapatkan bunga setiap jam."
    },
    {
        1520.0, -1675.0, 32.0, 1540.0, -1675.0, 24.0, 1554.95, -1675.65, 16.20,
        "3/5 - Markas Kepolisian LSPD",
        "Pusat layanan keamanan kota. Hubungi 911 lewat ponsel jika Anda melihat tindakan kriminal."
    },
    {
        1195.0, -1323.0, 32.0, 1182.0, -1323.0, 22.0, 1173.25, -1323.31, 15.39,
        "4/5 - Rumah Sakit All Saints (LSFD/EMS)",
        "Tim medis siaga menyelamatkan warga yang terluka parah atau membutuhkan perawatan darurat."
    },
    {
        1743.0, -1835.0, 26.0, 1743.0, -1850.0, 18.0, 1742.99, -1860.63, 13.57,
        "5/5 - Stasiun Kereta Unity Station",
        "Titik kedatangan utama pendatang baru. Anda bisa menyewa kendaraan atau memanggil taksi di sini."
    }
};

// ============================================================================
// FUNGSI TUTORIAL
// ============================================================================
static Tutorial_ShowStep(playerid, step)
{
    if (!IsPlayerConnected(playerid) || step < 0 || step >= MAX_TUTORIAL_STEPS)
    {
        return 0;
    }

    for (new i = 0; i < 10; i++)
    {
        SendClientMessage(playerid, -1, "");
    }

    InterpolateCameraPos(
        playerid,
        s_TutorialPoints[step][tCamFromX], s_TutorialPoints[step][tCamFromY], s_TutorialPoints[step][tCamFromZ],
        s_TutorialPoints[step][tCamToX], s_TutorialPoints[step][tCamToY], s_TutorialPoints[step][tCamToZ],
        TUTORIAL_STEP_DURATION_SEC * 1000,
        CAMERA_MOVE
    );
    InterpolateCameraLookAt(
        playerid,
        s_TutorialPoints[step][tLookX], s_TutorialPoints[step][tLookY], s_TutorialPoints[step][tLookZ],
        s_TutorialPoints[step][tLookX], s_TutorialPoints[step][tLookY], s_TutorialPoints[step][tLookZ],
        TUTORIAL_STEP_DURATION_SEC * 1000,
        CAMERA_MOVE
    );

    new titleMsg[128];
    format(titleMsg, sizeof(titleMsg), "[Tur Kota] %s", s_TutorialPoints[step][tTitle]);
    SendClientMessage(playerid, COLOR_PRIMARY, "%s", titleMsg);
    SendClientMessage(playerid, COLOR_INFO, "%s", s_TutorialPoints[step][tDesc]);
    return 1;
}

static Tutorial_Finish(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    PlayerData[playerid][pTutorialDone] = true;
    PlayerData[playerid][pTutorialStep] = 0;

    // Set posisi awal ke Unity Station
    PlayerData[playerid][pPosX] = 1742.9962;
    PlayerData[playerid][pPosY] = -1860.6310;
    PlayerData[playerid][pPosZ] = 13.5784;
    PlayerData[playerid][pPosA] = 0.0;
    PlayerData[playerid][pInterior] = 0;
    PlayerData[playerid][pVirtualWorld] = 0;

    if (Database_IsConnected())
    {
        new query[256];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "UPDATE `characters` SET `tutorial_done` = 1, `pos_x` = %f, `pos_y` = %f, `pos_z` = %f WHERE `id` = %d",
            PlayerData[playerid][pPosX],
            PlayerData[playerid][pPosY],
            PlayerData[playerid][pPosZ],
            PlayerData[playerid][pCharacterID]
        );
        mysql_tquery(g_SQL, query);
    }

    SendClientMessage(playerid, COLOR_SUCCESS, "[Tur Kota] Pengenalan kota selesai! Anda menerima modal awal $500 tunai dan $2.500 di rekening bank.");
    Character_SpawnToWorld(playerid, 4);
    return 1;
}

public Character_StartTutorial(playerid)
{
    if (!IsPlayerConnected(playerid) || !PlayerData[playerid][pCharacterLoaded])
    {
        return 0;
    }

    PlayerData[playerid][pAuthState] = AUTH_STATE_TUTORIAL;
    PlayerData[playerid][pTutorialStep] = 0;

    TogglePlayerSpectating(playerid, true);
    SetPlayerVirtualWorld(playerid, playerid + 200);
    SetPlayerInterior(playerid, 0);

    Tutorial_ShowStep(playerid, 0);
    return 1;
}

/**
 * Timer per pemain setiap 6 detik untuk memajukan tahapan tur kota.
 */
ptask Character_TutorialTickTask[TUTORIAL_STEP_DURATION_SEC * 1000](playerid)
{
    if (!IsPlayerConnected(playerid) || IsPlayerNPC(playerid))
    {
        return;
    }

    if (PlayerData[playerid][pAuthState] != AUTH_STATE_TUTORIAL)
    {
        return;
    }

    PlayerData[playerid][pTutorialStep]++;
    if (PlayerData[playerid][pTutorialStep] >= MAX_TUTORIAL_STEPS)
    {
        Tutorial_Finish(playerid);
    }
    else
    {
        Tutorial_ShowStep(playerid, PlayerData[playerid][pTutorialStep]);
    }
}
