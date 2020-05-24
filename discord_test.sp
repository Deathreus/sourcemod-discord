
#include <sourcemod>
#include <SteamWorks>
#include <discord>
#include <discord/bot>
#include <discord/message>
#include <discord/webhook>

#pragma semicolon 1
#pragma newdecls required

DiscordBot g_Bot;

ConVar cvarToken;
ConVar cvarWebhook;
ConVar cvarChannel;

public void OnPluginStart()
{
	cvarToken = CreateConVar("discord_token", "", "", FCVAR_PROTECTED);
	cvarWebhook = CreateConVar("discord_webhook", "", "", FCVAR_PROTECTED);
	cvarChannel = CreateConVar("discord_channel", "", "", FCVAR_PROTECTED);
}

public void OnConfigsExecuted()
{
	char sToken[96];
	cvarToken.GetString(sToken, sizeof(sToken));

	g_Bot = new DiscordBot(sToken);
	g_Bot.GetGuilds(OnGuildRetrieved);
}
public void OnGuildRetrieved(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data)
{
	bot.GetGuildChannels(id, OnChannelRetrieved);
}
public void OnChannelRetrieved(DiscordBot bot, char[] guild, DiscordChannel channel, any data)
{
	char sChannel[64];
	channel.GetName(sChannel, sizeof(sChannel));

	char sName[64];
	cvarChannel.GetString(sName, sizeof(sName));

	if(StrEqual(sName, sChannel))
		bot.StartListeningToChannel(channel, OnChannelMessage);
}


public void OnChannelMessage(DiscordBot bot, DiscordChannel channel, DiscordMessage message)
{
	DiscordUser author = message.GetAuthor();
	if(author.IsBot)
		return;

	char sAuthor[128];
	author.GetUsername(sAuthor, sizeof(sAuthor));
	char sDiscriminator[6];
	author.GetDiscriminator(sDiscriminator, sizeof(sDiscriminator));

	char sChannel[64];
	channel.GetName(sChannel, sizeof(sChannel));

	char sContent[256];
	message.GetContent(sContent, sizeof(sContent));

	PrintToServer("[%s] %s%s: %s", sChannel, sAuthor, sDiscriminator, sContent);
	LogMessage("[%s] %s%s: %s", sChannel, sAuthor, sDiscriminator, sContent);
}


public Action OnClientSayCommand(int iClient, const char[] sCommand, const char[] sArgs)
{
	if(IsChatTrigger() || !IsClientInGame(iClient))
		return Plugin_Handled;

	char sContents[256];
	strcopy(sContents, sizeof(sContents), sArgs);
	StripQuotes(sContents);
	TrimString(sContents);

	if(StrContains(sContents, "@here", false) != -1)
		ReplaceString(sContents, sizeof(sContents), "@here", "", false);
	if(StrContains(sContents, "@everyone", false) != -1)
		ReplaceString(sContents, sizeof(sContents), "@everyone", "", false);

	char sChannelID[256];
	cvarWebhook.GetString(sChannelID, sizeof(sChannelID));

	Format(sContents, sizeof(sContents), "%N: %s", iClient, sContents);

	DiscordWebHook hook = new DiscordWebHook(sChannelID);
	hook.SetUsername("SMDiscord");
	hook.SetContent(sContents);
	hook.Send();

	return Plugin_Continue;
}
