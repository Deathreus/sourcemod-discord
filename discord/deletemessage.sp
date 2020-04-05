public int Native_DiscordBot_DeleteMessageID(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	
	char channelid[64];
	GetNativeString(2, channelid, sizeof(channelid));
	
	char msgid[64];
	GetNativeString(3, msgid, sizeof(msgid));
	
	Function fCallback = GetNativeCell(4);
	any data = GetNativeCell(5);
	
	DataPack dp = new DataPack();
	dp.WriteCell(bot);
	dp.WriteString(channelid);
	dp.WriteString(msgid);
	dp.WriteCell(plugin);
	dp.WriteFunction(fCallback);
	dp.WriteCell(data);
	
	ThisDeleteMessage(bot, channelid, msgid, dp);
}

public int Native_DiscordBot_DeleteMessage(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	
	char channelid[64];
	DiscordChannel channel = GetNativeCell(2);
	channel.GetID(channelid, sizeof(channelid));
	
	char msgid[64];
	DiscordMessage msg = GetNativeCell(3);
	msg.GetID(msgid, sizeof(msgid));
	
	Function fCallback = GetNativeCell(4);
	any data = GetNativeCell(5);
	
	DataPack dp = new DataPack();
	dp.WriteCell(bot);
	dp.WriteString(channelid);
	dp.WriteString(msgid);
	dp.WriteCell(plugin);
	dp.WriteFunction(fCallback);
	dp.WriteCell(data);
	
	ThisDeleteMessage(bot, channelid, msgid, dp);
}

static void ThisDeleteMessage(DiscordBot bot, char[] channelid, char[] msgid, DataPack dp) {
	char url[64];
	FormatEx(url, sizeof(url), "channels/%s/messages/%s", channelid, msgid);
	
	Handle request = PrepareRequest(bot, url, k_EHTTPMethodDELETE, null, MessageDeletedResp);
	if(request == null) {
		CreateTimer(2.0, ThisDeleteMessageDelayed, dp);
		return;
	}
	
	SteamWorks_SetHTTPRequestContextValue(request, dp, UrlToDP(url));
	
	DiscordSendRequest(request, url);
}

public Action ThisDeleteMessageDelayed(Handle timer, DataPack dp) {
	dp.Reset();
	
	DiscordBot bot = dp.ReadCell();
	
	char channelid[32];
	dp.ReadString(channelid, sizeof(channelid));
	
	char msgid[32];
	dp.ReadString(msgid, sizeof(msgid));
	
	ThisDeleteMessage(bot, channelid, msgid, dp);
}

public int MessageDeletedResp(Handle request, bool failure, int offset, int statuscode, DataPack dp) {
	if(failure || statuscode != _:k_EHTTPStatusCode204NoContent) {
		if(statuscode == _:k_EHTTPStatusCode429TooManyRequests || statuscode == _:k_EHTTPStatusCode500InternalServerError) {
			dp.Reset();

			DiscordBot bot = dp.ReadCell();
			
			char channelid[32];
			dp.ReadString(channelid, sizeof(channelid));
			
			char msgid[32];
			dp.ReadString(msgid, sizeof(msgid));
			
			ThisDeleteMessage(bot, channelid, msgid, dp);
			
			delete request;
			return;
		}

		LogError("[DISCORD] Couldn't delete message - Fail %i %i", failure, statuscode);

		delete request;
		delete dp;
		return;
	}
	
	dp.Reset();

	DiscordBot bot = dp.ReadCell();
	
	char channelid[32];
	dp.ReadString(channelid, sizeof(channelid));
	
	char msgid[32];
	dp.ReadString(msgid, sizeof(msgid));
	
	Handle plugin = dp.ReadCell();
	Function func = dp.ReadFunction();
	any pluginData = dp.ReadCell();
	
	Handle fForward = INVALID_HANDLE;
	if(func != INVALID_FUNCTION) {
		fForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell);
		AddToForward(fForward, plugin, func);
		
		Call_StartForward(fForward);
		Call_PushCell(bot);
		Call_PushCell(pluginData);
		Call_Finish();
		
		delete fForward;
	}
	
	delete dp;
	delete request;
}