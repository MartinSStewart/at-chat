module Evergreen.V3.Route exposing (..)

import Evergreen.V3.Id
import Evergreen.V3.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V3.Id.Id Evergreen.V3.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V3.SecretId.SecretId Evergreen.V3.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V3.Id.Id Evergreen.V3.Id.GuildId) ChannelRoute
    | AiChatRoute
