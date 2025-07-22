module Evergreen.V14.Route exposing (..)

import Evergreen.V14.Id
import Evergreen.V14.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V14.Id.Id Evergreen.V14.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V14.SecretId.SecretId Evergreen.V14.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V14.Id.Id Evergreen.V14.Id.GuildId) ChannelRoute
    | AiChatRoute
