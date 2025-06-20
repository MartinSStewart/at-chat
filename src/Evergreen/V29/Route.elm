module Evergreen.V29.Route exposing (..)

import Evergreen.V29.Id
import Evergreen.V29.SecretId


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)


type ChannelRoute
    = ChannelRoute (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V29.Id.Id Evergreen.V29.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V29.SecretId.SecretId Evergreen.V29.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Evergreen.V29.Id.Id Evergreen.V29.Id.GuildId) ChannelRoute
