/* HL2Ware Natives Module */

int Native_RegisterMinigame(Handle plugin, int numParams)
{
    char pluginName[64];
    GetPluginFilename(plugin, pluginName, sizeof(pluginName));

    int len;
    GetNativeStringLength(1, len);
    if (len <= 0)
    {
        LogError("%s Plugin %s attempted to register a minigame with no name!", CONSOLETAG, pluginName);
        return -1;
    }

    // Get name string
    char[] name = new char[len + 1];
    GetNativeString(1, name, len + 1);

    for (int i = 0; i < g_Minigames.Length; i++)
    {
        // Iterate through registered minigames
        HL2Ware_Minigames minigame;
        g_Minigames.GetArray(i, minigame, sizeof(minigame));

        // Check whether we already have a minigame registered with the same name
        if (StrEqual(name, minigame.Name))
        {
            LogError("%s Plugin %s attempted to register an already registered minigame with the name %s!", CONSOLETAG, pluginName, name);
            return -1;
        }
    }

    // Minigame has not been registered yet, register it
    GetNativeStringLength(2, len);
    if (len <= 0)
    {
        LogError("%s Plugin %s attempted to register a minigame with no description!", CONSOLETAG, pluginName);
        return -1;
    }

    // Get description
    char[] description = new char[len + 1];
    GetNativeString(2, description, len + 1);

    // Get duration
    float duration = GetNativeCell(3);
    if (duration <= 0.0)
    {
        LogError("%s Plugin %s attempted to register a minigame with no duration!", CONSOLETAG, pluginName);
        return -1;
    }

    // Create minigame and push to list
    HL2Ware_Minigames minigame;
    Format(minigame.Name, sizeof(minigame.Name), name);
    Format(minigame.Description, sizeof(minigame.Description), description);
    minigame.Duration = duration;
    minigame.ID = g_Minigames.PushArray(minigame); // TODO: Check that this actually works
    
    return minigame.ID;
}

any Native_IsPlayer(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    }

    if (!IsClientInGame(client))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", client);
    }

    return g_Players[client].IsPlaying;
}

any Native_PassPlayer(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (client < 1 || client > MaxClients)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    }

    if (!IsClientInGame(client))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", client);
    }

    if (!g_Players[client].IsPlaying)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not playing", client);
    }

    return g_Players[client].Passed = true;
}