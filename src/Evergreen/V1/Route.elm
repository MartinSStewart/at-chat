module Evergreen.V1.Route exposing (..)

import Evergreen.V1.Id
import Evergreen.V1.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V1.Id.Id Evergreen.V1.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V1.SecretId.SecretId Evergreen.V1.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V1.Id.Id Evergreen.V1.Id.GuildId) ChannelRoute
