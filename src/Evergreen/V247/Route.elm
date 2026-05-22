module Evergreen.V247.Route exposing (..)

import Evergreen.V247.Discord
import Evergreen.V247.DmChannel
import Evergreen.V247.Id
import Evergreen.V247.Pagination
import Evergreen.V247.SecretId
import Evergreen.V247.SessionIdHash
import Evergreen.V247.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) (Maybe (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V247.Discord.Id Evergreen.V247.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId
    , guildId : Evergreen.V247.Discord.Id Evergreen.V247.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V247.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId
    , channelId : Evergreen.V247.Discord.Id Evergreen.V247.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V247.Id.Id Evergreen.V247.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V247.Id.Id Evergreen.V247.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V247.Slack.OAuthCode, Evergreen.V247.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V247.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.GoMatchPublicId)
