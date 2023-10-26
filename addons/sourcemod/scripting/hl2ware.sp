#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <hl2ware>

#pragma newdecls required
#pragma semicolon 1

#define CONSOLETAG  "[HL2Ware]"
//#define DEBUG

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
    char Name[32];
    char Description[256];
    float Duration;
    bool Enabled;
    Handle GameTimer;
}

ArrayList g_Minigames; // Contains a list of the currently registered minigames
HL2Ware_Minigames g_PreviousMinigame;
HL2Ware_Minigames g_CurrentMinigame;
HL2Ware_Minigames g_NextMinigame;

enum struct HL2Ware_Players
{
    int Score;
    bool IsPlaying;
    bool Passed;

    void Reset()
    {
        this.Score = 0;
        this.IsPlaying = false;
        this.Passed = false;
    }
}

HL2Ware_Players g_Players[MAXPLAYERS + 1];

GlobalForward g_CoreLoadedFwd;
GlobalForward g_MinigameStartFwd;
GlobalForward g_MinigameEndFwd;

ConVar g_Enabled;
ConVar g_StartPlayerNum;
ConVar g_AfkSeconds;
ConVar g_WaitSeconds;

bool g_Late;
bool g_Started;

// Include sub-plugins
#include "commands.sp"
#include "natives.sp"
#include "util.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("hl2ware");

    CreateNative("HL2Ware_RegisterMinigame", Native_RegisterMinigame);
    CreateNative("HL2Ware_IsPlayer", Native_IsPlayer);
    CreateNative("HL2Ware_PassPlayer", Native_PassPlayer);

    g_Late = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_Enabled = CreateConVar("hl2ware_enabled", "1", "Toggles whether the plugin is enabled or disabled");
    g_StartPlayerNum = CreateConVar("hl2ware_startplayers", "2", "The amount of players needed for minigames to start running");
    g_AfkSeconds = CreateConVar("hl2ware_afkseconds", "180", "How many seconds a player can be AFK before they are moved to spectate");
    g_WaitSeconds = CreateConVar("hl2ware_secondsbetweenrounds", "5", "How many seconds to wait after a minigame finishes before starting the next one");
    AutoExecConfig(true, "hl2ware");

    RegAdminCmd("sm_forceend", Command_ForceEndMinigame, ADMFLAG_CUSTOM2, "Forces the current minigame to end");
    RegAdminCmd("sm_forcestart", Command_ForceStartMinigame, ADMFLAG_CUSTOM2, "Forces the next minigame to be a specified one");
    RegAdminCmd("sm_disableminigame", Command_DisableMinigame, ADMFLAG_CUSTOM4, "Disables a specified minigame until it is enabled again or the minigame list is reloaded");
    RegAdminCmd("sm_enableminigame", Command_EnableMinigame, ADMFLAG_CUSTOM4, "Enables a minigame that was previously disabled");
    RegAdminCmd("sm_reloadminigames", Command_ReloadMinigames, ADMFLAG_CUSTOM4, "Reloads the list of current minigames"); // TODO: Is this needed?
    RegAdminCmd("sm_listminigames", Command_ListMinigames, ADMFLAG_CUSTOM2, "Shows a list of the current registered minigames");

    RegConsoleCmd("sm_leavegame", Command_LeaveGame, "Removes you from the game and moves you to spectator");
    RegConsoleCmd("sm_joingame", Command_JoinGame, "Adds you to the game and removes you from spectator");

    g_CoreLoadedFwd = new GlobalForward("HL2Ware_OnCoreLoaded", ET_Ignore);
    g_MinigameStartFwd = new GlobalForward("HL2Ware_OnMinigameStart", ET_Hook, Param_Cell);
    g_MinigameEndFwd = new GlobalForward("HL2Ware_OnMinigameEnd", ET_Ignore, Param_Cell);

    g_Minigames = new ArrayList(sizeof(HL2Ware_Minigames));

    // Late load support
    if (g_Late)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                OnClientPutInServer(i);
            }
        }
    }
}

public void OnConfigsExecuted()
{
    // Tell dependant plugins that we've finished loading
    Call_StartForward(g_CoreLoadedFwd);
    Call_Finish();
}

public void OnClientPutInServer(int client)
{
    g_Players[client].Reset();
    AddPlayer(client);
}

void AddPlayer(int client)
{
    g_Players[client].IsPlaying = true;

    // Do we have enough players to start the minigames?
    if (!g_Started && GetPlayerCount() >= g_StartPlayerNum.IntValue)
    {
        StartMinigames();
    }
}

void RemovePlayer(int client)
{
    // Reset player and move to spec
    g_Players[client].IsPlaying = false;
    g_Players[client].Passed = false;
    ChangeClientTeam(client, 1);

    if (g_Started && GetPlayerCount() < g_StartPlayerNum.IntValue)
    {
        // Not enough players to continue playing
        StopMinigames();
    }
}

void StartMinigames()
{
    if (g_Minigames.Length == 0)
    {
        LogMessage("%s No minigames have been registered, unable to start minigames.", CONSOLETAG);
        return;
    }

    CreateTimer(g_WaitSeconds.FloatValue, DelayMinigameStart);
}

Action DelayMinigameStart(Handle timer)
{
    return Plugin_Handled;
}

void StopMinigames()
{
    
}