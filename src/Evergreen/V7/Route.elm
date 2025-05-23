module Evergreen.V7.Route exposing (..)

import Evergreen.V7.Id
import Evergreen.V7.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V7.Id.Id Evergreen.V7.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V7.SecretId.SecretId Evergreen.V7.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V7.Id.Id Evergreen.V7.Id.GuildId) ChannelRoute
