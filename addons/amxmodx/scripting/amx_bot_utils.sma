#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#tryinclude <cstrike>
#tryinclude <round_sys>

#define PLUGIN_NAME 		"Bot Utils"
#define PLUGIN_VERSION 		"1.0.0"
#define PLUGIN_AUTHOR 		"szGabu"

//probably need to add localized strings for CS
#define ORIGINAL_JOIN_MSG	"has joined the game"
#define ORIGINAL_LEAVE_MSG	"has left the game"

#define BOT_NAME            "Crusher" // CS bot name for init, replace it with your own if you changed it in BotProfiles.db 

new g_cvarDesiredBotQuota;
new g_cvarVoteEnabled;
new g_cvarBotQuota; // CS specific
new g_cvarBotQuotaMode; // CS specific
new g_cvarBotJoinAfterPlayer; // CS specific
new g_cvarBotJoinDelay; // CS specific
new g_cvarVoteApplyImmediately; // CS specific
new g_cvarBotQuotaAlways;
new g_cvarBotPrefix;
new g_cvarBotUseRcBot;
new g_cvarIgnoreSpectators;
new g_cvarBotQuotaDetect;
new g_cvarBotAddCmd;

new g_iServerBotQuotaValue, g_iServerBotQuotaDetect; 
new bool:g_bEnableVote, bool:g_bVoteApplyImmediately;
new bool:g_bUsingRcbot, bool:g_bIgnoreSpectators, bool:g_bBotQuotaAlways; // non-CS
new g_szBotPrefix[32], g_szBotCommand[512]; // non-CS
new g_bFirstSpawn[MAX_PLAYERS+1] = { true, ... };
new g_szLastBotNameBuffer[MAX_NAME_LENGTH]; // non-CS
new bool:g_bBotsEnabled = true;

new bool:g_bPluginReady = false;
new g_hVoteBotsHandle = INVALID_HANDLE;

new g_iBotQuotaOrgValue = 0;
new g_szBotQuotaModeOrgValue[32];
new g_iBotJoinAfterPlayerOrgValue = 0;
new g_iServerBotJoinDelayOrgValue = 0;

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_dictionary("amx_bot_utils.txt");
	register_dictionary("adminvote.txt");
	g_cvarDesiredBotQuota = create_cvar("amx_bot_quota", cstrike_running() ? "10" : "4", FCVAR_NONE, "Amount playercount the bots should match.", true, 0.0, true, 32.0);
	g_cvarVoteEnabled = create_cvar("amx_bot_quota_vote_enabled", "1", FCVAR_NONE, "Whether to allow voting to enable/disable bots.", true, 0.0, true, 1.0);
	bind_pcvar_num(g_cvarVoteEnabled, g_bEnableVote);
	bind_pcvar_num(g_cvarDesiredBotQuota, g_iServerBotQuotaValue);
	hook_cvar_change(g_cvarDesiredBotQuota, "OnCvarBotQuotaChanged");

	if(!cstrike_running())
	{
		register_message(get_user_msgid("SayText"), "Event_NativeSayText");
		register_message(get_user_msgid("TextMsg"), "Event_NativeTextMessage");

		g_cvarBotQuotaAlways = create_cvar("amx_bot_quota_always", "1", FCVAR_NONE, "Whether to always keep bots up to the quota even if no human players are connected.", true, 0.0, true, 1.0);
		g_cvarBotPrefix = create_cvar("amx_bot_quota_prefix", "BOT", FCVAR_NONE, "Prefix to add to bot names to prevent conflicts with human players. Set to empty string to disable.");
		g_cvarBotUseRcBot = create_cvar("amx_bot_quota_using_rcbot", "0", FCVAR_NONE, "Whether to use RCBot commands.", true, 0.0, true, 1.0);
		g_cvarIgnoreSpectators = create_cvar("amx_bot_quota_ignore_spectators", "1", FCVAR_NONE, "Whether to ignore spectators when calculating bot quota.", true, 0.0, true, 1.0);
		g_cvarBotQuotaDetect = create_cvar("amx_bot_quota_mode", "1", FCVAR_NONE, "Method to detect bot quota changes.\n\n0. timer\n1. events", true, 0.0, true, 1.0);
		g_cvarBotAddCmd = create_cvar("amx_bot_quota_addbot_cmd", "jk_botti addbot", FCVAR_NONE, "Command to add bots.");

		bind_pcvar_num(g_cvarBotQuotaAlways, g_bBotQuotaAlways);
		bind_pcvar_string(g_cvarBotPrefix, g_szBotPrefix, charsmax(g_szBotPrefix));
		bind_pcvar_num(g_cvarBotUseRcBot, g_bUsingRcbot);
		bind_pcvar_num(g_cvarIgnoreSpectators, g_bIgnoreSpectators);
		bind_pcvar_num(g_cvarBotQuotaDetect, g_iServerBotQuotaDetect); 
		bind_pcvar_string(g_cvarBotAddCmd, g_szBotCommand, charsmax(g_szBotCommand));

		register_clcmd("spectate", "Command_Spectate");
	}
	else
	{
		g_cvarBotQuota = get_cvar_pointer("bot_quota");
		g_cvarBotQuotaMode = get_cvar_pointer("bot_quota_mode");
		g_cvarBotJoinAfterPlayer = get_cvar_pointer("bot_join_after_player");
		g_cvarBotJoinDelay = get_cvar_pointer("bot_join_delay");

		if(!module_exists("cstrike"))
        	set_fail_state("Missing critical dependency: AMXX 'cstrike' module.");

		if(!g_cvarBotQuota || !g_cvarBotJoinAfterPlayer || !g_cvarBotJoinDelay)
        	set_fail_state("Missing critical dependency: CSBot.");

		if(g_cvarBotQuotaMode)
			get_pcvar_string(g_cvarBotQuotaMode, g_szBotQuotaModeOrgValue, charsmax(g_szBotQuotaModeOrgValue));
		g_iBotJoinAfterPlayerOrgValue = get_pcvar_num(g_cvarBotJoinAfterPlayer);
		g_iServerBotJoinDelayOrgValue = get_pcvar_num(g_cvarBotJoinDelay);

		if(g_cvarBotQuotaMode && !equali(g_szBotQuotaModeOrgValue, "fill")) //this is only for ReGame (Doesn't exist in HL25)
			set_fail_state("This plugin only works with 'fill' bot quota mode.");

		register_logevent("Event_UpdateRoundBotQuota", 2, "1=Round_End");
		register_event("HLTV", "Event_UpdateRoundBotQuota", "a", "1=0", "2=0");
		register_event("BotProgress", "Event_BotProgress", "a");
		g_cvarVoteApplyImmediately = create_cvar("amx_bot_quota_vote_apply_immediately", "0", FCVAR_NONE, "Whether to apply bot quota changes immediately after voting instead of waiting for the next round. Enable for gamemodes like CSDM or similar.", true, 0.0, true, 1.0);
		bind_pcvar_num(g_cvarVoteApplyImmediately, g_bVoteApplyImmediately);
	}

	register_clcmd("say !votebots", "Command_VoteBots", _, "BU_VOTEBOTS_DESCRIPTION", _, true);
	register_clcmd("say votebots", "Command_VoteBots", _, "BU_VOTEBOTS_DESCRIPTION_AL", _, true);
	register_clcmd("say !bots", "Command_VoteBots", _, "BU_VOTEBOTS_DESCRIPTION_AL", _, true);
	register_clcmd("say bots", "Command_VoteBots", _, "BU_VOTEBOTS_DESCRIPTION_AL", _, true);

	RegisterHam(Ham_Spawn, "player", "HamForward_PlayerSpawn_Post", true);

	AutoExecConfig();
}

new bool:g_bCurrentlyInVote = false;
new g_iVoteArray[MAX_PLAYERS+1] = { -1, ... };

public Command_VoteBots(iClient)
{
	if(!g_bPluginReady || g_bCurrentlyInVote || !g_bEnableVote)
	{
		client_print(iClient, print_chat, "%L", LANG_PLAYER, g_bCurrentlyInVote ? "BU_VOTEBOTS_IN_PROGRESS" : "BU_VOTEBOTS_VOTE_DISABLED");
		return PLUGIN_HANDLED;
	}

	new iCurrentBots = get_playersnum_ex(GetPlayers_ExcludeHuman | GetPlayers_ExcludeHLTV);
	if(g_bBotsEnabled && iCurrentBots == 0)
	{
		client_print(iClient, print_chat, "%L", LANG_PLAYER, "BU_VOTEBOTS_VOTE_NO_EFFECTS");
		return PLUGIN_HANDLED;
	}

	g_bCurrentlyInVote = true;

	for(new iIndex = 1; iIndex <= MaxClients; iIndex++)
		g_iVoteArray[iIndex] = -1;

	g_hVoteBotsHandle = menu_create(g_bBotsEnabled ? "BU_VOTEBOTS_TITLE_DISABLE" : "BU_VOTEBOTS_TITLE_ENABLE", "VoteBotsVoteHandle", true);

	menu_setprop(g_hVoteBotsHandle, MPROP_EXIT, MEXIT_NEVER);
	menu_additem(g_hVoteBotsHandle, "BU_VOTEBOTS_ENABLE", "1");
	menu_additem(g_hVoteBotsHandle, "BU_VOTEBOTS_DISABLE", "2");
	
	// Display menu
	menu_display(iClient, g_hVoteBotsHandle, _, 10);

	set_task(10.0, "DetermineVoteWinner");

	return PLUGIN_CONTINUE;
}

public VoteBotsVoteHandle(iClient, hMenu, iItem)
{
	new szInfo[8], szClientName[MAX_NAME_LENGTH];
	menu_item_getinfo(hMenu, iItem, _, szInfo, charsmax(szInfo), _, _, _);
	new iOption = str_to_num(szInfo);
	get_user_name(iClient, szClientName, charsmax(szClientName));
	client_print(0, print_chat, "%L", LANG_PLAYER, iOption == 1  ? "VOTED_FOR" : "VOTED_AGAINST", szClientName)
	g_iVoteArray[iClient] = iOption == 1 ? 1 : 0;
	return PLUGIN_HANDLED;
}

public DetermineVoteWinner(iTaskId)
{
	g_bCurrentlyInVote = false;

	new rgPlayers[MAX_PLAYERS], iPlayerCount, iYesVotes = 0, iNoVotes = 0;
	get_players_ex(rgPlayers, iPlayerCount, GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV);
	for(new i = 0; i < iPlayerCount; i++)
	{
		new iClient = rgPlayers[i];
		new hVoteHandle = INVALID_HANDLE, hVoteKeys = INVALID_HANDLE;
		#pragma unused hVoteKeys
		#pragma unused hVoteHandle

		// Workaround to remove the menu from players who haven't voted
		if(!get_user_menu(iClient, hVoteHandle, hVoteKeys))
		{
			new hEmptyMenu = menu_create("", "Dummy");
			menu_setprop(hEmptyMenu, MPROP_EXIT, MEXIT_NEVER);
			menu_addtext2(hEmptyMenu, " ");
			menu_display(iClient, hEmptyMenu, _, 1);
		}

		if(g_iVoteArray[iClient] == 1)
			iYesVotes++;
		else if(g_iVoteArray[iClient] == 0)
			iNoVotes++;
	}

	if(iYesVotes == iNoVotes)
	{
		server_print("[INFO] %s::DetermineVoteWinner() - Vote tied, no changes made.", __BINARY__);
		client_print(0, print_chat, "%L", LANG_PLAYER, "BU_VOTEBOTS_TIED");
		return;
	}
	else if(iYesVotes > iNoVotes)
	{
		g_bBotsEnabled = true;
		server_print("[INFO] %s::DetermineVoteWinner() - Bots have been enabled by vote.", __BINARY__);
		client_print(0, print_chat, "%L", LANG_PLAYER, "BU_VOTEBOTS_ENABLED");
	}
	else
	{
		g_bBotsEnabled = false;
		server_print("[INFO] %s::DetermineVoteWinner() - Bots have been disabled by vote.", __BINARY__);
		client_print(0, print_chat, "%L", LANG_PLAYER, "BU_VOTEBOTS_DISABLED");
	}

	if(!cstrike_running())
		set_task(0.5, "Task_CheckCurrentPlayers", false);
	else if(g_bVoteApplyImmediately) // only CS games, this prevents CS from kicking bots on an ongoing round
		Event_UpdateRoundBotQuota();
}

/**
 * Returns nothing, it's a workaround for an empty callback.
 *
 * @return void
 */
public Dummy()
{
	return;
}

public plugin_natives()
{
	set_module_filter("ModuleFilterHandler");
	set_native_filter("NativeFilterHandler");
}

public ModuleFilterHandler(const szLibrary[], LibType:hLibType)
{
    if(equal(szLibrary, "cstrike"))
        return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public NativeFilterHandler(const szNative[], iNativeIndex, iTrapCode)
{
    if(iTrapCode == 0 && (equal(szNative, "cs_set_user_team") || equal(szNative, "cs_get_user_team")))
        return PLUGIN_HANDLED;

    return PLUGIN_CONTINUE;
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

	g_bPluginReady = true;
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
	if(!g_bPluginReady)
		return;

	new iPlayerCount = get_playersnum_ex(GetPlayers_ExcludeBots | GetPlayers_MatchTeam, "CT") + get_playersnum_ex(GetPlayers_ExcludeBots | GetPlayers_MatchTeam, "TERRORIST");

	if(!g_bBotsEnabled)
		set_pcvar_num(g_cvarBotQuota, 0);
	else if(iPlayerCount == 0)
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
	if(((!cstrike_running() &&g_iServerBotQuotaDetect == 1) || cstrike_running()) && is_user_alive(iClient) && g_bFirstSpawn[iClient] && !IsClientSpectating(iClient))
	{
		g_bFirstSpawn[iClient] = false;

		set_task(3.0, "Task_AnnounceBots", get_user_userid(iClient));

		if(cstrike_running())
		{
			if(g_bVoteApplyImmediately)
				Event_UpdateRoundBotQuota();
		}
		else
			set_task(0.5, "Task_CheckCurrentPlayers", false);
	}

	return HAM_IGNORED;
}

public Task_AnnounceBots(iTaskId)
{
	new iClient = find_player_ex(FindPlayer_MatchUserId, iTaskId);
	if(iClient)
	{
		new iNumBots = get_playersnum_ex(GetPlayers_ExcludeHuman | GetPlayers_ExcludeHLTV)
		if(iNumBots > 0 && g_bBotsEnabled)
			client_print(iClient, print_chat, "%L", LANG_PLAYER, "BU_QUOTA_DETECT_NOTICE", iNumBots);
	}
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

public client_remove(iClient)
{
	if(get_playersnum_ex(GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV) == 0)
	    g_bBotsEnabled = true;
}

public Task_CheckCurrentPlayers(bool:bTask)
{
	if(g_iServerBotQuotaDetect == 0 && !bTask || g_iServerBotQuotaDetect == 1 && bTask || cstrike_running())
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
			if ((!IsClientSpectating(iClient) && g_bIgnoreSpectators) || !g_bIgnoreSpectators)
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

	if((iHumanNum == 0 && iBotNum > 0 && !g_bBotQuotaAlways) || !g_bBotsEnabled) 
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

	if(g_bUsingRcbot)
	{
		server_cmd("rcbot config min_bots %d", iDesiredBotNum);
		server_cmd("rcbot config max_bots %d", iDesiredBotNum);
		if(iBotNum - iDesiredBotNum > 0)
			RemoveBots(iBotNum - iDesiredBotNum);
	} 
	else 
	{
		if(iDesiredBotNum > iBotNum) 
			AddBots(iDesiredBotNum - iBotNum);
		else if(iDesiredBotNum < iBotNum)
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

/**
 * Helper function to determine if a client is currently spectating
 *
 * @param iClient The client index to check
 *
 * @return bool True if the client is spectating, false otherwise
 */
stock bool:IsClientSpectating(iClient)
{
	if(cstrike_running())
	{
		new CsTeams:iTeam = cs_get_user_team(iClient);
		return iTeam == CS_TEAM_SPECTATOR || iTeam == CS_TEAM_UNASSIGNED;
	}
	else 
	{
		if(pev_valid(iClient) == 2)
			return get_ent_data(iClient, "CBasePlayer", "m_afPhysicsFlags") & PFLAG_OBSERVER > 0;
	}

	return false;
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