module Evergreen.V262.Route exposing (..)

import Evergreen.V262.Discord
import Evergreen.V262.DmChannel
import Evergreen.V262.Id
import Evergreen.V262.Pagination
import Evergreen.V262.SecretId
import Evergreen.V262.SessionIdHash
import Evergreen.V262.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) (Maybe (Evergreen.V262.Id.Id Evergreen.V262.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V262.SecretId.SecretId Evergreen.V262.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V262.Discord.Id Evergreen.V262.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId
    , guildId : Evergreen.V262.Discord.Id Evergreen.V262.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V262.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId
    , channelId : Evergreen.V262.Discord.Id Evergreen.V262.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V262.Id.Id Evergreen.V262.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V262.Id.Id Evergreen.V262.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V262.Slack.OAuthCode, Evergreen.V262.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V262.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V262.SecretId.SecretId Evergreen.V262.Id.GoMatchPublicId)
