module Evergreen.V30.Route exposing (..)

import Evergreen.V30.Id
import Evergreen.V30.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V30.Id.Id Evergreen.V30.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V30.SecretId.SecretId Evergreen.V30.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V30.Id.Id Evergreen.V30.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Maybe Int)
    | AiChatRoute
