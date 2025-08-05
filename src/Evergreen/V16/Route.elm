module Evergreen.V16.Route exposing (..)

import Evergreen.V16.Id
import Evergreen.V16.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V16.Id.Id Evergreen.V16.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V16.SecretId.SecretId Evergreen.V16.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V16.Id.Id Evergreen.V16.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (Maybe Int)
    | AiChatRoute
