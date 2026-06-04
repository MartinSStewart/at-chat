module Evergreen.V271.Route exposing (..)

import Evergreen.V271.Discord
import Evergreen.V271.DmChannel
import Evergreen.V271.Id
import Evergreen.V271.Pagination
import Evergreen.V271.SecretId
import Evergreen.V271.SessionIdHash
import Evergreen.V271.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) (Maybe (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V271.Discord.Id Evergreen.V271.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId
    , guildId : Evergreen.V271.Discord.Id Evergreen.V271.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V271.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId
    , channelId : Evergreen.V271.Discord.Id Evergreen.V271.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V271.Id.Id Evergreen.V271.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V271.Id.Id Evergreen.V271.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V271.Slack.OAuthCode, Evergreen.V271.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V271.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V271.SecretId.SecretId Evergreen.V271.Id.GoMatchPublicId)
