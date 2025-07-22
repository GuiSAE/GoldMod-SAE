#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

ConVar g_hHeal, g_hOverHeal;

public Plugin myinfo =
{
	name		= "Gain health on witch kill",
	author		= "",
	description = "击杀witch回血",
	version		= "1.0",
	url			= ""
};

public void OnPluginStart()
{
	HookEvent("witch_killed", SurvivorHeal);
	g_hHeal		= CreateConVar("z_witch_heal", "0", "实血回血量", 0, true, 0.0);
	g_hOverHeal = CreateConVar("z_witch_overheal", "0", "虚血回血量", 0, true, 0.0);
}

void SurvivorHeal(Handle event, const char[] name, bool dontBroadcast)
{
	int clientid = GetEventInt(event, "userid", -1);
	int client	 = GetClientOfUserId(clientid);
	if (clientid == -1 || !client)
		return;
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (g_hHeal.IntValue > 0)
		{
			int health = GetClientHealth(client);
			SetEntityHealth(client, health + g_hHeal.IntValue);
		}
		if (g_hOverHeal.IntValue > 0)
		{
			float temphealath = GetTempHealth(client);
			SetTempHealth(client, temphealath + g_hOverHeal.FloatValue);
		}
	}
}

void SetTempHealth(int client, float health)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", health);
}

// Code by SilverShot aka Silvers (Healing Gnome plugin https://forums.alliedmods.net/showthread.php?p=1658852)
float GetTempHealth(int client)
{
	float fTempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fTempHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * FindConVar("pain_pills_decay_rate").FloatValue;
	return fTempHealth < 0.0 ? 0.0 : fTempHealth;
}