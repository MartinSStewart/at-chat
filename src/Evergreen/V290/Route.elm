module Evergreen.V290.Route exposing (..)

import Evergreen.V290.Discord
import Evergreen.V290.DmChannel
import Evergreen.V290.Id
import Evergreen.V290.Pagination
import Evergreen.V290.SecretId
import Evergreen.V290.SessionIdHash
import Evergreen.V290.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) (Maybe (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V290.Discord.Id Evergreen.V290.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId
    , guildId : Evergreen.V290.Discord.Id Evergreen.V290.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V290.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId
    , channelId : Evergreen.V290.Discord.Id Evergreen.V290.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V290.Id.Id Evergreen.V290.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V290.Id.Id Evergreen.V290.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V290.Slack.OAuthCode, Evergreen.V290.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V290.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V290.SecretId.SecretId Evergreen.V290.Id.GoMatchPublicId)
