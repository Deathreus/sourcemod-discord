public int Native_DiscordBot_SendMessageToChannel(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	char channel[32];
	static char message[2048];
	GetNativeString(2, channel, sizeof(channel));
	GetNativeString(3, message, sizeof(message));
	
	Function fCallback = GetNativeCell(4);
	any data = GetNativeCell(5);
	Handle fForward = null;
	if(fCallback != INVALID_FUNCTION) {
		fForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		AddToForward(fForward, plugin, fCallback);
	}
	
	SendMessage(bot, channel, message, fForward, data);
}

public int Native_DiscordBot_SendMessage(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	
	DiscordChannel Channel = GetNativeCell(2);
	char channelID[32];
	Channel.GetID(channelID, sizeof(channelID));
	
	static char message[2048];
	GetNativeString(3, message, sizeof(message));
	
	Function fCallback = GetNativeCell(4);
	any data = GetNativeCell(5);
	Handle fForward = null;
	if(fCallback != INVALID_FUNCTION) {
		fForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		AddToForward(fForward, plugin, fCallback);
	}
	
	SendMessage(bot, channelID, message, fForward, data);
}

public int Native_DiscordChannel_SendMessage(Handle plugin, int numParams) {
	DiscordChannel channel = view_as<DiscordChannel>(GetNativeCell(1));
	
	char channelID[32];
	channel.GetID(channelID, sizeof(channelID));
	
	DiscordBot bot = GetNativeCell(2);
	
	static char message[2048];
	GetNativeString(3, message, sizeof(message));
	
	Function fCallback = GetNativeCell(4);
	any data = GetNativeCell(5);
	Handle fForward = null;
	if(fCallback != INVALID_FUNCTION) {
		fForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		AddToForward(fForward, plugin, fCallback);
	}
	
	SendMessage(bot, channelID, message, fForward, data);
}

static void SendMessage(DiscordBot bot, char[] channel, char[] message, Handle fForward, any data) {
	JSON_Object hJson = new JSON_Object();
	hJson.SetString("content", message);
	
	char url[64];
	FormatEx(url, sizeof(url), "channels/%s/messages", channel);
	
	DataPack dp = new DataPack();
	dp.WriteCell(bot);
	dp.WriteString(channel);
	dp.WriteString(message);
	dp.WriteCell(fForward);
	dp.WriteCell(data);
	
	Handle request = PrepareRequest(bot, url, k_EHTTPMethodPOST, hJson, GetSendMessageData);
	if(request == null) {
		delete hJson;
		CreateTimer(2.0, SendMessageDelayed, dp);
		return;
	}
	
	SteamWorks_SetHTTPRequestContextValue(request, dp, UrlToDP(url));
	
	DiscordSendRequest(request, url);
}

public Action SendMessageDelayed(Handle timer, DataPack dp) {
	dp.Reset();
	
	DiscordBot bot = dp.ReadCell();
	
	char channel[32];
	dp.ReadString(channel, sizeof(channel));
	
	char message[2048];
	dp.ReadString(message, sizeof(message));
	
	Handle fForward = dp.ReadCell();
	any dataa = dp.ReadCell();
	
	delete dp;
	
	SendMessage(bot, channel, message, fForward, dataa);
}

public int GetSendMessageData(Handle request, bool failure, int offset, int statuscode, DataPack dp) {
	if(failure || statuscode != _:k_EHTTPStatusCode200OK) {
		if(statuscode == _:k_EHTTPStatusCode429TooManyRequests || statuscode == _:k_EHTTPStatusCode500InternalServerError) {
			dp.Reset();

			DiscordBot bot = dp.ReadCell();
			
			char channel[32];
			dp.ReadString(channel, sizeof(channel));
			
			char message[2048];
			dp.ReadString(message, sizeof(message));
			
			Handle fForward = dp.ReadCell();
			any data = dp.ReadCell();
			
			SendMessage(bot, channel, message, fForward, data);
			
			delete dp;
			delete request;
			return;
		}

		LogError("[DISCORD] Couldn't Send Message - Fail %i %i", failure, statuscode);
	}

	delete request;
	delete dp;
}