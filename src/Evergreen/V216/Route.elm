module Evergreen.V216.Route exposing (..)

import Evergreen.V216.Discord
import Evergreen.V216.DmChannel
import Evergreen.V216.Id
import Evergreen.V216.Pagination
import Evergreen.V216.SecretId
import Evergreen.V216.SessionIdHash
import Evergreen.V216.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Maybe (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V216.SecretId.SecretId Evergreen.V216.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId
    , guildId : Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId))


type alias DmRouteData =
    { channelId : Evergreen.V216.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId
    , channelId : Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V216.Id.Id Evergreen.V216.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V216.Slack.OAuthCode, Evergreen.V216.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V216.Discord.UserAuth)
