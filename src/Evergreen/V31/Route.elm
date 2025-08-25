module Evergreen.V31.Route exposing (..)

import Evergreen.V31.Id
import Evergreen.V31.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V31.Id.Id Evergreen.V31.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V31.SecretId.SecretId Evergreen.V31.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V31.Id.Id Evergreen.V31.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) (Maybe Int)
    | AiChatRoute
