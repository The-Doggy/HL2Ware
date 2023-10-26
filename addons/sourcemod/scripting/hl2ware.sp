#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
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

// Include sub-plugins
#include "commands.sp"
#include "natives.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("hl2ware");

    CreateNative("HL2Ware_RegisterMinigame", Native_RegisterMinigame);
    CreateNative("HL2Ware_IsPlayer", Native_IsPlayer);
    CreateNative("HL2Ware_PassPlayer", Native_PassPlayer);
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("hl2ware_enabled", "1", "Toggles whether the plugin is enabled or disabled");
    CreateConVar("hl2ware_startplayers", "2", "The amount of players needed for minigames to start running");
    CreateConVar("hl2ware_afkseconds", "180", "How many seconds a player can be AFK before they are moved to spectate");
    AutoExecConfig(true, "hl2ware");

    RegAdminCmd("sm_forceend", Command_ForceEndMinigame, ADMFLAG_CUSTOM2, "Forces the current minigame to end");
    RegAdminCmd("sm_forcestart", Command_ForceStartMinigame, ADMFLAG_CUSTOM2, "Forces the next minigame to be a specified one");
    RegAdminCmd("sm_disableminigame", Command_DisableMinigame, ADMFLAG_CUSTOM4, "Disables a specified minigame until it is enabled again or the minigame list is reloaded");
    RegAdminCmd("sm_enableminigame", Command_EnableMinigame, ADMFLAG_CUSTOM4, "Enables a minigame that was previously disabled");
    RegAdminCmd("sm_reloadminigames", Command_ReloadMinigames, ADMFLAG_CUSTOM4, "Reloads the list of current minigames");
    RegAdminCmd("sm_listminigames", Command_ListMinigames, ADMFLAG_CUSTOM2, "Shows a list of the current registered minigames");

    RegConsoleCmd("sm_leavegame", Command_LeaveGame, "Removes you from the game and moves you to spectator");
    RegConsoleCmd("sm_joingame", Command_JoinGame, "Adds you to the game and removes you from spectator");

    g_CoreLoadedFwd = new GlobalForward("HL2Ware_OnCoreLoaded", ET_Ignore);
    g_MinigameStartFwd = new GlobalForward("HL2Ware_OnMinigameStart", ET_Hook, Param_Cell);
    g_MinigameEndFwd = new GlobalForward("HL2Ware_OnMinigameEnd", ET_Ignore, Param_Cell);

    g_Minigames = new ArrayList(sizeof(HL2Ware_Minigames));
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
}