module Evergreen.V41.Route exposing (..)

import Evergreen.V41.Id
import Evergreen.V41.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId) Evergreen.V41.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V41.SecretId.SecretId Evergreen.V41.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V41.Id.Id Evergreen.V41.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) Evergreen.V41.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
