module Evergreen.V22.Route exposing (..)

import Evergreen.V22.Id
import Evergreen.V22.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V22.Id.Id Evergreen.V22.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V22.SecretId.SecretId Evergreen.V22.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V22.Id.Id Evergreen.V22.Id.GuildId) ChannelRoute
