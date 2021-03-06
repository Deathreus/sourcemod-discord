#if defined _discord_included
	#endinput
#endif
#define _discord_included

#include <json>
#include <discord/stocks>

typedef DiscordGuildsRetrieve = function void (DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data);

typedef DiscordGuildsRetrievedAll = function void (DiscordBot bot, ArrayList id, ArrayList name, ArrayList icon, ArrayList owner, ArrayList permissions, any data);

typedef DiscordGuildChannelsRetrieve = function void (DiscordBot bot, char[] guild, DiscordChannel Channel, any data);

typedef DiscordGuildChannelsRetrieveAll = function void (DiscordBot bot, char[] guild, ArrayList Channels, any data);

typedef DiscordGuildGetRoles = function void (DiscordBot bot, char[] guild, RoleList Roles, any data);

// message is deleted on completion, clone if you need to keep it
typedef OnChannelMessage = function void(DiscordBot bot, DiscordChannel channel, DiscordMessage message);

typedef OnGetReactions = function void (DiscordBot bot, ArrayList Users, char[] channelID, const char[] messageID, const char[] emoji, any data);

// message is deleted on completion, clone if you need to keep it
typedef OnMessageSent = function void(DiscordBot bot, char[] channel, DiscordMessage message, any data);

typedef OnMessageDeleted = function void(DiscordBot bot, any data);

typedef OnGetMembers = function void(DiscordBot bot, char[] guild, Handle hMemberList);

methodmap Role < JSON_Object {
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

methodmap RoleList < JSON_Array {
	public Role GetRole(int i) {
		return view_as<Role>(this.GetObject(i));
	}
	public Role Get(int i) {
		return this.GetRole(i);
	}
	
};
