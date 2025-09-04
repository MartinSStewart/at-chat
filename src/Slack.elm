module Slack exposing
    ( AuthToken(..)
    , Channel
    , ClientSecret(..)
    , HttpError(..)
    , Id(..)
    , OAuthCode(..)
    , OAuthError(..)
    , SlackError(..)
    , SlackMessage
    , TokenResponse
    , User
    , Workspace
    , buildOAuthUrl
    , decodeChannel
    , decodeTokenResponse
    , decodeUser
    , decodeWorkspace
    , exchangeCodeForToken
    , loadUserWorkspaces
    , loadWorkspaceChannels
    , loadWorkspaceDetails
    , redirectUri
    )

import Duration exposing (Duration)
import Effect.Http as Http
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as Encode
import List.Extra
import Url.Builder
import Url.Parser.Query



-- AUTHENTICATION


type AuthToken
    = SlackAuth String


type OAuthCode
    = OAuthCode String


type ClientSecret
    = ClientSecret String


type Id a
    = Id String


type UserId
    = SlackUserId Never


type TeamId
    = SlackTeamId Never


type alias TokenResponse =
    { accessToken : AuthToken
    , scope : String
    , userId : Id UserId
    , teamId : Id TeamId
    , teamName : String
    }


type OAuthError
    = InvalidClientId
    | InvalidClientSecret
    | InvalidCode
    | InvalidGrantType
    | InvalidRedirectUri
    | InvalidScope
    | AccessDenied
    | ServerError
    | UnknownOAuthError String


buildOAuthUrl : { clientId : String, redirectUri : String, scopes : List String, state : String } -> String
buildOAuthUrl config =
    Url.Builder.crossOrigin "https://slack.com"
        [ "oauth", "v2", "authorize" ]
        [ Url.Builder.string "client_id" config.clientId
        , Url.Builder.string "redirect_uri" config.redirectUri
        , Url.Builder.string "scope" (String.join "," config.scopes)
        , Url.Builder.string "state" config.state
        ]


redirectUri : String
redirectUri =
    "https://542d827f6c05.ngrok-free.app/slack-oauth"


exchangeCodeForToken : ClientSecret -> String -> OAuthCode -> Task restriction HttpError TokenResponse
exchangeCodeForToken (ClientSecret clientSecret) clientId (OAuthCode code) =
    let
        url =
            Url.Builder.crossOrigin "https://slack.com" [ "api", "oauth.v2.access" ] []

        body =
            [ ( "client_id", clientId )
            , ( "client_secret", clientSecret )
            , ( "code", code )
            , ( "redirect_uri", redirectUri )
            ]
                |> List.map (\( key, value ) -> key ++ "=" ++ value)
                |> String.join "&"
                |> Http.stringBody "application/x-www-form-urlencoded"
    in
    Http.task
        { method = "POST"
        , headers = []
        , url = url
        , body = body
        , resolver = Http.stringResolver (handleOAuthResponse decodeTokenResponse)
        , timeout = Just (Duration.seconds 30)
        }



-- DATA STRUCTURES


type alias Workspace =
    { id : String
    , name : String
    , domain : String
    , icon : Maybe String
    , isDeleted : Bool
    }


type alias Channel =
    { id : String
    , name : String
    , isChannel : Bool
    , isGroup : Bool
    , isIm : Bool
    , isMember : Bool
    , isArchived : Bool
    , topic : Maybe String
    , purpose : Maybe String
    }


type alias User =
    { id : String
    , name : String
    , realName : Maybe String
    , displayName : Maybe String
    , email : Maybe String
    , isBot : Bool
    , isDeleted : Bool
    , profile : Maybe UserProfile
    }


type alias UserProfile =
    { avatarHash : Maybe String
    , image72 : Maybe String
    , image192 : Maybe String
    , image512 : Maybe String
    }


type alias SlackMessage =
    { ts : String
    , user : String
    , text : String
    , channelId : String
    , threadTs : Maybe String
    }



-- ERROR HANDLING


type SlackError
    = InvalidAuth
    | AccountInactive
    | InvalidArgName
    | InvalidArrayArg
    | RateLimited
    | RequestTimeout
    | InternalError
    | Unknown String


type HttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Int
    | BadBody String
    | SlackApiError SlackError



-- API FUNCTIONS


loadUserWorkspaces : AuthToken -> Task restriction HttpError (List Workspace)
loadUserWorkspaces (SlackAuth auth) =
    let
        url =
            Url.Builder.crossOrigin "https://slack.com" [ "api", "auth.teams.list" ] []
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" auth ]
        , url = url
        , body = Http.emptyBody
        , resolver = Http.stringResolver (handleSlackResponse decodeWorkspacesList)
        , timeout = Just (Duration.seconds 30)
        }


loadWorkspaceDetails : AuthToken -> String -> Task restriction HttpError Workspace
loadWorkspaceDetails (SlackAuth auth) teamId =
    let
        url =
            Url.Builder.crossOrigin "https://slack.com" [ "api", "team.info" ] []

        body =
            Http.stringBody "application/x-www-form-urlencoded" ("team=" ++ teamId)
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" auth ]
        , url = url
        , body = body
        , resolver = Http.stringResolver (handleSlackResponse decodeWorkspaceDetails)
        , timeout = Just (Duration.seconds 30)
        }


loadWorkspaceChannels : AuthToken -> Id TeamId -> Task restriction HttpError (List Channel)
loadWorkspaceChannels (SlackAuth auth) (Id teamId) =
    let
        url =
            Url.Builder.crossOrigin "https://slack.com" [ "api", "conversations.list" ] []

        body =
            Http.stringBody
                "application/x-www-form-urlencoded"
                ("team_id=" ++ teamId ++ "&types=public_channel,private_channel,mpim,im")
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ auth) ]
        , url = url
        , body = body
        , resolver = Http.stringResolver (handleSlackResponse decodeChannelsList)
        , timeout = Just (Duration.seconds 30)
        }



--{
--    "ok": true,
--    "channels": [
--        {
--            "id": "C09DJDQSWLU",
--            "created": 1756936522,
--            "creator": "U09DJDQL1A8",
--            "is_org_shared": false,
--            "is_im": false,
--            "context_team_id": "T09DJDQL18U",
--            "updated": 1756936539024,
--            "name": "all-test-slack",
--            "name_normalized": "all-test-slack",
--            "is_channel": true,
--            "is_group": false,
--            "is_mpim": false,
--            "is_private": false,
--            "is_archived": false,
--            "is_general": true,
--            "is_shared": false,
--            "is_ext_shared": false,
--            "unlinked": 0,
--            "is_pending_ext_shared": false,
--            "pending_shared": [],
--            "parent_conversation": null,
--            "purpose": {
--                "value": "Share announcements and updates about company news, upcoming events, or teammates who deserve some kudos. \u2b50",
--                "creator": "U09DJDQL1A8",
--                "last_set": 1756936522
--            },
--            "topic": {
--                "value": "",
--                "creator": "",
--                "last_set": 0
--            },
--            "shared_team_ids": [
--                "T09DJDQL18U"
--            ],
--            "pending_connected_team_ids": [],
--            "is_member": false,
--            "num_members": 1,
--            "properties": {
--                "use_case": "welcome"
--            },
--            "previous_names": [
--                "all-slack"
--            ]
--        },
--        {
--            "id": "C09DJDQUKKN",
--            "created": 1756936522,
--            "creator": "U09DJDQL1A8",
--            "is_org_shared": false,
--            "is_im": false,
--            "context_team_id": "T09DJDQL18U",
--            "updated": 1756936527359,
--            "name": "social",
--            "name_normalized": "social",
--            "is_channel": true,
--            "is_group": false,
--            "is_mpim": false,
--            "is_private": false,
--            "is_archived": false,
--            "is_general": false,
--            "is_shared": false,
--            "is_ext_shared": false,
--            "unlinked": 0,
--            "is_pending_ext_shared": false,
--            "pending_shared": [],
--            "parent_conversation": null,
--            "purpose": {
--                "value": "Other channels are for work. This one\u2019s just for fun. Get to know your teammates and show your lighter side. \ud83c\udf88",
--                "creator": "U09DJDQL1A8",
--                "last_set": 1756936522
--            },
--            "topic": {
--                "value": "",
--                "creator": "",
--                "last_set": 0
--            },
--            "shared_team_ids": [
--                "T09DJDQL18U"
--            ],
--            "pending_connected_team_ids": [],
--            "is_member": false,
--            "num_members": 1,
--            "properties": {
--                "tabs": [
--                    {
--                        "id": "Ct09DJDGSVC4",
--                        "type": "canvas",
--                        "data": {
--                            "file_id": "F09DJDGG476",
--                            "shared_ts": "1756936527.055909"
--                        },
--                        "label": ""
--                    }
--                ],
--                "tabz": [
--                    {
--                        "id": "Ct09DJDGSVC4",
--                        "type": "canvas",
--                        "data": {
--                            "file_id": "F09DJDGG476",
--                            "shared_ts": "1756936527.055909"
--                        }
--                    }
--                ],
--                "use_case": "random"
--            },
--            "previous_names": []
--        },
--        {
--            "id": "C09DJDRNNS0",
--            "created": 1756936551,
--            "creator": "U09DJDQL1A8",
--            "is_org_shared": false,
--            "is_im": false,
--            "context_team_id": "T09DJDQL18U",
--            "updated": 1756936551148,
--            "name": "new-channel",
--            "name_normalized": "new-channel",
--            "is_channel": true,
--            "is_group": false,
--            "is_mpim": false,
--            "is_private": false,
--            "is_archived": false,
--            "is_general": false,
--            "is_shared": false,
--            "is_ext_shared": false,
--            "unlinked": 0,
--            "is_pending_ext_shared": false,
--            "pending_shared": [],
--            "parent_conversation": null,
--            "purpose": {
--                "value": "This channel is for everything #new-channel. Hold meetings, share docs, and make decisions together with your team.",
--                "creator": "U09DJDQL1A8",
--                "last_set": 1756936551
--            },
--            "topic": {
--                "value": "",
--                "creator": "",
--                "last_set": 0
--            },
--            "shared_team_ids": [
--                "T09DJDQL18U"
--            ],
--            "pending_connected_team_ids": [],
--            "is_member": false,
--            "num_members": 1,
--            "properties": {
--                "use_case": "project"
--            },
--            "previous_names": []
--        },
--        {
--            "id": "D09DFEY0YFP",
--            "created": 1756987735,
--            "is_org_shared": false,
--            "is_im": true,
--            "is_archived": false,
--            "context_team_id": "T09DJDQL18U",
--            "updated": 1756987735048,
--            "user": "U09DJDQL1A8",
--            "is_user_deleted": false,
--            "priority": 0
--        },
--        {
--            "id": "D09DFEY02TX",
--            "created": 1756987734,
--            "is_org_shared": false,
--            "is_im": true,
--            "is_archived": false,
--            "context_team_id": "T09DJDQL18U",
--            "updated": 1756987734975,
--            "user": "USLACKBOT",
--            "is_user_deleted": false,
--            "priority": 0
--        }
--    ],
--    "response_metadata": {
--        "next_cursor": ""
--    }
--}



-- HTTP RESPONSE HANDLING


handleSlackResponse : Decoder a -> Http.Response String -> Result HttpError a
handleSlackResponse decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            Err (BadStatus metadata.statusCode)

        Http.GoodStatus_ metadata body ->
            case Decode.decodeString (slackResponseDecoder decoder) body of
                Ok result ->
                    Ok result

                Err decodeError ->
                    Err (BadBody (Decode.errorToString decodeError))


handleOAuthResponse : Decoder a -> Http.Response String -> Result HttpError a
handleOAuthResponse decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            Err (BadStatus metadata.statusCode)

        Http.GoodStatus_ metadata body ->
            case Decode.decodeString (oauthResponseDecoder decoder) body of
                Ok result ->
                    Ok result

                Err decodeError ->
                    Err (BadBody (Decode.errorToString decodeError))


slackResponseDecoder : Decoder a -> Decoder a
slackResponseDecoder dataDecoder =
    Decode.field "ok" Decode.bool
        |> Decode.andThen
            (\isOk ->
                if isOk then
                    dataDecoder

                else
                    Decode.field "error" Decode.string
                        |> Decode.andThen (\error -> Decode.fail ("Slack API error: " ++ error))
            )


oauthResponseDecoder : Decoder a -> Decoder a
oauthResponseDecoder dataDecoder =
    Decode.field "ok" Decode.bool
        |> Decode.andThen
            (\isOk ->
                if isOk then
                    dataDecoder

                else
                    Decode.field "error" Decode.string
                        |> Decode.andThen (\error -> Decode.fail ("OAuth error: " ++ error))
            )



-- DECODERS


decodeWorkspacesList : Decoder (List Workspace)
decodeWorkspacesList =
    Decode.field "teams" (Decode.list decodeWorkspace)


decodeWorkspaceDetails : Decoder Workspace
decodeWorkspaceDetails =
    Decode.field "team" decodeWorkspace


decodeWorkspace : Decoder Workspace
decodeWorkspace =
    Decode.map5 Workspace
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "domain" Decode.string)
        (Decode.maybe (Decode.field "icon" (Decode.field "image_68" Decode.string)))
        (Decode.field "deleted" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))


decodeChannelsList : Decoder (List Channel)
decodeChannelsList =
    Decode.field "channels" (Decode.list decodeChannel)


decodeChannel : Decoder Channel
decodeChannel =
    Decode.succeed Channel
        |> andMap (Decode.field "id" Decode.string)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.field "is_channel" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "is_group" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "is_im" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "is_member" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "is_archived" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.maybe (Decode.field "topic" (Decode.field "value" Decode.string)))
        |> andMap (Decode.maybe (Decode.field "purpose" (Decode.field "value" Decode.string)))


decodeUser : Decoder User
decodeUser =
    Decode.succeed User
        |> andMap (Decode.field "id" Decode.string)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.maybe (Decode.field "real_name" Decode.string))
        |> andMap (Decode.maybe (Decode.field "profile" (Decode.field "display_name" Decode.string)))
        |> andMap (Decode.maybe (Decode.field "profile" (Decode.field "email" Decode.string)))
        |> andMap (Decode.field "is_bot" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "deleted" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.maybe (Decode.field "profile" decodeUserProfile))


decodeUserProfile : Decoder UserProfile
decodeUserProfile =
    Decode.map4 UserProfile
        (Decode.maybe (Decode.field "avatar_hash" Decode.string))
        (Decode.maybe (Decode.field "image_72" Decode.string))
        (Decode.maybe (Decode.field "image_192" Decode.string))
        (Decode.maybe (Decode.field "image_512" Decode.string))


decodeTokenResponse : Decoder TokenResponse
decodeTokenResponse =
    Decode.map5 TokenResponse
        (Decode.field "access_token" (Decode.map SlackAuth Decode.string))
        (Decode.field "scope" Decode.string)
        (Decode.at [ "authed_user", "id" ] decodeId)
        (Decode.at [ "team", "id" ] decodeId)
        (Decode.at [ "team", "name" ] Decode.string)


decodeId =
    Decode.map Id Decode.string
