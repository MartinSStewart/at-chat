module Slack exposing
    ( Channel
    , ChannelId
    , DmChannel
    , DmChannelId
    , File
    , FileId
    , History
    , HttpError(..)
    , Id(..)
    , InThread(..)
    , Message
    , MessageContent(..)
    , MessageId
    , Reaction
    , RichTextElement(..)
    , RichTextInline(..)
    , SlackCookie(..)
    , SlackData
    , SlackToken(..)
    , Style
    , Team
    , TeamId
    , User
    , UserBoot
    , UserId
    , WebsocketEvent(..)
    , addReaction
    , deleteMessage
    , fileHeaders
    , history
    , httpErrorToString
    , idToString
    , isHostedBySlack
    , messageFiles
    , messageUserIds
    , messagesSince
    , noStyle
    , parseWebsocketEvent
    , postMessage
    , postMessageWithFiles
    , removeReaction
    , stringToSlackCookie
    , teamsJsonToSlackTokens
    , updateMessage
    , userBoot
    , userConversations
    , userInfo
    , usersById
    , validateSlackData
    , websocketRelayRequest
    , websocketRelayUrl
    )

import Bytes exposing (Bytes)
import Duration
import Effect.Command exposing (BackendOnly)
import Effect.Http as Http
import Effect.Process as Process
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Env
import Json.Decode as Decode exposing (Decoder)
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import NonemptySet exposing (NonemptySet)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import Url



-- AUTHENTICATION


{-| OpaqueVariants
-}
type SlackToken
    = SlackToken String


w3_validate_SlackToken : SlackToken -> Result String ()
w3_validate_SlackToken (SlackToken text) =
    stringToSlackToken text |> Result.map (\_ -> ())


{-| OpaqueVariants
-}
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


type FileId
    = FileId Never


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


{-| The icon is left out when the workspace hasn't picked one and Slack would show a generic
picture.
-}
type alias Team =
    { id : Id TeamId
    , name : String
    , domain : String
    , icon : Maybe String
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
    Decode.map2 Tuple.pair (Decode.field "id" decodeId) (Decode.field "team_id" decodeId)
        |> Decode.andThen (\( userId, teamId ) -> decodeUserHelper userId teamId)


decodeUserHelper : Id UserId -> Id TeamId -> Decoder User
decodeUserHelper userId teamId =
    Decode.map6
        (User userId teamId)
        (Decode.field "name" Decode.string)
        (optionalString [ "profile", "real_name" ])
        (optionalString [ "profile", "display_name" ])
        (decodeUserImage userId teamId)
        (optionalBool "is_bot")
        (optionalBool "deleted")


{-| client.userBoot and the edge API leave out the image\_ urls but give an avatar\_hash, which
Slack's avatar CDN serves the picture from.
-}
decodeUserImage : Id UserId -> Id TeamId -> Decoder String
decodeUserImage (Id userId) (Id teamId) =
    Decode.oneOf
        [ Decode.at [ "profile", "image_192" ] Decode.string
        , Decode.at [ "profile", "avatar_hash" ] Decode.string
            |> Decode.map (\hash -> "https://ca.slack-edge.com/" ++ teamId ++ "-" ++ userId ++ "-" ++ hash ++ "-192")
        , Decode.succeed ""
        ]


optionalString : List String -> Decoder String
optionalString path =
    Decode.oneOf [ Decode.at path Decode.string, Decode.succeed "" ]


userInfo : SecretId ServerSecret -> SlackCookie -> SlackToken -> Id UserId -> Task BackendOnly HttpError User
userInfo secretKey cookie token userId =
    http
        secretKey
        cookie
        token
        "users.info"
        [ ( "user", idToString userId ) ]
        (Decode.field "user" decodeUser)
        |> retryWhenRateLimited


{-| Loads many users at once through the edge API Slack's web client uses. It isn't documented, so
if a batch fails we look its users up one at a time with users.info instead. Users that can't be
loaded either way are left out.
-}
usersById :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id TeamId
    -> List (Id UserId)
    -> Task BackendOnly x (List User)
usersById secretKey cookie token teamId userIds =
    List.Extra.greedyGroupsOf 100 userIds
        |> List.map
            (\batch ->
                edgeUsersInfo secretKey cookie token teamId batch
                    |> Task.onError
                        (\_ ->
                            List.map
                                (\userId ->
                                    userInfo secretKey cookie token userId
                                        |> Task.map Just
                                        |> Task.onError (\_ -> Task.succeed Nothing)
                                )
                                batch
                                |> Task.sequence
                                |> Task.map (List.filterMap identity)
                        )
            )
        |> Task.sequence
        |> Task.map List.concat


edgeUsersInfo :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id TeamId
    -> List (Id UserId)
    -> Task BackendOnly HttpError (List User)
edgeUsersInfo secretKey (SlackCookie cookie) (SlackToken token) teamId userIds =
    Http.task
        { method = "POST"
        , headers = [ Http.header "x-secret-key" (SecretId.toString secretKey) ]
        , url = rustServerDomain ++ "/file/internal/custom-request"
        , body =
            Json.Encode.object
                [ ( "method", Json.Encode.string "POST" )
                , ( "url", Json.Encode.string ("https://edgeapi.slack.com/cache/" ++ idToString teamId ++ "/users/info") )
                , ( "headers"
                  , Json.Encode.list
                        (\( key, value ) ->
                            Json.Encode.object
                                [ ( "key", Json.Encode.string key )
                                , ( "value", Json.Encode.string value )
                                ]
                        )
                        [ ( "Content-Type", "application/json" )
                        , ( "Cookie", "d=" ++ cookie )
                        ]
                  )
                , ( "body"
                  , Json.Encode.object
                        [ ( "token", Json.Encode.string token )
                        , ( "check_interaction", Json.Encode.bool True )
                        , ( "updated_ids", Json.Encode.object (List.map (\userId -> ( idToString userId, Json.Encode.int 0 )) userIds) )
                        ]
                        |> Json.Encode.encode 0
                        |> Json.Encode.string
                  )
                ]
                |> Http.jsonBody
        , resolver = Http.stringResolver (resolveResponse (Decode.field "results" (Decode.list (decodeEdgeUser teamId)) |> Decode.map Ok))
        , timeout = Just Duration.minute
        }
        |> retryWhenRateLimited


{-| Same as decodeUser except the edge API might leave out team\_id.
-}
decodeEdgeUser : Id TeamId -> Decoder User
decodeEdgeUser teamId =
    Decode.map2
        Tuple.pair
        (Decode.field "id" decodeId)
        (Decode.oneOf [ Decode.field "team_id" decodeId, Decode.succeed teamId ])
        |> Decode.andThen (\( userId, teamId2 ) -> decodeUserHelper userId teamId2)


{-| Who wrote the message and everyone it mentions.
-}
messageUserIds : Message -> List (Id UserId)
messageUserIds message =
    case message.content of
        TextMessage { blocks } ->
            message.user
                :: List.concatMap
                    (\element ->
                        case element of
                            RichTextSection inlines ->
                                inlineUserIds inlines

                            RichTextPreformatted inlines ->
                                inlineUserIds inlines

                            RichTextQuote inlines ->
                                inlineUserIds inlines

                            RichTextList items ->
                                List.concatMap inlineUserIds items
                    )
                    blocks

        JoinedChannel ->
            [ message.user ]


inlineUserIds : List RichTextInline -> List (Id UserId)
inlineUserIds inlines =
    List.filterMap
        (\inline ->
            case inline of
                RichText_User userId ->
                    Just userId

                RichText_Text _ ->
                    Nothing

                RichText_Link _ ->
                    Nothing

                RichText_Emoji _ ->
                    Nothing

                RichText_Channel _ ->
                    Nothing

                RichText_Broadcast _ ->
                    Nothing

                RichText_Date _ ->
                    Nothing
        )
        inlines


decodeTeam : Decoder Team
decodeTeam =
    Decode.map4
        Team
        (Decode.field "id" decodeId)
        (Decode.field "name" Decode.string)
        (Decode.field "domain" Decode.string)
        (Decode.map2
            (\isDefault url ->
                if isDefault then
                    Nothing

                else
                    Just url
            )
            (Decode.oneOf [ Decode.at [ "icon", "image_default" ] Decode.bool, Decode.succeed False ])
            (Decode.at [ "icon", "image_132" ] Decode.string)
        )


type alias Message =
    { id : Id MessageId
    , createdAt : Time.Posix
    , user : Id UserId
    , content : MessageContent
    , inThread : InThread
    , replyCount : Int
    , reactions : List Reaction
    }


{-| Slack names the emoji rather than sending it.
-}
type alias Reaction =
    { name : String
    , users : List (Id UserId)
    }


{-| A thread's parent isn't in it, only its replies are. A reply that was also sent to the channel
shows up in both.
-}
type InThread
    = NotAReply
    | ReplyTo (Id MessageId)
    | BroadcastReplyTo (Id MessageId)


{-| A conversation's newest messages, and the replies of each of them that has a thread.
-}
type alias History =
    { messages : List Message
    , replies : SeqDict (Id MessageId) (List Message)
    }


type MessageContent
    = TextMessage { text : String, blocks : List RichTextElement, files : List File }
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


{-| Oldest first. Thread replies aren't included, only messages posted to the channel itself.
-}
messagesSince :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> Id MessageId
    -> Task BackendOnly x (List Message)
messagesSince secretKey cookie token channelId oldest =
    http
        secretKey
        cookie
        token
        "conversations.history"
        [ ( "channel", idToString channelId )
        , ( "oldest", idToString oldest )
        , ( "limit", "200" )
        , ( "include_free_team_extra_messages", "true" )
        ]
        (Decode.field "messages" (Decode.list (Decode.maybe decodeMessage))
            |> Decode.map (\messages -> List.filterMap identity messages |> List.reverse)
        )
        |> retryWhenRateLimited
        |> Task.onError (\_ -> Task.succeed [])


history :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Int
    -> Id channelId
    -> Task BackendOnly x History
history secretKey cookie token limit channelId =
    newestMessages secretKey cookie token limit channelId
        |> Task.andThen
            (\messages ->
                List.filterMap
                    (\message ->
                        if message.replyCount > 0 then
                            threadReplies secretKey cookie token channelId message.id
                                |> Task.map (Tuple.pair message.id)
                                |> Just

                        else
                            Nothing
                    )
                    messages
                    |> Task.sequence
                    |> Task.map (\replies -> { messages = messages, replies = SeqDict.fromList replies })
            )


{-| Oldest first. Slack includes the thread's parent, it's left out here.
-}
threadReplies :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> Id MessageId
    -> Task BackendOnly x (List Message)
threadReplies secretKey cookie token channelId threadId =
    http
        secretKey
        cookie
        token
        "conversations.replies"
        [ ( "channel", idToString channelId )
        , ( "ts", idToString threadId )
        , ( "limit", "1000" )
        , ( "include_free_team_extra_messages", "true" )
        ]
        (Decode.field "messages" (Decode.list (Decode.maybe decodeMessage))
            |> Decode.map (List.filterMap identity)
        )
        |> retryWhenRateLimited
        |> Task.map (List.filter (\message -> message.id /= threadId))
        |> Task.onError (\_ -> Task.succeed [])


{-| Returns the ts Slack gave the message, which is also its id. The text is only what notifications
show, the blocks are what Slack displays.
-}
postMessage :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> Maybe (Id MessageId)
    -> String
    -> List RichTextElement
    -> Task BackendOnly HttpError (Id MessageId)
postMessage secretKey cookie token channelId maybeThreadId text blocks =
    http
        secretKey
        cookie
        token
        "chat.postMessage"
        ([ ( "channel", idToString channelId )
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
            ++ (case maybeThreadId of
                    Just threadId ->
                        [ ( "thread_ts", idToString threadId ) ]

                    Nothing ->
                        []
               )
        )
        (Decode.field "ts" decodeId)


{-| Uploads the files and posts them as one message, like Slack's own app does. Slack shares the
files in the channel after it has answered, so the message's ts is looked up afterwards.
-}
postMessageWithFiles :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> Maybe (Id MessageId)
    -> List RichTextElement
    -> Nonempty { fileName : String, contentType : String, bytes : Bytes }
    -> Task BackendOnly HttpError ( Id MessageId, Nonempty (Id FileId) )
postMessageWithFiles secretKey cookie token channelId maybeThreadId blocks files =
    List.Nonempty.toList files
        |> List.map
            (\file ->
                http
                    secretKey
                    cookie
                    token
                    "files.getUploadURLExternal"
                    [ ( "filename", file.fileName ), ( "length", String.fromInt (Bytes.width file.bytes) ) ]
                    (Decode.map2 Tuple.pair (Decode.field "upload_url" Decode.string) (Decode.field "file_id" decodeId))
                    |> Task.andThen
                        (\( uploadUrl, fileId ) ->
                            Http.task
                                { method = "POST"
                                , headers = []
                                , url = uploadUrl
                                , body = Http.bytesBody file.contentType file.bytes
                                , resolver = Http.stringResolver resolveUpload
                                , timeout = Just Duration.minute
                                }
                                |> Task.map (\() -> ( fileId, file.fileName ))
                        )
            )
        |> Task.sequence
        |> Task.andThen
            (\uploaded ->
                case uploaded of
                    ( firstFileId, _ ) :: rest ->
                        http
                            secretKey
                            cookie
                            token
                            "files.completeUploadExternal"
                            ([ ( "files"
                               , Json.Encode.list
                                    (\( fileId, fileName ) ->
                                        Json.Encode.object
                                            [ ( "id", Json.Encode.string (idToString fileId) )
                                            , ( "title", Json.Encode.string fileName )
                                            ]
                                    )
                                    uploaded
                                    |> Json.Encode.encode 0
                               )
                             , ( "channel_id", idToString channelId )
                             ]
                                ++ (case maybeThreadId of
                                        Just threadId ->
                                            [ ( "thread_ts", idToString threadId ) ]

                                        Nothing ->
                                            []
                                   )
                                ++ (if List.isEmpty blocks then
                                        []

                                    else
                                        [ ( "blocks"
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
                                   )
                            )
                            (Decode.succeed ())
                            |> Task.andThen (\() -> sharedMessageId secretKey cookie token channelId firstFileId 5)
                            |> Task.map (\messageId -> ( messageId, Nonempty firstFileId (List.map Tuple.first rest) ))

                    [] ->
                        Task.fail (BadBody "No files to upload")
            )


{-| Slack answers an upload with plain text rather than JSON.
-}
resolveUpload : Http.Response String -> Result HttpError ()
resolveUpload response =
    case response of
        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            Err (BadStatus metadata.statusCode body)

        Http.GoodStatus_ _ _ ->
            Ok ()


{-| The ts of the message a file was shared in. Slack shares it a moment after the upload completes,
so this tries again a few times.
-}
sharedMessageId : SecretId ServerSecret -> SlackCookie -> SlackToken -> Id channelId -> Id FileId -> Int -> Task BackendOnly HttpError (Id MessageId)
sharedMessageId secretKey cookie token channelId fileId triesLeft =
    http
        secretKey
        cookie
        token
        "files.info"
        [ ( "file", idToString fileId ) ]
        (Decode.oneOf
            [ Decode.at [ "file", "shares" ] (Decode.keyValuePairs (Decode.keyValuePairs (Decode.list (Decode.field "ts" decodeId))))
            , Decode.succeed []
            ]
            |> Decode.map
                (\shares ->
                    List.concatMap Tuple.second shares
                        |> List.Extra.find (\( sharedIn, _ ) -> sharedIn == idToString channelId)
                        |> Maybe.andThen (\( _, messageIds ) -> List.head messageIds)
                )
        )
        |> Task.andThen
            (\maybeMessageId ->
                case maybeMessageId of
                    Just messageId ->
                        Task.succeed messageId

                    Nothing ->
                        if triesLeft > 1 then
                            Process.sleep Duration.second
                                |> Task.andThen (\() -> sharedMessageId secretKey cookie token channelId fileId (triesLeft - 1))

                        else
                            Task.fail (BadBody "The uploaded file wasn't shared in the channel")
            )


addReaction :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> Id MessageId
    -> String
    -> Task BackendOnly HttpError ()
addReaction secretKey cookie token channelId messageId name =
    http
        secretKey
        cookie
        token
        "reactions.add"
        [ ( "channel", idToString channelId ), ( "timestamp", idToString messageId ), ( "name", name ) ]
        (Decode.succeed ())
        |> retryWhenRateLimited


deleteMessage :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> Id MessageId
    -> Task BackendOnly HttpError ()
deleteMessage secretKey cookie token channelId messageId =
    http
        secretKey
        cookie
        token
        "chat.delete"
        [ ( "channel", idToString channelId ), ( "ts", idToString messageId ) ]
        (Decode.succeed ())
        |> retryWhenRateLimited


updateMessage :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> Id MessageId
    -> String
    -> List RichTextElement
    -> Task BackendOnly HttpError ()
updateMessage secretKey cookie token channelId messageId text blocks =
    http
        secretKey
        cookie
        token
        "chat.update"
        [ ( "channel", idToString channelId )
        , ( "ts", idToString messageId )
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
        (Decode.succeed ())
        |> retryWhenRateLimited


removeReaction :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> Id channelId
    -> Id MessageId
    -> String
    -> Task BackendOnly HttpError ()
removeReaction secretKey cookie token channelId messageId name =
    http
        secretKey
        cookie
        token
        "reactions.remove"
        [ ( "channel", idToString channelId ), ( "timestamp", idToString messageId ), ( "name", name ) ]
        (Decode.succeed ())
        |> retryWhenRateLimited


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


{-| A file attached to a message. Files that have been deleted, or that a free workspace hides
once they're too old, come without a url and are left out.
-}
type alias File =
    { id : Id FileId
    , name : String
    , mimetype : String
    , size : Int
    , url : String
    }


decodeFile : Decoder File
decodeFile =
    Decode.map5
        File
        (Decode.field "id" decodeId)
        (Decode.field "name" Decode.string)
        (Decode.oneOf [ Decode.field "mimetype" Decode.string, Decode.succeed "" ])
        (Decode.oneOf [ Decode.field "size" Decode.int, Decode.succeed 0 ])
        (Decode.field "url_private" Decode.string)


messageFiles : Message -> List File
messageFiles message =
    case message.content of
        TextMessage { files } ->
            files

        JoinedChannel ->
            []


{-| Remote files (Google Drive and the like, or anything an app adds with files.remote.add) have
whatever url whoever added them chose, and downloading one with `fileHeaders` would hand them the
credentials.
-}
isHostedBySlack : File -> Bool
isHostedBySlack file =
    case Url.fromString file.url of
        Just url ->
            url.protocol == Url.Https && url.host == "files.slack.com" && url.port_ == Nothing

        Nothing ->
            False


{-| Downloading a file from files.slack.com needs the same credentials as the API.
-}
fileHeaders : SlackCookie -> SlackToken -> List ( String, String )
fileHeaders (SlackCookie cookie) (SlackToken token) =
    [ ( "Cookie", "d=" ++ cookie ), ( "Authorization", "Bearer " ++ token ) ]


{-| Messages without a user (posted by integrations) and kinds of message at-chat has nothing to
show for fail to decode.
-}
decodeMessage : Decoder Message
decodeMessage =
    Decode.oneOf [ Decode.field "subtype" Decode.string, Decode.succeed "" ]
        |> Decode.andThen
            (\subtype ->
                Decode.map7
                    Message
                    (Decode.field "ts" decodeId)
                    (Decode.field "ts" decodeTimestamp)
                    (Decode.field "user" decodeId)
                    (if List.member subtype [ "", "thread_broadcast", "file_share", "me_message" ] then
                        Decode.map3
                            (\text blocks files -> TextMessage { text = text, blocks = blocks, files = files })
                            (Decode.oneOf [ Decode.field "text" Decode.string, Decode.succeed "" ])
                            (Decode.oneOf
                                [ Decode.field "blocks" (Decode.list decodeBlock) |> Decode.map List.concat
                                , Decode.succeed []
                                ]
                            )
                            (Decode.oneOf
                                [ Decode.field "files" (Decode.list (Decode.maybe decodeFile))
                                    |> Decode.map (List.filterMap identity)
                                , Decode.succeed []
                                ]
                            )

                     else if subtype == "channel_join" then
                        Decode.succeed JoinedChannel

                     else
                        Decode.fail ("Unsupported subtype " ++ subtype)
                    )
                    (Decode.map2
                        (\ts maybeThreadTs ->
                            case maybeThreadTs of
                                Just threadTs ->
                                    if threadTs == ts then
                                        NotAReply

                                    else if subtype == "thread_broadcast" then
                                        BroadcastReplyTo (Id threadTs)

                                    else
                                        ReplyTo (Id threadTs)

                                Nothing ->
                                    NotAReply
                        )
                        (Decode.field "ts" Decode.string)
                        (Decode.maybe (Decode.field "thread_ts" Decode.string))
                    )
                    (Decode.oneOf [ Decode.field "reply_count" Decode.int, Decode.succeed 0 ])
                    (Decode.oneOf
                        [ Decode.field
                            "reactions"
                            (Decode.list
                                (Decode.map2
                                    Reaction
                                    (Decode.field "name" Decode.string)
                                    (Decode.field "users" (Decode.list decodeId))
                                )
                            )
                        , Decode.succeed []
                        ]
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
    | WebsocketHello
    | WebsocketMessageCreated String Message
    | WebsocketMessageChanged String Message Time.Posix
    | WebsocketMessageDeleted String (Id UserId) (Id MessageId)
    | WebsocketReactionAdded { user : Id UserId, reaction : String, channel : String, messageId : Id MessageId }
    | WebsocketReactionRemoved { user : Id UserId, reaction : String, channel : String, messageId : Id MessageId }
    | WebsocketUserChanged User
    | WebsocketTeamRenamed String
    | WebsocketTeamDomainChanged String
    | WebsocketConversationsChanged
    | WebsocketChannelRenamed (Id ChannelId) String
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


decodeWebsocketEvent : Decoder WebsocketEvent
decodeWebsocketEvent =
    Decode.map2 Tuple.pair
        (Decode.field "type" Decode.string)
        (Decode.oneOf [ Decode.field "subtype" Decode.string, Decode.succeed "" ])
        |> Decode.andThen
            (\( eventType, subtype ) ->
                if eventType == "hello" then
                    Decode.succeed WebsocketHello

                else if eventType == "reaction_added" then
                    decodeReactionEvent |> Decode.map WebsocketReactionAdded

                else if eventType == "reaction_removed" then
                    decodeReactionEvent |> Decode.map WebsocketReactionRemoved

                else if eventType == "user_change" || eventType == "user_profile_changed" then
                    Decode.field "user" decodeUser |> Decode.map WebsocketUserChanged

                else if eventType == "team_rename" then
                    Decode.field "name" Decode.string |> Decode.map WebsocketTeamRenamed

                else if eventType == "team_domain_change" then
                    Decode.field "domain" Decode.string |> Decode.map WebsocketTeamDomainChanged

                else if List.member eventType conversationsChangedEvents then
                    Decode.succeed WebsocketConversationsChanged

                else if eventType == "channel_rename" || eventType == "group_rename" then
                    Decode.map2
                        WebsocketChannelRenamed
                        (Decode.at [ "channel", "id" ] decodeId)
                        (Decode.at [ "channel", "name" ] Decode.string)

                else if eventType /= "message" then
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
                    Decode.map2
                        WebsocketMessageCreated
                        (Decode.field "channel" Decode.string)
                        decodeMessage
            )


{-| Events where the conversations someone is in might have changed. Slack sends them for joining,
leaving, archiving and being added to DMs.
-}
conversationsChangedEvents : List String
conversationsChangedEvents =
    [ "channel_joined"
    , "channel_left"
    , "channel_deleted"
    , "channel_archive"
    , "channel_unarchive"
    , "group_joined"
    , "group_left"
    , "group_archive"
    , "group_unarchive"
    , "im_created"
    , "mpim_joined"
    ]


{-| Reactions can also be on files, which at-chat doesn't show.
-}
decodeReactionEvent : Decoder { user : Id UserId, reaction : String, channel : String, messageId : Id MessageId }
decodeReactionEvent =
    Decode.at [ "item", "type" ] Decode.string
        |> Decode.andThen
            (\itemType ->
                if itemType == "message" then
                    Decode.map4
                        (\user reaction channel messageId -> { user = user, reaction = reaction, channel = channel, messageId = messageId })
                        (Decode.field "user" decodeId)
                        (Decode.field "reaction" Decode.string)
                        (Decode.at [ "item", "channel" ] Decode.string)
                        (Decode.at [ "item", "ts" ] decodeId)

                else
                    Decode.fail "Not a reaction to a message"
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
        , resolver = Http.stringResolver (resolveResponse (decodeResponse decoder))
        , timeout = Just Duration.minute
        }


resolveResponse : Decoder (Result HttpError a) -> Http.Response String -> Result HttpError a
resolveResponse decoder response =
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
            case Decode.decodeString decoder body of
                Ok result ->
                    result

                Err error ->
                    Err (BadBody (Decode.errorToString error))


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
