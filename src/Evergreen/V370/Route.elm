module Evergreen.V370.Route exposing (..)

import Effect.Time
import Evergreen.V370.Discord
import Evergreen.V370.DmChannelId
import Evergreen.V370.Id
import Evergreen.V370.Pagination
import Evergreen.V370.SecretId
import Evergreen.V370.SessionIdHash
import Evergreen.V370.Slack
import Evergreen.V370.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) (Maybe (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V370.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V370.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId
    , guildId : Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V370.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V370.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId
    , channelId : Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V370.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V370.Id.Id Evergreen.V370.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V370.Slack.OAuthCode, Evergreen.V370.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V370.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V370.SecretId.SecretId Evergreen.V370.Id.GamePublicId)
    | E2eeInfo


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
