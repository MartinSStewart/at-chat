module Evergreen.V289.Route exposing (..)

import Evergreen.V289.Discord
import Evergreen.V289.DmChannel
import Evergreen.V289.Id
import Evergreen.V289.Pagination
import Evergreen.V289.SecretId
import Evergreen.V289.SessionIdHash
import Evergreen.V289.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) (Maybe (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V289.Discord.Id Evergreen.V289.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId
    , guildId : Evergreen.V289.Discord.Id Evergreen.V289.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V289.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId
    , channelId : Evergreen.V289.Discord.Id Evergreen.V289.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V289.Id.Id Evergreen.V289.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V289.Id.Id Evergreen.V289.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V289.Slack.OAuthCode, Evergreen.V289.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V289.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V289.SecretId.SecretId Evergreen.V289.Id.GoMatchPublicId)
