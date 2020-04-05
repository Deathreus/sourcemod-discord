public int Native_DiscordBot_GetGuilds(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	Function fCallback = GetNativeCell(2);
	Function fCallbackAll = GetNativeCell(3);
	any data = GetNativeCell(4);
	
	DataPack dp = new DataPack();
	dp.WriteCell(bot);
	dp.WriteCell(plugin);
	dp.WriteFunction(fCallback);
	dp.WriteFunction(fCallbackAll);
	dp.WriteCell(data);
	
	ThisSendRequest(bot, dp);
}

static void ThisSendRequest(DiscordBot bot, DataPack dp) {
	char url[64];
	FormatEx(url, sizeof(url), "users/@me/guilds");
	
	Handle request = PrepareRequest(bot, url, k_EHTTPMethodGET, null, GetGuildsData);
	if(request == null) {
		CreateTimer(2.0, GetGuildsDelayed, dp);
		return;
	}
	
	SteamWorks_SetHTTPRequestContextValue(request, dp, UrlToDP(url));
	
	DiscordSendRequest(request, url);
}

public Action GetGuildsDelayed(Handle timer, DataPack dp) {
	dp.Reset();
	
	DiscordBot bot = dp.ReadCell();
	
	ThisSendRequest(bot, dp);
}

public int GetGuildsData(Handle request, bool failure, int offset, int statuscode, DataPack dp) {
	if(failure || statuscode != _:k_EHTTPStatusCode200OK) {
		if(statuscode == _:k_EHTTPStatusCode429TooManyRequests || statuscode == _:k_EHTTPStatusCode500InternalServerError) {
			dp.Reset();

			DiscordBot bot = dp.ReadCell();

			ThisSendRequest(bot, dp);
			
			delete request;
			return;
		}

		LogError("[DISCORD] Couldn't Retrieve Guilds - Fail %i %i", failure, statuscode);

		delete request;
		delete dp;
		return;
	}

	SteamWorks_GetHTTPResponseBodyCallback(request, GetGuildsData_Data, dp);

	delete request;
}

public int GetGuildsData_Data(const char[] data, DataPack dp) {
	dp.Reset();

	JSON_Object hJson = json_decode(data);
	
	//Read from datapack to get info
	DiscordBot bot = dp.ReadCell();
	Handle plugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	Function funcAll = dp.ReadFunction();
	any pluginData = dp.ReadCell();

	delete dp;
	
	//Create forwards
	Handle fForward = INVALID_HANDLE;
	Handle fForwardAll = INVALID_HANDLE;
	if(func != INVALID_FUNCTION) {
		fForward = CreateForward(ET_Ignore, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell, Param_Cell);
		AddToForward(fForward, plugin, func);
	}
	
	if(funcAll != INVALID_FUNCTION) {
		fForwardAll = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		AddToForward(fForwardAll, plugin, funcAll);
	}
	
	ArrayList allId = null;
	ArrayList allName = null;
	ArrayList allIcon = null;
	ArrayList allOwner = null;
	ArrayList allPermissions = null;
	
	if(funcAll != INVALID_FUNCTION) {
		allId = CreateArray(32);
		allName = CreateArray(64);
		allIcon = CreateArray(128);
		allOwner = CreateArray();
		allPermissions = CreateArray();
	}
	
	if(hJson.IsArray)
	{
		JSON_Array hArray = view_as<JSON_Array>(hJson);
		//Loop through json
		for(int i = 0; i < hArray.Length; i++) {
			JSON_Object hObject = hArray.GetObject(i);
			
			static char id[32];
			static char name[64];
			static char icon[128];
			bool owner = false;
			int permissions;
			
			JsonObjectGetString(hObject, "id", id, sizeof(id));
			JsonObjectGetString(hObject, "name", name, sizeof(name));
			JsonObjectGetString(hObject, "icon", icon, sizeof(icon));
			
			owner = JsonObjectGetBool(hObject, "owner");
			permissions = JsonObjectGetBool(hObject, "permissions");
			
			if(fForward != INVALID_HANDLE) {
				Call_StartForward(fForward);
				Call_PushCell(bot);
				Call_PushString(id);
				Call_PushString(name);
				Call_PushString(icon);
				Call_PushCell(owner);
				Call_PushCell(permissions);
				Call_PushCell(pluginData);
				Call_Finish();
			}
			
			if(fForwardAll != INVALID_HANDLE) {
				allId.PushString(id);
				allName.PushString(name);
				allIcon.PushString(icon);
				allOwner.Push(owner);
				allPermissions.Push(permissions);
			}
		}
	}
	
	if(fForwardAll != INVALID_HANDLE) {
		Call_StartForward(fForwardAll);
		Call_PushCell(bot);
		Call_PushCell(allId);
		Call_PushCell(allName);
		Call_PushCell(allIcon);
		Call_PushCell(allOwner);
		Call_PushCell(allPermissions);
		Call_PushCell(pluginData);
		Call_Finish();
		
		delete allId;
		delete allName;
		delete allIcon;
		delete allOwner;
		delete allPermissions;
		
		delete fForwardAll;
	}
	
	if(fForward != INVALID_HANDLE) {
		delete fForward;
	}
	
	hJson.Cleanup();
	delete hJson;
}