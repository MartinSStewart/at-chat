module Evergreen.V25.Route exposing (..)

import Evergreen.V25.Id
import Evergreen.V25.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V25.Id.Id Evergreen.V25.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V25.SecretId.SecretId Evergreen.V25.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V25.Id.Id Evergreen.V25.Id.GuildId) ChannelRoute
