module Slack exposing
    ( Channel
    , ChannelId
    , DmChannel
    , DmChannelId
    , HttpError(..)
    , Id(..)
    , SlackCookie
    , SlackData
    , SlackToken
    , Team
    , TeamId
    , UserBoot
    , UserId
    , httpErrorToString
    , idToString
    , stringToSlackCookie
    , teamsJsonToSlackTokens
    , userBoot
    , userConversations
    , validateSlackData
    )

import Duration
import Effect.Command exposing (BackendOnly)
import Effect.Http as Http
import Effect.Task as Task exposing (Task)
import FileStatus
import Json.Decode as Decode exposing (Decoder)
import Json.Encode
import List.Nonempty exposing (Nonempty(..))
import NonemptySet exposing (NonemptySet)
import SecretId exposing (SecretId, ServerSecret)
import Url



-- AUTHENTICATION


type SlackToken
    = SlackToken String


w3_validate_SlackToken : SlackToken -> Result String ()
w3_validate_SlackToken (SlackToken text) =
    stringToSlackToken text |> Result.map (\_ -> ())


type SlackCookie
    = SlackCookie String


w3_validate_SlackCookie : SlackCookie -> Result String ()
w3_validate_SlackCookie (SlackCookie text) =
    stringToSlackCookie text |> Result.map (\_ -> ())


type alias SlackData =
    { cookie : SlackCookie
    , tokens : Nonempty SlackToken
    }


validateSlackData : { a | slackCookie : String, slackTeamsJson : String } -> Result () SlackData
validateSlackData { slackCookie, slackTeamsJson } =
    case ( stringToSlackCookie slackCookie, teamsJsonToSlackTokens slackTeamsJson ) of
        ( Ok cookie, Ok tokens ) ->
            Ok { cookie = cookie, tokens = tokens }

        _ ->
            Err ()


stringToSlackToken : String -> Result String SlackToken
stringToSlackToken text =
    if String.startsWith "xoxc-" text then
        if String.length text < 10 then
            Err "Token is too short"

        else
            Ok (SlackToken text)

    else
        Err "Token must start with \"xoxc-\""


stringToSlackCookie : String -> Result String SlackCookie
stringToSlackCookie text =
    if String.startsWith "xoxd-" text then
        if String.length text < 10 then
            Err "Cookie is too short"

        else
            Ok (SlackCookie text)

    else
        Err "Cookie must start with \"xoxd-\""


{-| Parses the `teams` object in the Slack web client's `localStorage.localConfig_v2`. It has an
entry for every workspace the browser is signed into, each with its own token.
-}
teamsJsonToSlackTokens : String -> Result String (Nonempty SlackToken)
teamsJsonToSlackTokens text =
    case Decode.decodeString (Decode.keyValuePairs (Decode.field "token" Decode.string)) text of
        Ok teams ->
            case List.map (\( _, token ) -> stringToSlackToken token) teams |> resultCombine of
                Ok tokens ->
                    case List.Nonempty.fromList tokens of
                        Just nonempty ->
                            Ok nonempty

                        Nothing ->
                            Err "No workspaces found"

                Err error ->
                    Err error

        Err _ ->
            Err "This isn't the teams JSON"


resultCombine : List (Result e a) -> Result e (List a)
resultCombine =
    List.foldr (Result.map2 (::)) (Ok [])


type Id a
    = Id String


type UserId
    = UserId Never


type TeamId
    = TeamId Never


type ChannelId
    = ChannelId Never


type DmChannelId
    = DmChannelId Never


idToString : Id a -> String
idToString (Id id) =
    id



-- API


type HttpError
    = SlackError String
    | BadStatus Int String
    | BadBody String
    | Timeout
    | NetworkError
    | BadUrl String


httpErrorToString : HttpError -> String
httpErrorToString error =
    case error of
        SlackError text ->
            "Slack said " ++ text

        BadStatus status body ->
            "Status " ++ String.fromInt status ++ ": " ++ String.left 200 body

        BadBody text ->
            "Unexpected response: " ++ text

        Timeout ->
            "Timed out"

        NetworkError ->
            "Network error"

        BadUrl url ->
            "Bad url " ++ url


type alias Team =
    { id : Id TeamId
    , name : String
    , domain : String
    , icon : String
    }


type alias UserBoot =
    { self : { id : Id UserId, name : String }
    , team : Team
    }


userBoot : SecretId ServerSecret -> SlackCookie -> SlackToken -> Task BackendOnly HttpError UserBoot
userBoot secretKey cookie token =
    http
        secretKey
        cookie
        token
        "client.userBoot"
        []
        (Decode.map2
            UserBoot
            (Decode.field
                "self"
                (Decode.map2
                    (\id name -> { id = id, name = name })
                    (Decode.field "id" decodeId)
                    (Decode.field "name" Decode.string)
                )
            )
            (Decode.field "team" decodeTeam)
        )


decodeTeam : Decoder Team
decodeTeam =
    Decode.map4
        Team
        (Decode.field "id" decodeId)
        (Decode.field "name" Decode.string)
        (Decode.field "domain" Decode.string)
        (Decode.at [ "icon", "image_132" ] Decode.string)


type alias Channel =
    { id : Id ChannelId
    , name : String
    , isPrivate : Bool
    }


type alias DmChannel =
    { id : Id DmChannelId
    , members : NonemptySet (Id UserId)
    }


type Conversation
    = ChannelConversation Channel
    | DmConversation { id : Id DmChannelId, user : Id UserId }
    | GroupDmConversation (Id DmChannelId)


{-| Every channel, DM and group DM the user is in, archived ones left out.
-}
userConversations :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id UserId
    -> Task BackendOnly HttpError { channels : List Channel, dmChannels : List DmChannel }
userConversations secretKey cookie token selfId =
    userConversationsHelper secretKey cookie token Nothing []
        |> Task.andThen
            (\conversations ->
                List.filterMap
                    (\conversation ->
                        case conversation of
                            ChannelConversation _ ->
                                Nothing

                            DmConversation { id, user } ->
                                Task.succeed { id = id, members = NonemptySet.fromNonemptyList (Nonempty selfId [ user ]) }
                                    |> Just

                            GroupDmConversation id ->
                                groupDmMembers secretKey cookie token id
                                    |> Task.map
                                        (\members -> { id = id, members = NonemptySet.fromNonemptyList (Nonempty selfId members) })
                                    |> Just
                    )
                    conversations
                    |> Task.sequence
                    |> Task.map
                        (\dmChannels ->
                            { channels =
                                List.filterMap
                                    (\conversation ->
                                        case conversation of
                                            ChannelConversation channel ->
                                                Just channel

                                            DmConversation _ ->
                                                Nothing

                                            GroupDmConversation _ ->
                                                Nothing
                                    )
                                    conversations
                            , dmChannels = dmChannels
                            }
                        )
            )


userConversationsHelper :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Maybe String
    -> List Conversation
    -> Task BackendOnly HttpError (List Conversation)
userConversationsHelper secretKey cookie token cursor conversationsSoFar =
    http
        secretKey
        cookie
        token
        "users.conversations"
        (( "types", "public_channel,private_channel,mpim,im" )
            :: ( "exclude_archived", "true" )
            :: ( "limit", "200" )
            :: cursorParameter cursor
        )
        (Decode.map2
            Tuple.pair
            (Decode.field "channels" (Decode.list decodeConversation))
            decodeNextCursor
        )
        |> Task.andThen
            (\( conversations, nextCursor ) ->
                case nextCursor of
                    Just nextCursor2 ->
                        userConversationsHelper secretKey cookie token (Just nextCursor2) (conversationsSoFar ++ conversations)

                    Nothing ->
                        Task.succeed (conversationsSoFar ++ conversations)
            )


groupDmMembers : SecretId ServerSecret -> SlackCookie -> SlackToken -> Id DmChannelId -> Task BackendOnly HttpError (List (Id UserId))
groupDmMembers secretKey cookie token channelId =
    groupDmMembersHelper secretKey cookie token channelId Nothing []


groupDmMembersHelper :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id DmChannelId
    -> Maybe String
    -> List (Id UserId)
    -> Task BackendOnly HttpError (List (Id UserId))
groupDmMembersHelper secretKey cookie token channelId cursor membersSoFar =
    http
        secretKey
        cookie
        token
        "conversations.members"
        (( "channel", idToString channelId ) :: ( "limit", "200" ) :: cursorParameter cursor)
        (Decode.map2
            Tuple.pair
            (Decode.field "members" (Decode.list decodeId))
            decodeNextCursor
        )
        |> Task.andThen
            (\( members, nextCursor ) ->
                case nextCursor of
                    Just nextCursor2 ->
                        groupDmMembersHelper secretKey cookie token channelId (Just nextCursor2) (membersSoFar ++ members)

                    Nothing ->
                        Task.succeed (membersSoFar ++ members)
            )


decodeConversation : Decoder Conversation
decodeConversation =
    Decode.map2
        Tuple.pair
        (optionalBool "is_im")
        (optionalBool "is_mpim")
        |> Decode.andThen
            (\( isIm, isMpim ) ->
                if isIm then
                    Decode.map2
                        (\id user -> DmConversation { id = id, user = user })
                        (Decode.field "id" decodeId)
                        (Decode.field "user" decodeId)

                else if isMpim then
                    Decode.map GroupDmConversation (Decode.field "id" decodeId)

                else
                    Decode.map3
                        (\id name isPrivate -> ChannelConversation { id = id, name = name, isPrivate = isPrivate })
                        (Decode.field "id" decodeId)
                        (Decode.field "name" Decode.string)
                        (optionalBool "is_private")
            )


optionalBool : String -> Decoder Bool
optionalBool field =
    Decode.oneOf [ Decode.field field Decode.bool, Decode.succeed False ]


cursorParameter : Maybe String -> List ( String, String )
cursorParameter cursor =
    case cursor of
        Just cursor2 ->
            [ ( "cursor", cursor2 ) ]

        Nothing ->
            []


{-| Slack sends an empty string once there are no more pages.
-}
decodeNextCursor : Decoder (Maybe String)
decodeNextCursor =
    Decode.oneOf
        [ Decode.at [ "response_metadata", "next_cursor" ] Decode.string
            |> Decode.map
                (\cursor ->
                    if cursor == "" then
                        Nothing

                    else
                        Just cursor
                )
        , Decode.succeed Nothing
        ]


{-| Goes through the Rust server since Slack needs the `d` cookie, and browsers and the Lamdera
backend won't send one.
-}
http :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> String
    -> List ( String, String )
    -> Decoder a
    -> Task BackendOnly HttpError a
http secretKey (SlackCookie cookie) (SlackToken token) method parameters decoder =
    Http.task
        { method = "POST"
        , headers = [ FileStatus.secretKeyHeader secretKey ]
        , url = FileStatus.domain ++ "/file/internal/custom-request"
        , body =
            Json.Encode.object
                [ ( "method", Json.Encode.string "POST" )
                , ( "url", Json.Encode.string ("https://slack.com/api/" ++ method) )
                , ( "headers"
                  , Json.Encode.list
                        (\( key, value ) ->
                            Json.Encode.object
                                [ ( "key", Json.Encode.string key )
                                , ( "value", Json.Encode.string value )
                                ]
                        )
                        [ ( "Content-Type", "application/x-www-form-urlencoded" )
                        , ( "Cookie", "d=" ++ cookie )
                        ]
                  )
                , ( "body"
                  , ( "token", token )
                        :: parameters
                        |> List.map (\( key, value ) -> key ++ "=" ++ Url.percentEncode value)
                        |> String.join "&"
                        |> Json.Encode.string
                  )
                ]
                |> Http.jsonBody
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.BadUrl_ url ->
                            Err (BadUrl url)

                        Http.Timeout_ ->
                            Err Timeout

                        Http.NetworkError_ ->
                            Err NetworkError

                        Http.BadStatus_ metadata body ->
                            Err (BadStatus metadata.statusCode body)

                        Http.GoodStatus_ _ body ->
                            case Decode.decodeString (decodeResponse decoder) body of
                                Ok result ->
                                    result

                                Err error ->
                                    Err (BadBody (Decode.errorToString error))
                )
        , timeout = Just Duration.minute
        }


decodeResponse : Decoder a -> Decoder (Result HttpError a)
decodeResponse decoder =
    Decode.field "ok" Decode.bool
        |> Decode.andThen
            (\ok ->
                if ok then
                    Decode.map Ok decoder

                else
                    Decode.field "error" Decode.string |> Decode.map (\error -> Err (SlackError error))
            )


decodeId : Decoder (Id a)
decodeId =
    Decode.map Id Decode.string
