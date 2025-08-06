module Evergreen.V17.Route exposing (..)

import Evergreen.V17.Id
import Evergreen.V17.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V17.Id.Id Evergreen.V17.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V17.SecretId.SecretId Evergreen.V17.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V17.Id.Id Evergreen.V17.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) (Maybe Int)
    | AiChatRoute
