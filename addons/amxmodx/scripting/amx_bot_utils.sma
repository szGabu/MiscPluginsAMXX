#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#tryinclude <round_sys>

#define PLUGIN_NAME 		"Bot Utils"
#define PLUGIN_VERSION 		"1.0.0"
#define PLUGIN_AUTHOR 		"szGabu"

//probably need to add localized strings for CS
#define ORIGINAL_JOIN_MSG	"has joined the game"
#define ORIGINAL_LEAVE_MSG	"has left the game"

#define BOT_NAME            "Crusher" // CS bot name for init, replace it with your own if you changed it in BotProfiles.db 

#define PFLAG_OBSERVER (1<<5)
#define m_afPhysicsFlags 194

new g_cvarDesiredBotQuota;
new g_cvarBotQuota; // CS specific
new g_cvarBotQuotaMode; // CS specific
new g_cvarBotJoinAfterPlayer; // CS specific
new g_cvarBotJoinDelay; // CS specific
new g_cvarBotQuotaAlways;
new g_cvarBotPrefix;
new g_cvarBotUseRcBot;
new g_cvarIgnoreSpectators;
new g_cvarBotQuotaDetect;
new g_cvarBotAddCmd;

new g_iServerBotQuotaValue, g_iServerBotQuotaDetect;
new bool:g_bUsingRcbot, bool:g_bIgnoreSpectators, bool:g_bBotQuotaAlways, bool:g_bInit = false;
new g_szBotPrefix[32], g_szBotCommand[512];
new g_bFirstSpawn[MAX_PLAYERS+1] = { true, ... };
new g_szLastBotNameBuffer[MAX_NAME_LENGTH];

new g_iBotQuotaOrgValue = 0;
new g_szBotQuotaModeOrgValue[32];
new g_iBotJoinAfterPlayerOrgValue = 0;
new g_iServerBotJoinDelayOrgValue = 0;

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	g_cvarDesiredBotQuota = create_cvar("amx_bot_quota", cstrike_running() ? "10" : "4", FCVAR_NONE, "Amount playercount the bots should match.", true, 0.0, true, 32.0);
	bind_pcvar_num(g_cvarDesiredBotQuota, g_iServerBotQuotaValue);
	hook_cvar_change(g_cvarDesiredBotQuota, "OnCvarBotQuotaChanged");

	if(!cstrike_running())
	{
		register_message(get_user_msgid("SayText"), "Event_NativeSayText");
		register_message(get_user_msgid("TextMsg"), "Event_NativeTextMessage");

		g_cvarBotQuotaAlways = register_cvar("amx_bot_quota_always", "1");
		g_cvarBotPrefix = register_cvar("amx_bot_quota_prefix", "BOT");
		g_cvarBotUseRcBot = register_cvar("amx_bot_quota_using_rcbot", "0");
		g_cvarIgnoreSpectators = register_cvar("amx_bot_quota_ignore_spectators", "1");
		g_cvarBotQuotaDetect = register_cvar("amx_bot_quota_mode", "1"); //0. timer | 1. events
		g_cvarBotAddCmd = register_cvar("amx_bot_quota_addbot_cmd", "jk_botti addbot");

		bind_pcvar_num(g_cvarBotQuotaAlways, g_bBotQuotaAlways);
		bind_pcvar_string(g_cvarBotPrefix, g_szBotPrefix, charsmax(g_szBotPrefix));
		bind_pcvar_num(g_cvarBotUseRcBot, g_bUsingRcbot);
		bind_pcvar_num(g_cvarIgnoreSpectators, g_bIgnoreSpectators);
		bind_pcvar_num(g_cvarBotQuotaDetect, g_iServerBotQuotaDetect); 
		bind_pcvar_string(g_cvarBotAddCmd, g_szBotCommand, charsmax(g_szBotCommand));

		RegisterHam(Ham_Spawn, "player", "HamForward_PlayerSpawn_Post", true);
		register_clcmd("spectate", "Command_Spectate");
	}
	else
	{
		g_cvarBotQuota = get_cvar_pointer("bot_quota");
		g_cvarBotQuotaMode = get_cvar_pointer("bot_quota_mode");
		g_cvarBotJoinAfterPlayer = get_cvar_pointer("bot_join_after_player");
		g_cvarBotJoinDelay = get_cvar_pointer("bot_join_delay");

		if(!g_cvarBotQuota || !g_cvarBotJoinAfterPlayer || !g_cvarBotJoinDelay)
        	set_fail_state("Missing dependency: CSBot.");

		if(g_cvarBotQuotaMode)
			get_pcvar_string(g_cvarBotQuotaMode, g_szBotQuotaModeOrgValue, charsmax(g_szBotQuotaModeOrgValue));
		g_iBotJoinAfterPlayerOrgValue = get_pcvar_num(g_cvarBotJoinAfterPlayer);
		g_iServerBotJoinDelayOrgValue = get_pcvar_num(g_cvarBotJoinDelay);

		if(g_cvarBotQuotaMode && !equali(g_szBotQuotaModeOrgValue, "fill")) //this is only for ReGame (Doesn't exist in HL25)
			set_fail_state("This plugin only works with 'fill' bot quota mode.");

		register_logevent("Event_UpdateRoundBotQuota", 2, "1=Round_End");
		register_event("HLTV", "Event_UpdateRoundBotQuota", "a", "1=0", "2=0");
		register_event("BotProgress", "Event_BotProgress", "a");
	}

	AutoExecConfig();
}

public OnConfigsExecuted()
{
	register_message(get_user_msgid("SayText"), "ChangeNameNotifBlock");

	if(cstrike_running())
	{
		set_pcvar_num(g_cvarBotJoinAfterPlayer, g_iBotJoinAfterPlayerOrgValue);
		set_pcvar_num(g_cvarBotJoinDelay, g_iServerBotJoinDelayOrgValue);
	}
	else
	{
		if(g_iServerBotQuotaDetect == 1)
			set_task(0.5, "Task_CheckCurrentPlayers", false);
		else
			set_task(1.0, "Task_CheckCurrentPlayers", true, _, _, "b");
	}

	g_bInit = true;
}

public client_connect(iClient)
{
	g_bFirstSpawn[iClient] = true;
}

public client_putinserver(iClient)
{
	//check on next frame
	RequestFrame("FrameNext_BotCheckName", iClient);

	if(!cstrike_running() && g_iServerBotQuotaDetect == 1)
		set_task(0.5, "Task_CheckCurrentPlayers", false);
}

public plugin_end()
{
	if(cstrike_running())
	{
		set_pcvar_num(g_cvarBotQuota, g_iBotQuotaOrgValue);
		set_pcvar_string(g_cvarBotQuotaMode, g_szBotQuotaModeOrgValue);
		set_pcvar_num(g_cvarBotJoinAfterPlayer, g_iBotJoinAfterPlayerOrgValue);
		set_pcvar_num(g_cvarBotJoinDelay, g_iServerBotJoinDelayOrgValue);
	}
}

public Event_BotProgress()
{
    server_print("[INFO] %s::Event_BotProgress() - Bots are learning the map. Plugin paused.", __BINARY__);
    pause("ad");
}


public Event_UpdateRoundBotQuota()
{
    if(!g_bInit)
        return;

    new iPlayerCount = get_playersnum_ex(GetPlayers_ExcludeBots | GetPlayers_MatchTeam, "CT") + get_playersnum_ex(GetPlayers_ExcludeBots | GetPlayers_MatchTeam, "TERRORIST");

    if(iPlayerCount == 0)
        set_pcvar_num(g_cvarBotQuota, g_iServerBotQuotaValue);
    else 
    {
        if(iPlayerCount > g_iServerBotQuotaValue)
        {
            new iEvenBotQuota = (iPlayerCount % 2 == 0) ? iPlayerCount : iPlayerCount + 1;
            set_pcvar_num(g_cvarBotQuota, iEvenBotQuota);
        }
        else 
            set_pcvar_num(g_cvarBotQuota, g_iServerBotQuotaValue);    

        BalanceTeams();
    }
}

BalanceTeams()
{
    new iCTs = get_playersnum_ex(GetPlayers_MatchTeam, "CT");
    new iTerrors = get_playersnum_ex(GetPlayers_MatchTeam, "TERRORIST");
    
    // Allow 1 player difference (standard for odd player counts)
    if(abs(iCTs - iTerrors) <= 1)
        return;
    
    new iDifference = abs(iCTs - iTerrors);
    new iTransfersNeeded = iDifference / 2;
    
    new rgPlayers[MAX_PLAYERS], iNum, iBot;
    get_players(rgPlayers, iNum, "de", iCTs > iTerrors ? "CT" : "TERRORIST");
    
    new iTransferred = 0;
    for(new i = 0; i < iNum && iTransferred < iTransfersNeeded; i++)
    {
        iBot = rgPlayers[i];
        if(!is_user_bot(iBot))
            continue;
            
        cs_set_user_team(iBot, iCTs > iTerrors ? CS_TEAM_T : CS_TEAM_CT, CS_DONTCHANGE, true);
        ExecuteHam(Ham_CS_RoundRespawn, iBot);
        iTransferred++;
    }
}

#if defined _round_sys_included
public RoundSys_WarmUpClockTick(iTimeLeft)
{
    Event_UpdateRoundBotQuota();
}
#endif

public FrameNext_BotCheckName(iClient)
{
	if(is_user_bot(iClient))
	{
		new szName[MAX_NAME_LENGTH];
		get_user_name(iClient, szName, charsmax(szName));
		if(!cstrike_running() && strlen(g_szBotPrefix) > 0) //CS already has logic for bot prefixes
		{
			//server_print("[DEBUG] amx_bot_quota.amxx::client_putinserver() - %s contains %s ?", szName, g_szBotPrefix);
			if(containi(szName, g_szBotPrefix) == -1)
			{
				new szNewName[MAX_NAME_LENGTH];
				formatex(szNewName, charsmax(szNewName), "%s %s", g_szBotPrefix, szName);
				//check first if there's a bot with that name
				if(find_player_ex(FindPlayer_MatchName, szNewName))
				{
					server_cmd("kick #%d", get_user_userid(iClient));
					if(!cstrike_running())
						AddBots(1);
					return;
				}

				set_user_info(iClient, "name", szNewName);
			}
		}
		else if(containi(szName, "(1)") == 0)
        	server_cmd("kick #%d", get_user_userid(iClient));
	}
}

public Event_NativeTextMessage(iMsgId, iDest, iReceiver)
{
	new iDestinationType = get_msg_arg_int(1);

	if(iDestinationType == 3)
	{
		new szMessage[MAX_USER_INFO_LENGTH];
		get_msg_arg_string(2, szMessage, charsmax(szMessage));
		if((szMessage[0] == '-' || szMessage[0] == '+' || szMessage[0] == '*') && szMessage[1] == ' ')
			if(containi(szMessage, g_szLastBotNameBuffer) == 2)
				return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Event_NativeSayText(iMsgId, iDest, iReceiver)
{
	new iSenderId = get_msg_arg_int(1);
	if(iSenderId >= 1 && iSenderId <= MaxClients)
	{
		new szMessage[MAX_USER_INFO_LENGTH];
		get_msg_arg_string(2, szMessage, charsmax(szMessage));
		if(szMessage[0] == '*')
			return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public OnCvarBotQuotaChanged(pCvar, const szOldVal[], const szNewVal[])
{
	if(cstrike_running())
		return;
	set_task(0.5, "Task_CheckCurrentPlayers", false);
}

public HamForward_PlayerSpawn_Post(iClient)
{
	if(cstrike_running())
		return HAM_IGNORED;

	if(g_iServerBotQuotaDetect == 1 && is_user_alive(iClient) && g_bFirstSpawn[iClient])
	{
		g_bFirstSpawn[iClient] = false;
		set_task(0.5, "Task_CheckCurrentPlayers", false);
	}

	return HAM_IGNORED;
}

public Command_Spectate(iClient)
{
	if(cstrike_running())
		return;
		
	if(g_iServerBotQuotaDetect == 1)
		set_task(0.5, "Task_CheckCurrentPlayers", false);
}

public ChangeNameNotifBlock(iMsgId, iDestination, iReceiver)
{
	//this is horribly inneficient, but should work across all games
	new szMessage[128], szBotName[MAX_NAME_LENGTH];

	if(get_msg_args() == 2)
	{
		get_msg_arg_string(2, szMessage, charsmax(szMessage));

		for (new iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (is_user_connected(iClient) && is_user_bot(iClient))
				get_user_name(iClient, szBotName, charsmax(szBotName));


			if(contain(szMessage, szBotName) != -1)
				return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public client_disconnected(iClient)
{
	if(is_user_bot(iClient))
		get_user_name(iClient, g_szLastBotNameBuffer, charsmax(g_szLastBotNameBuffer));

	if(g_iServerBotQuotaDetect == 1)
		set_task(0.5, "Task_CheckCurrentPlayers", false);
}

public Task_CheckCurrentPlayers(bool:bTask)
{
	if(g_iServerBotQuotaDetect == 0 && !bTask || g_iServerBotQuotaDetect == 1 && bTask)
		return;

	// Ensure bot quota is within valid range
	if (g_iServerBotQuotaValue < 0)
		g_iServerBotQuotaValue = 0;
	else if (g_iServerBotQuotaValue > MaxClients - 1)
		g_iServerBotQuotaValue = MaxClients - 1; // Reserve at least one slot for human players

	new iBotNum = 0, iHumanNum = 0;

	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (is_user_connected(iClient))
		{
			if ((!is_spectating(iClient) && g_bIgnoreSpectators) || !g_bIgnoreSpectators)
			{
				if (is_user_bot(iClient)) // Excludes proxies
					iBotNum++;
				else if (!is_user_bot(iClient)) // Confirmed human player
					iHumanNum++;
			}
		}
	}

	new iDesiredBotNum = g_iServerBotQuotaValue - iHumanNum;
	iDesiredBotNum = clamp(iDesiredBotNum, 0, g_iServerBotQuotaValue);

	if(iHumanNum == 0)
		iDesiredBotNum = g_bBotQuotaAlways ? g_iServerBotQuotaValue : 0;

	if (iHumanNum == 0 && iBotNum > 0 && !g_bBotQuotaAlways) 
	{
		// Remove all bots if no humans are connected
		KickAllBots();

		if (g_bUsingRcbot)
		{
			server_cmd("rcbot config min_bots 0");
			server_cmd("rcbot config max_bots 0");
		}
		return;
	}

	if (g_bUsingRcbot)
	{
		server_cmd("rcbot config min_bots %d", iDesiredBotNum);
		server_cmd("rcbot config max_bots %d", iDesiredBotNum);
		if(iBotNum - iDesiredBotNum > 0)
			RemoveBots(iBotNum - iDesiredBotNum);
	} 
	else 
	{
		if (iDesiredBotNum > iBotNum) 
			AddBots(iDesiredBotNum - iBotNum);
		else if (iDesiredBotNum < iBotNum)
			RemoveBots(iBotNum - iDesiredBotNum);
	}
}

// Helper function to determine if we should spawn more bots to fill the current quota
stock bool:ShouldSpawnMoreBots()
{
	new rgUnuPlayers[MAX_PLAYERS], iCurrentPlayers, iCurrentHumans;
	get_players(rgUnuPlayers, iCurrentPlayers, "h");
	get_players(rgUnuPlayers, iCurrentHumans, "ch");
	if(iCurrentHumans == 0)
		return false;

	return iCurrentPlayers < g_iServerBotQuotaValue;
}

// Helper function to check if a player is spectating
stock bool:is_spectating(iClient)
{
	return pev_valid(iClient) == 2 && (get_pdata_int(iClient, m_afPhysicsFlags) & PFLAG_OBSERVER > 0);
}

// Helper function to kick all bots
stock KickAllBots()
{
    for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
        if (is_user_connected(iClient) && is_user_bot(iClient))
			server_cmd("kick #%d", get_user_userid(iClient));
    }
}

// Helper function to add bots
stock AddBots(iBotsToAdd)
{
    for (new i = 0; i < iBotsToAdd; i++)
	{
		new szConCmd[512];
		copy(szConCmd, charsmax(szConCmd), g_szBotCommand);
		replace_string(szConCmd, charsmax(szConCmd), "$QUOT$", "^"");
		server_cmd(szConCmd);
    }
}

stock RemoveBots(iBotsToRemove)
{
	while(iBotsToRemove > 0)
	{
		for (new iClient = 1; iClient <= MaxClients && iBotsToRemove > 0; iClient++)
		{
			if (is_user_connected(iClient) && is_user_bot(iClient))
			{
				server_cmd("kick #%d", get_user_userid(iClient));
				iBotsToRemove--;
			}
		}
	}
}