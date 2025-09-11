module Evergreen.V54.Route exposing (..)

import Effect.Lamdera
import Evergreen.V54.Id
import Evergreen.V54.SecretId
import Evergreen.V54.Slack


type ChannelRoute
    = ChannelRoute (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId) Evergreen.V54.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V54.SecretId.SecretId Evergreen.V54.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V54.Id.Id Evergreen.V54.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V54.Slack.OAuthCode, Effect.Lamdera.SessionId ))
