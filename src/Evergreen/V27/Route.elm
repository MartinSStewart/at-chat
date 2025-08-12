module Evergreen.V27.Route exposing (..)

import Evergreen.V27.Id
import Evergreen.V27.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V27.Id.Id Evergreen.V27.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V27.SecretId.SecretId Evergreen.V27.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V27.Id.Id Evergreen.V27.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Maybe Int)
    | AiChatRoute
