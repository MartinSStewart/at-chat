module Evergreen.V24.Route exposing (..)

import Evergreen.V24.Id
import Evergreen.V24.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V24.Id.Id Evergreen.V24.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V24.SecretId.SecretId Evergreen.V24.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V24.Id.Id Evergreen.V24.Id.GuildId) ChannelRoute
