public int Native_DiscordBot_StartTimer(Handle plugin, int numParams) {
	DiscordBot bot = GetNativeCell(1);
	DiscordChannel channel = GetNativeCell(2);
	Function func = GetNativeCell(3);
	
	JSON_Object hObj = new JSON_Object();
	hObj.SetObject("bot", bot);
	hObj.SetObject("channel", channel.ShallowCopy());
	
	Handle fwd = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	AddToForward(fwd, plugin, func);
	hObj.SetValue("callback", fwd);
	
	GetMessages(hObj);
}

public void GetMessages(JSON_Object hObject) {
	DiscordBot bot = view_as<DiscordBot>(hObject.GetObject("bot"));
	DiscordChannel channel = view_as<DiscordChannel>(hObject.GetObject("channel"));
	
	char channelID[32];
	channel.GetID(channelID, sizeof(channelID));
	
	char lastMessage[64];
	channel.GetLastMessageID(lastMessage, sizeof(lastMessage));
	
	char url[256];
	FormatEx(url, sizeof(url), "channels/%s/messages?limit=%i&after=%s", channelID, 100, lastMessage);
	
	Handle request = PrepareRequest(bot, url, _, null, OnGetMessage);
	if(request == null) {
		CreateTimer(2.0, GetMessagesDelayed, hObject);
		return;
	}
	
	char route[128];
	FormatEx(route, sizeof(route), "channels/%s", channelID);
	
	SteamWorks_SetHTTPRequestContextValue(request, hObject, UrlToDP(route));
	
	DiscordSendRequest(request, route);
}

public Action GetMessagesDelayed(Handle timer, any data) {
	GetMessages(view_as<JSON_Object>(data));
}

public Action CheckMessageTimer(Handle timer, any data) {
	GetMessages(view_as<JSON_Object>(data));
}

public int OnGetMessage(Handle request, bool failure, int offset, int statuscode, JSON_Object data) {
	if(failure || statuscode != _:k_EHTTPStatusCode200OK) {
		if(statuscode == _:k_EHTTPStatusCode429TooManyRequests || statuscode == _:k_EHTTPStatusCode500InternalServerError) {
			GetMessages(data);

			delete request;
			return;
		}

		LogError("[DISCORD] Couldn't Retrieve Messages - Fail %i %i", failure, statuscode);

		delete request;

		Handle fwd = null;
		data.GetValue("callback", fwd);
		if(fwd != null) delete fwd;

		delete data;
		return;
	}

	SteamWorks_GetHTTPResponseBodyCallback(request, OnGetMessage_Data, data);

	delete request;
}

public int OnGetMessage_Data(const char[] data, JSON_Object hObj) {
	DiscordBot bot = view_as<DiscordBot>(hObj.GetObject("bot"));
	DiscordChannel channel = view_as<DiscordChannel>(hObj.GetObject("channel"));
	
	Handle fwd = null;
	hObj.GetValue("callback", fwd);
	
	if(!bot.IsListeningToChannel(channel) || GetForwardFunctionCount(fwd) == 0) {
		hObj.Cleanup();
		delete hObj;

		delete fwd;
		return;
	}
	
	JSON_Object hJson = json_decode(data);
	if(hJson.IsArray) {
		JSON_Array hArray = view_as<JSON_Array>(hJson);
		for(int i = hArray.Length - 1; i >= 0; i--) {
			JSON_Object hObject = hArray.GetObject(i);
			
			//The reason we find Channel for each message instead of global incase
			//Bot stops listening for the channel while we are still sending messages
			char channelID[32];
			JsonObjectGetString(hObject, "channel_id", channelID, sizeof(channelID));
			
			if(!bot.IsListeningToChannelID(channelID)) {
				//Channel is no longer listened to, remove any handles & stop
				hObj.Cleanup();
				delete hObj;

				delete fwd;

				hJson.Cleanup();
				delete hJson;

				return;
			}
			
			char id[32];
			JsonObjectGetString(hObject, "id", id, sizeof(id));
			
			if(i == 0) {
				channel.SetLastMessageID(id);
			}
			
			//Get info and fire forward
			if(fwd != null) {
				Call_StartForward(fwd);
				Call_PushCell(bot);
				Call_PushCell(channel);
				Call_PushCell(hObject);
				Call_Finish();
			}
		}
	}
	
	CreateTimer(bot.MessageCheckInterval, CheckMessageTimer, hObj);
	
	hJson.Cleanup();
	delete hJson;
}