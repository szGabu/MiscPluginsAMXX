#include <amxmodx>
#include <amxmisc>
#include <geoip>

#pragma semicolon 			1
#pragma dynamic 			8192

#define PLUGIN_NAME			"Join and Leave Messages"
#define PLUGIN_AUTHOR		"szGabu"
#define PLUGIN_VERSION		"1.0.0-26w21a"

#define ORIGINAL_JOIN_MSG	"has joined the game"
#define ORIGINAL_LEAVE_MSG	"has left the game"

#define JOIN_SOUND			"buttons/bell1.wav"
#define LEAVE_SOUND			"buttons/blip1.wav"

#define MAX_OVERRIDES		1024

new g_cvarEnabled;
new g_cvarSounds;

new bool:g_bIgnoreBots = false;
new bool:g_bFullyJoined[MAX_PLAYERS+1] = { false, ... };

// Storage for SteamID overrides
new g_szSteamIDOverrides[MAX_OVERRIDES][32];
new g_szCountryOverrides[MAX_OVERRIDES][MAX_NAME_LENGTH];
new g_iOverrideCount = 0;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	g_cvarEnabled = create_cvar("amx_joinleave_enabled", "1", FCVAR_NONE, "Enables the plugin", true, 0.0, true, 1.0);
	g_cvarSounds = create_cvar("amx_joinleave_sounds", "1", FCVAR_NONE, "Enables sounds when joining or leaving", true, 0.0, true, 1.0);

	if(!cstrike_running())
	{
		if(is_running("svencoop"))
		{
			register_message(get_user_msgid("SayText"), "Event_NativeSayText");
			register_message(get_user_msgid("TextMsg"), "Event_NativeSvenLeaveMessage");
		}
		else
			register_message(get_user_msgid("TextMsg"), "Event_NativeJoinGameMessage");
	}

	AutoExecConfig();

	register_dictionary("joinleave_messages.txt");
	
	// Load overrides from file
	LoadCountryOverrides();
}

public Event_NativeSvenLeaveMessage(iMsgId, iDest, iReceiver)
{
	new iDestinationType = get_msg_arg_int(1);

	if(iDestinationType == 3)
	{
		new szMessage[MAX_USER_INFO_LENGTH];
		get_msg_arg_string(2, szMessage, charsmax(szMessage));
		// - GaussJumper9986 has left the game
		if(containi(szMessage, ORIGINAL_LEAVE_MSG) != -1)
			return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Event_NativeJoinGameMessage(iMsgId, iDest, iReceiver)
{
	if(get_pcvar_bool(g_cvarEnabled))
	{
		new iDestinationType = get_msg_arg_int(1);

		if(iDestinationType == 3)
		{
			new szMessage[MAX_USER_INFO_LENGTH];
			get_msg_arg_string(2, szMessage, charsmax(szMessage));
			if(containi(szMessage, ORIGINAL_JOIN_MSG) > 0)
				return PLUGIN_HANDLED;
			else if(containi(szMessage, ORIGINAL_LEAVE_MSG) != -1)
				return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public Event_NativeSayText(iMsgId, iDest, iReceiver)
{
	if(get_pcvar_bool(g_cvarEnabled))
	{
		new iSenderId = get_msg_arg_int(1);
		if(iSenderId >= 1 && iSenderId <= MaxClients)
		{
			new szMessage[MAX_USER_INFO_LENGTH];
			get_msg_arg_string(2, szMessage, charsmax(szMessage));

			if(szMessage[0] == '-' && szMessage[1] == ' ' && containi(szMessage, ORIGINAL_JOIN_MSG) > 0)
				return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public client_putinserver(iClient)
{
	if(!get_pcvar_bool(g_cvarEnabled) || is_user_bot(iClient) || is_user_hltv(iClient))
		return;
		
	set_task(2.0, "print_join_message", iClient);
}

public client_disconnected(iClient, bool:bDrop, szMessage[], iMaxLen)
{
	if(g_bFullyJoined[iClient] && get_pcvar_bool(g_cvarSounds) && (!g_bIgnoreBots || !is_user_bot(iClient)))
	{
		client_print(0, print_chat, "%L", LANG_PLAYER, "PLAYER_LEFT_STRING", iClient, szMessage);
		client_cmd(0, "spk %s", LEAVE_SOUND);
	}

	g_bFullyJoined[iClient] = false;
}

public print_join_message(iClient)
{
	if(is_user_connected(iClient))
	{
		new szIP[32];
		new szName[32];
		new szSteamID[32];
		get_user_name(iClient, szName, charsmax(szName));
		get_user_ip(iClient, szIP, charsmax(szIP), true);
		get_user_authid(iClient, szSteamID, charsmax(szSteamID));

		new szCountry[MAX_NAME_LENGTH];

		new szSteamIDOverride[MAX_NAME_LENGTH];
		if(GetSteamIDCountryOverride(szSteamID, szSteamIDOverride))
			copy(szCountry, charsmax(szCountry), szSteamIDOverride);
		else
		{
			new iRetVal = geoip_country_ex(szIP, szCountry, charsmax(szCountry));
			if(!iRetVal)
				copy(szCountry, charsmax(szCountry), "Unknown Country");
		}

		client_print(0, print_chat, "%L", LANG_PLAYER, "PLAYER_JOIN_STRING", szName, szCountry);

		if(get_pcvar_bool(g_cvarSounds))
			client_cmd(0, "spk %s", JOIN_SOUND);

		g_bFullyJoined[iClient] = true;
	}
}

/**
 * Loads country overrides from the configuration file
 * Format: STEAMID|Country
 * Example: STEAM_0:0:123456789|United States
 */
LoadCountryOverrides()
{
	new szFilePath[256];
	get_configsdir(szFilePath, charsmax(szFilePath));
	format(szFilePath, charsmax(szFilePath), "%s/geoip_overrides.ini", szFilePath);

	if(!file_exists(szFilePath))
	{
		log_amx("GeoIP Override file not found: %s", szFilePath);
		g_iOverrideCount = 0;
		return;
	}

	new szBuffer[256];
	new szSteamID[32];
	new szCountry[MAX_NAME_LENGTH];
	new iFile = fopen(szFilePath, "rt");

	if(!iFile)
	{
		log_amx("Failed to open GeoIP Override file: %s", szFilePath);
		return;
	}

	g_iOverrideCount = 0;

	while(fgets(iFile, szBuffer, charsmax(szBuffer)) && g_iOverrideCount < MAX_OVERRIDES)
	{
		// Skip empty lines and comments
		if(szBuffer[0] == '^0' || szBuffer[0] == ';' || szBuffer[0] == '/')
			continue;

		// Trim whitespace
		trim(szBuffer);

		// Parse the line: STEAMID|Country
		new iDelimiterPos = contain(szBuffer, "|");
		if(iDelimiterPos == -1)
			continue;

		copy(szSteamID, 31, szBuffer);
		szSteamID[iDelimiterPos] = '^0';
		trim(szSteamID);

		copy(szCountry, charsmax(szCountry), szBuffer[iDelimiterPos + 1]);
		trim(szCountry);

		if(strlen(szSteamID) > 0 && strlen(szCountry) > 0)
		{
			copy(g_szSteamIDOverrides[g_iOverrideCount], 31, szSteamID);
			copy(g_szCountryOverrides[g_iOverrideCount], charsmax(g_szCountryOverrides[]), szCountry);
			g_iOverrideCount++;
		}
	}

	fclose(iFile);
	log_amx("Loaded %d SteamID country overrides", g_iOverrideCount);
}

/**
 * Retrieves the country override for a given SteamID
 * Returns true if an override exists, false otherwise
 */
GetSteamIDCountryOverride(const szSteamID[], szCountryBuffer[])
{
	for(new i = 0; i < g_iOverrideCount; i++)
	{
		if(equal(g_szSteamIDOverrides[i], szSteamID))
		{
			copy(szCountryBuffer, MAX_NAME_LENGTH - 1, g_szCountryOverrides[i]);
			return true;
		}
	}
	return false;
}
