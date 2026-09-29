module Evergreen.V392.Route exposing (..)

import Effect.Time
import Evergreen.V392.Discord
import Evergreen.V392.DmChannelId
import Evergreen.V392.Id
import Evergreen.V392.Pagination
import Evergreen.V392.SecretId
import Evergreen.V392.SessionIdHash
import Evergreen.V392.Slack
import Evergreen.V392.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Maybe (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V392.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V392.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId
    , guildId : Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V392.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V392.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId
    , channelId : Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V392.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute (Maybe Overlay)
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V392.Id.Id Evergreen.V392.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V392.Slack.OAuthCode, Evergreen.V392.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V392.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
