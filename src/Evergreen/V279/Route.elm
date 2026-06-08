module Evergreen.V279.Route exposing (..)

import Evergreen.V279.Discord
import Evergreen.V279.DmChannel
import Evergreen.V279.Id
import Evergreen.V279.Pagination
import Evergreen.V279.SecretId
import Evergreen.V279.SessionIdHash
import Evergreen.V279.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) (Maybe (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V279.Discord.Id Evergreen.V279.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId
    , guildId : Evergreen.V279.Discord.Id Evergreen.V279.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V279.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId
    , channelId : Evergreen.V279.Discord.Id Evergreen.V279.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V279.Id.Id Evergreen.V279.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V279.Id.Id Evergreen.V279.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V279.Slack.OAuthCode, Evergreen.V279.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V279.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V279.SecretId.SecretId Evergreen.V279.Id.GoMatchPublicId)
