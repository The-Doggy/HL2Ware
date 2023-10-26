#if defined _hl2ware_included_
    #endinput
#endif
#define _hl2ware_included_

/**
 * Registers a minigame module with the core plugin.
 * 
 * @param name          The title of the minigame.
 * @param description   A short description about the minigame.
 * @param duration      How long the minigame should last in seconds.
 * @param enabled       Whether the minigame should be enabled/disabled when registered, defaults to true
 * @return              An ID that the core plugin has assigned to the minigame if successful, else -1
 */
native int HL2Ware_RegisterMinigame(const char[] name, const char[] description, float duration, bool enabled = true);

/**
 * Gets whether a player is actively participating in the game.
 * 
 * @param client    The client index to check for participation
 * @return          True if participating, else false
 */
native bool HL2Ware_IsPlayer(int client);

/**
 * Passes a player for the current minigame.
 * 
 * @param client    The client index to pass
 * @noreturn
 */
native void HL2Ware_PassPlayer(int client);

/**
 * Called when a minigame is about to start.
 * Return Plugin_Continue to allow the minigame to start or return
 * a higher action to block the minigame from starting and force
 * the core plugin to pick a new minigame
 * 
 * @param id    The ID of the minigame to start
 * @return      Plugin_Continue to allow the minigame to start, higher value to block and pick a new minigame
 */
forward Action HL2Ware_OnMinigameStart(int id);

/**
 * Called when a minigame has ended.
 * 
 * @param id    The ID of the minigame that ended
 * @noreturn
 */
forward void HL2Ware_OnMinigameEnd(int id);

