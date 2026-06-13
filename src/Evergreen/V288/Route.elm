module Evergreen.V288.Route exposing (..)

import Evergreen.V288.Discord
import Evergreen.V288.DmChannel
import Evergreen.V288.Id
import Evergreen.V288.Pagination
import Evergreen.V288.SecretId
import Evergreen.V288.SessionIdHash
import Evergreen.V288.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) (Maybe (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V288.Discord.Id Evergreen.V288.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId
    , guildId : Evergreen.V288.Discord.Id Evergreen.V288.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V288.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId
    , channelId : Evergreen.V288.Discord.Id Evergreen.V288.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V288.Id.Id Evergreen.V288.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V288.Id.Id Evergreen.V288.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V288.Slack.OAuthCode, Evergreen.V288.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V288.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V288.SecretId.SecretId Evergreen.V288.Id.GoMatchPublicId)
