#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define PLUGIN_NAME         "Bot Add Test"
#define PLUGIN_VERSION      "1.0.0"
#define PLUGIN_AUTHOR       "szGabu"

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    register_clcmd("amx_botfill", "ClientCommand_BotAdd");
}

public ClientCommand_BotAdd(iClient)
{
    new szPlayerName[32] = "BOT";

    new pBot = engfunc(EngFunc_CreateFakeClient, szPlayerName);

    //Failed?
    if(!pBot)
        return PLUGIN_HANDLED;
        
    engfunc(EngFunc_FreeEntPrivateData, pBot);

    //Create the player entity by calling MOD's player function
    dllfunc(MetaFunc_CallGameEntity, "player", pBot);

    //Set all Infobuffer Keys for this Bot
    new infokeybuffer = engfunc(EngFunc_GetInfoKeyBuffer, pBot);

    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "model", "gordon");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "rate", "3500.000000");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "cl_updaterate", "20");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "cl_lw", "1");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "cl_lc", "1");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "tracker", "0");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "cl_dlmax", "128");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "lefthand", "1");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "friends", "0");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "dm", "0");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "_ah", "0");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "_vgui_menus", "0");
    engfunc(EngFunc_SetClientKeyValue, pBot, infokeybuffer, "*bot", "1");

    //Allocate space for message from ClientConnect
    new ptr[128];

    //Connect this client with the local loopback
    dllfunc(DLLFunc_ClientConnect, pBot, szPlayerName, "127.0.0.1", ptr);

    //Set the third party bot flag
    set_pev(pBot, pev_flags, pev(pBot, pev_flags) | FL_FAKECLIENT);

    //Pieter van Dijk - use instead of DispatchSpawn() - Hip Hip Hurray!
    dllfunc(DLLFunc_ClientPutInServer, pBot);

    return PLUGIN_HANDLED;
}