module Evergreen.V38.Route exposing (..)

import Evergreen.V38.Id
import Evergreen.V38.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId) Evergreen.V38.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V38.SecretId.SecretId Evergreen.V38.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V38.Id.Id Evergreen.V38.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) Evergreen.V38.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
