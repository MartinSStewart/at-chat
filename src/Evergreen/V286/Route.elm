module Evergreen.V286.Route exposing (..)

import Evergreen.V286.Discord
import Evergreen.V286.DmChannel
import Evergreen.V286.Id
import Evergreen.V286.Pagination
import Evergreen.V286.SecretId
import Evergreen.V286.SessionIdHash
import Evergreen.V286.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) (Maybe (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V286.Discord.Id Evergreen.V286.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId
    , guildId : Evergreen.V286.Discord.Id Evergreen.V286.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V286.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId
    , channelId : Evergreen.V286.Discord.Id Evergreen.V286.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V286.Id.Id Evergreen.V286.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V286.Id.Id Evergreen.V286.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V286.Slack.OAuthCode, Evergreen.V286.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V286.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V286.SecretId.SecretId Evergreen.V286.Id.GoMatchPublicId)
