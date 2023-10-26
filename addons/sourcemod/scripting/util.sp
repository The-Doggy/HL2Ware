/* HL2Ware Util Functions */

int GetPlayerCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && g_Players[i].IsPlaying)
        {
            count++;
        }
    }

    return count;
}

void PrintToPlayersAll(const char[] format, any ...)
{
	char sMessage[1024];
	VFormat(sMessage, sizeof(sMessage), format, 2);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !g_Players[i].IsPlaying)
        {
            continue;
        }

		SetGlobalTransTarget(i);
		MC_PrintToChat(i, "%s", sMessage);
	}
}