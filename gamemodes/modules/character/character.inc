// =============================================================================
// File: gamemodes/modules/character/character.inc
// Fungsi: Induk modul sistem karakter (Pilih, Buat, Hapus, Spawn, Save, Tutorial).
// Dependensi: <open.mp>, <a_mysql>, <samp_bcrypt>, sub-modul character/*
// =============================================================================

#if defined _INC_MODULE_CHARACTER
    #endinput
#endif
#define _INC_MODULE_CHARACTER

// Sub-modul Karakter
#include "modules/character/character_select.inc"
#include "modules/character/character_create.inc"
#include "modules/character/character_tutorial.inc"
#include "modules/character/character_spawn.inc"
#include "modules/character/character_save.inc"
#include "modules/character/character_delete.inc"

// -----------------------------------------------------------------------------
// Router Terpusat Respon Dialog Modul Karakter (ID 200 - 299)
// -----------------------------------------------------------------------------
stock Character_OnDialogResponse(playerid, dialogid, response, listitem, const inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_CHAR_SELECT:
        {
            return Character_OnSelectDialogResponse(playerid, response, listitem);
        }
        case DIALOG_CHAR_CREATE_NAME, DIALOG_CHAR_CREATE_GENDER, DIALOG_CHAR_CREATE_AGE,
             DIALOG_CHAR_CREATE_ORIGIN, DIALOG_CHAR_CREATE_SKIN:
        {
            return Character_OnCreateDialogResponse(playerid, dialogid, response, listitem, inputtext);
        }
        case DIALOG_CHAR_TUTORIAL:
        {
            return Character_OnTutorialDialogResponse(playerid, response);
        }
        case DIALOG_CHAR_SPAWN_SELECT:
        {
            return Character_OnSpawnDialogResponse(playerid, response, listitem);
        }
        case DIALOG_CHAR_DELETE_SELECT, DIALOG_CHAR_DELETE_CONFIRM:
        {
            return Character_OnDeleteDialogResponse(playerid, dialogid, response, listitem, inputtext);
        }
    }
    return 0;
}
