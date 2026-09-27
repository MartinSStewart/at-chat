module Evergreen.V386.Route exposing (..)

import Effect.Time
import Evergreen.V386.Discord
import Evergreen.V386.DmChannelId
import Evergreen.V386.Id
import Evergreen.V386.Pagination
import Evergreen.V386.SecretId
import Evergreen.V386.SessionIdHash
import Evergreen.V386.Slack
import Evergreen.V386.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Maybe (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V386.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V386.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId
    , guildId : Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V386.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V386.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId
    , channelId : Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V386.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V386.Id.Id Evergreen.V386.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V386.Slack.OAuthCode, Evergreen.V386.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V386.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
