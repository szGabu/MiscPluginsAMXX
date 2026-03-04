#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME 		"Bot Quota Control"
#define PLUGIN_VERSION 		"1.0.0"
#define PLUGIN_AUTHOR 		"szGabu"

#define ORIGINAL_JOIN_MSG	"has joined the game"
#define ORIGINAL_LEAVE_MSG	"has left the game"

#define PFLAG_OBSERVER (1<<5)
#define m_afPhysicsFlags 194

new g_iBotQuota, g_iQuotaMode;
new bool:g_bUsingRcbot, bool:g_bIgnoreSpectators, bool:g_bBotQuotaAlways;
new g_szBotPrefix[32], g_szBotCommand[512];
new g_bFirstSpawn[MAX_PLAYERS+1] = { true, ... };
new g_szLastBotNameBuffer[MAX_NAME_LENGTH];

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	new cvarBotQuota = register_cvar("amx_bot_quota", "4");
	new cvarBotQuotaAlways = register_cvar("amx_bot_quota_always", "1");
	new cvarBotPrefix = register_cvar("amx_bot_quota_prefix", "BOT");
	new cvarBotUseRcBot = register_cvar("amx_bot_quota_using_rcbot", "0");
	new cvarIgnoreSpectators = register_cvar("amx_bot_quota_ignore_spectators", "1");
	new cvarBotQuotaMode = register_cvar("amx_bot_quota_mode", "1"); //0. timer | 1. events
	new cvarBotAddCmd = register_cvar("amx_bot_quota_addbot_cmd", "jk_botti addbot");

	AutoExecConfig();

	hook_cvar_change(cvarBotQuota, "OnCvarBotQuotaChanged");

	bind_pcvar_num(cvarBotQuota, g_iBotQuota);
	bind_pcvar_num(cvarBotQuotaAlways, g_bBotQuotaAlways);
	bind_pcvar_string(cvarBotPrefix, g_szBotPrefix, charsmax(g_szBotPrefix));
	bind_pcvar_num(cvarBotUseRcBot, g_bUsingRcbot);
	bind_pcvar_num(cvarIgnoreSpectators, g_bIgnoreSpectators);
	bind_pcvar_num(cvarBotQuotaMode, g_iQuotaMode); 
	bind_pcvar_string(cvarBotAddCmd, g_szBotCommand, charsmax(g_szBotCommand));

	if(!cstrike_running())
	{
		register_message(get_user_msgid("SayText"), "Event_NativeSayText");
		register_message(get_user_msgid("TextMsg"), "Event_NativeTextMessage");
	}

	RegisterHam(Ham_Spawn, "player", "HamForward_PlayerSpawn_Post", true);
	register_clcmd("spectate", "Command_Spectate");
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
	set_task(0.5, "CheckPlayers", false);
}

public HamForward_PlayerSpawn_Post(iClient)
{
	if(g_iQuotaMode == 1 && is_user_alive(iClient) && g_bFirstSpawn[iClient])
	{
		g_bFirstSpawn[iClient] = false;
		set_task(0.5, "CheckPlayers", false);
	}
}

public Command_Spectate(iClient)
{
    if(g_iQuotaMode == 1)
		set_task(0.5, "CheckPlayers", false);
}

public OnConfigsExecuted()
{
	register_message(get_user_msgid("SayText"), "ChangeNameNotifBlock");

	if(g_iQuotaMode == 1)
		set_task(0.5, "CheckPlayers", false);
	else
		set_task(1.0, "CheckPlayers", true, _, _, "b");
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

public client_connect(iClient)
{
	g_bFirstSpawn[iClient] = true;
}

public client_putinserver(iClient)
{
	//check on next frame
	RequestFrame("BotCheckName", iClient);

	if(g_iQuotaMode == 1)
		set_task(0.5, "CheckPlayers", false);
}

public BotCheckName(iClient)
{
	if(is_user_bot(iClient))
	{
		if(strlen(g_szBotPrefix) > 0)
		{
			new szName[MAX_NAME_LENGTH];
			get_user_name(iClient, szName, charsmax(szName));
			//server_print("[DEBUG] amx_bot_quota.amxx::client_putinserver() - %s contains %s ?", szName, g_szBotPrefix);
			if(containi(szName, g_szBotPrefix) == -1)
			{
				new szNewName[MAX_NAME_LENGTH];
				formatex(szNewName, charsmax(szNewName), "%s %s", g_szBotPrefix, szName);
				//check first if there's a bot with that name
				if(find_player_ex(FindPlayer_MatchName, szNewName))
				{
					server_cmd("kick #%d", get_user_userid(iClient));
					AddBots(1);
					return;
				}

				set_user_info(iClient, "name", szNewName);
			}
		}
	}
}

public client_disconnected(iClient)
{
	if(is_user_bot(iClient))
		get_user_name(iClient, g_szLastBotNameBuffer, charsmax(g_szLastBotNameBuffer));

	if(g_iQuotaMode == 1)
		set_task(0.5, "CheckPlayers", false);
}

public CheckPlayers(bool:bTask)
{
	if(g_iQuotaMode == 0 && !bTask || g_iQuotaMode == 1 && bTask)
		return;

	// Ensure bot quota is within valid range
	if (g_iBotQuota < 0)
		g_iBotQuota = 0;
	else if (g_iBotQuota > MaxClients - 1)
		g_iBotQuota = MaxClients - 1; // Reserve at least one slot for human players

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

	new iDesiredBotNum = g_iBotQuota - iHumanNum;
	iDesiredBotNum = clamp(iDesiredBotNum, 0, g_iBotQuota);

	if(iHumanNum == 0)
		iDesiredBotNum = g_bBotQuotaAlways ? g_iBotQuota : 0;

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

	return iCurrentPlayers < g_iBotQuota;
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