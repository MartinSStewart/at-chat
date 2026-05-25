module Evergreen.V251.Route exposing (..)

import Evergreen.V251.Discord
import Evergreen.V251.DmChannel
import Evergreen.V251.Id
import Evergreen.V251.Pagination
import Evergreen.V251.SecretId
import Evergreen.V251.SessionIdHash
import Evergreen.V251.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) (Maybe (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V251.Discord.Id Evergreen.V251.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId
    , guildId : Evergreen.V251.Discord.Id Evergreen.V251.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V251.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId
    , channelId : Evergreen.V251.Discord.Id Evergreen.V251.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V251.Id.Id Evergreen.V251.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V251.Id.Id Evergreen.V251.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V251.Slack.OAuthCode, Evergreen.V251.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V251.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.GoMatchPublicId)
