module Evergreen.V294.Route exposing (..)

import Evergreen.V294.Discord
import Evergreen.V294.DmChannel
import Evergreen.V294.Id
import Evergreen.V294.Pagination
import Evergreen.V294.SecretId
import Evergreen.V294.SessionIdHash
import Evergreen.V294.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) (Maybe (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V294.Discord.Id Evergreen.V294.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId
    , guildId : Evergreen.V294.Discord.Id Evergreen.V294.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V294.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId
    , channelId : Evergreen.V294.Discord.Id Evergreen.V294.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V294.Id.Id Evergreen.V294.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V294.Id.Id Evergreen.V294.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V294.Slack.OAuthCode, Evergreen.V294.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V294.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V294.SecretId.SecretId Evergreen.V294.Id.GoMatchPublicId)
