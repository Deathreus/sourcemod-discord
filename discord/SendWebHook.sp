public int Native_DiscordWebHook_Send(Handle plugin, int numParams) {
	DiscordWebHook hook = GetNativeCell(1);
	SendWebHook(hook);
}

public void SendWebHook(DiscordWebHook hook) {
	char url[256];
	hook.GetUrl(url, sizeof(url));
	
	if(hook.SlackMode) {
		if(StrContains(url, "/slack") == -1) {
			Format(url, sizeof(url), "%s/slack", url);
		}
		
		RenameJsonObject(hook.Data, "content", "text");
		RenameJsonObject(hook.Data, "embeds", "attachments");
		
		JSON_Object hAttachments = hook.Data.GetObject("attachments");
		if(hAttachments != null && hAttachments.IsArray) {
			JSON_Array hAttachArray = view_as<JSON_Array>(hAttachments);
			for(int i = 0; i < hAttachArray.Length; i++) {
				JSON_Object hEmbed = hAttachArray.GetObject(i);
				
				JSON_Object hFields = hEmbed.GetObject("fields");
				if(hFields != null && hFields.IsArray) {
					JSON_Array hFieldsArray = view_as<JSON_Array>(hFields);
					for(int j = 0; j < hFieldsArray.Length; j++) {
						JSON_Object hField = hFieldsArray.GetObject(j);
						RenameJsonObject(hField, "name", "title");
						RenameJsonObject(hField, "inline", "short");
					}
				}
			}
		}
	}
	
	//Send
	DiscordRequest request = new DiscordRequest(url, k_EHTTPMethodPOST);
	if(request == null) {
		CreateTimer(2.0, SendWebHookDelayed, hook);
		return;
	}
	request.SetCallbacks(HTTPCompleted, SendWebHookReceiveData);
	request.SetJsonBody(hook.Data);
	request.SetContextValue(hook.Data, UrlToDP(url));
	
	request.Send(url);
}

public Action SendWebHookDelayed(Handle timer, DiscordWebHook data) {
	SendWebHook(data);
}

public SendWebHookReceiveData(Handle request, bool failure, int offset, int statuscode, JSON_Object data) {
	if(failure || (statuscode != _:k_EHTTPStatusCode200OK && statuscode != _:k_EHTTPStatusCode204NoContent)) {
		if(statuscode == _:k_EHTTPStatusCode400BadRequest) {
			PrintToServer("BAD REQUEST");
			SteamWorks_GetHTTPResponseBodyCallback(request, WebHookData, data);
		}
		
		if(statuscode == _:k_EHTTPStatusCode429TooManyRequests || statuscode == _:k_EHTTPStatusCode500InternalServerError) {
			SendWebHook(data);
			
			delete request;
			return;
		}
		
		LogError("[DISCORD] Couldn't Send Webhook - Fail %i %i", offset, statuscode);
	}

	delete request;
	
	data.Cleanup();
	delete data;
}

public int WebHookData(const char[] data, DiscordWebHook hook) {
	PrintToServer("DATA RECE: %s", data);
	static char stringJson[16384];
	stringJson[0] = '\0';
	hook.Encode(stringJson, sizeof(stringJson), true);
	PrintToServer("DATA SENT: %s", stringJson);
}