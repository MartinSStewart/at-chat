module Evergreen.V32.Route exposing (..)

import Evergreen.V32.Id
import Evergreen.V32.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V32.Id.Id Evergreen.V32.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V32.SecretId.SecretId Evergreen.V32.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V32.Id.Id Evergreen.V32.Id.GuildId) ChannelRoute
