module Slack exposing
    ( Channel
    , ChannelId
    , DmChannel
    , DmChannelId
    , HttpError(..)
    , Id(..)
    , Message
    , MessageContent(..)
    , MessageId
    , RichTextElement(..)
    , RichTextInline(..)
    , SlackCookie
    , SlackData
    , SlackToken
    , Style
    , Team
    , TeamId
    , User
    , UserBoot
    , UserId
    , WebsocketEvent(..)
    , httpErrorToString
    , idToString
    , newestMessages
    , noStyle
    , parseWebsocketEvent
    , postMessage
    , stringToSlackCookie
    , teamsJsonToSlackTokens
    , userBoot
    , userConversations
    , users
    , validateSlackData
    , websocketRelayRequest
    , websocketRelayUrl
    )

import Duration
import Effect.Command exposing (BackendOnly)
import Effect.Http as Http
import Effect.Process as Process
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Env
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


{-| A message's `ts`, which only identifies it within its channel.
-}
type MessageId
    = MessageId Never


idToString : Id a -> String
idToString (Id id) =
    id



-- API


type HttpError
    = SlackError String
    | RateLimited
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

        RateLimited ->
            "Rate limited"

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
    { self : User
    , team : Team
    }


type alias User =
    { id : Id UserId
    , teamId : Id TeamId
    , name : String
    , realName : String
    , displayName : String
    , image : String
    , isBot : Bool
    , deleted : Bool
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
            (Decode.field "self" decodeUser)
            (Decode.field "team" decodeTeam)
        )


decodeUser : Decoder User
decodeUser =
    Decode.map8
        User
        (Decode.field "id" decodeId)
        (Decode.field "team_id" decodeId)
        (Decode.field "name" Decode.string)
        (optionalString [ "profile", "real_name" ])
        (optionalString [ "profile", "display_name" ])
        (optionalString [ "profile", "image_72" ])
        (optionalBool "is_bot")
        (optionalBool "deleted")


optionalString : List String -> Decoder String
optionalString path =
    Decode.oneOf [ Decode.at path Decode.string, Decode.succeed "" ]


{-| Everyone in the workspace, deleted users included since they can still have written messages.
-}
users : SecretId ServerSecret -> SlackCookie -> SlackToken -> Task BackendOnly HttpError (List User)
users secretKey cookie token =
    usersHelper secretKey cookie token Nothing []


usersHelper :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Maybe String
    -> List User
    -> Task BackendOnly HttpError (List User)
usersHelper secretKey cookie token cursor usersSoFar =
    http
        secretKey
        cookie
        token
        "users.list"
        (( "limit", "200" ) :: cursorParameter cursor)
        (Decode.map2
            Tuple.pair
            (Decode.field "members" (Decode.list decodeUser))
            decodeNextCursor
        )
        |> retryWhenRateLimited
        |> Task.andThen
            (\( users2, nextCursor ) ->
                case nextCursor of
                    Just nextCursor2 ->
                        usersHelper secretKey cookie token (Just nextCursor2) (usersSoFar ++ users2)

                    Nothing ->
                        Task.succeed (usersSoFar ++ users2)
            )


decodeTeam : Decoder Team
decodeTeam =
    Decode.map4
        Team
        (Decode.field "id" decodeId)
        (Decode.field "name" Decode.string)
        (Decode.field "domain" Decode.string)
        (Decode.at [ "icon", "image_132" ] Decode.string)


type alias Message =
    { id : Id MessageId
    , createdAt : Time.Posix
    , user : Id UserId
    , content : MessageContent
    }


type MessageContent
    = TextMessage { text : String, blocks : List RichTextElement }
    | JoinedChannel


type RichTextElement
    = RichTextSection (List RichTextInline)
    | RichTextPreformatted (List RichTextInline)
    | RichTextQuote (List RichTextInline)
    | RichTextList (List (List RichTextInline))


type RichTextInline
    = RichText_Text { text : String, style : Style }
    | RichText_Link { url : String, text : String, style : Style }
    | RichText_Emoji { name : String, unicode : String, style : Style }
    | RichText_User (Id UserId)
    | RichText_Channel (Id ChannelId)
    | RichText_Broadcast String
    | RichText_Date { timestamp : Int, fallback : String }


type alias Style =
    { bold : Bool
    , italic : Bool
    , strike : Bool
    , code : Bool
    }


{-| The newest messages first. Messages Slack hides on the free plan are included, and anything that
fails to load gives an empty list rather than failing everything else being loaded.
-}
newestMessages :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Int
    -> Id channelId
    -> Task BackendOnly x (List Message)
newestMessages secretKey cookie token limit channelId =
    http
        secretKey
        cookie
        token
        "conversations.history"
        [ ( "channel", idToString channelId )
        , ( "limit", String.fromInt limit )
        , ( "include_free_team_extra_messages", "true" )
        ]
        (Decode.field "messages" (Decode.list (Decode.maybe decodeMessage))
            |> Decode.map (List.filterMap identity)
        )
        |> retryWhenRateLimited
        |> Task.onError (\_ -> Task.succeed [])


{-| Returns the ts Slack gave the message, which is also its id. The text is only what notifications
show, the blocks are what Slack displays.
-}
postMessage :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> String
    -> List RichTextElement
    -> Task BackendOnly HttpError (Id MessageId)
postMessage secretKey cookie token channelId text blocks =
    http
        secretKey
        cookie
        token
        "chat.postMessage"
        [ ( "channel", idToString channelId )
        , ( "text", text )
        , ( "blocks"
          , Json.Encode.list
                identity
                [ Json.Encode.object
                    [ ( "type", Json.Encode.string "rich_text" )
                    , ( "elements", Json.Encode.list encodeRichTextElement blocks )
                    ]
                ]
                |> Json.Encode.encode 0
          )
        ]
        (Decode.field "ts" decodeId)


encodeRichTextElement : RichTextElement -> Json.Encode.Value
encodeRichTextElement element =
    case element of
        RichTextSection inlines ->
            encodeRichTextElementHelper "rich_text_section" inlines

        RichTextPreformatted inlines ->
            encodeRichTextElementHelper "rich_text_preformatted" inlines

        RichTextQuote inlines ->
            encodeRichTextElementHelper "rich_text_quote" inlines

        RichTextList items ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "rich_text_list" )
                , ( "style", Json.Encode.string "bullet" )
                , ( "elements", Json.Encode.list (encodeRichTextElementHelper "rich_text_section") items )
                ]


encodeRichTextElementHelper : String -> List RichTextInline -> Json.Encode.Value
encodeRichTextElementHelper elementType inlines =
    Json.Encode.object
        [ ( "type", Json.Encode.string elementType )
        , ( "elements", Json.Encode.list encodeInline inlines )
        ]


encodeInline : RichTextInline -> Json.Encode.Value
encodeInline inline =
    case inline of
        RichText_Text { text, style } ->
            Json.Encode.object
                (( "type", Json.Encode.string "text" )
                    :: ( "text", Json.Encode.string text )
                    :: encodeStyle style
                )

        RichText_Link { url, text, style } ->
            Json.Encode.object
                (( "type", Json.Encode.string "link" )
                    :: ( "url", Json.Encode.string url )
                    :: (if text == "" then
                            encodeStyle style

                        else
                            ( "text", Json.Encode.string text ) :: encodeStyle style
                       )
                )

        RichText_Emoji { name, unicode, style } ->
            Json.Encode.object
                (( "type", Json.Encode.string "emoji" )
                    :: ( "name", Json.Encode.string name )
                    :: ( "unicode", Json.Encode.string unicode )
                    :: encodeStyle style
                )

        RichText_User userId ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "user" )
                , ( "user_id", Json.Encode.string (idToString userId) )
                ]

        RichText_Channel channelId ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "channel" )
                , ( "channel_id", Json.Encode.string (idToString channelId) )
                ]

        RichText_Broadcast range ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "broadcast" )
                , ( "range", Json.Encode.string range )
                ]

        RichText_Date { timestamp, fallback } ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "date" )
                , ( "timestamp", Json.Encode.int timestamp )
                , ( "format", Json.Encode.string "{date_short_pretty} at {time}" )
                , ( "fallback", Json.Encode.string fallback )
                ]


encodeStyle : Style -> List ( String, Json.Encode.Value )
encodeStyle style =
    if style == noStyle then
        []

    else
        [ ( "style"
          , Json.Encode.object
                [ ( "bold", Json.Encode.bool style.bold )
                , ( "italic", Json.Encode.bool style.italic )
                , ( "strike", Json.Encode.bool style.strike )
                , ( "code", Json.Encode.bool style.code )
                ]
          )
        ]


noStyle : Style
noStyle =
    { bold = False, italic = False, strike = False, code = False }


{-| Messages without a user (posted by integrations) and kinds of message at-chat has nothing to
show for fail to decode.
-}
decodeMessage : Decoder Message
decodeMessage =
    Decode.map4
        Message
        (Decode.field "ts" decodeId)
        (Decode.field "ts" decodeTimestamp)
        (Decode.field "user" decodeId)
        (Decode.oneOf [ Decode.field "subtype" Decode.string, Decode.succeed "" ]
            |> Decode.andThen
                (\subtype ->
                    if List.member subtype [ "", "thread_broadcast", "file_share", "me_message" ] then
                        Decode.map2
                            (\text blocks -> TextMessage { text = text, blocks = blocks })
                            (Decode.oneOf [ Decode.field "text" Decode.string, Decode.succeed "" ])
                            (Decode.oneOf
                                [ Decode.field "blocks" (Decode.list decodeBlock) |> Decode.map List.concat
                                , Decode.succeed []
                                ]
                            )

                    else if subtype == "channel_join" then
                        Decode.succeed JoinedChannel

                    else
                        Decode.fail ("Unsupported subtype " ++ subtype)
                )
        )



-- WEBSOCKET


{-| Slack's websocket refuses connections that don't carry the d cookie and Effect.Websocket can't
set headers, so the backend connects to a relay on the Rust server instead
(rust-server/src/websocket\_relay.rs). The relay says it's ready, is sent websocketRelayRequest, and
from then on passes every message between the backend and Slack unchanged.
-}
websocketRelayUrl : String
websocketRelayUrl =
    (if String.startsWith "https://" rustServerDomain then
        "wss://" ++ String.dropLeft 8 rustServerDomain

     else
        "ws://" ++ String.dropLeft 7 rustServerDomain
    )
        ++ "/file/websocket-relay"


websocketRelayRequest : SecretId ServerSecret -> SlackCookie -> SlackToken -> String
websocketRelayRequest secretKey (SlackCookie cookie) (SlackToken token) =
    Json.Encode.object
        [ ( "secretKey", Json.Encode.string (SecretId.toString secretKey) )
        , ( "url", Json.Encode.string ("wss://wss-primary.slack.com/?token=" ++ Url.percentEncode token) )
        , ( "headers"
          , Json.Encode.list
                (\( key, value ) -> Json.Encode.list Json.Encode.string [ key, value ])
                [ ( "Cookie", "d=" ++ cookie )
                , ( "Origin", "https://app.slack.com" )
                ]
          )
        ]
        |> Json.Encode.encode 0


{-| The channel is a String since it can be a channel or a DM.
-}
type WebsocketEvent
    = WebsocketRelayReady
    | WebsocketMessageCreated String Message
    | WebsocketMessageChanged String Message Time.Posix
    | WebsocketMessageDeleted String (Id UserId) (Id MessageId)
    | WebsocketOtherEvent


parseWebsocketEvent : String -> WebsocketEvent
parseWebsocketEvent text =
    if text == "relay_ready" then
        WebsocketRelayReady

    else
        case Decode.decodeString decodeWebsocketEvent text of
            Ok event ->
                event

            Err _ ->
                WebsocketOtherEvent


{-| Thread replies are left out since threads aren't supported yet.
-}
decodeWebsocketEvent : Decoder WebsocketEvent
decodeWebsocketEvent =
    Decode.map2 Tuple.pair
        (Decode.field "type" Decode.string)
        (Decode.oneOf [ Decode.field "subtype" Decode.string, Decode.succeed "" ])
        |> Decode.andThen
            (\( eventType, subtype ) ->
                if eventType /= "message" then
                    Decode.succeed WebsocketOtherEvent

                else if subtype == "message_changed" then
                    Decode.map3
                        WebsocketMessageChanged
                        (Decode.field "channel" Decode.string)
                        (Decode.field "message" decodeMessage)
                        (Decode.oneOf
                            [ Decode.at [ "message", "edited", "ts" ] decodeTimestamp
                            , Decode.field "event_ts" decodeTimestamp
                            ]
                        )

                else if subtype == "message_deleted" then
                    Decode.map3
                        WebsocketMessageDeleted
                        (Decode.field "channel" Decode.string)
                        (Decode.at [ "previous_message", "user" ] decodeId)
                        (Decode.field "deleted_ts" decodeId)

                else
                    Decode.map3
                        (\channel message isThreadReply ->
                            if isThreadReply then
                                WebsocketOtherEvent

                            else
                                WebsocketMessageCreated channel message
                        )
                        (Decode.field "channel" Decode.string)
                        decodeMessage
                        (Decode.map2
                            (\ts maybeThreadTs ->
                                case maybeThreadTs of
                                    Just threadTs ->
                                        threadTs /= ts && subtype /= "thread_broadcast"

                                    Nothing ->
                                        False
                            )
                            (Decode.field "ts" Decode.string)
                            (Decode.maybe (Decode.field "thread_ts" Decode.string))
                        )
            )


decodeTimestamp : Decoder Time.Posix
decodeTimestamp =
    Decode.string
        |> Decode.andThen
            (\text ->
                case String.toFloat text of
                    Just seconds ->
                        Time.millisToPosix (round (seconds * 1000)) |> Decode.succeed

                    Nothing ->
                        Decode.fail ("Invalid timestamp " ++ text)
            )


{-| Only rich\_text blocks are kept, they are what people's messages are written in.
-}
decodeBlock : Decoder (List RichTextElement)
decodeBlock =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\blockType ->
                if blockType == "rich_text" then
                    Decode.field "elements" (Decode.list (Decode.maybe decodeRichTextElement))
                        |> Decode.map (List.filterMap identity)

                else
                    Decode.succeed []
            )


decodeRichTextElement : Decoder RichTextElement
decodeRichTextElement =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\elementType ->
                case elementType of
                    "rich_text_section" ->
                        Decode.map RichTextSection decodeInlines

                    "rich_text_preformatted" ->
                        Decode.map RichTextPreformatted decodeInlines

                    "rich_text_quote" ->
                        Decode.map RichTextQuote decodeInlines

                    "rich_text_list" ->
                        Decode.field "elements" (Decode.list decodeInlines) |> Decode.map RichTextList

                    _ ->
                        Decode.fail ("Unsupported rich text element " ++ elementType)
            )


decodeInlines : Decoder (List RichTextInline)
decodeInlines =
    Decode.field "elements" (Decode.list (Decode.maybe decodeInline))
        |> Decode.map (List.filterMap identity)


decodeInline : Decoder RichTextInline
decodeInline =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\inlineType ->
                case inlineType of
                    "text" ->
                        Decode.map2
                            (\text style -> RichText_Text { text = text, style = style })
                            (Decode.field "text" Decode.string)
                            decodeStyle

                    "link" ->
                        Decode.map3
                            (\url text style -> RichText_Link { url = url, text = text, style = style })
                            (Decode.field "url" Decode.string)
                            (optionalString [ "text" ])
                            decodeStyle

                    "emoji" ->
                        Decode.map3
                            (\name unicode style -> RichText_Emoji { name = name, unicode = unicode, style = style })
                            (Decode.field "name" Decode.string)
                            (optionalString [ "unicode" ])
                            decodeStyle

                    "user" ->
                        Decode.map RichText_User (Decode.field "user_id" decodeId)

                    "channel" ->
                        Decode.map RichText_Channel (Decode.field "channel_id" decodeId)

                    "broadcast" ->
                        Decode.map RichText_Broadcast (Decode.field "range" Decode.string)

                    "date" ->
                        Decode.map2
                            (\timestamp fallback -> RichText_Date { timestamp = timestamp, fallback = fallback })
                            (Decode.field "timestamp" Decode.int)
                            (optionalString [ "fallback" ])

                    _ ->
                        Decode.fail ("Unsupported rich text inline " ++ inlineType)
            )


decodeStyle : Decoder Style
decodeStyle =
    Decode.oneOf
        [ Decode.field
            "style"
            (Decode.map4
                Style
                (optionalBool "bold")
                (optionalBool "italic")
                (optionalBool "strike")
                (optionalBool "code")
            )
        , Decode.succeed noStyle
        ]


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
        |> retryWhenRateLimited
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
        |> retryWhenRateLimited
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


{-| The Rust server doesn't pass Slack's Retry-After header back, so this waits long enough for
Slack's per minute limits to reset.
-}
retryWhenRateLimited : Task BackendOnly HttpError a -> Task BackendOnly HttpError a
retryWhenRateLimited task =
    retryWhenRateLimitedHelper 3 task


retryWhenRateLimitedHelper : Int -> Task BackendOnly HttpError a -> Task BackendOnly HttpError a
retryWhenRateLimitedHelper retriesLeft task =
    Task.onError
        (\error ->
            case error of
                RateLimited ->
                    if retriesLeft > 0 then
                        Process.sleep (Duration.seconds 30)
                            |> Task.andThen (\() -> retryWhenRateLimitedHelper (retriesLeft - 1) task)

                    else
                        Task.fail error

                SlackError _ ->
                    Task.fail error

                BadStatus _ _ ->
                    Task.fail error

                BadBody _ ->
                    Task.fail error

                Timeout ->
                    Task.fail error

                NetworkError ->
                    Task.fail error

                BadUrl _ ->
                    Task.fail error
        )
        task


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
        , headers = [ Http.header "x-secret-key" (SecretId.toString secretKey) ]
        , url = rustServerDomain ++ "/file/internal/custom-request"
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
                            if metadata.statusCode == 429 then
                                Err RateLimited

                            else
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


{-| Same as FileStatus.domain. Slack can't import FileStatus since that would be an import cycle through Id.
-}
rustServerDomain : String
rustServerDomain =
    if Env.isProduction then
        Env.domain

    else
        "http://localhost:3000"
