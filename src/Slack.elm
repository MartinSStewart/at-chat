module Slack exposing
    ( AuthToken(..)
    , Block(..)
    , BlockElement(..)
    , Channel(..)
    , ChannelId
    , ClientSecret(..)
    , CurrentUser
    , Id(..)
    , ImChannelData
    , Message
    , MessageId
    , MessageType(..)
    , NormalChannelData
    , OAuthCode(..)
    , RichTextElement(..)
    , RichText_Emoji_Data
    , RichText_Text_Data
    , Team
    , TeamId
    , TokenResponse
    , User
    , UserId
    , buildOAuthUrl
    , channelId
    , exchangeCodeForToken
    , getCurrentUser
    , listUsers
    , loadMessages
    , loadWorkspaceChannels
    , redirectUri
    , teamInfo
    )

import Duration
import Effect.Http as Http
import Effect.Task exposing (Task)
import Effect.Time as Time
import Env
import Hex
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra
import List.Nonempty exposing (Nonempty)
import String.Nonempty exposing (NonemptyString)
import Url.Builder



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
    = UserId Never


type ChannelId
    = ChannelId Never


type TeamId
    = TeamId Never


type MessageId
    = MessageId Never


type alias TokenResponse =
    { botAccessToken : AuthToken
    , userAccessToken : AuthToken
    , userId : Id UserId
    , teamId : Id TeamId
    , teamName : String
    }


buildOAuthUrl :
    { clientId : String
    , redirectUri : String
    , botScopes : Nonempty String
    , userScopes : Nonempty String
    , state : String
    }
    -> String
buildOAuthUrl config =
    Url.Builder.crossOrigin "https://slack.com"
        [ "oauth", "v2", "authorize" ]
        [ Url.Builder.string "client_id" config.clientId
        , Url.Builder.string "redirect_uri" config.redirectUri
        , Url.Builder.string "scope" (String.join "," (List.Nonempty.toList config.botScopes))
        , Url.Builder.string "user_scope" (String.join "," (List.Nonempty.toList config.userScopes))
        , Url.Builder.string "state" config.state
        ]


redirectUri : String
redirectUri =
    (if Env.isProduction then
        Env.domain

     else
        ngrokPath
    )
        ++ "/slack-oauth"


ngrokPath : String
ngrokPath =
    "https://d5f652f01c6d.ngrok-free.app"


exchangeCodeForToken : ClientSecret -> String -> OAuthCode -> Task restriction Http.Error TokenResponse
exchangeCodeForToken (ClientSecret clientSecret) clientId (OAuthCode code) =
    Http.task
        { method = "POST"
        , headers = []
        , url = Url.Builder.crossOrigin "https://slack.com" [ "api", "oauth.v2.access" ] []
        , body =
            [ ( "client_id", clientId )
            , ( "client_secret", clientSecret )
            , ( "code", code )
            , ( "redirect_uri", redirectUri )
            ]
                |> List.map (\( key, value ) -> key ++ "=" ++ value)
                |> String.join "&"
                |> Http.stringBody "application/x-www-form-urlencoded"
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.BadUrl_ url ->
                            Err (Http.BadUrl url)

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.NetworkError_ ->
                            Err Http.NetworkError

                        Http.BadStatus_ metadata _ ->
                            Err (Http.BadStatus metadata.statusCode)

                        Http.GoodStatus_ _ body ->
                            case Decode.decodeString decodeTokenResponse body of
                                Ok result ->
                                    Ok result

                                Err decodeError ->
                                    Err (Http.BadBody (Decode.errorToString decodeError))
                )
        , timeout = Just (Duration.seconds 30)
        }



-- DATA STRUCTURES


type alias NormalChannelData =
    { id : Id ChannelId
    , isArchived : Bool
    , name : String
    , isMember : Bool
    , isPrivate : Bool
    , created : Time.Posix
    }


type alias ImChannelData =
    { id : Id ChannelId
    , isArchived : Bool
    , user : Id UserId
    , isUserDeleted : Bool
    , isOrgShared : Bool
    , created : Time.Posix
    }


type Channel
    = NormalChannel NormalChannelData
    | ImChannel ImChannelData


channelId : Channel -> Id ChannelId
channelId channel =
    case channel of
        NormalChannel normalChannelData ->
            normalChannelData.id

        ImChannel imChannelData ->
            imChannelData.id


type alias User =
    { id : Id UserId
    , name : String
    , isBot : Bool
    , isDeleted : Bool
    , profile : String
    }


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


decodeUser : Decoder User
decodeUser =
    Decode.succeed User
        |> andMap (Decode.field "id" decodeId)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.field "is_bot" Decode.bool)
        |> andMap (Decode.field "deleted" Decode.bool)
        |> andMap (Decode.at [ "profile", "image_192" ] Decode.string)



-- API FUNCTIONS


teamInfo : AuthToken -> Task restriction Http.Error Team
teamInfo auth =
    httpRequest
        auth
        "GET"
        "team.info"
        []
        (Decode.field "team" decodeTeam)


getCurrentUser : AuthToken -> Task restriction Http.Error CurrentUser
getCurrentUser auth =
    httpRequest
        auth
        "GET"
        "auth.test"
        []
        decodeCurrentUser


type alias Team =
    { id : Id TeamId
    , name : String
    , domain : String
    , image132 : String
    }


type alias CurrentUser =
    { userId : Id UserId
    , teamId : Id TeamId
    , url : String
    , team : String
    , user : String
    , enterpriseId : Maybe String
    }


decodeTeam : Decoder Team
decodeTeam =
    Decode.succeed Team
        |> andMap (Decode.field "id" decodeId)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.at [ "icon", "image_132" ] Decode.string)


decodeCurrentUser : Decoder CurrentUser
decodeCurrentUser =
    Decode.succeed CurrentUser
        |> andMap (Decode.field "user_id" decodeId)
        |> andMap (Decode.field "team_id" decodeId)
        |> andMap (Decode.field "url" Decode.string)
        |> andMap (Decode.field "team" Decode.string)
        |> andMap (Decode.field "user" Decode.string)
        |> andMap (Decode.maybe (Decode.field "enterprise_id" Decode.string))


listUsers : AuthToken -> Int -> Maybe String -> Task restriction Http.Error ( List User, Maybe String )
listUsers auth limit cursor =
    httpRequest
        auth
        "GET"
        "users.list"
        [ Just ( "limit", String.fromInt limit )
        , case cursor of
            Just cursor2 ->
                Just ( "cursor", cursor2 )

            Nothing ->
                Nothing
        ]
        (Decode.map2
            Tuple.pair
            (Decode.field "members" (Decode.list decodeUser))
            (Decode.at [ "response_metadata", "next_cursor" ] Decode.string |> Decode.maybe)
        )


loadWorkspaceChannels : AuthToken -> Id TeamId -> Task restriction Http.Error (List Channel)
loadWorkspaceChannels auth (Id teamId) =
    httpRequest
        auth
        "POST"
        "conversations.list"
        [ Just ( "team_id", teamId ), Just ( "types", "public_channel,private_channel,mpim,im" ) ]
        decodeChannelsList


loadMessages : AuthToken -> Id ChannelId -> Int -> Task restriction Http.Error (List Message)
loadMessages auth (Id channelId2) limit =
    httpRequest
        auth
        "POST"
        "conversations.history"
        [ Just ( "channel", channelId2 ), Just ( "limit", String.fromInt limit ) ]
        (Decode.field "messages" (Decode.list decodeMessage))


httpRequest : AuthToken -> String -> String -> List (Maybe ( String, String )) -> Decoder a -> Task restriction Http.Error a
httpRequest (SlackAuth auth) method rpcFunction body decoder =
    Http.task
        { method = method
        , headers = [ Http.header "Authorization" ("Bearer " ++ auth) ]
        , url = Url.Builder.crossOrigin "https://slack.com" [ "api", rpcFunction ] []
        , body =
            Http.stringBody
                "application/x-www-form-urlencoded"
                (List.filterMap
                    (\maybe ->
                        case maybe of
                            Just ( key, value ) ->
                                key ++ "=" ++ value |> Just

                            Nothing ->
                                Nothing
                    )
                    body
                    |> String.join "&"
                )
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.BadUrl_ url ->
                            Err (Http.BadUrl url)

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.NetworkError_ ->
                            Err Http.NetworkError

                        Http.BadStatus_ metadata _ ->
                            Err (Http.BadStatus metadata.statusCode)

                        Http.GoodStatus_ _ body2 ->
                            case Decode.decodeString decoder body2 of
                                Ok result ->
                                    Ok result

                                Err decodeError ->
                                    Err (Http.BadBody (Decode.errorToString decodeError))
                )
        , timeout = Just (Duration.seconds 30)
        }


type alias Message =
    { createdBy : Id UserId
    , createdAt : Time.Posix
    , messageType : MessageType
    }


type MessageType
    = UserJoinedMessage
    | UserMessage (Id MessageId) (List Block)
    | JoinerNotificationForInviter
    | BotMessage


decodeMessage : Decoder Message
decodeMessage =
    Decode.succeed Message
        |> andMap (Decode.field "user" decodeId)
        |> andMap (Decode.field "ts" decodeTimePosixString)
        |> andMap
            (Json.Decode.Extra.optionalField
                "subtype"
                Decode.string
                |> Decode.andThen
                    (\subtype ->
                        case subtype of
                            Just "channel_join" ->
                                Decode.succeed UserJoinedMessage

                            Just "joiner_notification_for_inviter" ->
                                Decode.succeed JoinerNotificationForInviter

                            Just "bot_message" ->
                                Decode.succeed BotMessage

                            Just subtype2 ->
                                Decode.fail ("Unknown message subtype \"" ++ subtype2 ++ "\"")

                            Nothing ->
                                Decode.succeed UserMessage
                                    |> andMap (Decode.field "client_msg_id" decodeId)
                                    |> andMap (Decode.field "blocks" (Decode.list decodeBlock))
                    )
            )


type Block
    = RichTextBlock (List BlockElement)


type BlockElement
    = RichTextSection (List RichTextElement)
    | RichTextPreformattedSection (List RichTextElement)


type RichTextElement
    = RichText_Text RichText_Text_Data
    | RichText_Emoji RichText_Emoji_Data
    | RichText_UserMention (Id UserId)


type alias RichText_Text_Data =
    { text : String
    , italic : Bool
    , bold : Bool
    , code : Bool
    , strikethrough : Bool
    }


type alias RichText_Emoji_Data =
    { name : String
    , unicode : NonemptyString
    }


decodeBlock : Decoder Block
decodeBlock =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\blockType ->
                case blockType of
                    "rich_text" ->
                        Decode.field "elements" (Decode.list decodeBlockElement)
                            |> Decode.map RichTextBlock

                    _ ->
                        Decode.fail ("Unknown message block type \"" ++ blockType ++ "\"")
            )


decodeBlockElement : Decoder BlockElement
decodeBlockElement =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\elementType ->
                case elementType of
                    "rich_text_section" ->
                        Decode.field "elements" (Decode.list decodeRichTextElement)
                            |> Decode.map RichTextSection

                    "rich_text_preformatted" ->
                        Decode.field "elements" (Decode.list decodeRichTextElement)
                            |> Decode.map RichTextPreformattedSection

                    _ ->
                        Decode.fail ("Unknown block section type \"" ++ elementType ++ "\"")
            )


decodeRichTextElement : Decoder RichTextElement
decodeRichTextElement =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\type_ ->
                case type_ of
                    "text" ->
                        Decode.succeed RichText_Text_Data
                            |> andMap (Decode.field "text" Decode.string)
                            |> andMap (optionalBool "italic")
                            |> andMap (optionalBool "bold")
                            |> andMap (optionalBool "code")
                            |> andMap (optionalBool "strike")
                            |> Decode.map RichText_Text

                    "emoji" ->
                        Decode.succeed RichText_Emoji_Data
                            |> andMap (Decode.field "name" Decode.string)
                            |> andMap (Decode.field "unicode" decodeUnicode)
                            |> Decode.map RichText_Emoji

                    "user" ->
                        Decode.field "user_id" decodeId |> Decode.map RichText_UserMention

                    _ ->
                        Decode.fail ("Unknown block section type \"" ++ type_ ++ "\"")
            )


decodeUnicode : Decoder NonemptyString
decodeUnicode =
    Decode.andThen
        (\text ->
            case Hex.fromString text of
                Ok int ->
                    Decode.succeed (String.Nonempty.fromChar (Char.fromCode int))

                Err _ ->
                    Decode.fail ("Invalid emoji code \"" ++ text ++ "\"")
        )
        Decode.string


optionalBool : String -> Decoder Bool
optionalBool fieldName =
    Json.Decode.Extra.optionalField fieldName Decode.bool |> Decode.map (Maybe.withDefault False)


decodeTimePosixString : Decoder Time.Posix
decodeTimePosixString =
    Decode.andThen
        (\text ->
            case String.toFloat text of
                Just float ->
                    round float |> Time.millisToPosix |> Decode.succeed

                Nothing ->
                    Decode.fail "Invalid time posix"
        )
        Decode.string



-- DECODERS


decodeChannelsList : Decoder (List Channel)
decodeChannelsList =
    Decode.field "channels" (Decode.list decodeChannel)


decodeChannel : Decoder Channel
decodeChannel =
    Decode.map2
        Tuple.pair
        (Json.Decode.Extra.optionalField "is_im" Decode.bool |> Decode.map (Maybe.withDefault False))
        (Json.Decode.Extra.optionalField "is_channel" Decode.bool |> Decode.map (Maybe.withDefault False))
        |> Decode.andThen
            (\( isIm, isChannel ) ->
                if isIm then
                    Decode.map ImChannel decodeImChannel

                else if isChannel then
                    Decode.map NormalChannel decodeNormalChannel

                else
                    Decode.fail "Invalid channel type"
            )


decodeTime : Decoder Time.Posix
decodeTime =
    Decode.map Time.millisToPosix Decode.int


decodeImChannel : Decoder ImChannelData
decodeImChannel =
    Decode.succeed ImChannelData
        |> andMap (Decode.field "id" decodeId)
        |> andMap (Decode.field "is_archived" Decode.bool)
        |> andMap (Decode.field "user" decodeId)
        |> andMap (Decode.field "is_user_deleted" Decode.bool)
        |> andMap (Decode.field "is_org_shared" Decode.bool)
        |> andMap (Decode.field "created" decodeTime)


decodeNormalChannel : Decoder NormalChannelData
decodeNormalChannel =
    Decode.succeed NormalChannelData
        |> andMap (Decode.field "id" decodeId)
        |> andMap (Decode.field "is_archived" Decode.bool)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.field "is_member" Decode.bool)
        |> andMap (Decode.field "is_private" Decode.bool)
        |> andMap (Decode.field "created" decodeTime)


decodeTokenResponse : Decoder TokenResponse
decodeTokenResponse =
    Decode.map5 TokenResponse
        (Decode.field "access_token" (Decode.map SlackAuth Decode.string))
        (Decode.at [ "authed_user", "access_token" ] (Decode.map SlackAuth Decode.string))
        (Decode.at [ "authed_user", "id" ] decodeId)
        (Decode.at [ "team", "id" ] decodeId)
        (Decode.at [ "team", "name" ] Decode.string)


decodeId : Decoder (Id a)
decodeId =
    Decode.map Id Decode.string
