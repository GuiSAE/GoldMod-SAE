#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>
#include <colors>
//#include <timers.inc>

#define TEAM_SURVIVOR           2 
#define TEAM_INFECTED           3

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

// damage type
#define DMG_GENERIC             0               // generic damage was done
#define DMG_CRUSH               (1 << 0)        // crushed by falling or moving object. 
                                                // NOTE: It's assumed crush damage is occurring as a result of physics collision, so no extra physics force is generated by crush damage.
                                                // DON'T use DMG_CRUSH when damaging entities unless it's the result of a physics collision. You probably want DMG_CLUB instead.
#define DMG_BULLET              (1 << 1)        // shot
#define DMG_SLASH               (1 << 2)        // cut, clawed, stabbed
#define DMG_BURN                (1 << 3)        // heat burned
#define DMG_BLAST               (1 << 6)        // explosive blast damage
#define DMG_CLUB                (1 << 7)        // crowbar, punch, headbutt
#define DMG_BUCKSHOT            (1 << 29)       // not quite a bullet. Little, rounder, different. 

#define HITGROUP_GENERIC        0
#define HITGROUP_HEAD           1
#define HITGROUP_CHEST          2
#define HITGROUP_STOMACH        3
#define HITGROUP_LEFTARM        4
#define HITGROUP_RIGHTARM       5
#define HITGROUP_LEFTLEG        6
#define HITGROUP_RIGHTLEG       7
#define HITGROUP_GEAR           10


#define CHARGER_DMG_DEFAULT     10.0
#define CHARGER_DMG_STUMBLE      2.0
#define CHARGER_DMG_POUND       15.0

#define CHARGER_KILL_TIME       0.05


enum TankOrSIWeapon
{
    TANKWEAPON,
    CHARGERWEAPON,
    SIWEAPON
}

//new Handle: hPluginEnabled;                                   // convar: enable fix
new Handle: hInflictorTrie = INVALID_HANDLE;                    // names to look up
new bool: bLateLoad;

//new Handle: hDmgPunch = INVALID_HANDLE;                         // damage per normal punch
new Handle: hDmgFirst = INVALID_HANDLE;                         // damage for first punch after spawning
new Handle: hDmgSmash = INVALID_HANDLE;                         // damage for the smash-inpact (def.10)
new Handle: hDmgStumble = INVALID_HANDLE;                       // damage for stumble
new Handle: hDmgPound = INVALID_HANDLE;                         // damage for pound-slams (replaces natural cvar)
new Handle: hDmgCappedVictim = INVALID_HANDLE;                  // scratch damage for capped Survivors
new Handle: hDmgIncappedPound = INVALID_HANDLE;                  // damage for incapped Survivors

new bool: bChargerPunched[MAXPLAYERS + 1];                      // whether charger player got a punch in current life
new bool: bChargerCharging[MAXPLAYERS + 1];                     // whether the charger is in a charge

//new Float: fPlayerPreviousHit[MAXPLAYERS + 1][MAXPLAYERS + 1];  // when was the previous attack from the client (EngineTime)

new const survivorProps[] = 
{
	13284,	// smoker
	16008,	// hunter
	16128,	// jockey
	15976	// charger
};


public Plugin:myinfo = 
{
    name = "Charger Damage",
    author = "Tabun, Jacob, Visor",
    description = "Charger damage modifier",
    version = "0.4",
    url = "https://github.com/Attano/L4D2-Competitive-Framework"
}

/* -------------------------------
 *      Init
 * ------------------------------- */

public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax)
{
    bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart()
{
    // hook already existing clients if loading late
    if (bLateLoad) {
        for (new i = 1; i < MaxClients+1; i++) {
            if (IsClientInGame(i)) {
                SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
    }
    
    // cvars
    //hPluginEnabled = CreateConVar("sm_jockeyglitchfix_enabled", "1", "Enable the fix for the jockey-damage glitch.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    //hDmgPunch = CreateConVar("charger_dmg_punch",          			"0.0",    "Damage per (normal) charger punch.", FCVAR_PLUGIN, true, 0.0);// 每次右键伤害
    hDmgFirst = CreateConVar("charger_dmg_firstpunch",     			"-1.0",    "Damage for first charger punch (in its life). -1 to ignore punch count", FCVAR_PLUGIN, true, -1.0);// 存活期间第一次拳击的伤害
    hDmgSmash = CreateConVar("charger_dmg_impact",         			"10",    "Damage for impact after a charge.", FCVAR_PLUGIN, true, 0.0);// 冲锋撞击后（一撞多）以及撞停造成的伤害
    hDmgStumble = CreateConVar("charger_dmg_stumble",      			"2",    "Damage for stumbled impact after a charge.", FCVAR_PLUGIN, true, 0.0);// 震人的伤害
    hDmgPound = CreateConVar("charger_dmg_pound",          			"15",    "Damage for pounds after charge/collision completed.", FCVAR_PLUGIN, true, 0.0);// 压制造成的伤害
    hDmgCappedVictim = CreateConVar("charger_dmg_cappedvictim",  	"0.0",    "Damage for capped Survivor victims.", FCVAR_PLUGIN, true, 0.0);// 对被猴子乘骑时的生还造成的伤害
    hDmgIncappedPound = CreateConVar("charger_dmg_incapped",  	"15",    "Damage for incapped victims.", FCVAR_PLUGIN, true, 0.0);// 对倒地幸存者造成的伤害
    
    // hooks
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("player_spawn", PlayerSpawn_Event, EventHookMode_Post);
    //HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
    HookEvent("charger_charge_start", ChargeStart_Event, EventHookMode_Post);
    HookEvent("charger_charge_end", ChargeEnd_Event, EventHookMode_Post);
    
    // trie
    hInflictorTrie = BuildInflictorTrie();
}


/* -------------------------------
 *      General hooks / events
 * ------------------------------- */

public OnClientPostAdminCheck(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
    setCleanSlate();
}

public Action: RoundStart_Event (Handle:event, const String:name[], bool:dontBroadcast)
{
    setCleanSlate();
}

public Action:PlayerSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    //if (!GetConVarBool(hPluginEnabled))                                 { return Plugin_Continue; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    // the usual checks, only actual jockeys
    if (!IsClientAndInGame(client))                                     { return Plugin_Continue; }
    if (GetClientTeam(client) != TEAM_INFECTED)                         { return Plugin_Continue; }
    if (GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_CHARGER)   { return Plugin_Continue; }
    
    // just spawned, prepare for that first punch
    bChargerPunched[client] = false;
    bChargerCharging[client] = false;
    
    return Plugin_Continue;
}

public ChargeStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new clientId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(clientId);
    
    if (IsClientAndInGame(client)) {
        bChargerCharging[client] = true;
    }    
}
public ChargeEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new clientId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(clientId);
    
    if (IsClientAndInGame(client)) {
        bChargerCharging[client] = false;
    }   
}

/* --------------------------------------
 *     GOT MY EYES ON YOU, DAMAGE
 * -------------------------------------- */

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	//if (!GetConVarBool(hPluginEnabled)) { return Plugin_Continue; }
	if (!inflictor || !attacker || !victim || !IsValidEdict(victim) || !IsValidEdict(inflictor)) { return Plugin_Continue; }

	// only check player-to-player damage
	decl String:classname[64];
	if (IsClientAndInGame(attacker) && IsClientAndInGame(victim))
	{
		if (attacker == inflictor)                                              // for claws
		{
			GetClientWeapon(inflictor, classname, sizeof(classname));
		}
		else
		{
			GetEdictClassname(inflictor, classname, sizeof(classname));         // for tank punch/rock
		}
	}
	else { return Plugin_Continue; }

	// check teams
	if (GetClientTeam(attacker) != TEAM_INFECTED || GetClientTeam(victim) != TEAM_SURVIVOR) { return Plugin_Continue; }

	// only allow chargers
	if (GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_CHARGER) { return Plugin_Continue; }

	// test:
	//PrintToChatAll("[test:] inflictor class: [%s] type [%d] damage [%.0f] force [%.0f %.0f %.0f]", classname, damageType, damage, damageForce[0], damageForce[1], damageForce[2]);

	// only check tank punch/rock and SI claws (also rules out anything but infected-to-survivor damage)
	new TankOrSIWeapon: inflictorID;
	if (!GetTrieValue(hInflictorTrie, classname, inflictorID)) { return Plugin_Continue; }
	if (inflictorID != CHARGERWEAPON) { return Plugin_Continue; }


	// okay, it is a charger

	// punch =          10 + has force > 0,0,0
	// bowl =           10 + has force > 0,0,0
	// stumble =        2 (+ small force)
	// charge impact =  10 + force 0,0,0
	// pound =          15 + force 0,0,0


	if (damage == CHARGER_DMG_DEFAULT)
	{
		if (damageForce[0] == 0.0 && damageForce[1] == 0.0 && damageForce[2] == 0.0) {
			// CHARGE IMPACT
			
			damage = GetConVarFloat(hDmgSmash);
			return Plugin_Changed;
			
		} else {
			// PUNCH
			new Float:dmgFirst = GetConVarFloat(hDmgFirst);
			if (!bChargerPunched[attacker] && dmgFirst > -1.0)
			{
				// this is the first attack
				bChargerPunched[attacker] = true;
				damage = dmgFirst;
				return Plugin_Changed;
			}
			
			// this is a (second+) charger punch (or first if firstpunch cvar is set to -1)
			//damage = IsUnderAttack(victim) ? GetConVarFloat(hDmgCappedVictim) : GetConVarFloat(hDmgPunch);
			return Plugin_Changed;
		}
	}
	else if (damage == CHARGER_DMG_STUMBLE)
	{
		// STUMBLE
		damage = GetConVarFloat(hDmgStumble);
		return Plugin_Changed;
	}
	else if (damage == CHARGER_DMG_POUND && (damageForce[0] == 0.0 && damageForce[1] == 0.0 && damageForce[2] == 0.0))
	{
		// POUND
		damage = IsIncapped(victim) ? GetConVarFloat(hDmgIncappedPound) : GetConVarFloat(hDmgPound);
		return Plugin_Changed;
	}
	/*
	// this is a (second+) charger punch
	//damage = GetConVarFloat(hDmgPunch);
	return Plugin_Changed;
	*/
	//CPrintToChatAll("{default}-{blue}Charger Damage{default}- {green}warning, charger doing a type of damage it shouldn't! infl.: [%s] type [%d] damage [%.0f] force [%.0f %.0f %.0f]", classname, damageType, damage, damageForce[0], damageForce[1], damageForce[2]);
	return Plugin_Handled;
}
    

    
/* --------------------------------------
 *     Shared function(s)
 * -------------------------------------- */

bool:IsClientAndInGame(index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

setCleanSlate()
{
    new i, maxplayers = MAXPLAYERS;
    for (i = 1; i <= maxplayers; i++)
    {
        bChargerPunched[i] = false;
        bChargerCharging[i] = false;
    }
}

stock String:hitGroupName(hitgroup)
{
    new String:tmpString[15] = "";
    switch (hitgroup)
    {
        case 0: { tmpString = "body"; }
        case 1: { tmpString = "head"; }
        case 2: { tmpString = "chest"; }
        case 3: { tmpString = "stomach"; }
        case 4: { tmpString = "left arm"; }
        case 5: { tmpString = "right arm"; }
        case 6: { tmpString = "left leg"; }
        case 7: { tmpString = "right leg"; }
        case 10: { tmpString = "nuts"; }
    }
    return tmpString;
}

Handle:BuildInflictorTrie()
{
    new Handle: trie = CreateTrie();
    SetTrieValue(trie, "weapon_tank_claw",      TANKWEAPON);
    SetTrieValue(trie, "tank_rock",             TANKWEAPON);
    //SetTrieValue(trie, "weapon_boomer_claw",    SIWEAPON);
    SetTrieValue(trie, "weapon_charger_claw",   CHARGERWEAPON);
    //SetTrieValue(trie, "weapon_hunter_claw",    SIWEAPON);
    //SetTrieValue(trie, "weapon_jockey_claw",    SIWEAPON);
    //SetTrieValue(trie, "weapon_smoker_claw",    SIWEAPON);
    //SetTrieValue(trie, "weapon_spitter_claw",   SIWEAPON);
    return trie;    
}

bool:IsUnderAttack(survivor)
{
	for (new i = 0; i < sizeof(survivorProps); i++)
	{
		if (IsClientAndInGame(GetEntDataEnt2(survivor, survivorProps[i])))
			return true;
	}
	return false;
}

bool:IsIncapped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}