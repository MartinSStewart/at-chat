module Evergreen.V12.Route exposing (..)

import Evergreen.V12.Id
import Evergreen.V12.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V12.Id.Id Evergreen.V12.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V12.SecretId.SecretId Evergreen.V12.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V12.Id.Id Evergreen.V12.Id.GuildId) ChannelRoute
