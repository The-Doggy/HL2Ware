#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
    name = "HL2Ware Core",
    author = "The Doggy",
    description = "Core plugin of HL2Ware",
    version = "0.0.1",
    url = "https://github.com/The-Doggy/HL2Ware"
};

enum struct HL2Ware_Minigames
{
    int ID;
}

enum struct HL2Ware_Players
{
    int Score;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    return APLRes_Success;
}

public void OnPluginStart()
{
    
}