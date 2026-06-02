module Evergreen.V264.Route exposing (..)

import Evergreen.V264.Discord
import Evergreen.V264.DmChannel
import Evergreen.V264.Id
import Evergreen.V264.Pagination
import Evergreen.V264.SecretId
import Evergreen.V264.SessionIdHash
import Evergreen.V264.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) (Maybe (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V264.Discord.Id Evergreen.V264.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId
    , guildId : Evergreen.V264.Discord.Id Evergreen.V264.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V264.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId
    , channelId : Evergreen.V264.Discord.Id Evergreen.V264.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V264.Id.Id Evergreen.V264.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V264.Id.Id Evergreen.V264.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V264.Slack.OAuthCode, Evergreen.V264.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V264.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V264.SecretId.SecretId Evergreen.V264.Id.GoMatchPublicId)
