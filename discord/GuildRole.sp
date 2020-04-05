public int Native_DiscordBot_GetGuildRoles(Handle plugin, int numParams) {
	DiscordBot bot = view_as<DiscordBot>(GetNativeCell(1));
	
	char guild[32];
	GetNativeString(2, guild, sizeof(guild));
	
	Function fCallback = GetNativeCell(3);
	
	any data = GetNativeCell(4);
	
	JSON_Object hData = new JSON_Object();
	hData.SetObject("bot", bot);
	hData.SetString("guild", guild);
	hData.SetValue("data1", data);
	
	Handle fwd = CreateForward(ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell);
	AddToForward(fwd, plugin, fCallback);
	hData.SetValue("callback", fwd);
	
	GetGuildRoles(hData);
}

static void GetGuildRoles(JSON_Object hData) {
	DiscordBot bot = view_as<DiscordBot>(hData.GetObject("bot"));
	
	char guild[32];
	JsonObjectGetString(hData, "guild", guild, sizeof(guild));
	
	char url[256];
	FormatEx(url, sizeof(url), "https://discordapp.com/api/guilds/%s/roles", guild);
	
	char route[128];
	FormatEx(route, sizeof(route), "guild/%s/roles", guild);
	
	DiscordRequest request = new DiscordRequest(url, k_EHTTPMethodGET);
	if(request == null) {
		CreateTimer(2.0, SendGetGuildRoles, hData);
		return;
	}
	request.SetCallbacks(HTTPCompleted, GetGuildRolesReceive);
	request.SetBot(bot);
	request.SetData(hData, route);
	
	request.Send(route);
}

public Action SendGetGuildRoles(Handle timer, any data) {
	GetGuildRoles(view_as<JSON_Object>(data));
}


public GetGuildRolesReceive(Handle request, bool failure, int offset, int statuscode, JSON_Object dp) {
	if(failure || (statuscode != _:k_EHTTPStatusCode200OK)) {
		if(statuscode == _:k_EHTTPStatusCode400BadRequest) {
			PrintToServer("BAD REQUEST");
		}
		
		if(statuscode == _:k_EHTTPStatusCode429TooManyRequests || statuscode == _:k_EHTTPStatusCode500InternalServerError) {
			GetGuildRoles(dp);
			
			delete request;
			return;
		}

		LogError("[DISCORD] Couldn't Send GetGuildRoles - Fail %i %i", failure, statuscode);

		delete request;
		delete dp;
		return;
	}

	SteamWorks_GetHTTPResponseBodyCallback(request, GetRolesData, dp);
	delete request;
}

public int GetRolesData(const char[] data, JSON_Object hData) {
	JSON_Object hJson = json_decode(data);

	DiscordBot bot = view_as<DiscordBot>(hData.GetObject("bot"));

	Handle fwd; any data1;
	hData.GetValue("callback", fwd);
	hData.GetValue("data1", data1);
	
	char guild[32];
	JsonObjectGetString(hData, "guild", guild, sizeof(guild));
	
	if(fwd != null) {
		Call_StartForward(fwd);
		Call_PushCell(bot);
		Call_PushString(guild);
		Call_PushCell(view_as<RoleList>(hJson));
		Call_PushCell(data1);
		Call_Finish();
	}
	
	delete hJson;
	delete hData;
	delete fwd;
}