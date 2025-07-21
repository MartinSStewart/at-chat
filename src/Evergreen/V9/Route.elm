module Evergreen.V9.Route exposing (..)

import Evergreen.V9.Id
import Evergreen.V9.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V9.Id.Id Evergreen.V9.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V9.SecretId.SecretId Evergreen.V9.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V9.Id.Id Evergreen.V9.Id.GuildId) ChannelRoute
    | AiChatRoute
