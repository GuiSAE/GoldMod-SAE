#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>
#include <sdktools>
#include <l4d2lib>
#include <l4d2util_stocks>

#define PLUGIN_TAG "" // \x04[Hybrid Bonus]

#define SM2_DEBUG    0

/** 
	Bibliography:
	'l4d2_scoremod' by CanadaRox, ProdigySim
	'damage_bonus' by CanadaRox, Stabby
	'l4d2_scoringwip' by ProdigySim
	'srs.scoringsystem' by AtomicStryker
	'prop_bonus' by GuiSAE
	'throwables_bonus' by GuiSAE
**/

new Handle:hCvarBonusPerSurvivorMultiplier;
new Handle:hCvarPermanentHealthProportion;
new Handle:hCvarPropHpFactor;
new Handle:hCvarPropMaxBonus;
new Handle:hCvarThroHpFactor;
new Handle:hCvarThroMaxBonus;
// new Handle:hCvarTiebreakerBonus;

new Handle:hCvarValveSurvivalBonus;
new Handle:hCvarValveTieBreaker;

new Float:fMapBonus;
new Float:fMapHealthBonus;
new Float:fMapDamageBonus;
new Float:fMapTempHealthBonus;
new Float:fPermHpWorth;
new Float:fTempHpWorth;
new Float:fSurvivorBonus[2];

new iMapDistance;
new iTeamSize;
new iPropWorth;
new iThroWorth;
new iLostTempHealth[2];
new iTempHealth[MAXPLAYERS + 1];
new iSiDamage[2];

new String:sSurvivorState[2][32];

new bool:bLateLoad;
new bool:bRoundOver;
new bool:bTiebreakerEligibility[2];


public Plugin:myinfo =
{
	name = "L4D2 Scoremod+",
	author = "Visor",
	description = "The next generation scoring mod",
	version = "2.2.4",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

// -------------------------------------------
// 添加投掷物分以及肾上腺素分
// 投掷物统一算TB/肾上腺素跟药丸统一算PB
// 分数修改用法与Sir团队的hybrid相同
// 添加部分中文注解
// by:GuiSAE
// -------------------------------------------

// 创造原生函数供其他插件调用
public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax)
{
    CreateNative("GMPlus_GetHealthBonus", Native_GetHealthBonus);
    CreateNative("GMPlus_GetDamageBonus", Native_GetDamageBonus);
    CreateNative("GMPlus_GetPropBonus", Native_GetPropBonus);
    CreateNative("GMPlus_GetThroBonus", Native_GetThroBonus);
    CreateNative("GMPlus_GetMaxHealthBonus", Native_GetMaxHealthBonus);
    CreateNative("GMPlus_GetMaxDamageBonus", Native_GetMaxDamageBonus);
    CreateNative("GMPlus_GetMaxPropBonus", Native_GetMaxPropBonus);
    CreateNative("GMPlus_GetMaxThroBonus", Native_GetMaxThroBonus);
    RegPluginLibrary("l4d2_hybrid_scoremod_sae");
    bLateLoad = late;
    return APLRes_Success;
}

// 创造ConVar修改相关数据，并供cfgogl使用
public OnPluginStart()
{
	hCvarBonusPerSurvivorMultiplier = CreateConVar("sm2_bonus_per_survivor_multiplier", "0.5", "Total Survivor Bonus = this * Number of Survivors * Map Distance");
	hCvarPermanentHealthProportion = CreateConVar("sm2_permament_health_proportion", "0.75", "Permanent Health Bonus = this * Map Bonus; rest goes for Temporary Health Bonus");
	hCvarPropMaxBonus = CreateConVar("sm2_prop_max_bonus", "30", "Unused prop cannot be worth more than this");
	hCvarPropHpFactor = CreateConVar("sm2_prop_hp_factor", "6.0", "Unused prop HP worth = map bonus HP value / this");
	hCvarThroMaxBonus = CreateConVar("sm2_thro_max_bonus", "30", "Unused thro cannot be worth more than this");
	hCvarThroHpFactor = CreateConVar("sm2_thro_hp_factor", "6.0", "Unused thro HP worth = map bonus HP value / this");
	// hCvarTiebreakerBonus = CreateConVar("sm2_tiebreaker_bonus", "25", "Tiebreaker for those cases when both teams make saferoom with no bonus");
	
	hCvarValveSurvivalBonus = FindConVar("vs_survival_bonus");
	hCvarValveTieBreaker = FindConVar("vs_tiebreak_bonus");

	HookConVarChange(hCvarBonusPerSurvivorMultiplier, CvarChanged);
	HookConVarChange(hCvarPermanentHealthProportion, CvarChanged);

	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("player_ledge_grab", OnPlayerLedgeGrab);
	HookEvent("player_incapacitated", OnPlayerIncapped);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("revive_success", OnPlayerRevived, EventHookMode_Post);

	RegConsoleCmd("sm_health", CmdBonus);
	RegConsoleCmd("sm_damage", CmdBonus);
	RegConsoleCmd("sm_bonus", CmdBonus);
	RegConsoleCmd("sm_mapinfo", CmdMapInfo);

	if (bLateLoad) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (!IsClientInGame(i))
				continue;

			OnClientPutInServer(i);
		}
	}
}

public OnPluginEnd()
{
	ResetConVar(hCvarValveSurvivalBonus);
	ResetConVar(hCvarValveTieBreaker);
}

// 相应分数的计算方法
public OnConfigsExecuted()
{
	iTeamSize = GetConVarInt(FindConVar("survivor_limit"));
	SetConVarInt(hCvarValveTieBreaker, 0);

	iMapDistance = L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore());
	L4D_SetVersusMaxCompletionScore(iMapDistance);

	new Float:fPermHealthProportion = GetConVarFloat(hCvarPermanentHealthProportion);
	new Float:fTempHealthProportion = 1.0 - fPermHealthProportion;
	fMapBonus = iMapDistance * (GetConVarFloat(hCvarBonusPerSurvivorMultiplier) * iTeamSize);
	fMapHealthBonus = fMapBonus * fPermHealthProportion;
	fMapDamageBonus = fMapBonus * fTempHealthProportion;
	fMapTempHealthBonus = iTeamSize * 100/* HP */ / fPermHealthProportion * fTempHealthProportion;
	fPermHpWorth = fMapBonus / iTeamSize / 100 * fPermHealthProportion;
	fTempHpWorth = fMapBonus * fTempHealthProportion / fMapTempHealthBonus; // this should be almost equal to the perm hp worth, but for accuracy we'll keep it separate
	iPropWorth = L4D2Util_Clamp(RoundToNearest(50 * (fPermHpWorth / GetConVarFloat(hCvarPropHpFactor)) / 5) * 5, 5, GetConVarInt(hCvarPropMaxBonus)); // make it pretty
	iThroWorth = L4D2Util_Clamp(RoundToNearest(50 * (fPermHpWorth / GetConVarFloat(hCvarThroHpFactor)) / 5) * 5, 5, GetConVarInt(hCvarThroMaxBonus)); // make it pretty
#if SM2_DEBUG
	PrintToChatAll("\x01Map health bonus: \x05%.1f\x01, temp health bonus: \x05%.1f\x01, perm hp worth: \x03%.1f\x01, temp hp worth: \x03%.1f\x01, prop worth: \x03%i\x01, thor worth: \x03%i\x01", fMapBonus, fMapTempHealthBonus, fPermHpWorth, fTempHpWorth, iPropWorth, iThroWorth);
#endif
}

public OnMapStart()
{
	OnConfigsExecuted();

	iLostTempHealth[0] = 0;
	iLostTempHealth[1] = 0;
	iSiDamage[0] = 0;
	iSiDamage[1] = 0;
	bTiebreakerEligibility[0] = false;
	bTiebreakerEligibility[1] = false;
}

public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	OnConfigsExecuted();
}


public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public void RoundStartEvent(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		iTempHealth[i] = 0;
	}
	bRoundOver = false;
}

/*public void OnRoundIsLive()
{
	new Float:fMaxPropBonus = float(iPropWorth * iTeamSize);
	new Float:fMaxThroBonus = float(iThroWorth * 1);
	new Float:fTotalBonus = fMapBonus + fMaxPropBonus + fMaxThroBonus;
	PrintToChatAll("\x04地图信息\x01: \x01路程分:\x05%d\x01 | \x01奖励分:\x05%d\x01 | \x01总分:\x05%d\x01", iMapDistance , RoundToFloor(fTotalBonus) , RoundToFloor(fTotalBonus)+iMapDistance);
}*/

// 调用函数列如 Native_GetHealthBonus = GetSurvivorHealthBonus
public Native_GetHealthBonus(Handle:plugin, numParams)
{
    return RoundToFloor(GetSurvivorHealthBonus());
}
 
any Native_GetMaxHealthBonus(Handle:plugin, numParams)
{
    return RoundToFloor(fMapHealthBonus);
}
 
public Native_GetDamageBonus(Handle:plugin, numParams)
{
    return RoundToFloor(GetSurvivorDamageBonus());
}
 
any Native_GetMaxDamageBonus(Handle:plugin, numParams)
{
    return RoundToFloor(fMapDamageBonus);
}
 
public Native_GetPropBonus(Handle:plugin, numParams)
{
    return RoundToFloor(GetSurvivorPropBonus());
}

public Native_GetThroBonus(Handle:plugin, numParams)
{
    return RoundToFloor(GetSurvivorThroBonus());
}
 
any Native_GetMaxPropBonus(Handle:plugin, numParams)
{
    return iPropWorth * iTeamSize;
}

any Native_GetMaxThroBonus(Handle:plugin, numParams)
{
    return iThroWorth * 1;
}

// 我也不知道显示在哪的信息
/*public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	new Float:fMaxPropBonus = float(iPropWorth * iTeamSize);
	new Float:fMaxThroBonus = float(iThroWorth * 1);
	new Float:fTotalBonus = fMapBonus + fMaxPropsBonus;
	PrintToChatAll("地图信息:");
	PrintToChatAll("\x01路程分: \x05%d\x01", iMapDistance);
	PrintToChatAll("\x01HB: \x05%d\x01 <\x03%.1f%%\x01>", RoundToFloor(fMapHealthBonus), CalculateBonusPercent(fMapHealthBonus, fTotalBonus));
	PrintToChatAll("\x01DB: \x05%d\x01 <\x03%.1f%%\x01>", RoundToFloor(fMapDamageBonus), CalculateBonusPercent(fMapDamageBonus, fTotalBonus));
	PrintToChatAll("\x01PB: \x05%d\x01(max \x05%d\x01) <\x03%.1f%%\x01>", RoundToFloor(fMaxPropBonus), CalculateBonusPercent(fMaxPropBonus, fTotalBonus));
	PrintToChatAll("\x01TB: \x05%d\x01(max \x05%d\x01) <\x03%.1f%%\x01>", RoundToFloor(fMaxThroBonus), CalculateBonusPercent(fMaxThroBonus, fTotalBonus));
	PrintToChatAll("总分:\x05%d\x01", RoundToFloor(fTotalBonus)+iMapDistance);
}*/

// 聊天框信息显示
public Action:CmdBonus(client, args)
{
	if (bRoundOver || !client)
		return Plugin_Handled;

	decl String:sCmdType[64];
	GetCmdArg(1, sCmdType, sizeof(sCmdType));

	new Float:fHealthBonus = GetSurvivorHealthBonus();
	new Float:fDamageBonus = GetSurvivorDamageBonus();
	new Float:fPropBonus = GetSurvivorPropBonus();
	new Float:fThroBonus = GetSurvivorThroBonus();
	new Float:fMaxPropBonus = float(iPropWorth * iTeamSize);
	// 因GoldMod只有一个投掷，所以投掷数量只需 * 1，有多少投掷以此类推，最多 = 生还数量 iTeamSize
	new Float:fMaxThroBonus = float(iThroWorth * 1);

	// 以下是聊天框显示的信息
	if (StrEqual(sCmdType, "full"))
	{
		if (InSecondHalfOfRound())
		{
			PrintToChat(client, "%s\x01R\x04#1\x01 [Gold] 奖励分: \x05%d\x01/\x05%d\x01 <\x03%.1f%%\x01> [%s]", PLUGIN_TAG, RoundToFloor(fSurvivorBonus[0]), RoundToFloor(fMapBonus + fMaxPropBonus), CalculateBonusPercent(fSurvivorBonus[0]), sSurvivorState[0]);
		}
		PrintToChat(client, "%s\x01R\x04#%i\x01 [Gold] 奖励分: \x05%d\x01 <\x03%.1f%%\x01> [HB: \x05%d\x01 <\x03%.1f%%\x01> | DB: \x05%d\x01 <\x03%.1f%%\x01> | PB: \x05%d\x01 <\x03%.1f%%\x01> | TB: \x03%.0f%%\x01]", PLUGIN_TAG, InSecondHalfOfRound() + 1, RoundToFloor(fHealthBonus + fDamageBonus + fPropBonus + fThroBonus), CalculateBonusPercent(fHealthBonus + fDamageBonus + fPropBonus + fThroBonus, fMapHealthBonus + fMapDamageBonus + fMaxPropBonus + fMaxThroBonus), RoundToFloor(fHealthBonus), CalculateBonusPercent(fHealthBonus, fMapHealthBonus), RoundToFloor(fDamageBonus), CalculateBonusPercent(fDamageBonus, fMapDamageBonus), RoundToFloor(fPropBonus), CalculateBonusPercent(fPropBonus, fMaxPropBonus), CalculateBonusPercent(fThroBonus, fMaxThroBonus));
		// [Gold] R#1 Bonus: 556 <69.5%> [HB: 439 <73.1%> | DB: 117 <58.5%> | PB: 90 <75.0%> | TB: 20 <100.0%>]
	}
	else if (StrEqual(sCmdType, "lite"))
	{
		PrintToChat(client, "%s\x01R\x04#%i\x01 [Gold] 奖励分: \x05%d\x01 <\x03%.1f%%\x01>", PLUGIN_TAG, InSecondHalfOfRound() + 1, RoundToFloor(fHealthBonus + fDamageBonus + fPropBonus), CalculateBonusPercent(fHealthBonus + fDamageBonus + fPropBonus + fThroBonus, fMapHealthBonus + fMapDamageBonus + fMaxPropBonus + fMaxThroBonus));
		// [Gold] R#1 Bonus: 556 <69.5%>
	}
	else
	{
		if (InSecondHalfOfRound())
		{
			PrintToChat(client, "%s\x01R\x04#1\x01 [Gold] 奖励分: \x05%d\x01 <\x03%.1f%%\x01>", PLUGIN_TAG, RoundToFloor(fSurvivorBonus[0]), CalculateBonusPercent(fSurvivorBonus[0]));
		}
		PrintToChat(client, "%s\x01R\x04#%i\x01 [Gold] 奖励分: \x05%d\x01 <\x03%.1f%%\x01> [HB: \x03%.0f%%\x01 | DB: \x03%.0f%%\x01 | PB: \x03%.0f%%\x01 | TB: \x03%.0f%%\x01]", PLUGIN_TAG, InSecondHalfOfRound() + 1, RoundToFloor(fHealthBonus + fDamageBonus + fPropBonus + fThroBonus), CalculateBonusPercent(fHealthBonus + fDamageBonus + fPropBonus + fThroBonus, fMapHealthBonus + fMapDamageBonus + fMaxPropBonus + fMaxThroBonus), CalculateBonusPercent(fHealthBonus, fMapHealthBonus), CalculateBonusPercent(fDamageBonus, fMapDamageBonus), CalculateBonusPercent(fPropBonus, fMaxPropBonus), CalculateBonusPercent(fThroBonus, fMaxThroBonus));
		// R#1 [Gold] Bonus: 556 <69.5%> [HB: 73% | DB: 58% | PB: 75% | TB: 100%]
	}
	return Plugin_Handled;
}

// 应该是显示在控制台的信息
public Action:CmdMapInfo(client, args)
{
	new Float:fMaxPropBonus = float(iPropWorth * iTeamSize);
	new Float:fMaxThroBonus = float(iThroWorth * 1);
	new Float:fTotalBonus = fMapBonus + fMaxPropBonus + fMaxThroBonus;
	PrintToChat(client, "\x01[\x04Hybrid Bonus\x01 :: \x03%iv%i\x01] Map Info", iTeamSize, iTeamSize);
	PrintToChat(client, "\x01路程分: \x05%d\x01", iMapDistance);
	PrintToChat(client, "\x01总奖励分: \x05%d\x01 <\x03100.0%%\x01>", RoundToFloor(fTotalBonus));
	PrintToChat(client, "\x01HB: \x05%d\x01 <\x03%.1f%%\x01>", RoundToFloor(fMapHealthBonus), CalculateBonusPercent(fMapHealthBonus, fTotalBonus));
	PrintToChat(client, "\x01DB: \x05%d\x01 <\x03%.1f%%\x01>", RoundToFloor(fMapDamageBonus), CalculateBonusPercent(fMapDamageBonus, fTotalBonus));
	PrintToChat(client, "\x01PB: \x05%d\x01(max \x05%d\x01) <\x03%.1f%%\x01>", iPropWorth, RoundToFloor(fMaxPropBonus), CalculateBonusPercent(fMaxPropBonus, fTotalBonus));
	PrintToChat(client, "\x01TB: \x05%d\x01(max \x05%d\x01) <\x03%.1f%%\x01>", iThroWorth, RoundToFloor(fMaxThroBonus), CalculateBonusPercent(fMaxThroBonus, fTotalBonus));
	PrintToChat(client, "\x01单个道具分: \x05%d\x01", iPropWorth);
	PrintToChat(client, "\x01单个投掷物分: \x05%d\x01", iThroWorth);
	// [ScoreMod 2 :: 4v4] Map Info
	// Distance: 400
	// Bonus: 920 <100.0%>
	// Health Bonus: 600 <65.2%>
	// Damage Bonus: 200 <21.7%>
	// Prop Bonus: 30(max 120) <13.1%>
	// Throwables Bonus: 30(max 120) <13.1%>
	// Tiebreaker: 30
	// Throwables: 30
	return Plugin_Handled;
}

// 实血及伤害分计算代码，建议不动
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsSurvivor(victim) || IsPlayerIncap(victim)) return Plugin_Continue;

#if SM2_DEBUG
	if (GetSurvivorTemporaryHealth(victim) > 0) PrintToChatAll("\x04%N\x01 has \x05%d\x01 temp HP now(damage: \x03%.1f\x01)", victim, GetSurvivorTemporaryHealth(victim), damage);
#endif
	iTempHealth[victim] = GetSurvivorTemporaryHealth(victim);
	
	// Small failsafe/workaround for stuff that inflicts more than 100 HP damage (like tank hittables); we don't want to reward that more than it's worth
	if (!IsAnyInfected(attacker)) iSiDamage[InSecondHalfOfRound()] += (damage <= 100.0 ? RoundFloat(damage) : 100);
	
	return Plugin_Continue;
}

public OnPlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	iLostTempHealth[InSecondHalfOfRound()] += L4D2Direct_GetPreIncapHealthBuffer(client);
}

public OnPlayerIncapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client))
	{
		iLostTempHealth[InSecondHalfOfRound()] += RoundToFloor((fMapDamageBonus / 100.0) * 5.0 / fTempHpWorth);
	} 
}

public void OnPlayerRevived(Handle:event, const String:name[], bool:dontBroadcast)
{
	bool bLedge = GetEventBool(event, "ledge_hang");
	if (!bLedge) {
		return;
	}
	
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (!IsSurvivor(client)) {
		return;
	}
	
	RequestFrame(Revival, client);
}

public void Revival(int client)
{
	iLostTempHealth[InSecondHalfOfRound()] -= GetSurvivorTemporaryHealth(client);
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	new damagetype = GetEventInt(event, "type");

	new fFakeDamage = damage;

	// Victim has to be a Survivor.
	// Attacker has to be a Survivor.
	// Player can't be Incapped.
	// Damage has to be from manipulated Shotgun FF. (Plasma)
	// Damage has to be higher than the Survivor's permanent health.
	if (!IsSurvivor(victim) || !IsSurvivor(attacker) || IsPlayerIncap(victim) || damagetype != DMG_PLASMA || fFakeDamage < GetSurvivorPermanentHealth(victim)) return Plugin_Continue;

	iTempHealth[victim] = GetSurvivorTemporaryHealth(victim);
	if (fFakeDamage > iTempHealth[victim]) fFakeDamage = iTempHealth[victim];

	iLostTempHealth[InSecondHalfOfRound()] += fFakeDamage;
	iTempHealth[victim] = GetSurvivorTemporaryHealth(victim) - fFakeDamage;

	return Plugin_Continue;
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (!IsSurvivor(victim)) return;
		
#if SM2_DEBUG
	PrintToChatAll("\x03%N\x01\x05 lost %i\x01 temp HP after being attacked(arg damage: \x03%.1f\x01)", victim, iTempHealth[victim] - (IsPlayerAlive(victim) ? GetSurvivorTemporaryHealth(victim) : 0), damage);
#endif
	if (!IsPlayerAlive(victim) || (IsPlayerIncap(victim) && !IsPlayerLedged(victim)))
	{
		iLostTempHealth[InSecondHalfOfRound()] += iTempHealth[victim];
	}
	else if (!IsPlayerLedged(victim))
	{
		iLostTempHealth[InSecondHalfOfRound()] += iTempHealth[victim] ? (iTempHealth[victim] - GetSurvivorTemporaryHealth(victim)) : 0;
	}
	iTempHealth[victim] = IsPlayerIncap(victim) ? 0 : GetSurvivorTemporaryHealth(victim);
}

// Compatibility with Alternate Damage Mechanics plugin
// This plugin(i.e. Scoremod2) will work ideally fine with or without the aforementioned plugin
public L4D2_ADM_OnTemporaryHealthSubtracted(client, oldHealth, newHealth)
{
	new healthLost = oldHealth - newHealth;
	iTempHealth[client] = newHealth;
	iLostTempHealth[InSecondHalfOfRound()] += healthLost;
	iSiDamage[InSecondHalfOfRound()] += healthLost; // this forward doesn't fire for ledged/incapped survivors so we're good
}

public Action:L4D2_OnEndVersusModeRound(bool:countSurvivors)
{
#if SM2_DEBUG
	PrintToChatAll("CDirector::OnEndVersusModeRound() called. InSecondHalfOfRound(): %d, countSurvivors: %d", InSecondHalfOfRound(), countSurvivors);
#endif
	if (bRoundOver)
		return Plugin_Continue;

	new team = InSecondHalfOfRound();
	new iSurvivalMultiplier = GetUprightSurvivors();    // I don't know how reliable countSurvivors is and I'm too lazy to test
	// 注意！！！下一行为最终结算代码，如有修改函数一定要记得把这行也改了
	fSurvivorBonus[team] = GetSurvivorHealthBonus() + GetSurvivorDamageBonus() + GetSurvivorPropBonus() + GetSurvivorThroBonus();
	fSurvivorBonus[team] = float(RoundToFloor(fSurvivorBonus[team] / float(iTeamSize)) * iTeamSize); // make it a perfect divisor of team size value
	if (iSurvivalMultiplier > 0 && RoundToFloor(fSurvivorBonus[team] / iSurvivalMultiplier) >= iTeamSize) // anything lower than team size will result in 0 after division
	{
		SetConVarInt(hCvarValveSurvivalBonus, RoundToFloor(fSurvivorBonus[team] / iSurvivalMultiplier));
		fSurvivorBonus[team] = float(GetConVarInt(hCvarValveSurvivalBonus) * iSurvivalMultiplier);    // workaround for the discrepancy caused by RoundToFloor()
		Format(sSurvivorState[team], 32, "%s%i\x01/\x05%i\x01", (iSurvivalMultiplier == iTeamSize ? "\x05" : "\x04"), iSurvivalMultiplier, iTeamSize);
	#if SM2_DEBUG
		PrintToChatAll("\x01Survival bonus cvar updated. Value: \x05%i\x01 [multiplier: \x05%i\x01]", GetConVarInt(hCvarValveSurvivalBonus), iSurvivalMultiplier);
	#endif
	}
	else
	{
		fSurvivorBonus[team] = 0.0;
		SetConVarInt(hCvarValveSurvivalBonus, 0);
		Format(sSurvivorState[team], 32, "\x04%s\x01", (iSurvivalMultiplier == 0 ? "中途团灭" : "无奖励分"));
		bTiebreakerEligibility[team] = (iSurvivalMultiplier == iTeamSize);
	}

	// Check if it's the end of the second round and a tiebreaker case
	if (team > 0 && bTiebreakerEligibility[0] && bTiebreakerEligibility[1])
	{
		GameRules_SetProp("m_iChapterDamage", iSiDamage[0], _, 0, true);
		GameRules_SetProp("m_iChapterDamage", iSiDamage[1], _, 1, true);
		
		// That would be pretty funny otherwise
		if (iSiDamage[0] != iSiDamage[1])
		{
			SetConVarInt(hCvarValveTieBreaker, iPropWorth);
		}
	}
	
	// Scores print
	CreateTimer(3.0, PrintRoundEndStats, _, TIMER_FLAG_NO_MAPCHANGE);

	bRoundOver = true;
	return Plugin_Continue;
}

// 回合结束显示分数
public Action:PrintRoundEndStats(Handle:timer) 
{
	for (new i = 0; i <= InSecondHalfOfRound(); i++)
	{
		PrintToChatAll("%s\x01R\x04#%i\x01 [Gold] 奖励分: \x05%d\x01/\x05%d\x01 <\x03%.1f%%\x01> [%s]", PLUGIN_TAG, (i + 1), RoundToFloor(fSurvivorBonus[i]), RoundToFloor(fMapBonus + float(iPropWorth * iTeamSize) + float(iThroWorth * 1)), CalculateBonusPercent(fSurvivorBonus[i]), sSurvivorState[i]);
		// [EQSM :: Round 1] Bonus: 487/1200 <42.7%> [3/4]
	}
	
	if (InSecondHalfOfRound() && bTiebreakerEligibility[0] && bTiebreakerEligibility[1])
	{
		PrintToChatAll("%s\x03TIEBREAKER\x01: Team \x04%#1\x01 - \x05%i\x01, Team \x04%#2\x01 - \x05%i\x01", PLUGIN_TAG, iSiDamage[0], iSiDamage[1]);
		if (iSiDamage[0] == iSiDamage[1])
		{
			PrintToChatAll("%s\x05Teams have performed absolutely equal! Impossible to decide a clear round winner", PLUGIN_TAG);
		}
	}

	return Plugin_Stop;
}

// 调用侦测生还者实血分代码
Float:GetSurvivorHealthBonus()
{
	new Float:fHealthBonus;
	new survivorCount;
	new survivalMultiplier;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
			{
				survivalMultiplier++;
				fHealthBonus += GetSurvivorPermanentHealth(i) * fPermHpWorth;
			#if SM2_DEBUG
				PrintToChatAll("\x01Adding \x05%N's\x01 perm hp bonus contribution: \x05%d\x01 perm HP -> \x03%.1f\x01 bonus; new total: \x05%.1f\x01", i, GetSurvivorPermanentHealth(i), GetSurvivorPermanentHealth(i) * fPermHpWorth, fHealthBonus);
			#endif
			}
		}
	}
	return (fHealthBonus / iTeamSize * survivalMultiplier);
}

// 调用侦测生还者伤害分代码
Float:GetSurvivorDamageBonus()
{
	new survivalMultiplier = GetUprightSurvivors();
	new Float:fDamageBonus = (fMapTempHealthBonus - float(iLostTempHealth[InSecondHalfOfRound()])) * fTempHpWorth / iTeamSize * survivalMultiplier;
#if SM2_DEBUG
	PrintToChatAll("\x01Adding temp hp bonus: \x05%.1f\x01 (eligible survivors: \x05%d\x01)", fDamageBonus, survivalMultiplier);
#endif
	return (fDamageBonus > 0.0 && survivalMultiplier > 0) ? fDamageBonus : 0.0;
}

// 调用侦测4号槽位物品代码
Float:GetSurvivorPropBonus()
{			
	new propBonus;
	new survivorCount;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && !IsPlayerIncap(i))
			{
				if(HasItems(i,4)) propBonus += iPropWorth;
			#if SM2_DEBUG
				PrintToChatAll("\x01Adding \x05%N's\x01 prop contribution, total bonus: \x05%d\x01 pts", i, propBonus);
			#endif
			}
		}
	}
	return Float:float(propBonus);
}

// 调用侦测2号槽位物品代码
Float:GetSurvivorThroBonus()
{			
	new throBonus;
	new survivorCount;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && !IsPlayerIncap(i))
			{
				if(HasItems(i,2)) throBonus += iThroWorth;
			#if SM2_DEBUG
				PrintToChatAll("\x01Adding \x05%N's\x01 prop contribution, total bonus: \x05%d\x01 pts", i, throBonus);
			#endif
			}
		}
	}
	return Float:float(throBonus);
}

// 用于计算实际奖励分占最大可能奖励分的百分比，因为投掷物数量过少，我选择不加入计算
Float:CalculateBonusPercent(Float:score, Float:maxbonus = -1.0)
{
	return score / (maxbonus == -1.0 ? (fMapBonus + float(iPropWorth * iTeamSize)) : maxbonus) * 100;
}

/************/
/** Stocks **/
/************/

// 此处没研究，最好不要动，我觉得是侦测实血分以及伤害分的代码
InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool:IsAnyInfected(entity)
{
	if (entity > 0 && entity <= MaxClients)
	{
		return IsClientInGame(entity) && GetClientTeam(entity) == 3;
	}
	else if (entity > MaxClients)
	{
		decl String:classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "infected") || StrEqual(classname, "witch")) 
		{
			return true;
		}
	}
	return false;
}

bool:IsPlayerIncap(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsPlayerLedged(client)
{
	return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

GetUprightSurvivors()
{
	new aliveCount;
	new survivorCount;
	for (new i = 1; i <= MaxClients && survivorCount < iTeamSize; i++)
	{
		if (IsSurvivor(i))
		{
			survivorCount++;
			if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
			{
				aliveCount++;
			}
		}
	}
	return aliveCount;
}

GetSurvivorTemporaryHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return (temphp > 0 ? temphp : 0);
}

GetSurvivorPermanentHealth(client)
{
	// Survivors always have minimum 1 permanent hp
	// so that they don't faint in place just like that when all temp hp run out
	// We'll use a workaround for the sake of fair calculations
	// Edit 2: "Incapped HP" are stored in m_iHealth too; we heard you like workarounds, dawg, so we've added a workaround in a workaround
	return GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0 ? 0 : (GetEntProp(client, Prop_Send, "m_iHealth") > 0 ? GetEntProp(client, Prop_Send, "m_iHealth") : 0);
}

// 侦测所有物品栏代码
bool:HasItems(client, slot)
{
	return IsValidEdict(GetPlayerWeaponSlot(client, slot));
}

// ----------------------------------------------------------------------------------------------------------------
//
// Ps: 主武器槽位slot 0 / 副武器槽位slot 1 / 投掷物槽位slot 2 / 医疗物品及升级包槽位slot 3 / 副医疗物槽位slot 4
//
// 侦测代码例子
// 1.单一物品栏多种物品侦测
//bool:HasProp(client)
//{
//	new item = GetPlayerWeaponSlot(client, 4);
//	if(IsValidEdict(item))
//	{
//		decl String:buffer[64];
//		GetEdictClassname(item,buffer,sizeof(buffer));
//		return ( StrEqual(buffer,"weapon_adrenaline")||StrEqual(buffer,"weapon_pain_pills"));
//	}
//	return false;
//}
//
// ----------------------------------------------------------------------------------------------------------------
//
// 2.多种物品栏单一物品侦测
// 
//bool:HasItems(client, slot)
//{
//	new item = GetPlayerWeaponSlot(client, slot);
//	if (IsValidEdict(item))
//	{
//		decl String:buffer[64];
//		GetEdictClassname(item, buffer, sizeof(buffer));
//		return StrEqual(buffer, g_sItemName[slot]);
//	}
//	return false;
//}
//
// 搭配以下代码使用
//
//static String:g_sItemName[][] = {
//"",
//"",
//"",
//"weapon_first_aid_kit",
//"weapon_pain_pills"
//};
//
// 0 / 1 / 2 /槽位物品不结算分数所以留空
//
// ----------------------------------------------------------------------------------------------------------------
//
// 单一物品栏单一物品侦测照抄l4d2_hybrid_scoremod_zone即可
//
// 多种物品栏多种物品侦测直接疯狂bool第一点例子即可
//
// 如果没有那么多物品需求建议按需写，侦测所有物品只要是那个物品栏的都算分，误刷物品带进门有弊端
//
// ----------------------------------------------------------------------------------------------------------------
