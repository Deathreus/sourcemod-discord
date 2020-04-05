public int Native_DiscordBot_GetGuildChannels(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	
	char guild[32];
	GetNativeString(2, guild, sizeof(guild));
	
	Function fCallback = GetNativeCell(3);
	Function fCallbackAll = GetNativeCell(4);
	any data = GetNativeCell(5);
	
	DataPack dp = CreateDataPack();
	dp.WriteCell(bot);
	dp.WriteString(guild);
	dp.WriteCell(plugin);
	dp.WriteFunction(fCallback);
	dp.WriteFunction(fCallbackAll);
	dp.WriteCell(data);
	
	ThisSendRequest(bot, guild, dp);
}

static void ThisSendRequest(DiscordBot bot, char[] guild, DataPack dp) {
	char url[64];
	FormatEx(url, sizeof(url), "guilds/%s/channels", guild);
	
	Handle request = PrepareRequest(bot, url, k_EHTTPMethodGET, null, GetGuildChannelsData);
	if(request == null) {
		CreateTimer(2.0, GetGuildChannelsDelayed, dp);
		return;
	}
	
	SteamWorks_SetHTTPRequestContextValue(request, dp, UrlToDP(url));
	
	DiscordSendRequest(request, url);
}

public Action GetGuildChannelsDelayed(Handle timer, DataPack dp) {
	dp.Reset();
	
	DiscordBot bot = dp.ReadCell();
	
	char guild[32];
	dp.ReadString(guild, sizeof(guild));
	
	ThisSendRequest(bot, guild, dp);
}

public int GetGuildChannelsData(Handle request, bool failure, int offset, int statuscode, DataPack dp) {
	if(failure || statuscode != _:k_EHTTPStatusCode200OK) {
		if(statuscode == _:k_EHTTPStatusCode429TooManyRequests || statuscode == _:k_EHTTPStatusCode500InternalServerError) {
			dp.Reset();

			DiscordBot bot = dp.ReadCell();
			
			char guild[32];
			dp.ReadString(guild, sizeof(guild));
			
			ThisSendRequest(bot, guild, view_as<DataPack>(dp));
			
			delete request;
			return;
		}

		LogError("[DISCORD] Couldn't Retrieve Guild Channels - Fail %i %i", failure, statuscode);

		delete request;
		delete dp;
		return;
	}

	SteamWorks_GetHTTPResponseBodyCallback(request, GetGuildChannelsData_Data, dp);
	delete request;
}

public int GetGuildChannelsData_Data(const char[] data, DataPack dp) {
	JSON_Object hJson = json_decode(data);
	
	//Read from datapack to get info
	dp.Reset();
	DiscordBot bot = dp.ReadCell();
	
	char guild[32];
	dp.ReadString(guild, sizeof(guild));
	
	Handle plugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	Function funcAll = dp.ReadFunction();
	any pluginData = dp.ReadCell();
	delete dp;
	
	//Create forwards
	Handle fForward = INVALID_HANDLE;
	Handle fForwardAll = INVALID_HANDLE;
	if(func != INVALID_FUNCTION) {
		fForward = CreateForward(ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell);
		AddToForward(fForward, plugin, func);
	}
	
	if(funcAll != INVALID_FUNCTION) {
		fForwardAll = CreateForward(ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell);
		AddToForward(fForwardAll, plugin, funcAll);
	}
	
	ArrayList allChannels = null;
	if(funcAll != INVALID_FUNCTION) {
		allChannels = CreateArray();
	}
	
	if(hJson.IsArray)
	{
		JSON_Array hArray = view_as<JSON_Array>(hJson);
		//Loop through json
		for(int i = 0; i < hArray.Length; i++) {
			DiscordChannel Channel = view_as<DiscordChannel>(hArray.GetObject(i));
			
			if(fForward != INVALID_HANDLE) {
				Call_StartForward(fForward);
				Call_PushCell(bot);
				Call_PushString(guild);
				Call_PushCell(Channel);
				Call_PushCell(pluginData);
				Call_Finish();
			}
			
			if(fForwardAll != INVALID_HANDLE) {
				allChannels.Push(Channel);
			}
		}
	}
	
	if(fForwardAll != INVALID_HANDLE) {
		Call_StartForward(fForwardAll);
		Call_PushCell(bot);
		Call_PushString(guild);
		Call_PushCell(allChannels);
		Call_PushCell(pluginData);
		Call_Finish();
		
		for(int i = 0; i < allChannels.Length; i++) {
			Handle hChannel = view_as<Handle>(allChannels.Get(i));
			delete hChannel;
		}
		
		delete allChannels;
		delete fForwardAll;
	}
	
	if(fForward != INVALID_HANDLE) {
		delete fForward;
	}
	
	hJson.Cleanup();
	delete hJson;
}