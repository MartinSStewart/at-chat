module Evergreen.V60.Route exposing (..)

import Effect.Lamdera
import Evergreen.V60.Id
import Evergreen.V60.SecretId
import Evergreen.V60.Slack


type ChannelRoute
    = ChannelRoute (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId) Evergreen.V60.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V60.SecretId.SecretId Evergreen.V60.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V60.Id.Id Evergreen.V60.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V60.Slack.OAuthCode, Effect.Lamdera.SessionId ))
