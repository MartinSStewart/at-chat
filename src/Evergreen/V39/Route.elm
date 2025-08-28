module Evergreen.V39.Route exposing (..)

import Evergreen.V39.Id
import Evergreen.V39.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId) Evergreen.V39.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V39.SecretId.SecretId Evergreen.V39.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V39.Id.Id Evergreen.V39.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) Evergreen.V39.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
