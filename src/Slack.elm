module Slack exposing
    ( AuthToken(..)
    , BlockElement(..)
    , Channel
    , ClientSecret(..)
    , HttpError(..)
    , Id(..)
    , Message
    , OAuthCode(..)
    , OAuthError(..)
    , RichTextElement(..)
    , RichText_Emoji_Data
    , RichText_Text_Data
    , SlackError(..)
    , SlackMessage
    , TokenResponse
    , User
    , UserMessageData
    , Workspace
    , buildOAuthUrl
    , channelId
    , decodeChannel
    , decodeTokenResponse
    , decodeWorkspace
    , exchangeCodeForToken
    , loadMessages
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


type ChannelId
    = ChannelId Never


type TeamId
    = SlackTeamId Never


type alias TokenResponse =
    { botAccessToken : Maybe AuthToken
    , userAccessToken : AuthToken
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


buildOAuthUrl :
    { clientId : String
    , redirectUri : String
    , botScopes : List String
    , userScopes : List String
    , state : String
    }
    -> String
buildOAuthUrl config =
    Url.Builder.crossOrigin "https://slack.com"
        [ "oauth", "v2", "authorize" ]
        [ Url.Builder.string "client_id" config.clientId
        , Url.Builder.string "redirect_uri" config.redirectUri
        , Url.Builder.string "scope" (String.join "," config.botScopes)
        , Url.Builder.string "user_scope" (String.join "," config.userScopes)
        , Url.Builder.string "state" config.state
        ]


redirectUri : String
redirectUri =
    "https://6b11fa4fc5b1.ngrok-free.app/slack-oauth"


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
    , channelId : Id ChannelId
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


loadMessages : AuthToken -> Id ChannelId -> Int -> Task restriction HttpError (List Message)
loadMessages (SlackAuth auth) (Id channelId2) limit =
    let
        url =
            Url.Builder.crossOrigin "https://slack.com" [ "api", "conversations.history" ] []

        body =
            Http.stringBody
                "application/x-www-form-urlencoded"
                ("channel=" ++ channelId2 ++ "&limit=" ++ String.fromInt limit)
    in
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ auth) ]
        , url = url
        , body = body
        , resolver = Http.stringResolver (handleSlackResponse (Decode.field "messages" (Decode.list decodeMessage)))
        , timeout = Just (Duration.seconds 30)
        }


type Message
    = UserJoinedMessage (Id UserId) Time.Posix
    | UserMessage UserMessageData
    | JoinerNotificationForInviter (Id UserId) Time.Posix
    | BotMessage (Id UserId) Time.Posix


type alias UserMessageData =
    { user : Id UserId
    , blocks : List Block
    , createdAt : Time.Posix
    }


decodeMessage : Decoder Message
decodeMessage =
    Json.Decode.Extra.optionalField "subtype" Decode.string
        |> Decode.andThen
            (\subtype ->
                case subtype of
                    Just "channel_join" ->
                        Decode.succeed UserJoinedMessage
                            |> andMap (Decode.field "user" decodeId)
                            |> andMap (Decode.field "ts" decodeTimePosixString)

                    Just "joiner_notification_for_inviter" ->
                        Decode.succeed JoinerNotificationForInviter
                            |> andMap (Decode.field "user" decodeId)
                            |> andMap (Decode.field "ts" decodeTimePosixString)

                    Just "bot_message" ->
                        Decode.succeed BotMessage
                            |> andMap (Decode.field "user" decodeId)
                            |> andMap (Decode.field "ts" decodeTimePosixString)

                    Just subtype2 ->
                        Decode.fail ("Unknown message subtype \"" ++ subtype2 ++ "\"")

                    Nothing ->
                        Decode.succeed UserMessageData
                            |> andMap (Decode.field "user" decodeId)
                            |> andMap (Decode.field "blocks" (Decode.list decodeBlock))
                            |> andMap (Decode.field "ts" decodeTimePosixString)
                            |> Decode.map UserMessage
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
    { text : String, italic : Bool, bold : Bool, code : Bool }


type alias RichText_Emoji_Data =
    { name : String, unicode : String, italic : Bool, bold : Bool, code : Bool }


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
                            |> Decode.map RichText_Text

                    "emoji" ->
                        Decode.succeed RichText_Emoji_Data
                            |> andMap (Decode.field "name" Decode.string)
                            |> andMap (Decode.field "unicode" Decode.string)
                            |> andMap (optionalBool "italic")
                            |> andMap (optionalBool "bold")
                            |> andMap (optionalBool "code")
                            |> Decode.map RichText_Emoji

                    "user" ->
                        Decode.field "user_id" decodeId |> Decode.map RichText_UserMention

                    _ ->
                        Decode.fail ("Unknown block section type \"" ++ type_ ++ "\"")
            )


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
        (Json.Decode.Extra.optionalField "access_token" (Decode.map SlackAuth Decode.string))
        (Decode.at [ "authed_user", "access_token" ] (Decode.map SlackAuth Decode.string))
        (Decode.at [ "authed_user", "id" ] decodeId)
        (Decode.at [ "team", "id" ] decodeId)
        (Decode.at [ "team", "name" ] Decode.string)


decodeId : Decoder (Id a)
decodeId =
    Decode.map Id Decode.string
