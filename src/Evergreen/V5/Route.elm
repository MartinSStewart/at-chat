module Evergreen.V5.Route exposing (..)

import Evergreen.V5.Id
import Evergreen.V5.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V5.Id.Id Evergreen.V5.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V5.SecretId.SecretId Evergreen.V5.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V5.Id.Id Evergreen.V5.Id.GuildId) ChannelRoute
