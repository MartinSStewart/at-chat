module Evergreen.V26.Route exposing (..)

import Evergreen.V26.Id
import Evergreen.V26.SecretId


type ChannelRoute
    = ChannelRoute (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId) (Maybe Int)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V26.Id.Id Evergreen.V26.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V26.SecretId.SecretId Evergreen.V26.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V26.Id.Id Evergreen.V26.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Maybe Int)
    | AiChatRoute
