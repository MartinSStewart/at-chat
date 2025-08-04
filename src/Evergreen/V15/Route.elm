module Evergreen.V15.Route exposing (..)

import Evergreen.V15.Id
import Evergreen.V15.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V15.Id.Id Evergreen.V15.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V15.SecretId.SecretId Evergreen.V15.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V15.Id.Id Evergreen.V15.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) (Maybe Int)
    | AiChatRoute
