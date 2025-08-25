module Evergreen.V33.Route exposing (..)

import Evergreen.V33.Id
import Evergreen.V33.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId) Evergreen.V33.Id.ThreadRoute (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V33.Id.Id Evergreen.V33.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V33.SecretId.SecretId Evergreen.V33.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V33.Id.Id Evergreen.V33.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Id.ThreadRoute (Maybe Int)
    | AiChatRoute
