module Evergreen.V46.Route exposing (..)

import Evergreen.V46.Id
import Evergreen.V46.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId) Evergreen.V46.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V46.SecretId.SecretId Evergreen.V46.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V46.Id.Id Evergreen.V46.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
