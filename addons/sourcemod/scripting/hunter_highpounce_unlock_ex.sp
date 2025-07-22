#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <l4d2util>
#include <colors>

#define DEBUG 0

float		  g_fPouncingPos[MAXPLAYERS + 1][3];
int			  g_iNextPounceDmg[MAXPLAYERS + 1];
ConVar		  g_cvarMinPounceDistance, g_cvarMaxPounceDistance, g_cvarMaxPounceDamage, g_hcvarPouceDamagemult, g_cvarMaxPounceDamageF, g_cvarOverrideMsg;
bool		  g_bLate;
GlobalForward g_hOnHunterHighPounce;

ArrayList	  g_hOverrideClient;

float		  g_fMin, g_fMax, g_fLinear, g_fMaxDmg, g_fMaxDmgF, g_fMult;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate				  = late;
	g_hOnHunterHighPounce = new GlobalForward("OnHunterHighPounce_Ex", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float);
	return APLRes_Success;
}

public Plugin myinfo =
{
	name		= "Hunter Pounce Dagame Unlock",
	author		= "Nepkey",
	description = "从插件层面上间接修改ht的扑袭伤害。Indirectly modify a hunter's high pounce damage at the plugin level",
	version		= "1.0",
	url			= ""
};

public void OnPluginStart()
{
	g_hOverrideClient = new ArrayList();

	HookUserMessage(GetUserMessageId("PZDmgMsg"), OnHunterPounce, true);
	HookEvent("ability_use", OnHunterUseAbility, EventHookMode_Pre);
	HookEvent("round_start", Initialization);
	HookEvent("round_end", Initialization);
	HookEvent("lunge_pounce", OnPlayerGetPounced, EventHookMode_Post);

	g_cvarMinPounceDistance = CreateConVar("z_pounce_damage_range_fix_min", "300.0", "", 0, true, 0.0, false);
	g_cvarMaxPounceDistance = CreateConVar("z_pounce_damage_range_fix_max", "1000", "", 0, true, 0.0, false);
	g_cvarMaxPounceDamage	= CreateConVar("z_max_pounce_bonus_damage", "24", "", 0, true, 0.0, false);
	g_cvarMaxPounceDamageF	= CreateConVar("z_max_pounce_damage", "25", "无论扑袭的最终伤害有多大，其永远不会超过这个值", 0, true, 0.0);
	g_hcvarPouceDamagemult	= CreateConVar("z_pounce_damage_mult", "1.0", "伤害的额外倍率，乘算", 0, true, 0.0, false);
	g_cvarOverrideMsg		= CreateConVar("z_pounce_msg_override", "2", "0 = 不干预系统伤害提示，1 = 屏蔽系统伤害提示，2 = 复写系统伤害提示\n;如果其他插件或此插件频繁报message错误，请设置为0或1", 0, true, 0.0, true, 2.0);
	g_cvarMinPounceDistance.AddChangeHook(OnCvarChanged);
	g_cvarMaxPounceDistance.AddChangeHook(OnCvarChanged);
	g_cvarMaxPounceDamage.AddChangeHook(OnCvarChanged);
	g_cvarMaxPounceDamageF.AddChangeHook(OnCvarChanged);
	g_hcvarPouceDamagemult.AddChangeHook(OnCvarChanged);
	OnCvarChanged(null, "", "");

	if (g_bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnClientTakeDamage);
			}
		}
	}
}

void OnCvarChanged(ConVar c, const char[] o, const char[] n)
{
	g_fMin	   = g_cvarMinPounceDistance.FloatValue;
	g_fMax	   = g_cvarMaxPounceDistance.FloatValue;
	g_fMaxDmg  = g_cvarMaxPounceDamage.FloatValue;
	g_fMaxDmgF = g_cvarMaxPounceDamageF.FloatValue;
	g_fMult	   = g_hcvarPouceDamagemult.FloatValue;
	// 预计算，原始伤害公式为 damage =  (fMaxDmg * (distance - g_fMin) / (g_fMax - g_fMin)) + 1.0;
	// g_fLiner即表示扑袭距离达到300单位后，每增加1单位就增加多少伤害
	g_fLinear  = g_fMult * g_fMaxDmg / (g_fMax - g_fMin);
}

Action OnHunterPounce(UserMsg msg_id, any msg, const int[] players, int playersNum, bool reliable, bool init)
{
	BfRead bfMsg	= msg;

	int	   type		= bfMsg.ReadByte();
	int	   attacker = bfMsg.ReadShort();
#if DEBUG
	int victimid = bfMsg.ReadShort();
#else
	bfMsg.ReadShort();
#endif
#if DEBUG
	int pass = bfMsg.ReadShort();
#else
	bfMsg.ReadShort();
#endif
#if DEBUG
	int damage = bfMsg.ReadShort();
#endif

	// 只有type为12即ht高扑提示
	if (type != 12 || !g_cvarOverrideMsg.IntValue)
	{
		return Plugin_Continue;
	}
#if DEBUG
	PrintToConsoleAll("Msg > param1:[%d] param2[%d] param3[%d] param4[%d] param5[%d]", type, attacker, victimid, pass, damage);
#endif
	int index = g_hOverrideClient.FindValue(attacker);
	if (g_cvarOverrideMsg.IntValue == 2 && index > -1)
	{
		// PrintToConsoleAll("Find ClientUID %d In Override List, Release this Msg.", attacker);
		g_hOverrideClient.Erase(index);
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

void NextFrame_HandlePZDmgMsg(DataPack dp)
{
	dp.Reset();
	int	   attackerID = dp.ReadCell();
	int	   victimID	  = dp.ReadCell();
	int	   attacker	  = GetClientOfUserId(attackerID);
	Handle hBuffer	  = StartMessageAll("PZDmgMsg");

	BfWriteByte(hBuffer, 12);
	BfWriteShort(hBuffer, attackerID);
	BfWriteShort(hBuffer, victimID);
	BfWriteShort(hBuffer, 0);
	BfWriteShort(hBuffer, g_iNextPounceDmg[attacker]);
	EndMessage();
#if DEBUG
	PrintToConsoleAll("Changed:> type:[%d] attackerID[%d] victimID[%d] param4[0] newdamage[%d]", 12, attackerID, victimID, g_iNextPounceDmg[attacker]);
#endif
	delete dp;
}

public void OnClientPutInServer(int client)
{
	g_iNextPounceDmg[client] = 0;
	SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}

public void OnClientDisconnect(int client)
{
	g_iNextPounceDmg[client] = 0;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}

void Initialization(Event e, const char[] n, bool b)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iNextPounceDmg[i] = 0;
	}
	delete g_hOverrideClient;
	g_hOverrideClient = new ArrayList();
}

void OnPlayerGetPounced(Event e, const char[] n, bool b)
{
	int victimid   = e.GetInt("victim");
	int attackerid = e.GetInt("userid");
	int victim	   = GetClientOfUserId(victimid);
	int attacker   = GetClientOfUserId(attackerid);
	if (victim && attacker && IsSurvivor(victim) && IsHunter(attacker) && g_cvarOverrideMsg.IntValue == 2)
	{
		g_hOverrideClient.Push(GetClientUserId(attacker));

		DataPack dp = new DataPack();
		dp.WriteCell(attackerid);
		dp.WriteCell(victimid);
		RequestFrame(NextFrame_HandlePZDmgMsg, dp);
	}
}

Action OnClientTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsSurvivor(victim) && IsHunter(attacker) && (damagetype & DMG_CRUSH) && damage >= 1)
	{
		float victimpos[3];
		GetClientAbsOrigin(victim, victimpos);
		float fDistance			   = GetVectorDistance(g_fPouncingPos[attacker], victimpos);
		fDistance				   = fDistance < g_fMin ? g_fMin : fDistance;
		damage					   = (fDistance - g_fMin) * g_fLinear + 1.0;
		damage					   = damage > g_fMaxDmgF ? g_fMaxDmgF : damage;
		g_iNextPounceDmg[attacker] = RoundToFloor(damage);
		Call_StartForward(g_hOnHunterHighPounce);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(RoundToFloor(damage));
		Call_PushFloat(fDistance);
		Call_Finish();

		float distance = GetVectorDistance(g_fPouncingPos[attacker], victimpos);
		float fHeight  = g_fPouncingPos[attacker][2] - victimpos[2];
		if (distance >= 300 && fHeight > 0)
		{
			CPrintToChatAll("{olive}★ {red}%N {olive}以 {green}%.0f {olive}的高度{red}(%.0f伤害){olive}扑袭 {green}%N{olive}。", attacker, fHeight, damage, victim);
		}

		return Plugin_Changed;
	}
	return Plugin_Continue;
}

Action OnHunterUseAbility(Event event, const char[] name, bool dontBroadcast)
{
	char ablityName[64];
	event.GetString("ability", ablityName, sizeof(ablityName));
	if (StrEqual(ablityName, "ability_lunge"))
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		GetClientAbsOrigin(client, g_fPouncingPos[client]);
	}
	return Plugin_Continue;
}

stock bool IsHunter(int client)
{
	return IsValidClientIndex(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 3 && GetClientTeam(client) == 3;
}