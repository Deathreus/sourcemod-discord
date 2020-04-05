#include <discord/message>

methodmap DiscordWebHook < JSON_Object {
	public DiscordWebHook(char[] url) {
		JSON_Object mp = new JSON_Object();
		mp.SetString("__url", url);

		JSON_Object data = new JSON_Object();
		mp.SetObject("__data", data);

		return view_as<DiscordWebHook>(mp);
	}

	public void GetUrl(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "__url", buffer, maxlength);
	}

	/**
	 * Gets/Sets if the hook should be sent as Slack.
	 * Note: color is different for slack than discord msg.
	 *
	 * @return 			True if Slack, otherwise false.
	 */
	property bool SlackMode {
		public get() {
			return JsonObjectGetBool(this, "__slack", false);
		}

		public set(bool value) {
			this.SetBool("__slack", value);
		}
	}

	property JSON_Object Data {
		public get() {
			return this.GetObject("__data");
		}

		public set(JSON_Object value) {
			if(this.HasKey("__data"))
			{
				this.GetObject("__data").Cleanup();
				delete this.GetObject("__data");
			}
			this.SetObject("__data", value);
		}
	}

	public void Embed(DiscordEmbed Object) {
		JSON_Array hArray = this.Data.GetObject("embeds");

		if(hArray == null) {
			hArray = new JSON_Array();
			this.Data.SetObject("embeds", hArray);
		}

		hArray.PushObject(Object);
	}

	property bool TTS {
		public get() {
			return JsonObjectGetBool(this.Data, "tts");
		}

		public set(bool value) {
			this.Data.SetBool("tts", value);
		}
	}

	public bool GetUsername(char[] buffer, int maxlength) {
		return JsonObjectGetString(this.Data, "username", buffer, maxlength);
	}

	public void SetUsername(const char[] name) {
		this.Data.SetString("username", name);
	}

	public bool GetAvatar(char[] buffer, int maxlength) {
		return JsonObjectGetString(this.Data, "icon_url", buffer, maxlength);
	}

	public void SetAvatar(const char[] icon_url) {
		this.Data.SetString("icon_url", icon_url);
	}

	public bool GetContent(char[] buffer, int maxlength) {
		return JsonObjectGetString(this.Data, "content", buffer, maxlength);
	}

	public void SetContent(const char[] content) {
		this.Data.SetString("content", content);
	}

	/*** NOTE: Object is destroyed upon completion ***/
	public native void Send();
};
