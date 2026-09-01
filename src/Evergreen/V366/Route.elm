module Evergreen.V366.Route exposing (..)

import Effect.Time
import Evergreen.V366.Discord
import Evergreen.V366.DmChannelId
import Evergreen.V366.Id
import Evergreen.V366.Pagination
import Evergreen.V366.SecretId
import Evergreen.V366.SessionIdHash
import Evergreen.V366.Slack
import Evergreen.V366.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Maybe (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V366.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V366.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId
    , guildId : Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V366.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V366.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId
    , channelId : Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V366.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V366.Id.Id Evergreen.V366.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V366.Slack.OAuthCode, Evergreen.V366.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V366.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
