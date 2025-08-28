module Evergreen.V42.Route exposing (..)

import Evergreen.V42.Id
import Evergreen.V42.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId) Evergreen.V42.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V42.SecretId.SecretId Evergreen.V42.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V42.Id.Id Evergreen.V42.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
