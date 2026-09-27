module Evergreen.V388.Route exposing (..)

import Effect.Time
import Evergreen.V388.Discord
import Evergreen.V388.DmChannelId
import Evergreen.V388.Id
import Evergreen.V388.Pagination
import Evergreen.V388.SecretId
import Evergreen.V388.SessionIdHash
import Evergreen.V388.Slack
import Evergreen.V388.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Maybe (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V388.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V388.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId
    , guildId : Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V388.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V388.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId
    , channelId : Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V388.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V388.Id.Id Evergreen.V388.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V388.Slack.OAuthCode, Evergreen.V388.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V388.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
