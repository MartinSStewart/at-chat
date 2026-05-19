module Evergreen.V240.Route exposing (..)

import Evergreen.V240.Discord
import Evergreen.V240.DmChannel
import Evergreen.V240.Id
import Evergreen.V240.Pagination
import Evergreen.V240.SecretId
import Evergreen.V240.SessionIdHash
import Evergreen.V240.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) (Maybe (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V240.SecretId.SecretId Evergreen.V240.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V240.Discord.Id Evergreen.V240.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId
    , guildId : Evergreen.V240.Discord.Id Evergreen.V240.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V240.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId
    , channelId : Evergreen.V240.Discord.Id Evergreen.V240.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe DmChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V240.Id.Id Evergreen.V240.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V240.Id.Id Evergreen.V240.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V240.Slack.OAuthCode, Evergreen.V240.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V240.Discord.UserAuth)
