/**
 * File: gamemodes/modules/chat/animations.inc
 * Modul: Roleplay Animations & Library Preloader
 * Deskripsi: Melakukan preload library animasi SA-MP agar berjalan mulus tanpa jeda,
 *            menyediakan menu dialog /anim maupun perintah langsung (/anim [nama]),
 *            serta /stopanim.
 * Dependensi: <open.mp>, <Pawn.CMD>, <YSI_Coding\y_hooks>,
 *             core/colors.inc, core/enums.inc, core/variables.inc
 */

#if defined _INC_CHAT_ANIMATIONS
    #endinput
#endif
#define _INC_CHAT_ANIMATIONS

#include <YSI_Coding\y_hooks>

// ============================================================================
// DAFTAR ANIMASI ROLEPLAY TERPOPULER
// ============================================================================
enum E_RP_ANIMATION
{
    animKey[16],
    animLabel[32],
    animLib[24],
    animName[24],
    Float:animDelta,
    bool:animLoop,
    bool:animLockX,
    bool:animLockY,
    bool:animFreeze,
    animTime
};

static const s_RPAnimations[][E_RP_ANIMATION] = {
    {"duduk",       "Duduk Santai di Kursi",        "PED",          "SEAT_IDLE",        4.1, true,  false, false, false, 0},
    {"duduklantai", "Duduk di Lantai",              "BEACH",        "ParkSit_M_loop",   4.1, true,  false, false, false, 0},
    {"tiduran",     "Tiduran / Berbaring",          "CRACK",        "crckidle2",        4.1, true,  false, false, false, 0},
    {"angkat",      "Angkat Tangan (Menyerah)",     "ROB_BANK",     "SHP_HandsUp_Scr",  4.1, false, true,  true,  true,  0},
    {"merokok",     "Merokok Santai",               "SMOKING",      "M_smklean_loop",   4.1, true,  false, false, false, 0},
    {"bersandar",   "Bersandar di Dinding",         "GANGS",        "leanIDLE",         4.1, true,  false, false, false, 0},
    {"tepuktangan", "Bertepuk Tangan",              "RIOT",         "RIOT_CHANT",       4.1, true,  false, false, false, 0},
    {"melambai",    "Melambaikan Tangan",           "ON_LOOKERS",   "wave_loop",        4.1, true,  false, false, false, 0},
    {"menari1",     "Menari Gaya 1",                "DANCING",      "DAN_Loop_A",       4.1, true,  false, false, false, 0},
    {"menari2",     "Menari Gaya 2",                "DANCING",      "dnce_M_a",         4.1, true,  false, false, false, 0},
    {"sedih",       "Menangis / Menutupi Wajah",    "GRAVEYARD",    "mrnF_loop",        4.1, true,  false, false, false, 0},
    {"pikir",       "Berpikir / Tangan di Dagu",    "COP_AMBIENT",  "Coplook_think",    4.1, true,  false, false, false, 0},
    {"silangtangan","Menyilangkan Tangan di Dada",  "COP_AMBIENT",  "Coplook_loop",     4.1, true,  false, false, false, 0},
    {"periksa",     "Berjongkok Memeriksa Sesuatu", "BOMBER",       "BOM_Plant",        4.1, false, false, false, false, 0},
    {"pushup",      "Olahraga Push-Up",             "GYMNASIUM",    "gym_bp_up_smooth", 4.1, true,  false, false, false, 0},
    {"lambaistop",  "Isyarat Berhenti (Polisi)",    "POLICE",       "CopTraf_Stop",     4.1, true,  false, false, false, 0}
};

// ============================================================================
// FUNGSI PRELOAD & EKSEKUSI ANIMASI
// ============================================================================

/**
 * Melakukan preload seluruh library animasi yang dipakai server saat pemain spawn.
 */
stock Anim_PreloadLibraries(playerid)
{
    if (!IsPlayerConnected(playerid) || PlayerData[playerid][pAnimPreloaded])
    {
        return 0;
    }

    for (new i = 0; i < sizeof(s_RPAnimations); i++)
    {
        ApplyAnimation(playerid, s_RPAnimations[i][animLib], "null", 0.0, false, false, false, false, 0, SYNC_NONE);
    }

    PlayerData[playerid][pAnimPreloaded] = true;
    return 1;
}

static Anim_PlayByIndex(playerid, index)
{
    if (!IsPlayerConnected(playerid) || index < 0 || index >= sizeof(s_RPAnimations))
    {
        return 0;
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda harus berjalan kaki (tidak di dalam kendaraan) untuk memakai animasi!");
        return 0;
    }

    if (PlayerData[playerid][pInjured] || PlayerData[playerid][pJailTime] > 0)
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat menggunakan animasi saat terluka atau dipenjara!");
        return 0;
    }

    ApplyAnimation(
        playerid,
        s_RPAnimations[index][animLib],
        s_RPAnimations[index][animName],
        s_RPAnimations[index][animDelta],
        s_RPAnimations[index][animLoop],
        s_RPAnimations[index][animLockX],
        s_RPAnimations[index][animLockY],
        s_RPAnimations[index][animFreeze],
        s_RPAnimations[index][animTime],
        SYNC_ALL
    );

    PlayerData[playerid][pUsingAnim] = true;

    new msg[128];
    format(msg, sizeof(msg), "[Animasi] Memainkan '%s'. Tekan tombol LOMPAT (Space) atau ketik /stopanim untuk berhenti.", s_RPAnimations[index][animLabel]);
    SendClientMessage(playerid, COLOR_INFO, "%s", msg);
    return 1;
}

stock Anim_StopPlayer(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    if (PlayerData[playerid][pInjured])
    {
        SendClientMessage(playerid, COLOR_ERROR, "Anda tidak dapat menghentikan animasi saat sedang terluka parah!");
        return 0;
    }

    ClearAnimations(playerid, SYNC_ALL);
    PlayerData[playerid][pUsingAnim] = false;
    return 1;
}

// ============================================================================
// PERINTAH ANIMASI (/anim, /stopanim)
// ============================================================================
CMD:anim(playerid, params[])
{
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    // Jika pemain mengetik parameter langsung, misal: /anim duduk
    if (!isnull(params))
    {
        for (new i = 0; i < sizeof(s_RPAnimations); i++)
        {
            if (strcmp(params, s_RPAnimations[i][animKey], true) == 0)
            {
                Anim_PlayByIndex(playerid, i);
                return 1;
            }
        }
        SendClientMessage(playerid, COLOR_ERROR, "Nama animasi tidak ditemukan! Ketik /anim tanpa parameter untuk melihat daftar.");
        return 1;
    }

    new
        dialogBody[1024],
        line[80];

    format(dialogBody, sizeof(dialogBody), "Perintah Cepat\tDeskripsi Animasi\n");
    for (new i = 0; i < sizeof(s_RPAnimations); i++)
    {
        format(line, sizeof(line), "{00D4FF}/anim %s\t{FFFFFF}%s\n", s_RPAnimations[i][animKey], s_RPAnimations[i][animLabel]);
        strcat(dialogBody, line);
    }

    ShowPlayerDialog(playerid, DIALOG_ANIM_LIST, DIALOG_STYLE_TABLIST_HEADERS, "{00D4FF}Daftar Animasi Roleplay", dialogBody, "Mainkan", "Tutup");
    return 1;
}
alias:anim("anims", "animation")

CMD:stopanim(playerid, params[])
{
    #pragma unused params
    if (PlayerData[playerid][pAuthState] != AUTH_STATE_SPAWNED)
    {
        return 1;
    }

    if (Anim_StopPlayer(playerid))
    {
        SendClientMessage(playerid, COLOR_INFO, "Animasi dihentikan.");
    }
    return 1;
}
alias:stopanim("sa", "clearanim")

// ============================================================================
// HOOKS DIALOG, SPAWN & TOMBOL BATAL ANIMASI
// ============================================================================
hook OnPlayerSpawn(playerid)
{
    if (PlayerData[playerid][pCharacterLoaded])
    {
        Anim_PreloadLibraries(playerid);
    }
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    if (dialogid == DIALOG_ANIM_LIST)
    {
        if (!response)
        {
            return 1;
        }

        if (listitem >= 0 && listitem < sizeof(s_RPAnimations))
        {
            Anim_PlayByIndex(playerid, listitem);
        }
        return 1;
    }
    return 0;
}

hook OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
    #pragma unused oldkeys
    if (PlayerData[playerid][pUsingAnim] && !PlayerData[playerid][pInjured] && (newkeys & KEY_JUMP))
    {
        Anim_StopPlayer(playerid);
    }
    return 1;
}
