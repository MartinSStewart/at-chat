module Slack exposing
    ( HttpError(..)
    , SlackAuth(..)
    , SlackChannel
    , SlackError(..)
    , SlackMessage
    , SlackUser
    , SlackWorkspace
    , decodeChannel
    , decodeUser
    , decodeWorkspace
    , encodeAuth
    , loadUserWorkspaces
    , loadWorkspaceChannels
    , loadWorkspaceDetails
    )

import Duration exposing (Duration)
import Effect.Http as Http
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as Encode
import Url.Builder



-- AUTHENTICATION


type SlackAuth
    = BotToken String
    | UserToken String


encodeAuth : SlackAuth -> String
encodeAuth auth =
    case auth of
        BotToken token ->
            "Bearer " ++ token

        UserToken token ->
            "Bearer " ++ token



-- DATA STRUCTURES


type alias SlackWorkspace =
    { id : String
    , name : String
    , domain : String
    , icon : Maybe String
    , isDeleted : Bool
    }


type alias SlackChannel =
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


type alias SlackUser =
    { id : String
    , name : String
    , realName : Maybe String
    , displayName : Maybe String
    , email : Maybe String
    , isBot : Bool
    , isDeleted : Bool
    , profile : Maybe SlackUserProfile
    }


type alias SlackUserProfile =
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


loadUserWorkspaces : SlackAuth -> Task restriction HttpError (List SlackWorkspace)
loadUserWorkspaces auth =
    let
        url =
            Url.Builder.crossOrigin "https://slack.com" [ "api", "auth.teams.list" ] []
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" (encodeAuth auth) ]
        , url = url
        , body = Http.emptyBody
        , resolver = Http.stringResolver (handleSlackResponse decodeWorkspacesList)
        , timeout = Just (Duration.seconds 30)
        }


loadWorkspaceDetails : SlackAuth -> String -> Task restriction HttpError SlackWorkspace
loadWorkspaceDetails auth teamId =
    let
        url =
            Url.Builder.crossOrigin "https://slack.com" [ "api", "team.info" ] []

        body =
            Http.stringBody "application/x-www-form-urlencoded" ("team=" ++ teamId)
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" (encodeAuth auth) ]
        , url = url
        , body = body
        , resolver = Http.stringResolver (handleSlackResponse decodeWorkspaceDetails)
        , timeout = Just (Duration.seconds 30)
        }


loadWorkspaceChannels : SlackAuth -> String -> Task restriction HttpError (List SlackChannel)
loadWorkspaceChannels auth teamId =
    let
        url =
            Url.Builder.crossOrigin "https://slack.com" [ "api", "conversations.list" ] []

        body =
            Http.stringBody "application/x-www-form-urlencoded" ("team_id=" ++ teamId ++ "&types=public_channel,private_channel,mpim,im")
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" (encodeAuth auth) ]
        , url = url
        , body = body
        , resolver = Http.stringResolver (handleSlackResponse decodeChannelsList)
        , timeout = Just (Duration.seconds 30)
        }



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



-- DECODERS


decodeWorkspacesList : Decoder (List SlackWorkspace)
decodeWorkspacesList =
    Decode.field "teams" (Decode.list decodeWorkspace)


decodeWorkspaceDetails : Decoder SlackWorkspace
decodeWorkspaceDetails =
    Decode.field "team" decodeWorkspace


decodeWorkspace : Decoder SlackWorkspace
decodeWorkspace =
    Decode.map5 SlackWorkspace
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "domain" Decode.string)
        (Decode.maybe (Decode.field "icon" (Decode.field "image_68" Decode.string)))
        (Decode.field "deleted" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))


decodeChannelsList : Decoder (List SlackChannel)
decodeChannelsList =
    Decode.field "channels" (Decode.list decodeChannel)


decodeChannel : Decoder SlackChannel
decodeChannel =
    Decode.succeed SlackChannel
        |> andMap (Decode.field "id" Decode.string)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.field "is_channel" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "is_group" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "is_im" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "is_member" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "is_archived" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.maybe (Decode.field "topic" (Decode.field "value" Decode.string)))
        |> andMap (Decode.maybe (Decode.field "purpose" (Decode.field "value" Decode.string)))


decodeUser : Decoder SlackUser
decodeUser =
    Decode.succeed SlackUser
        |> andMap (Decode.field "id" Decode.string)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.maybe (Decode.field "real_name" Decode.string))
        |> andMap (Decode.maybe (Decode.field "profile" (Decode.field "display_name" Decode.string)))
        |> andMap (Decode.maybe (Decode.field "profile" (Decode.field "email" Decode.string)))
        |> andMap (Decode.field "is_bot" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.field "deleted" Decode.bool |> Decode.maybe |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.maybe (Decode.field "profile" decodeUserProfile))


decodeUserProfile : Decoder SlackUserProfile
decodeUserProfile =
    Decode.map4 SlackUserProfile
        (Decode.maybe (Decode.field "avatar_hash" Decode.string))
        (Decode.maybe (Decode.field "image_72" Decode.string))
        (Decode.maybe (Decode.field "image_192" Decode.string))
        (Decode.maybe (Decode.field "image_512" Decode.string))
