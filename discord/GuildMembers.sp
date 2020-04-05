/**
 * public native void GetGuildMembers(char[] guild, OnGetMembers fCallback, char[] afterUserID="", int limit=250);
 */
public int Native_DiscordBot_GetGuildMembers(Handle plugin, int numParams) {
	DiscordBot bot = view_as<DiscordBot>(GetNativeCell(1));
	
	char guild[32];
	GetNativeString(2, guild, sizeof(guild));
	
	Function fCallback = GetNativeCell(3);
	
	int limit = GetNativeCell(4);
	
	char afterID[32];
	GetNativeString(5, afterID, sizeof(afterID));
	
	JSON_Object hData = new JSON_Object();
	hData.SetObject("bot", bot);
	hData.SetString("guild", guild);
	hData.SetInt("limit", limit);
	hData.SetString("afterID", afterID);
	
	Handle fwd = CreateForward(ET_Ignore, Param_Cell, Param_String, Param_Cell);
	AddToForward(fwd, plugin, fCallback);
	hData.SetValue("callback", fwd);
	
	GetMembers(hData);
}

public int Native_DiscordBot_GetGuildMembersAll(Handle plugin, int numParams) {
	DiscordBot bot = view_as<DiscordBot>(GetNativeCell(1));
	
	char guild[32];
	GetNativeString(2, guild, sizeof(guild));
	
	Function fCallback = GetNativeCell(3);
	
	int limit = GetNativeCell(4);
	
	char afterID[32];
	GetNativeString(5, afterID, sizeof(afterID));
	
	JSON_Object hData = new JSON_Object();
	hData.SetObject("bot", bot);
	hData.SetString("guild", guild);
	hData.SetInt("limit", limit);
	hData.SetString("afterID", afterID);
	
	Handle fwd = CreateForward(ET_Ignore, Param_Cell, Param_String, Param_Cell);
	AddToForward(fwd, plugin, fCallback);
	hData.SetValue("callback", fwd);
	
	GetMembers(hData);
}

static void GetMembers(JSON_Object hData) {
	DiscordBot bot = view_as<DiscordBot>(hData.GetObject("bot"));
	
	char guild[32];
	JsonObjectGetString(hData, "guild", guild, sizeof(guild));
	
	int limit = JsonObjectGetInt(hData, "limit");
	
	char afterID[32];
	JsonObjectGetString(hData, "afterID", afterID, sizeof(afterID));
	
	char url[256];
	if(StrEqual(afterID, "")) {
		FormatEx(url, sizeof(url), "https://discordapp.com/api/guilds/%s/members?limit=%i", guild, limit);
	}else {
		FormatEx(url, sizeof(url), "https://discordapp.com/api/guilds/%s/members?limit=%i&afterID=%s", guild, limit, afterID);
	}
	
	char route[128];
	FormatEx(route, sizeof(route), "guild/%s/members", guild);
	
	DiscordRequest request = new DiscordRequest(url, k_EHTTPMethodGET);
	if(request == null) {
		CreateTimer(2.0, SendGetMembers, hData);
		return;
	}
	request.SetCallbacks(HTTPCompleted, MembersDataReceive);
	request.SetBot(bot);
	request.SetData(hData, route);
	
	request.Send(route);
}

public Action SendGetMembers(Handle timer, any data) {
	GetMembers(view_as<JSON_Object>(data));
}


public MembersDataReceive(Handle request, bool failure, int offset, int statuscode, JSON_Object dp) {
	if(failure || (statuscode != _:k_EHTTPStatusCode200OK)) {
		if(statuscode == _:k_EHTTPStatusCode400BadRequest) {
			PrintToServer("BAD REQUEST");
		}
		
		if(statuscode == _:k_EHTTPStatusCode429TooManyRequests || statuscode == _:k_EHTTPStatusCode500InternalServerError) {
			GetMembers(dp);
			
			delete request;
			return;
		}

		LogError("[DISCORD] Couldn't Send GetMembers - Fail %i %i", failure, statuscode);

		delete request;
		delete dp;
		return;
	}

	SteamWorks_GetHTTPResponseBodyCallback(request, GetMembersData, dp);

	delete request;
}

public int GetMembersData(const char[] data, JSON_Object hData) {
	JSON_Object hJson = json_decode(data);
	
	DiscordBot bot = view_as<DiscordBot>(hData.GetObject("bot"));
	
	Handle fwd;
	hData.GetValue("callback", fwd);
	
	char guild[32];
	JsonObjectGetString(hData, "guild", guild, sizeof(guild));
	
	if(fwd != null) {
		Call_StartForward(fwd);
		Call_PushCell(bot);
		Call_PushString(guild);
		Call_PushCell(hJson);
		Call_Finish();
	}
	
	if(JsonObjectGetBool(hData, "autoPaginate")) {
		JSON_Array hArray = view_as<JSON_Array>(hJson);

		int size = hArray.Length;
		int limit = JsonObjectGetInt(hData, "limit");
		if(limit == size) {
			JSON_Object hLast = hArray.GetObject(size - 1);
			
			char lastID[32];
			hLast.Encode(lastID, sizeof(lastID));

			hJson.Cleanup();
			delete hJson;
			
			hData.SetString("afterID", lastID);

			GetMembers(hData);
			
			return;
		}
	}
	
	delete hData;
	delete fwd;
	
	hJson.Cleanup();
	delete hJson;
}