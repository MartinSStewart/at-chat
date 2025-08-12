module Evergreen.V23.Route exposing (..)

import Evergreen.V23.Id
import Evergreen.V23.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V23.Id.Id Evergreen.V23.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V23.SecretId.SecretId Evergreen.V23.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V23.Id.Id Evergreen.V23.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) (Maybe Int)
    | AiChatRoute
