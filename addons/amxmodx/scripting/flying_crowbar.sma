#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>
//#tryinclude <compressor>
#include <xs>

#define FLYING_CROWBAR_ENTITY_NAME      "projectile_crowbar"

#define PLUGIN_NAME                     "Flying Crowbar"
#define PLUGIN_VERSION                  "1.0.0-25w18a"
#define PLUGIN_AUTHOR                   "szGabu, forked from SPiNX, Gauss and GordonFreeman"

new const g_iColorPalette[256][3] = {
    {255,   0,   0},
    {255,   5,   0},
    {255,  10,   0},
    {255,  15,   0},
    {255,  20,   0},
    {255,  25,   0},
    {255,  31,   0},
    {255,  36,   0},
    {255,  41,   0},
    {255,  46,   0},
    {255,  51,   0},
    {255,  57,   0},
    {255,  62,   0},
    {255,  67,   0},
    {255,  72,   0},
    {255,  77,   0},
    {255,  83,   0},
    {255,  88,   0},
    {255,  93,   0},
    {255,  98,   0},
    {255, 103,   0},
    {255, 109,   0},
    {255, 114,   0},
    {255, 119,   0},
    {255, 124,   0},
    {255, 129,   0},
    {255, 135,   0},
    {255, 140,   0},
    {255, 145,   0},
    {255, 150,   0},
    {255, 155,   0},
    {255, 161,   0},
    {255, 165,   0},
    {255, 168,   0},
    {255, 171,   0},
    {255, 174,   0},
    {255, 177,   0},
    {255, 179,   0},
    {255, 182,   0},
    {255, 185,   0},
    {255, 188,   0},
    {255, 191,   0},
    {255, 194,   0},
    {255, 196,   0},
    {255, 199,   0},
    {255, 202,   0},
    {255, 205,   0},
    {255, 208,   0},
    {255, 211,   0},
    {255, 213,   0},
    {255, 216,   0},
    {255, 219,   0},
    {255, 222,   0},
    {255, 225,   0},
    {255, 228,   0},
    {255, 230,   0},
    {255, 233,   0},
    {255, 236,   0},
    {255, 239,   0},
    {255, 242,   0},
    {255, 245,   0},
    {255, 247,   0},
    {255, 250,   0},
    {255, 253,   0},
    {250, 255,   0},
    {242, 255,   0},
    {234, 255,   0},
    {226, 255,   0},
    {218, 255,   0},
    {210, 255,   0},
    {202, 255,   0},
    {194, 255,   0},
    {186, 255,   0},
    {178, 255,   0},
    {170, 255,   0},
    {162, 255,   0},
    {154, 255,   0},
    {146, 255,   0},
    {138, 255,   0},
    {130, 255,   0},
    {122, 255,   0},
    {114, 255,   0},
    {106, 255,   0},
    { 98, 255,   0},
    { 90, 255,   0},
    { 82, 255,   0},
    { 74, 255,   0},
    { 66, 255,   0},
    { 58, 255,   0},
    { 50, 255,   0},
    { 42, 255,   0},
    { 34, 255,   0},
    { 26, 255,   0},
    { 18, 255,   0},
    { 10, 255,   0},
    {  2, 255,   0},
    {  0, 255,   6},
    {  0, 255,  14},
    {  0, 255,  22},
    {  0, 255,  30},
    {  0, 255,  38},
    {  0, 255,  46},
    {  0, 255,  54},
    {  0, 255,  62},
    {  0, 255,  70},
    {  0, 255,  78},
    {  0, 255,  86},
    {  0, 255,  94},
    {  0, 255, 102},
    {  0, 255, 110},
    {  0, 255, 118},
    {  0, 255, 126},
    {  0, 255, 134},
    {  0, 255, 142},
    {  0, 255, 150},
    {  0, 255, 158},
    {  0, 255, 166},
    {  0, 255, 174},
    {  0, 255, 182},
    {  0, 255, 190},
    {  0, 255, 198},
    {  0, 255, 206},
    {  0, 255, 214},
    {  0, 255, 222},
    {  0, 255, 230},
    {  0, 255, 238},
    {  0, 255, 246},
    {  0, 255, 255},
    {  5, 253, 254},
    { 10, 252, 253},
    { 16, 251, 252},
    { 21, 250, 251},
    { 27, 248, 251},
    { 32, 247, 250},
    { 38, 246, 249},
    { 43, 245, 248},
    { 49, 243, 247},
    { 54, 242, 247},
    { 59, 241, 246},
    { 65, 240, 245},
    { 70, 239, 244},
    { 76, 237, 243},
    { 81, 236, 243},
    { 87, 235, 242},
    { 92, 234, 241},
    { 98, 232, 240},
    {103, 231, 240},
    {108, 230, 239},
    {114, 229, 238},
    {119, 227, 237},
    {125, 226, 236},
    {130, 225, 236},
    {136, 224, 235},
    {141, 223, 234},
    {147, 221, 233},
    {152, 220, 232},
    {158, 219, 232},
    {163, 218, 231},
    {168, 216, 230},
    {171, 214, 230},
    {166, 207, 230},
    {160, 200, 231},
    {155, 193, 232},
    {149, 187, 233},
    {144, 180, 234},
    {138, 173, 234},
    {133, 166, 235},
    {128, 159, 236},
    {122, 153, 237},
    {117, 146, 238},
    {111, 139, 238},
    {106, 132, 239},
    {100, 125, 240},
    { 95, 119, 241},
    { 89, 112, 242},
    { 84, 105, 242},
    { 79,  98, 243},
    { 73,  91, 244},
    { 68,  85, 245},
    { 62,  78, 245},
    { 57,  71, 246},
    { 51,  64, 247},
    { 46,  57, 248},
    { 40,  51, 249},
    { 35,  44, 249},
    { 29,  37, 250},
    { 24,  30, 251},
    { 19,  23, 252},
    { 13,  17, 253},
    {  8,  10, 253},
    {  2,   3, 254},
    {  2,   0, 253},
    {  6,   0, 249},
    { 10,   0, 245},
    { 14,   0, 241},
    { 18,   0, 237},
    { 22,   0, 233},
    { 26,   0, 229},
    { 30,   0, 225},
    { 34,   0, 220},
    { 38,   0, 216},
    { 42,   0, 212},
    { 46,   0, 208},
    { 50,   0, 204},
    { 54,   0, 200},
    { 58,   0, 197},
    { 62,   0, 193},
    { 66,   0, 189},
    { 70,   0, 185},
    { 74,   0, 181},
    { 78,   0, 177},
    { 82,   0, 173},
    { 86,   0, 169},
    { 90,   0, 165},
    { 94,   0, 161},
    { 98,   0, 156},
    {102,   0, 152},
    {106,   0, 148},
    {110,   0, 144},
    {114,   0, 140},
    {118,   0, 137},
    {122,   0, 133},
    {126,   0, 129},
    {131,   2, 129},
    {135,   5, 130},
    {138,   9, 132},
    {142,  12, 134},
    {146,  15, 135},
    {150,  19, 137},
    {154,  22, 139},
    {158,  25, 140},
    {163,  28, 142},
    {167,  32, 143},
    {171,  35, 145},
    {175,  38, 147},
    {179,  42, 148},
    {183,  45, 150},
    {187,  48, 152},
    {191,  52, 153},
    {195,  55, 155},
    {199,  58, 157},
    {202,  62, 158},
    {206,  65, 160},
    {210,  68, 161},
    {214,  71, 163},
    {218,  75, 165},
    {222,  78, 166},
    {227,  81, 168},
    {231,  85, 170},
    {235,  88, 171},
    {239,  91, 173},
    {243,  95, 175},
    {247,  98, 176},
    {251,  71, 138},
    {255,  55, 120},
    {255,   0,   0},
};

#define PICKUP_SOUND_DEFAULT    "items/gunpickup2.wav"

/* Private Data for Sven Co-op - New values might be required when new version comes. */
#define SvenCoop_m_pPlayer 		420
#define SvenCoop_g_iUnixDiff 	16

#define SF_UNKNOWN              (1 << 12) //use only?
#define SF_NOTINDEATHMATCH      (1 << 11) //SVENCOOP ONLY apparently this deprecated flag is used somewhere else
#define SF_DISABLERESPAWN       (1 << 10) //source: sven manor

// content
static g_hContentBloodDrop;
static g_hContentBloodSpray;
static g_hContentTrailSprite;

enum _:CrowbarSounds {
    CBAR_HIT1,
    CBAR_HIT2,
    CBAR_HITBOD1,
    CBAR_HITBOD2,
    CBAR_HITBOD3,
    CBAR_MISS1
}

static g_hContentCrowbarSounds[CrowbarSounds];

static g_cvarCrowbarTime;
static g_cvarCrowbarSpeed;
static g_cvarCrowbarRender;
static g_cvarCrowbarTrail;
static g_cvarCrowbarRenderColor;
static g_cvarCrowbarTrailColor;
static g_cvarCrowbarDamage;

static Float:g_fCrowbarTime;
static g_iCrowbarSpeed;
static bool:g_bCrowbarRender;
static bool:g_bCrowbarTrail;
static g_iCrowbarRenderColor;
static g_iCrowbarTrailColor;
static Float:g_fCrowbarDamage;

static bool:g_bSvenCoopRunning;

public plugin_precache()
{
    g_hContentBloodDrop = precache_model("sprites/blood.spr");
    g_hContentBloodSpray = precache_model("sprites/bloodspray.spr");
    g_hContentTrailSprite = precache_model("sprites/zbeam3.spr");
    precache_sound(PICKUP_SOUND_DEFAULT);

    // these are already precached in HLDM, but Sven Co-op uses another way to play them
    g_hContentCrowbarSounds[CBAR_HIT1] = precache_sound("weapons/cbar_hit1.wav"); 
    g_hContentCrowbarSounds[CBAR_HIT2] = precache_sound("weapons/cbar_hit2.wav"); 
    g_hContentCrowbarSounds[CBAR_HITBOD1] = precache_sound("weapons/cbar_hitbod1.wav"); 
    g_hContentCrowbarSounds[CBAR_HITBOD2] = precache_sound("weapons/cbar_hitbod2.wav"); 
    g_hContentCrowbarSounds[CBAR_HITBOD3] = precache_sound("weapons/cbar_hitbod3.wav"); 
    g_hContentCrowbarSounds[CBAR_MISS1] = precache_sound("weapons/cbar_miss1.wav");
}

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR); 

    g_bSvenCoopRunning = is_running("svencoop") == 1;

    new iDeathMsgMessageId = get_user_msgid("DeathMsg")

    if(iDeathMsgMessageId)
        register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg");

    RegisterHam(g_bSvenCoopRunning ? Ham_SC_Weapon_TertiaryAttack : Ham_Weapon_SecondaryAttack, "weapon_crowbar", "Event_CrowbarSecondaryAttack_Pre");

    RegisterHam(Ham_AddPlayerItem, "player", "Event_PlayerAddPlayerTtem_Pre");

    register_think(FLYING_CROWBAR_ENTITY_NAME, "Forward_FlyingCrowbarThink_Pre");
    register_touch(FLYING_CROWBAR_ENTITY_NAME, "*", "FlyCrowbar_Touch");

    g_cvarCrowbarTime = create_cvar("fly_crowbar_alive_time","15.0", FCVAR_NONE, "Determines for how long the crowbar should be in the game after landing, a value of 0 makes it disappear instantly.", true, 0.0);
    g_cvarCrowbarSpeed = create_cvar("fly_crowbar_flyspeed","1300", FCVAR_NONE, "Determines the speed of the flying crowbar.", true, 0.0);
    g_cvarCrowbarRender = create_cvar("fly_crowbar_glow","1", FCVAR_NONE, "Determines if the flying crowbar should glow.", true, 0.0, true, 1.0);
    g_cvarCrowbarTrail = create_cvar("fly_crowbar_glow_color","1", FCVAR_NONE, "Determines the glowing color of the crowbar. 0 = Random, 1 = Use Player's Top Color, 2 = Use Player's Bottom Color", true, 0.0, true, 2.0);
    g_cvarCrowbarRenderColor = create_cvar("fly_crowbar_trail","1", FCVAR_NONE, "Determines if the flying crowbar should have a trail", true, 0.0, true, 1.0);
    g_cvarCrowbarTrailColor = create_cvar("fly_crowbar_trail_color","2", FCVAR_NONE, "Determines the trail color of the crowbar. 0 = Random, 1 = Use Player's Top Color, 2 = Use Player's Bottom Color", true, 0.0, true, 2.0);
    g_cvarCrowbarDamage = create_cvar("fly_crowbar_damage","300.0", FCVAR_NONE, "Determines the damage of the flying crowbar.", true, 0.0);

    register_dictionary("flying_crowbar.txt");

    AutoExecConfig();
}

public plugin_cfg()
{
    bind_pcvar_float(g_cvarCrowbarTime, g_fCrowbarTime);
    bind_pcvar_num(g_cvarCrowbarSpeed, g_iCrowbarSpeed);
    bind_pcvar_num(g_cvarCrowbarRender, g_bCrowbarRender);
    bind_pcvar_num(g_cvarCrowbarTrail, g_iCrowbarRenderColor);
    bind_pcvar_num(g_cvarCrowbarRenderColor, g_bCrowbarTrail);
    bind_pcvar_num(g_cvarCrowbarTrailColor, g_iCrowbarTrailColor);
    bind_pcvar_float(g_cvarCrowbarDamage, g_fCrowbarDamage);
}

public Message_DeathMsg()
{
    static sWeapon[20];
    get_msg_arg_string(3,sWeapon,19);
    if(equal(sWeapon, FLYING_CROWBAR_ENTITY_NAME))
        set_msg_arg_string(3,"crowbar");
}

public Event_CrowbarSecondaryAttack_Pre(iWeapon)
{
    if(pev_valid(iWeapon))
    {
        new iClient
        if(g_bSvenCoopRunning)
            iClient = get_pdata_ehandle(iWeapon, SvenCoop_m_pPlayer, SvenCoop_g_iUnixDiff)
        else 
            iClient = get_ent_data_entity(iWeapon, "CBasePlayerItem", "m_pPlayer");
        if(is_user_connected(iClient))
        {    
            if(!FlyCrowbar_Spawn(iClient, iWeapon))
                return HAM_IGNORED;
            
            if(g_bSvenCoopRunning)
                return HAM_SUPERCEDE;
        }
    }

    return HAM_IGNORED;
}

public FlyCrowbar_Touch(iCrowbar, iVictim)
{
    new Float:fOrigin[3], Float:fAngles[3], Float:fStartingPos[3];
    pev(iCrowbar, pev_origin, fOrigin);
    pev(iCrowbar, pev_angles, fAngles);
    pev(iCrowbar, pev_vuser1, fStartingPos);
    new iClient = pev(iCrowbar, pev_owner);

    if(!is_user_connected(iClient))
        iClient = 0;

    if(iVictim && pev_valid(iVictim) && !ExecuteHam(g_bSvenCoopRunning ? Ham_SC_IsBSPModel : Ham_IsBSPModel, iVictim))
    {
        //we landed on a player or a non-bsp model entity (a monster, for example)
        new Float:fDist = get_distance_f(fStartingPos, fOrigin) * 0.0254;
        new Float:fDamage = fDist*25.0;
        ExecuteHamB(Ham_TakeDamage, iVictim, iCrowbar, iClient, fDamage, DMG_CLUB);
        if(iClient)
            client_print(iClient, print_center, "%L", iClient, "FLYING_CROWBAR_HIT", floatround(fDamage), floatround(fDist));

        if(iClient && fDist > 20.0)
        {
            new szAttackerName[MAX_NAME_LENGTH], szVictimName[MAX_NAME_LENGTH];
            get_user_name(iClient, szAttackerName, charsmax(szAttackerName));
            pev(iVictim, pev_netname, szVictimName, charsmax(szVictimName));

            if(is_user_connected(iVictim))
                get_user_name(iVictim, szVictimName, charsmax(szVictimName));
            else 
                pev(iVictim, pev_netname, szVictimName, charsmax(szVictimName));
                
            if(strlen(szVictimName) > 0)
            {
                set_hudmessage(200, 200, 200, -1.0, 0.27, 0, 6.0, 5.0);
                show_hudmessage(0, "%L", LANG_PLAYER, "FLYING_LONG_HIT", szAttackerName, szVictimName, floatround(fDist));
            }
        }

        emit_sound(iCrowbar, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM);

        engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
        write_byte(TE_BLOODSPRITE);
        engfunc(EngFunc_WriteCoord, fOrigin[0]+random_num(-20,20));
        engfunc(EngFunc_WriteCoord, fOrigin[1]+random_num(-20,20));
        engfunc(EngFunc_WriteCoord, fOrigin[2]+random_num(-20,20));
        write_short(g_hContentBloodSpray);
        write_short(g_hContentBloodDrop);
        write_byte(ExecuteHamB(Ham_BloodColor, iVictim)); // color index
        write_byte(15); // size
        message_end();
    }
    else
    {
        if(pev_valid(iVictim))
            ExecuteHamB(Ham_TakeDamage, iVictim, iCrowbar, pev(iCrowbar, pev_owner), g_fCrowbarDamage, DMG_CLUB);

        emit_sound(iCrowbar,CHAN_WEAPON,"weapons/cbar_hit1.wav",0.9,ATTN_NORM,0,PITCH_NORM);

        engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY, fOrigin,0);
        write_byte(TE_SPARKS);
        engfunc(EngFunc_WriteCoord, fOrigin[0]);
        engfunc(EngFunc_WriteCoord, fOrigin[1]);
        engfunc(EngFunc_WriteCoord, fOrigin[2]);
        message_end();
    }

    new szModel[PLATFORM_MAX_PATH];
    new iOriginalCrowbar = pev(iCrowbar, pev_euser1);
    pev(iCrowbar, pev_model, szModel, charsmax(szModel));
    engfunc(EngFunc_RemoveEntity, iCrowbar);

    new iDroppedCrow = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString, "weapon_crowbar"));
    DispatchSpawn(iDroppedCrow);

    #if defined _compressor_included
    Compressor_SetModel(iDroppedCrow, szModel);
    #else 
    engfunc(EngFunc_SetModel, iDroppedCrow, szModel);
    #endif
    
    set_pev(iDroppedCrow, pev_euser1, iOriginalCrowbar);
        
    set_pev(iDroppedCrow, pev_spawnflags, g_bSvenCoopRunning ? (SF_NORESPAWN | SF_UNKNOWN | SF_NOTINDEATHMATCH | SF_DISABLERESPAWN) : SF_NORESPAWN); //maybe not needed? it's deleted when added to player

    if(g_fCrowbarTime > 0.0)
        set_task(g_fCrowbarTime, "Task_CrowbarRemoveFromWorld", iDroppedCrow);

    fAngles[0] = 0.0;
    fAngles[2] = 0.0;

    set_pev(iDroppedCrow, pev_origin, fOrigin);
    set_pev(iDroppedCrow, pev_angles, fAngles);

    if(g_bCrowbarRender)
    {
        new iRed, iGreen, iBlue;
        switch(g_iCrowbarRenderColor)
        {
            case 0:
            {
                iRed = 55 + random(200);
                iGreen = 55 + random(200);
                iBlue = 55 + random(200);
            }
            case 1:
            {
                new iColorIndex = GetUserTopColor(iClient);
                iRed = g_iColorPalette[iColorIndex][0];
                iGreen = g_iColorPalette[iColorIndex][1];
                iBlue = g_iColorPalette[iColorIndex][2];
            }
            case 2:
            {
                new iColorIndex = GetUserBottomColor(iClient);
                iRed = g_iColorPalette[iColorIndex][0];
                iGreen = g_iColorPalette[iColorIndex][1];
                iBlue = g_iColorPalette[iColorIndex][2];
            }
        }

        fm_set_rendering(iDroppedCrow, kRenderFxGlowShell, iRed, iGreen, iBlue, kRenderNormal);
    }
}

public Task_CrowbarRemoveFromWorld(iEnt)
{
    if(pev_valid(iEnt))
    {
        new iOriginalCrowbar = pev(iEnt, pev_euser1);
        
        engfunc(EngFunc_RemoveEntity, iEnt);

        if(iOriginalCrowbar)
            engfunc(EngFunc_RemoveEntity, iOriginalCrowbar);
    }
}

public Event_PlayerAddPlayerTtem_Pre(iClient, iWeapon)
{
    new szClassName[MAX_NAME_LENGTH];
    pev(iWeapon, pev_classname, szClassName, charsmax(szClassName))
    if(equali(szClassName, "weapon_crowbar"))
    {
        new iOriginalCrowbar = pev(iWeapon, pev_euser1);
        if(iOriginalCrowbar)
        {
            ExecuteHam(Ham_AddPlayerItem, iClient, iOriginalCrowbar);
            
            if(g_bSvenCoopRunning)
            {
                new szSoundFile[PLATFORM_MAX_PATH];
                ExecuteHam(Ham_SC_Item_GetPickupSound, iWeapon, szSoundFile, charsmax(szSoundFile));
                emit_sound(iClient, CHAN_ITEM, szSoundFile, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                //engfunc(EngFunc_RemoveEntity, iWeapon);
            }
            else 
            {
                emit_sound(iClient, CHAN_ITEM, PICKUP_SOUND_DEFAULT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                //ExecuteHam(Ham_Item_Kill, iWeapon);
            }

            set_pev(iWeapon, pev_euser1, 0);
            set_pev(iWeapon, pev_flags, pev(iWeapon, pev_flags) | FL_KILLME);
            remove_task(iWeapon);

            return HAM_SUPERCEDE;
        }
    }

    return HAM_IGNORED;
}

public FlyCrowbar_Spawn(iClient, iOriginal)
{
    new iFlyingCrowbar = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString, "info_target"));

    if(!pev_valid(iFlyingCrowbar))
        return 0;

    //store original crowbar values, this is needed to make it pickable again in Sven Co-op
    new szModel[PLATFORM_MAX_PATH];
    if(g_bSvenCoopRunning)
    {
        ExecuteHam(Ham_SC_Item_DetachFromPlayer, iOriginal);
        pev(iOriginal, pev_model, szModel, charsmax(szModel));
        ExecuteHam(Ham_Item_AttachToPlayer, iOriginal, iClient); //this is needed to get the original w_ model
        ExecuteHam(Ham_SC_RemovePlayerItem, iClient, iOriginal);
    }
    else
    {
        ExecuteHam(Ham_RemovePlayerItem, iClient, iOriginal);
        //ExecuteHam(Ham_Item_Kill, iOriginal);
        copy(szModel, charsmax(szModel), "models/w_crowbar.mdl");
    }

    set_pev(iFlyingCrowbar, pev_classname, FLYING_CROWBAR_ENTITY_NAME);
    
    #if defined _compressor_included
    Compressor_SetModel(iFlyingCrowbar, szModel);
    #else 
    engfunc(EngFunc_SetModel, iFlyingCrowbar, szModel);
    #endif

    engfunc(EngFunc_SetSize, iFlyingCrowbar, Float:{-4.0, -4.0, -4.0} , Float:{4.0, 4.0, 4.0});

    new Float:fVector[3];
    get_projective_pos(iClient, fVector);
    engfunc(EngFunc_SetOrigin, iFlyingCrowbar, fVector);
    set_pev(iFlyingCrowbar, pev_vuser1, fVector);

    pev(iClient, pev_v_angle, fVector);
    fVector[0] = 90.0;
    fVector[2] = floatadd(fVector[2],-90.0);

    set_pev(iFlyingCrowbar, pev_owner, iClient);
    
    set_pev(iFlyingCrowbar, pev_angles, fVector);

    set_pev(iFlyingCrowbar, pev_euser1, iOriginal); //store original crowbar here

    velocity_by_aim(iClient, g_iCrowbarSpeed+get_speed(iClient), fVector);
    set_pev(iFlyingCrowbar, pev_velocity, fVector);

    set_pev(iFlyingCrowbar, pev_nextthink, get_gametime()+0.1);

    DispatchSpawn(iFlyingCrowbar);

    if(g_bCrowbarTrail)
    {
        new iRed, iGreen, iBlue;
        switch(g_iCrowbarTrailColor)
        {
            case 0:
            {
                iRed = 55+random(200);
                iGreen = 55+random(200);
                iBlue = 55+random(200);
            }
            case 1:
            {
                new iColorIndex = GetUserTopColor(iClient);
                iRed = g_iColorPalette[iColorIndex][0];
                iGreen = g_iColorPalette[iColorIndex][1];
                iBlue = g_iColorPalette[iColorIndex][2];
            }
            case 2:
            {
                new iColorIndex = GetUserBottomColor(iClient);
                iRed = g_iColorPalette[iColorIndex][0];
                iGreen = g_iColorPalette[iColorIndex][1];
                iBlue = g_iColorPalette[iColorIndex][2];
            }
        }

        message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
        write_byte(TE_BEAMFOLLOW);
        write_short(iFlyingCrowbar);
        write_short(g_hContentTrailSprite);
        write_byte(15);
        write_byte(2);
        write_byte(iRed);
        write_byte(iGreen);
        write_byte(iBlue);
        write_byte(255);
        message_end();
    }

    set_pev(iFlyingCrowbar, pev_movetype, MOVETYPE_TOSS);
    set_pev(iFlyingCrowbar, pev_solid, SOLID_BBOX);

    emit_sound(iClient, CHAN_WEAPON, "weapons/cbar_miss1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM);
    set_task(0.1, "FlyCrowbar_Whizz", iFlyingCrowbar);

    return iFlyingCrowbar;
}

public Forward_FlyingCrowbarThink_Pre(iFlyingCrowbar)
{
    new Float:fVector[3];
    pev(iFlyingCrowbar, pev_angles, fVector);
    fVector[0] = floatadd(fVector[0], -15.0);
    set_pev(iFlyingCrowbar, pev_angles, fVector);

    set_pev(iFlyingCrowbar, pev_nextthink, get_gametime()+0.01);
}

public FlyCrowbar_Whizz(iFlyingCrowbar)
{
    if(pev_valid(iFlyingCrowbar))
    {
        emit_sound(iFlyingCrowbar, CHAN_WEAPON, "weapons/cbar_miss1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM);
        set_task(0.2, "FlyCrowbar_Whizz", iFlyingCrowbar);
    }
}

get_projective_pos(iClient, Float:fOrigin[3])
{
    new Float:fVectorForward[3];
    new Float:fVectorRight[3];
    new Float:fVectorUp[3];

    GetGunPosition(iClient, fOrigin);

    global_get(glb_v_forward, fVectorForward);
    global_get(glb_v_right, fVectorRight);
    global_get(glb_v_up, fVectorUp);

    xs_vec_mul_scalar(fVectorForward, 6.0, fVectorForward);
    xs_vec_mul_scalar(fVectorRight, 2.0, fVectorRight);
    xs_vec_mul_scalar(fVectorUp, -2.0, fVectorUp);

    xs_vec_add(fOrigin, fVectorForward, fOrigin);
    xs_vec_add(fOrigin, fVectorRight, fOrigin);
    xs_vec_add(fOrigin, fVectorUp, fOrigin);
}

stock GetGunPosition(const iClient, Float:fOrigin[3])
{
    new Float:fViewOfs[3];

    pev(iClient, pev_origin, fOrigin);
    pev(iClient, pev_view_ofs, fViewOfs);

    xs_vec_add(fOrigin, fViewOfs, fOrigin);
}

stock GetUserTopColor(iClient)
{
    if(is_user_connected(iClient))
    {
        new szInfo[5];
        get_user_info(iClient, "topcolor", szInfo, charsmax(szInfo));
        return clamp(str_to_num(szInfo), 0, 255);  
    }
    else
        return 0;
}

stock GetUserBottomColor(iClient)
{
    if(is_user_connected(iClient))
    {
        new szInfo[5];
        get_user_info(iClient, "bottomcolor", szInfo, charsmax(szInfo));
        return clamp(str_to_num(szInfo), 0, 255);  
    }
    else
        return 0;
}