module Evergreen.V4.Route exposing (..)

import Evergreen.V4.Id
import Evergreen.V4.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V4.Id.Id Evergreen.V4.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V4.SecretId.SecretId Evergreen.V4.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V4.Id.Id Evergreen.V4.Id.GuildId) ChannelRoute
