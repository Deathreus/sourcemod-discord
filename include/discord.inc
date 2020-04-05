#if defined _discord_included
	#endinput
#endif
#define _discord_included

#include <smjansson>
#include <discord/stocks>

typedef DiscordGuildsRetrieve = function void (DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data);

typedef DiscordGuildsRetrievedAll = function void (DiscordBot bot, ArrayList id, ArrayList name, ArrayList icon, ArrayList owner, ArrayList permissions, any data);

//Channel are Handles that are closed immediately after forwards called. To keep, clone. Or store id if thats what you want
typedef DiscordGuildChannelsRetrieve = function void (DiscordBot bot, char[] guild, DiscordChannel Channel, any data);

typedef DiscordGuildChannelsRetrieveAll = function void (DiscordBot bot, char[] guild, ArrayList Channels, any data);

typedef DiscordGuildGetRoles = function void (DiscordBot bot, char[] guild, RoleList Roles, any data);

/** 
 * Called when message is received
 * bot/channel/message are all destroyed after callback is sent.
 * You can clone it if need to keep.
 */
typeset OnChannelMessage { 
	function void(DiscordBot bot, DiscordChannel channel, DiscordMessage message);
};

typedef OnGetReactions = function void (DiscordBot bot, ArrayList Users, char[] channelID, const char[] messageID, const char[] emoji, any data);

typedef OnMessageSent = function void(DiscordBot bot, char[] channel, DiscordMessage message, any data);

typedef OnMessageDeleted = function void(DiscordBot bot, any data);

//hMemberList is JSON array containing guild members
typedef OnGetMembers = function void(DiscordBot bot, char[] guild, Handle hMemberList);

methodmap Role < Handle {
	public void GetID(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "id", buffer, maxlength);
	}
	
	public void GetName(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "name", buffer, maxlength);
	}
	
	public int GetColor() {
		return JsonObjectGetInt(this, "color");
	}
	
	public int GetPosition() {
		return JsonObjectGetInt(this, "position");
	}
	
	public int GetPermissions() {
		return JsonObjectGetInt(this, "permissions");
	}
	
	public bool Hoist() {
		return JsonObjectGetBool(this, "hoist");
	}
	
	public bool Managed() {
		return JsonObjectGetBool(this, "managed");
	}
	
	public bool Mentionable() {
		return JsonObjectGetBool(this, "mentionable");
	}
};

methodmap RoleList < Handle {
	property int Size {
		public get() {
			return json_array_size(this);
		}
	}
	public Role GetRole(int i) {
		return view_as<Role>(
			json_array_get(this, i)
		);
	}
	public Role Get(int i) {
		return this.GetRole(i);
	}
	
};
