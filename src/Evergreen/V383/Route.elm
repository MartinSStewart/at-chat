module Evergreen.V383.Route exposing (..)

import Effect.Time
import Evergreen.V383.Discord
import Evergreen.V383.DmChannelId
import Evergreen.V383.Id
import Evergreen.V383.Pagination
import Evergreen.V383.SecretId
import Evergreen.V383.SessionIdHash
import Evergreen.V383.Slack
import Evergreen.V383.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Maybe (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V383.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V383.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId
    , guildId : Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V383.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V383.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId
    , channelId : Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V383.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V383.Id.Id Evergreen.V383.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V383.Slack.OAuthCode, Evergreen.V383.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V383.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
