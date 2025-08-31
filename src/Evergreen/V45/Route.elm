module Evergreen.V45.Route exposing (..)

import Evergreen.V45.Id
import Evergreen.V45.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId) Evergreen.V45.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V45.SecretId.SecretId Evergreen.V45.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V45.Id.Id Evergreen.V45.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
