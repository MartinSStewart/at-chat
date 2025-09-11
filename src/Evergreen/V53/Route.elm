module Evergreen.V53.Route exposing (..)

import Effect.Lamdera
import Evergreen.V53.Id
import Evergreen.V53.SecretId
import Evergreen.V53.Slack


type ChannelRoute
    = ChannelRoute (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId) Evergreen.V53.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V53.SecretId.SecretId Evergreen.V53.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V53.Id.Id Evergreen.V53.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) Evergreen.V53.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V53.Slack.OAuthCode, Effect.Lamdera.SessionId ))
