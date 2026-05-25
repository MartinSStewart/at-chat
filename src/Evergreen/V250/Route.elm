module Evergreen.V250.Route exposing (..)

import Evergreen.V250.Discord
import Evergreen.V250.DmChannel
import Evergreen.V250.Id
import Evergreen.V250.Pagination
import Evergreen.V250.SecretId
import Evergreen.V250.SessionIdHash
import Evergreen.V250.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) (Maybe (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V250.Discord.Id Evergreen.V250.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId
    , guildId : Evergreen.V250.Discord.Id Evergreen.V250.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V250.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId
    , channelId : Evergreen.V250.Discord.Id Evergreen.V250.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V250.Id.Id Evergreen.V250.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V250.Id.Id Evergreen.V250.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V250.Slack.OAuthCode, Evergreen.V250.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V250.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.GoMatchPublicId)
