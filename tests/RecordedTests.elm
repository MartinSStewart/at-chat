module RecordedTests exposing (main, setup)

import Array exposing (Array)
import Backend
import Bytes exposing (Bytes)
import Codec
import Coord
import Dict
import DiscordRecordedTests
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events exposing (Visibility(..))
import Effect.Lamdera as Lamdera exposing (SessionId)
import Effect.Test as T exposing (DelayInMs, FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..), RequestedBy(..))
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Category(..), SkinTone(..))
import Env
import Expect
import FileStatus
import Frontend
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import Json.Decode
import Json.Encode
import Local exposing (ChangeId(..))
import LoginForm
import NonemptyDict
import Pages.Home
import PersonName
import Range exposing (Range)
import RateLimit
import RecordedTestExtra
import RichText exposing (Domain(..))
import Route
import SecretId exposing (SecretId(..))
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test.Html.Query
import Test.Html.Selector
import Time
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, InitialLoadRequest(..), LocalChange(..), LoginTokenData(..), ToBackend(..), ToFrontend(..))
import User
import UserSession exposing (NotificationMode(..), SetViewing(..), ToBeFilledInByBackend(..))
import VisibleMessages


setup : T.ViewerWith (List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel))
setup =
    T.viewerWith tests
        |> T.addStringFile "/tests/data/discord-op0-ready.json"
        |> T.addStringFile "/tests/data/discord-op0-ready-supplemental.json"
        |> T.addStringFile "/tests/data/discord-sticker-packs.json"
        |> T.addBytesFile "/tests/data/at-user-icon.png"
        |> T.addStringFile "/public/compact-emoji.json"


main : Program () (T.Model ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel) (T.Msg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startViewer setup


tests :
    String
    -> String
    -> String
    -> Bytes
    -> String
    -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests discordOp0Ready discordOp0ReadySupplemental discordStickerPacks atUserIcon emojiJson =
    let
        handleNormalHttpRequests : ({ currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> Maybe HttpResponse) -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> HttpResponse
        handleNormalHttpRequests overrides ({ currentRequest } as httpRequests) =
            case overrides httpRequests of
                Just response ->
                    response

                Nothing ->
                    case String.split "/" currentRequest.url of
                        [ "", "_i" ] ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                RecordedTestExtra.infoEndpointResponse

                        [ "", "compact-emoji.json" ] ->
                            StringHttpResponse
                                { url = currentRequest.url
                                , statusCode = 200
                                , statusText = "OK"
                                , headers = Dict.empty
                                }
                                emojiJson

                        "http:" :: "" :: "localhost:3000" :: "file" :: rest ->
                            case rest of
                                "internal" :: rest2 ->
                                    RecordedTestExtra.handleInternalRequests discordStickerPacks currentRequest rest2

                                [ "upload" ] ->
                                    StringHttpResponse
                                        { url = currentRequest.url
                                        , statusCode = 200
                                        , statusText = "OK"
                                        , headers = Dict.empty
                                        }
                                        (Codec.encodeToString
                                            0
                                            FileStatus.uploadResponseCodec
                                            { fileHash = FileStatus.fileHash "123123123"
                                            , imageSize =
                                                { imageSize = Coord.xy 128 128
                                                , orientation = Nothing
                                                , gpsLocation = Nothing
                                                , cameraOwner = Nothing
                                                , exposureTime = Nothing
                                                , fNumber = Nothing
                                                , focalLength = Nothing
                                                , isoSpeedRating = Nothing
                                                , make = Nothing
                                                , model = Nothing
                                                , software = Nothing
                                                , userComment = Nothing
                                                }
                                                    |> Just
                                            }
                                        )

                                [ "upload-url" ] ->
                                    case currentRequest.body of
                                        T.JsonBody json ->
                                            case Codec.decodeValue FileStatus.uploadUrlCodec json of
                                                Ok request ->
                                                    -- Check if we are trying to upload a Discord standard sticker. We don't want those loaded by automated systems as they are copyrighted material
                                                    if String.contains "796138864933863456" request.url then
                                                        UnhandledHttpRequest

                                                    else
                                                        StringHttpResponse
                                                            { url = currentRequest.url
                                                            , statusCode = 200
                                                            , statusText = "OK"
                                                            , headers = Dict.empty
                                                            }
                                                            (Codec.encodeToString
                                                                0
                                                                FileStatus.uploadResponseCodec
                                                                { fileHash = FileStatus.fileHash request.url
                                                                , imageSize =
                                                                    { imageSize = Coord.xy 128 128
                                                                    , orientation = Nothing
                                                                    , gpsLocation = Nothing
                                                                    , cameraOwner = Nothing
                                                                    , exposureTime = Nothing
                                                                    , fNumber = Nothing
                                                                    , focalLength = Nothing
                                                                    , isoSpeedRating = Nothing
                                                                    , make = Nothing
                                                                    , model = Nothing
                                                                    , software = Nothing
                                                                    , userComment = Nothing
                                                                    }
                                                                        |> Just
                                                                }
                                                            )

                                                Err _ ->
                                                    StringHttpResponse
                                                        { url = currentRequest.url
                                                        , statusCode = 500
                                                        , statusText = "Bad request"
                                                        , headers = Dict.empty
                                                        }
                                                        ""

                                        _ ->
                                            StringHttpResponse
                                                { url = currentRequest.url
                                                , statusCode = 500
                                                , statusText = "Bad request"
                                                , headers = Dict.empty
                                                }
                                                ""

                                _ ->
                                    UnhandledHttpRequest

                        [ "https:", "", "api.postmarkapp.com", "email" ] ->
                            case currentRequest.body of
                                T.JsonBody json ->
                                    case Json.Decode.decodeValue (Json.Decode.field "To" Json.Decode.string) json of
                                        Ok email ->
                                            StringHttpResponse
                                                { url = currentRequest.url
                                                , statusCode = 200
                                                , statusText = "OK"
                                                , headers = Dict.empty
                                                }
                                                ("""{"To":\""""
                                                    ++ email
                                                    ++ """","SubmittedAt":"2023-09-30T14:26:56.6614723Z","MessageID":"edd386b7-63f1-471f-a4ba-2b216188fb6c","ErrorCode":0,"Message":"OK"}"""
                                                )

                                        Err err ->
                                            let
                                                _ =
                                                    Debug.log "Parse postmark request error" err
                                            in
                                            UnhandledHttpRequest

                                _ ->
                                    UnhandledHttpRequest

                        _ ->
                            if String.startsWith "https://cdn.discordapp.com/avatars/" currentRequest.url then
                                BytesHttpResponse
                                    { url = currentRequest.url
                                    , statusCode = 200
                                    , statusText = "OK"
                                    , headers = Dict.empty
                                    }
                                    atUserIcon

                            else
                                UnhandledHttpRequest

        handleFileRequest : { data : T.Data frontendModel backendModel, mimeTypes : List String } -> FileUpload
        handleFileRequest _ =
            UnhandledFileUpload

        handleMultiFileUpload : { data : T.Data frontendModel backendModel, mimeTypes : List String } -> MultipleFilesUpload
        handleMultiFileUpload _ =
            UnhandledMultiFileUpload

        normalConfig : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        normalConfig =
            T.Config
                Frontend.app_
                Backend.app_
                (handleNormalHttpRequests (\_ -> Nothing))
                RecordedTestExtra.handlePortToJs
                handleFileRequest
                handleMultiFileUpload
                RecordedTestExtra.domain
    in
    [ attackerTriesToLeakSensitiveData normalConfig discordOp0Ready discordOp0ReadySupplemental
    , RecordedTestExtra.inviteUserAndDmChat normalConfig
    , RecordedTestExtra.startTest
        "Admin can open admin page"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId0
            "/"
            RecordedTestExtra.desktopWindow
            (\admin ->
                [ RecordedTestExtra.handleLogin RecordedTestExtra.firefoxDesktop RecordedTestExtra.adminEmail admin
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_goToHomepage")
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Regenerate server secret button hits rust-server and applies response"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId0
            "/"
            RecordedTestExtra.desktopWindow
            (\admin ->
                [ RecordedTestExtra.handleLogin RecordedTestExtra.firefoxDesktop RecordedTestExtra.adminEmail admin
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_API keys")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Not regenerated" ])
                , admin.click 100 (Dom.id "admin_regenerateServerSecret")
                , T.checkState
                    100
                    (\data ->
                        case
                            List.filter
                                (\request ->
                                    (request.url == "http://localhost:3000/file/internal/regenerate-server-secret")
                                        && (request.method == "POST")
                                        && (request.requestedBy == RequestedByBackend)
                                        && List.member ( "x-secret-key", Env.secretKey ) request.headers
                                )
                                data.httpRequests
                        of
                            [ _ ] ->
                                Ok ()

                            [] ->
                                Err "Expected one POST to rust-server /file/internal/regenerate-server-secret"

                            _ ->
                                Err "Expected exactly one POST to rust-server /file/internal/regenerate-server-secret"
                    )
                , T.checkState
                    100
                    (\data ->
                        if SecretId.toString data.backend.serverSecret == RecordedTestExtra.regeneratedServerSecretValue then
                            Ok ()

                        else
                            Err
                                ("Backend server secret was not updated, got: "
                                    ++ SecretId.toString data.backend.serverSecret
                                )
                    )
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Last regenerated at " ])
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "Not regenerated"
                        , Test.Html.Selector.exactText "Regenerating"
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Create message with embeds and then edit that message"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                let
                    checkCards : Int -> Int -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    checkCards elmCampCardCount meetdownCardCount =
                        [ admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Title for https://elm.camp/" ] html
                                    |> Test.Html.Query.count (Expect.equal elmCampCardCount)
                            )
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Title for https://meetdown.app/" ] html
                                    |> Test.Html.Query.count (Expect.equal meetdownCardCount)
                            )
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Title for https://some-other-website.app/" ])
                        , user.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Title for https://elm.camp/" ] html
                                    |> Test.Html.Query.count (Expect.equal elmCampCardCount)
                            )
                        , user.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Title for https://meetdown.app/" ] html
                                    |> Test.Html.Query.count (Expect.equal meetdownCardCount)
                            )
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Title for https://some-other-website.app/" ])
                        ]
                            |> T.collapsableGroup "Check cards"
                in
                [ RecordedTestExtra.writeMessage admin 100 "Test https://elm.camp/ https://elm.camp/ https://meetdown.app/"
                , checkCards 2 1
                , T.collapsableGroup
                    "Edit message"
                    [ admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            ]
                        )
                    , user.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.text "(editing...)" ])
                    , admin.click 2000 (Dom.id "messageMenu_editMessage")
                    , admin.input 200 (Dom.id "editMessageTextInput") "Edited https://elm.camp/ https://some-other-website.app/"
                    , user.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.text "(editing...)" ])
                    , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                    ]
                , checkCards 1 0
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Friend label shows typing indicator"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                [ admin.click 100 (Dom.id "guild_openDm_1")
                , RecordedTestExtra.writeMessage admin 100 "Hello from admin"
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , user.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "Typing...", Test.Html.Selector.exactText "Editing..." ]
                    )

                -- Admin types in DM, user sees "Typing..." but admin does not
                , admin.input 100 (Dom.id "channel_textinput") "I am typing"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Typing..." ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Typing..." ])

                -- Admin sends the message, typing indicator disappears
                , admin.click 100 (Dom.id "guild_friendLabel_1")
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Typing..." ])

                -- Admin edits a message, user sees "Editing..." but admin does not
                , admin.custom
                    100
                    (Dom.id "guild_message_0")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , admin.input 200 (Dom.id "editMessageTextInput") "Edited message"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Editing..." ])
                , admin.click 100 (Dom.id "guildIcon_showFriends")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Editing..." ])

                -- Admin finishes editing, editing indicator disappears
                , admin.click 100 (Dom.id "guild_friendLabel_1")
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Editing..." ])
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Emoji selector arrow key navigation"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin _ ->
                let
                    checkHover :
                        (Maybe Emoji.EmojiOrSticker -> Result String ())
                        -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    checkHover predicate =
                        admin.checkModel
                            100
                            (\model ->
                                case model of
                                    Types.Loaded loaded ->
                                        case loaded.loginStatus of
                                            Types.LoggedIn loggedIn ->
                                                predicate loggedIn.emojiSelector.emojiHovered

                                            _ ->
                                                Err "Admin isn't logged in"

                                    Types.Loading _ ->
                                        Err "Admin frontend didn't finish loading"
                            )

                    expectHovered : Maybe Emoji.EmojiOrSticker -> Maybe Emoji.EmojiOrSticker -> Result String ()
                    expectHovered expected actual =
                        if actual == expected then
                            Ok ()

                        else
                            Err ("Expected emojiHovered to be " ++ Debug.toString expected ++ " but was " ++ Debug.toString actual)

                    expectSomeHovered : Maybe Emoji.EmojiOrSticker -> Result String ()
                    expectSomeHovered actual =
                        case actual of
                            Just _ ->
                                Ok ()

                            Nothing ->
                                Err "Expected some emoji to be hovered but none was"
                in
                [ admin.click 100 (Dom.id "messageMenu_channelInput_openEmojiSelector")
                , checkHover (expectHovered Nothing)

                -- Left/right do nothing while no emoji is highlighted.
                , admin.keyDown 100 Emoji.searchInputId "ArrowRight" []
                , checkHover (expectHovered Nothing)
                , admin.keyDown 100 Emoji.searchInputId "ArrowLeft" []
                , checkHover (expectHovered Nothing)

                -- ArrowDown enters keyboard navigation and highlights the first emoji.
                , admin.keyDown 100 Emoji.searchInputId "ArrowDown" []
                , checkHover expectSomeHovered

                -- ArrowRight keeps navigation going while something is highlighted.
                , admin.keyDown 100 Emoji.searchInputId "ArrowRight" []
                , checkHover expectSomeHovered

                -- ArrowUp from the top row clears the highlight so the cursor
                -- is free again and no emoji is highlighted.
                , admin.keyDown 100 Emoji.searchInputId "ArrowUp" []
                , checkHover (expectHovered Nothing)

                -- ArrowDown then Enter selects and closes the selector.
                , admin.keyDown 100 Emoji.searchInputId "ArrowDown" []
                , checkHover expectSomeHovered
                , admin.keyDown 100 Emoji.searchInputId "Enter" []
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.id (Dom.idToString Emoji.searchInputId) ]
                    )
                , T.andThen
                    100
                    (\data ->
                        case List.filter (\request -> request.portName == "exec_command_to_js") data.portRequests of
                            [ _ ] ->
                                []

                            _ ->
                                [ admin.checkModel 100 (\_ -> Err "Expected emoji to be assigned to text input") ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Message length limit and counter"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                let
                    shortText : String
                    shortText =
                        String.repeat 100 "a"

                    atThreshold : String
                    atThreshold =
                        String.repeat 1100 "b"

                    atLimit : String
                    atLimit =
                        String.repeat 2000 "c"

                    overLimit : String
                    overLimit =
                        String.repeat 2001 "d"
                in
                [ RecordedTestExtra.focusEvent admin 100 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.click 100 (Dom.id "channel_textinput")

                -- Below the counter threshold: no counter is rendered.
                , admin.input 100 (Dom.id "channel_textinput") shortText
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "/2000" ])

                -- Hitting the threshold shows the counter.
                , admin.input 100 (Dom.id "channel_textinput") atThreshold
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "900/2000" ])

                -- Going over the limit still shows the counter, and Enter refuses to send.
                , admin.input 100 (Dom.id "channel_textinput") overLimit
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , admin.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_1" ])

                -- Exactly 2000 chars is allowed and Enter sends.
                , admin.input 100 (Dom.id "channel_textinput") atLimit
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_message_1" ])

                -- Editing the message over the limit is blocked too.
                , admin.custom
                    100
                    (Dom.id "guild_message_1")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , admin.input 200 (Dom.id "editMessageTextInput") overLimit
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []

                -- Enter with over-limit text leaves the edit dialog open (counter still shown).
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])

                -- A valid edit within the limit still works.
                , admin.input 200 (Dom.id "editMessageTextInput") "Short edit"
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Short edit" ])
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Short edit" ])
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_2" ])
                , user.sendToBackend
                    100
                    (LocalModelChangeRequest (ChangeId 1)
                        (Local_SendMessage
                            (Time.millisToPosix 0)
                            (GuildOrDmId_Guild (Id.fromInt 1) (Id.fromInt 0))
                            (NonemptyString 'm' (String.repeat RichText.maxLength "m"))
                            (NoThreadWithMaybeMessage Nothing)
                            SeqDict.empty
                        )
                    )
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_2" ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_2" ])
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Message length limit and counter mobile"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.mobileWindow
            (\admin user ->
                let
                    shortText : String
                    shortText =
                        String.repeat 100 "a"

                    atThreshold : String
                    atThreshold =
                        String.repeat 1100 "b"

                    atLimit : String
                    atLimit =
                        String.repeat 2000 "c"

                    overLimit : String
                    overLimit =
                        String.repeat 2001 "d"
                in
                [ RecordedTestExtra.focusEvent admin 100 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.click 100 (Dom.id "channel_textinput")

                -- Below the counter threshold: no counter is rendered.
                , admin.input 100 (Dom.id "channel_textinput") shortText
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "/2000" ])

                -- Hitting the threshold shows the counter.
                , admin.input 100 (Dom.id "channel_textinput") atThreshold
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "900/2000" ])

                -- Going over the limit still shows the counter, and Enter refuses to send.
                , admin.input 100 (Dom.id "channel_textinput") overLimit
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])
                , admin.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_1" ])

                -- Exactly 2000 chars is allowed and Enter sends.
                , admin.input 100 (Dom.id "channel_textinput") atLimit
                , admin.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_message_1" ])

                -- Editing the message over the limit is blocked too.
                , admin.custom
                    100
                    (Dom.id "guild_message_1")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , admin.input 200 (Dom.id "editMessageTextInput") overLimit
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])
                , admin.click 100 (Dom.id "messageMenu_editMobile_sendMessage")

                -- Enter with over-limit text leaves the edit dialog open (counter still shown).
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "-1/2000" ])

                -- A valid edit within the limit still works.
                , admin.input 200 (Dom.id "editMessageTextInput") "Short edit"
                , admin.click 100 (Dom.id "messageMenu_editMobile_sendMessage")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Short edit" ])
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Short edit" ])
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_message_2" ])
                ]
            )
        ]
    , T.testGroup "Discord" (DiscordRecordedTests.discordTests normalConfig discordOp0Ready discordOp0ReadySupplemental)
    , RecordedTestExtra.startTest
        "Connect multiple devices"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId0
            "/"
            RecordedTestExtra.desktopWindow
            (\adminA ->
                [ RecordedTestExtra.handleLogin RecordedTestExtra.firefoxDesktop RecordedTestExtra.adminEmail adminA
                , adminA.click 100 (Dom.id "guild_showUserOptions")
                , RecordedTestExtra.hasExactText adminA [ "Desktop • Firefox (current device)" ]
                , T.connectFrontend
                    100
                    RecordedTestExtra.sessionId1
                    "/"
                    RecordedTestExtra.desktopWindow
                    (\adminB ->
                        [ RecordedTestExtra.handleLogin RecordedTestExtra.safariIphone RecordedTestExtra.adminEmail adminB
                        , RecordedTestExtra.hasExactText adminA [ "Mobile • Safari", "Desktop • Firefox (current device)" ]
                        , adminB.click 100 (Dom.id "guild_showUserOptions")
                        , T.connectFrontend
                            100
                            RecordedTestExtra.sessionId2
                            "/"
                            RecordedTestExtra.desktopWindow
                            (\adminC ->
                                [ RecordedTestExtra.handleLogin RecordedTestExtra.chromeDesktop RecordedTestExtra.adminEmail adminC
                                , RecordedTestExtra.hasExactText
                                    adminA
                                    [ "Mobile • Safari"
                                    , "Desktop • Firefox (current device)"
                                    , "Desktop • Chrome"
                                    ]
                                , adminC.click 100 (Dom.id "guild_showUserOptions")
                                , RecordedTestExtra.hasExactText
                                    adminC
                                    [ "Mobile • Safari"
                                    , "Desktop • Firefox"
                                    , "Desktop • Chrome (current device)"
                                    ]
                                ]
                            )
                        , adminB.click 100 (Dom.id "options_logout")
                        , RecordedTestExtra.hasNotExactText adminA [ "Mobile • Safari" ]
                        , RecordedTestExtra.hasExactText adminA [ "Desktop • Chrome", "Desktop • Firefox (current device)" ]
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "spoilers"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                [ RecordedTestExtra.writeMessage admin 100 "This message is ||very|| ||secret||"
                , admin.mouseEnter 100 (Dom.id "guild_message_1") ( 10, 10 ) []
                , admin.custom
                    100
                    (Dom.id "miniView_reply")
                    "click"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.int 300 )
                        , ( "clientY", Json.Encode.int 300 )
                        ]
                    )
                , RecordedTestExtra.writeMessage admin 100 "Another ||*super*|| *||secret||* message"
                , RecordedTestExtra.clickSpoiler user (Dom.id "spoiler_1_0")
                , RecordedTestExtra.clickSpoiler user (Dom.id "spoiler_1_1")
                , RecordedTestExtra.clickSpoiler user (Dom.id "spoiler_2_1")
                , RecordedTestExtra.clickSpoiler user (Dom.id "spoiler_2_0")
                , RecordedTestExtra.createThread admin (Id.fromInt 2)
                , RecordedTestExtra.clickSpoiler admin (Dom.id "spoiler_2_0")
                , RecordedTestExtra.clickSpoiler admin (Dom.id "spoiler_2_1")
                , RecordedTestExtra.writeMessage admin 100 "||*super*|| ||duper|| *||secret||* text"
                , user.click 100 (Dom.id "guild_threadStarterIndicator_2")
                , RecordedTestExtra.clickSpoiler admin (Dom.id "threadSpoiler_0_0")
                , RecordedTestExtra.clickSpoiler admin (Dom.id "threadSpoiler_0_2")
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Mobile edit message"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId2
            "/"
            RecordedTestExtra.mobileWindow
            (\admin ->
                [ RecordedTestExtra.handleLogin RecordedTestExtra.safariIphone RecordedTestExtra.adminEmail admin
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , RecordedTestExtra.writeMessageMobile admin "Test"
                , admin.custom
                    100
                    (Dom.id "guild_message_0")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , admin.input 1000 (Dom.id "editMessageTextInput") "Test Edited"
                , admin.input 200 (Dom.id "editMessageTextInput") "Test Edited\nLinebreak"
                , admin.click 1000 (Dom.id "messageMenu_editMobile_sendMessage")
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Desktop edit message"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId2
            "/"
            RecordedTestExtra.desktopWindow
            (\admin ->
                [ RecordedTestExtra.handleLogin RecordedTestExtra.safariIphone RecordedTestExtra.adminEmail admin
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , RecordedTestExtra.writeMessageMobile admin "Test"
                , admin.custom
                    100
                    (Dom.id "guild_message_0")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , RecordedTestExtra.hasExactText admin [ "Edit message" ]
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , RecordedTestExtra.hasNotExactText admin [ "Edit message" ]
                , admin.input 1000 (Dom.id "editMessageTextInput") "Test Edited"
                , admin.input 200 (Dom.id "editMessageTextInput") "Test Edited\nLinebreak"
                , RecordedTestExtra.hasText admin [ "to cancel edit" ]
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , RecordedTestExtra.hasNotText admin [ "to cancel edit" ]
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Change notification level"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , user.keyUp 100 (Dom.id "guild_notificationLevel") "ArrowDown" []
                , RecordedTestExtra.writeMessage admin 100 "Test"
                , RecordedTestExtra.checkNotification "Test"
                , RecordedTestExtra.writeMessage admin 100 "Test 2"
                , user.click 100 (Dom.id "guild_openChannel_0")
                , RecordedTestExtra.writeMessage user 100 "I shouldn't get notified"
                , RecordedTestExtra.checkNoNotification "I shouldn't get notified"
                ]
            )
        ]

    --, RecordedTestExtra.startTest
    --    "Remove direct mention when viewed on another session"
    --    RecordedTestExtra.startTime
    --    normalConfig
    --    [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
    --       RecordedTestExtra.desktopWindow (\admin user ->
    --            [ user.click 100 (Dom.id "guildIcon_showFriends")
    --            , writeMessage admin 100 "@Stevie Steve"
    --            , writeMessage admin 100 "@Stevie Steve"
    --            , writeMessage admin 100 "@Stevie Steve"
    --            , hasExactText user [ "3" ]
    --            , T.connectFrontend
    --                100
    --                sessionId1
    --                (Route.encode Route.HomePageRoute)
    --                RecordedTestExtra.desktopWindow
    --                (\userReload ->
    --                    [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string RecordedTestExtra.firefoxDesktop)
    --                    , userReload.click 100 (Dom.id "guild_openGuild_1")
    --                    , hasExactText user [ "3" ]
    --                    , userReload.click 100 (Dom.id "guildIcon_showFriends")
    --                    , hasNotExactText user [ "3" ]
    --                    ]
    --                )
    --            ]
    --        )
    --    ]
    , RecordedTestExtra.startTest
        "Check notification icons appear"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guildIcon_showFriends")
                , admin.click 100 (Dom.id "guild_newChannel")
                , admin.input 100 (Dom.id "newChannelName") "Second-channel-goes-here"
                , admin.click 100 (Dom.id "guild_createChannel")
                , RecordedTestExtra.writeMessage admin 100 "First message"
                , RecordedTestExtra.writeMessage admin 100 "Next message"
                , RecordedTestExtra.writeMessage admin 100 "Third message"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.style "aria-label" "3" ])
                , user.click 100 (Dom.id "guild_openGuild_1")
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.style "aria-label" "3" ])
                , RecordedTestExtra.writeMessage admin 100 "@Stevie Steve Hello!"
                , RecordedTestExtra.writeMessage admin 100 "@Stevie Steve Hello again!"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.style "aria-label" "2" ])
                , T.connectFrontend
                    100
                    RecordedTestExtra.sessionId1
                    (Route.encode Route.HomePageRoute)
                    RecordedTestExtra.desktopWindow
                    (\userReload ->
                        [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string RecordedTestExtra.firefoxDesktop)
                        , userReload.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.style "aria-label" "2" ])
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Guild icon notification is shown"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guildIcon_showFriends")
                , RecordedTestExtra.writeMessage admin 100 "See if notification appears next to guild icon"
                , user.snapshotView 100 { name = "Guild icon new message notification" }
                , T.connectFrontend
                    100
                    RecordedTestExtra.sessionId1
                    (Route.encode Route.HomePageRoute)
                    RecordedTestExtra.desktopWindow
                    (\_ ->
                        [ user.snapshotView 100 { name = "Guild icon new message notification on reload" } ]
                    )
                , RecordedTestExtra.writeMessage admin 100 "@Stevie Steve now you should see a red icon"
                , user.snapshotView 100 { name = "Guild icon new mention notification" }
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "No messages missing even in long chat history"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\_ user ->
                [ List.range 0 (VisibleMessages.pageSize * 2)
                    |> List.map (\index -> RecordedTestExtra.writeMessage user 1000 ("Message " ++ String.fromInt (index + 1)))
                    |> T.group
                , T.connectFrontend
                    100
                    RecordedTestExtra.sessionId1
                    (Route.encode Route.HomePageRoute)
                    RecordedTestExtra.desktopWindow
                    (\userReload ->
                        [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string RecordedTestExtra.firefoxDesktop)
                        , userReload.click 100 (Dom.id "guild_openGuild_1")
                        , RecordedTestExtra.writeMessage userReload 100 "Another message"
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Another message" ])
                        , RecordedTestExtra.hasNotExactText userReload [ "This is the start of #general", "Message 31" ]
                        , RecordedTestExtra.hasExactText userReload [ "Message 32", "Message 61" ]
                        , RecordedTestExtra.noMissingMessages 100 userReload
                        , RecordedTestExtra.scrollToTop userReload
                        , userReload.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.exactText "This is the start of #general"
                                , Test.Html.Selector.exactText "Message 1"
                                ]
                            )
                        , userReload.checkView
                            0
                            (Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Message 2"
                                , Test.Html.Selector.exactText "Message 61"
                                ]
                            )
                        , RecordedTestExtra.noMissingMessages 100 userReload
                        , RecordedTestExtra.scrollToMiddle userReload
                        , userReload.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "This is the start of #general" ])
                        , RecordedTestExtra.scrollToTop userReload
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "This is the start of #general" ])
                        , T.backendUpdate
                            5000
                            (Types.UserDisconnected RecordedTestExtra.sessionId1 userReload.clientId)
                        , T.backendUpdate
                            100
                            (Types.UserConnected RecordedTestExtra.sessionId1 userReload.clientId)
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Another message" ])
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Notifications"
        RecordedTestExtra.startTime
        normalConfig
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                [ admin.input 100 (Dom.id "channel_textinput") "@Stevie Steve Hi!"
                , user.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "AT is typing..." ]
                    )
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , user.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "AT is typing..." ]
                    )
                , RecordedTestExtra.checkNoNotification "@Stevie Steve Hi!"
                , RecordedTestExtra.enableNotifications False admin
                , user.mouseEnter 100 (Dom.id "guild_message_1") ( 10, 10 ) []
                , user.custom
                    100
                    (Dom.id "miniView_reply")
                    "click"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.int 300 )
                        , ( "clientY", Json.Encode.int 300 )
                        ]
                    )
                , user.input 100 (Dom.id "channel_textinput") "Hello admin!"
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "Stevie Steve is typing..." ]
                    )
                , user.click 100 (Dom.id "messageMenu_channelInput_sendMessage")
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "Stevie Steve is typing..." ]
                    )
                , RecordedTestExtra.checkNoNotification "Hello admin!"
                , RecordedTestExtra.createThread admin (Id.fromInt 2)
                , admin.input 100 (Dom.id "channel_textinput") "Lets move this to a thread..."
                , user.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "AT is typing..." ]
                    )
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , RecordedTestExtra.checkNotification "Lets move this to a thread..."
                , user.click 100 (Dom.id "guild_threadStarterIndicator_2")
                , admin.click 100 (Dom.id "guild_openDm_1")
                , RecordedTestExtra.writeMessage admin 100 "Here's a DM to you"
                , user.click 100 (Dom.id "guildsColumn_openDm_0")
                , RecordedTestExtra.writeMessage user 100 "Here's a reply!"
                , RecordedTestExtra.writeMessage user 100 "And another reply"
                , user.update 100 (Types.VisibilityChanged Hidden)
                , T.connectFrontend
                    100
                    RecordedTestExtra.sessionId1
                    (Route.encode Route.HomePageRoute)
                    RecordedTestExtra.desktopWindow
                    (\userReload ->
                        [ userReload.portEvent 10 "user_agent_from_js" (Json.Encode.string RecordedTestExtra.firefoxDesktop)
                        , userReload.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.id "guildsColumn_openDm_0" ]
                            )
                        , userReload.click 100 (Dom.id "guildIcon_showFriends")
                        , userReload.click 100 (Dom.id "guild_friendLabel_0")
                        , RecordedTestExtra.noMissingMessages 20 userReload
                        , userReload.click 100 (Dom.id "guild_openGuild_1")
                        , RecordedTestExtra.noMissingMessages 20 userReload
                        , userReload.click 100 (Dom.id "guild_openChannel_0")
                        , RecordedTestExtra.noMissingMessages 20 userReload
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Enable 2FA"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId0
            "/"
            RecordedTestExtra.desktopWindow
            (\user ->
                [ RecordedTestExtra.handleLogin RecordedTestExtra.firefoxDesktop RecordedTestExtra.adminEmail user
                , user.click 100 (Dom.id "guild_showUserOptions")
                , user.click 100 (Dom.id "userOverview_start2FaSetup")
                , user.snapshotView 100 { name = "2FA setup" }
                , user.input 100 (Dom.id "userOverview_twoFactorCodeInput") "123123"
                , user.snapshotView 100 { name = "2FA setup with wrong code" }
                , T.andThen
                    100
                    (\data ->
                        case SeqDict.get RecordedTestExtra.sessionId0 data.backend.sessions of
                            Just { userId } ->
                                case SeqDict.get userId data.backend.twoFactorAuthenticationSetup of
                                    Just { secret } ->
                                        case TwoFactorAuthentication.getConfig "" secret of
                                            Ok key ->
                                                [ user.input
                                                    100
                                                    (Dom.id "userOverview_twoFactorCodeInput")
                                                    (TwoFactorAuthentication.getCode RecordedTestExtra.startTime key
                                                        |> Maybe.withDefault 0
                                                        |> String.fromInt
                                                        |> String.padLeft LoginForm.twoFactorCodeLength '0'
                                                    )
                                                , user.checkView
                                                    100
                                                    (Test.Html.Query.has
                                                        [ Test.Html.Selector.exactText
                                                            "Two factor authentication enabled!"
                                                        ]
                                                    )
                                                , user.snapshotView 100 { name = "2FA setup complete" }
                                                ]

                                            Err _ ->
                                                [ T.checkState 100 (\_ -> Err "Failed to get 2FA config") ]

                                    Nothing ->
                                        [ T.checkState 100 (\_ -> Err "Failed to get 2FA setup") ]

                            Nothing ->
                                [ T.checkState 100 (\_ -> Err "User not found") ]
                    )
                , user.click 100 (Dom.id "options_logout")
                ]
            )
        , T.connectFrontend
            100
            RecordedTestExtra.sessionId0
            "/"
            RecordedTestExtra.desktopWindow
            (\user ->
                [ RecordedTestExtra.handleLogin RecordedTestExtra.firefoxDesktop RecordedTestExtra.adminEmail user
                , user.snapshotView 100 { name = "2FA login step" }
                , T.andThen
                    100
                    (\data ->
                        case SeqDict.get RecordedTestExtra.sessionId0 data.backend.pendingLogins of
                            Just (WaitingForTwoFactorToken { userId }) ->
                                case SeqDict.get userId data.backend.twoFactorAuthentication of
                                    Just { secret } ->
                                        case TwoFactorAuthentication.getConfig "" secret of
                                            Ok key ->
                                                [ user.input
                                                    100
                                                    (Dom.id "loginForm_twoFactorCodeInput")
                                                    (TwoFactorAuthentication.getCode RecordedTestExtra.startTime key
                                                        |> Maybe.withDefault 0
                                                        |> String.fromInt
                                                        |> String.padLeft LoginForm.twoFactorCodeLength '0'
                                                    )
                                                , user.click 100 (Dom.id "guild_showUserOptions")
                                                , user.checkView
                                                    100
                                                    (Test.Html.Query.has
                                                        [ Test.Html.Selector.exactText (PersonName.toString Backend.adminUser.name)
                                                        , Test.Html.Selector.exactText "Two factor authentication was enabled "
                                                        ]
                                                    )
                                                , user.snapshotView 100 { name = "user overview with two factor already complete" }
                                                ]

                                            Err _ ->
                                                [ T.checkState 100 (\_ -> Err "Failed to get 2FA config") ]

                                    Nothing ->
                                        [ T.checkState 100 (\_ -> Err "Failed to get 2FA setup") ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Pending login not found") ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest "Logins are rate limited"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId0
            "/"
            RecordedTestExtra.desktopWindow
            (\user ->
                let
                    openLoginAndSubmitEmail delay =
                        T.group
                            [ user.click delay Pages.Home.loginButtonId
                            , user.input 100 LoginForm.emailInputId (EmailAddress.toString RecordedTestExtra.adminEmail)
                            , user.click 100 LoginForm.submitEmailButtonId
                            ]

                    tooManyIncorrectAttempts : List Test.Html.Selector.Selector
                    tooManyIncorrectAttempts =
                        [ Test.Html.Selector.text "Too many incorrect attempts." ]
                in
                [ user.portEvent 10 "user_agent_from_js" (Json.Encode.string RecordedTestExtra.firefoxDesktop)
                , openLoginAndSubmitEmail 100
                , List.range 0 9
                    |> List.map
                        (\index ->
                            [ user.checkView 100 (Test.Html.Query.hasNot tooManyIncorrectAttempts)
                            , user.input
                                100
                                LoginForm.loginCodeInputId
                                (String.padLeft LoginForm.loginCodeLength '0' (String.fromInt index))
                            ]
                                |> T.group
                        )
                    |> T.group
                , user.checkView 100 (Test.Html.Query.has tooManyIncorrectAttempts)
                , user.snapshotView 100 { name = "Too many incorrect attempts" }
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (RecordedTestExtra.isLoginEmail RecordedTestExtra.adminEmail) data.httpRequests of
                            loginCode :: _ ->
                                [ user.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode) ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                , user.checkView 100 (Test.Html.Query.has tooManyIncorrectAttempts)
                , [ RecordedTestExtra.hasNotText user [ "Too many login attempts have been made." ]
                  , openLoginAndSubmitEmail 100
                  ]
                    |> T.group
                    |> List.repeat 6
                    |> T.group
                , RecordedTestExtra.hasText user [ "Too many login attempts have been made." ]
                , user.snapshotView 100 { name = "Too many login attempts" }
                , -- Should be able to log in again after some time has passed
                  openLoginAndSubmitEmail (5 * 60 * 1000)
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (RecordedTestExtra.isLoginEmail RecordedTestExtra.adminEmail) data.httpRequests of
                            loginCode :: _ ->
                                [ user.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode) ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                , RecordedTestExtra.hasExactText user [ PersonName.toString Backend.adminUser.name ]
                ]
            )
        , T.checkState
            (Duration.hours 4.01 |> Duration.inMilliseconds)
            (\data ->
                case List.filterMap (RecordedTestExtra.isLogErrorEmail Env.adminEmail) data.httpRequests of
                    [ "LoginsRateLimited" ] ->
                        Ok ()

                    _ ->
                        Err "Expected to only see LoginsRateLimited as an error email"
            )
        ]
    , RecordedTestExtra.startTest "Test login"
        RecordedTestExtra.startTime
        normalConfig
        [ T.connectFrontend
            100
            RecordedTestExtra.sessionId0
            "/"
            RecordedTestExtra.desktopWindow
            (\client ->
                [ client.portEvent 10 "user_agent_from_js" (Json.Encode.string RecordedTestExtra.firefoxDesktop)
                , client.snapshotView 100 { name = "homepage" }
                , client.click 100 Pages.Home.loginButtonId
                , client.snapshotView 100 { name = "login" }
                , client.input 100 LoginForm.emailInputId "asdf123"
                , client.click 100 LoginForm.submitEmailButtonId
                , client.snapshotView 100 { name = "invalid email" }
                , client.input 100 LoginForm.emailInputId (EmailAddress.toString RecordedTestExtra.adminEmail)
                , client.snapshotView 100 { name = "valid email" }
                , client.click 100 LoginForm.submitEmailButtonId
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (RecordedTestExtra.isLoginEmail RecordedTestExtra.adminEmail) data.httpRequests of
                            loginCode :: _ ->
                                [ client.input 100 LoginForm.loginCodeInputId "12345678"
                                , client.snapshotView 100 { name = "invalid code" }
                                , client.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode)
                                , client.snapshotView 100 { name = "logged in" }
                                ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                ]
            )
        , RecordedTestExtra.checkNoErrorLogs
        ]
    , RecordedTestExtra.startTest
        "Add and remove reaction emojis"
        (Time.millisToPosix 1756739527046)
        normalConfig
        [ T.connectFrontend
            0
            (Lamdera.sessionIdFromString "24334c04b8f7b594cdeedebc2a8029b82943b0a6")
            "/"
            { width = 1887, height = 770 }
            (\tabA ->
                [ tabA.portEvent 8 "check_notification_permission_from_js" (Json.Encode.string "granted")
                , tabA.portEvent 1 "check_pwa_status_from_js" (RecordedTestExtra.stringToJson "false")
                , tabA.portEvent
                    1
                    "user_agent_from_js"
                    (Json.Encode.string "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0")
                , tabA.portEvent 19 "load_user_settings_from_js" (Json.Encode.string "")
                , T.connectFrontend
                    17
                    (Lamdera.sessionIdFromString "24334c04b8f7b594cdeedebc2a8029b82943b0a6")
                    "/"
                    { width = 1887, height = 674 }
                    (\tabB ->
                        [ tabB.portEvent 11 "check_notification_permission_from_js" (Json.Encode.string "granted")
                        , tabB.portEvent 0 "check_pwa_status_from_js" (RecordedTestExtra.stringToJson "false")
                        , tabB.portEvent 8 "load_user_settings_from_js" (Json.Encode.string "")
                        , RecordedTestExtra.handleLogin "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0" RecordedTestExtra.adminEmail tabB
                        , tabA.click 1747 (Dom.id "guild_openGuild_0")
                        , RecordedTestExtra.writeMessage tabA 100 "Test"
                        , tabB.click 111 (Dom.id "guild_openGuild_0")
                        , RecordedTestExtra.focusEvent tabB 25 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , tabA.mouseEnter 991 (Dom.id "guild_message_0") ( 620, 54 ) []
                        , RecordedTestExtra.focusEvent tabA 921 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , RecordedTestExtra.focusEvent tabA 4 Nothing Nothing
                        , RecordedTestExtra.focusEvent tabB 17 Nothing Nothing
                        , tabA.click 28 (Dom.id "miniView_reply")
                        , RecordedTestExtra.focusEvent tabA 8 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , tabA.mouseLeave 375 (Dom.id "guild_message_0") ( 1286, 57 ) []
                        , tabA.click 457 (Dom.id "channel_textinput")
                        , tabA.input 781 (Dom.id "channel_textinput") "Test2"
                        , RecordedTestExtra.focusEvent tabA 4 Nothing Nothing
                        , tabA.click 78 (Dom.id "messageMenu_channelInput_sendMessage")
                        , T.collapsableGroup
                            "Add emoji to guild channel message"
                            [ tabA.mouseEnter 1 (Dom.id "guild_message_0") ( 1036, 55 ) []
                            , tabA.click 1205 (Dom.id "miniView_showReactionEmojiSelector")
                            , tabA.mouseLeave 633 (Dom.id "guild_message_0") ( 690, -1 ) []
                            , tabA.click 991 (Dom.id "guild_emojiSelector_131")
                            , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "😀" ])
                            , tabA.mouseEnter 348 (Dom.id "guild_message_0") ( 66, 13 ) []
                            , tabA.click 548 (Dom.id "guild_removeReactionEmoji_0")
                            , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "😀" ])
                            , tabA.click 100 (Dom.id "miniView_emojiReact_0")
                            , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "😀" ])
                            , tabA.click 100 (Dom.id "miniView_emojiReact_0")
                            , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "😀" ])
                            , tabA.mouseLeave 410 (Dom.id "guild_message_0") ( 148, 63 ) []
                            ]
                        , RecordedTestExtra.createThread tabA (Id.fromInt 0)
                        , tabA.mouseEnter 1 (Dom.id "guild_message_0") ( 1036, 55 ) []
                        , tabA.click 1205 (Dom.id "miniView_showReactionEmojiSelector")
                        , tabA.mouseLeave 633 (Dom.id "guild_message_0") ( 690, -1 ) []
                        , tabA.click 991 (Dom.id "guild_emojiSelector_131")
                        , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "😀" ])
                        , tabA.mouseEnter 348 (Dom.id "guild_message_0") ( 66, 13 ) []
                        , tabA.click 548 (Dom.id "guild_removeReactionEmoji_0")
                        , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "😀" ])
                        , tabA.mouseLeave 410 (Dom.id "guild_message_0") ( 148, 63 ) []
                        , tabA.click 457 (Dom.id "channel_textinput")
                        , tabA.input 781 (Dom.id "channel_textinput") "Test3"
                        , RecordedTestExtra.focusEvent tabA 2357 Nothing Nothing
                        , tabA.click 78 (Dom.id "messageMenu_channelInput_sendMessage")
                        , tabB.click 100 (Dom.id "guild_viewThread_0_0")
                        , tabA.mouseEnter 1 (Dom.id "thread_message_0") ( 1036, 55 ) []
                        , tabA.click 1205 (Dom.id "miniView_showReactionEmojiSelector")
                        , tabA.mouseLeave 633 (Dom.id "thread_message_0") ( 690, -1 ) []
                        , tabA.click 100 (Dom.id "emoji_category_People & Body")
                        , tabA.click 991 (Dom.id "guild_emojiSelector_351")
                        , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "👍" ])
                        , tabA.mouseEnter 348 (Dom.id "thread_message_0") ( 66, 13 ) []
                        , tabA.click 548 (Dom.id "guild_removeReactionEmoji_0")
                        , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "👍" ])
                        , tabA.click 100 (Dom.id "miniView_emojiReact_1")
                        , tabB.checkView 50 (Test.Html.Query.has [ Test.Html.Selector.exactText "👍" ])
                        , tabA.click 100 (Dom.id "miniView_emojiReact_1")
                        , tabB.checkView 50 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "👍" ])
                        , tabA.mouseLeave 410 (Dom.id "thread_message_0") ( 148, 63 ) []
                        ]
                    )
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Opening non-existent guild shouldn't show \"Unable to reach the server.\" warning"
        (Time.millisToPosix 1757158297558)
        normalConfig
        [ T.connectFrontend
            0
            (Lamdera.sessionIdFromString "207950c04b8f7b594cdeedebc2a8029b82943b0a")
            "/g/1/c/0"
            { width = 1615, height = 820 }
            (\tabA ->
                [ tabA.portEvent 10 "check_notification_permission_from_js" (Json.Encode.string "granted")
                , tabA.portEvent 1 "check_pwa_status_from_js" (RecordedTestExtra.stringToJson "false")
                , tabA.portEvent 990 "load_user_settings_from_js" (Json.Encode.string "")
                , RecordedTestExtra.handleLogin "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0" RecordedTestExtra.adminEmail tabA
                , tabA.click 17660 (Dom.id "guild_openGuild_0")
                , RecordedTestExtra.focusEvent tabA 17 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , RecordedTestExtra.focusEvent tabA 3994 Nothing Nothing
                , tabA.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Unable to reach the server." ])
                ]
            )
        ]
    , RecordedTestExtra.startTest
        "Export and import backend round-trip"
        RecordedTestExtra.startTime
        (T.Config
            Frontend.app_
            Backend.app_
            (handleNormalHttpRequests (\_ -> Nothing))
            RecordedTestExtra.handlePortToJs
            (\requestData ->
                case requestData.data.downloads of
                    [ backup ] ->
                        case backup.content of
                            T.BytesFile bytes ->
                                UploadFile
                                    (T.uploadBytesFile backup.filename backup.mimeType bytes RecordedTestExtra.startTime)

                            T.StringFile _ ->
                                UnhandledFileUpload

                    _ ->
                        UnhandledFileUpload
            )
            handleMultiFileUpload
            RecordedTestExtra.domain
        )
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                [ RecordedTestExtra.writeMessage admin 100 "Hello export test!"
                , user.click 100 (Dom.id "guild_openDm_0")
                , RecordedTestExtra.writeMessage user 100 "Hello!"
                , RecordedTestExtra.linkDiscordAndLogin
                    (Lamdera.sessionIdFromString "JoeSession")
                    "Joe"
                    RecordedTestExtra.joeEmail
                    True
                    discordOp0Ready
                    discordOp0ReadySupplemental
                    (\_ -> [])
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_Export/Import")
                , T.andThen
                    100
                    (\beforeExportData ->
                        [ admin.click 100 (Dom.id "admin_exportBackendButton")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Guilds")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Users")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Discord guilds")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Discord DM channels")
                        , T.andThen
                            100
                            (\data ->
                                let
                                    deleteGuildActions =
                                        SeqDict.keys data.backend.guilds
                                            |> List.map
                                                (\guildId ->
                                                    admin.click 100 (Dom.id ("Admin_deleteGuildButton_" ++ Id.toString guildId))
                                                )

                                    deleteUserActions =
                                        NonemptyDict.toList data.backend.users
                                            |> List.filterMap
                                                (\( userId, backendUser ) ->
                                                    if backendUser.isAdmin then
                                                        Nothing

                                                    else
                                                        Just (admin.click 100 (Dom.id ("Admin_deleteUserButton_a_" ++ Id.toString userId ++ "_")))
                                                )
                                in
                                deleteGuildActions
                                    ++ deleteUserActions
                                    ++ [ admin.click 100 (Dom.id "admin_saveUserChangesButton")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordGuildButton_705745250815311942")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_185574444641550336")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_222087308516524036")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_1215077285749858324")
                                       ]
                                    |> T.collapsableGroup "Delete stuff"
                                    |> List.singleton
                            )
                        , admin.click 300 (Dom.id "admin_importBackendButton")
                        , admin.checkView
                            500
                            (Test.Html.Query.has [ Test.Html.Selector.text "Imported!" ])
                        , T.checkState
                            100
                            (\afterImportData ->
                                if
                                    (beforeExportData.backend.guilds == afterImportData.backend.guilds)
                                        && (beforeExportData.backend.dmChannels == afterImportData.backend.dmChannels)
                                        && (beforeExportData.backend.discordGuilds == afterImportData.backend.discordGuilds)
                                        && (beforeExportData.backend.discordDmChannels == afterImportData.backend.discordDmChannels)
                                        && (beforeExportData.backend.users == afterImportData.backend.users)
                                        && (beforeExportData.backend.discordUsers == afterImportData.backend.discordUsers)
                                then
                                    Ok ()

                                else
                                    Err "Expected at least one guild in backend after import"
                            )
                        ]
                    )
                ]
            )
        ]
    , sendMessageRateLimitTest normalConfig
    , RecordedTestExtra.startTest
        "Scheduled backend export uploads bytes"
        RecordedTestExtra.startTime
        (T.Config
            Frontend.app_
            Backend.app_
            (handleNormalHttpRequests (\_ -> Nothing))
            RecordedTestExtra.handlePortToJs
            (\requestData ->
                case backupRequests requestData.data of
                    [ backupA, backupB ] ->
                        let
                            oldestBackup =
                                if Time.posixToMillis backupA.sentAt < Time.posixToMillis backupB.sentAt then
                                    backupA

                                else
                                    backupB
                        in
                        case oldestBackup.body of
                            T.BytesBody mimeType bytes ->
                                UploadFile
                                    (T.uploadBytesFile "backup.bin" mimeType bytes RecordedTestExtra.startTime)

                            _ ->
                                UnhandledFileUpload

                    _ ->
                        UnhandledFileUpload
            )
            handleMultiFileUpload
            RecordedTestExtra.domain
        )
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                [ RecordedTestExtra.writeMessage admin 100 "Hello export test!"
                , user.click 100 (Dom.id "guild_openDm_0")
                , RecordedTestExtra.writeMessage user 100 "Hello!"
                , RecordedTestExtra.linkDiscordAndLogin
                    (Lamdera.sessionIdFromString "JoeSession")
                    "Joe"
                    RecordedTestExtra.joeEmail
                    True
                    discordOp0Ready
                    discordOp0ReadySupplemental
                    (\_ -> [])
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_Export/Import")
                , T.andThen
                    100
                    (\beforeExportData ->
                        [ T.checkState
                            (Duration.hours 5 |> Duration.inMilliseconds)
                            (\data ->
                                case backupRequests data of
                                    [ _ ] ->
                                        Ok ()

                                    [] ->
                                        Err "Expected one upload HTTP request for scheduled export"

                                    _ ->
                                        Err "Expected exactly one upload HTTP request for scheduled export"
                            )
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Guilds")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Users")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Discord guilds")
                        , admin.click 100 (Dom.id "admin_expandSectionButton_Discord DM channels")
                        , T.andThen
                            100
                            (\data ->
                                let
                                    deleteGuildActions =
                                        SeqDict.keys data.backend.guilds
                                            |> List.map
                                                (\guildId ->
                                                    admin.click 100 (Dom.id ("Admin_deleteGuildButton_" ++ Id.toString guildId))
                                                )

                                    deleteUserActions =
                                        NonemptyDict.toList data.backend.users
                                            |> List.filterMap
                                                (\( userId, backendUser ) ->
                                                    if backendUser.isAdmin then
                                                        Nothing

                                                    else
                                                        Just (admin.click 100 (Dom.id ("Admin_deleteUserButton_a_" ++ Id.toString userId ++ "_")))
                                                )
                                in
                                deleteGuildActions
                                    ++ deleteUserActions
                                    ++ [ admin.click 100 (Dom.id "admin_saveUserChangesButton")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordGuildButton_705745250815311942")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_185574444641550336")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_222087308516524036")
                                       , admin.click 100 (Dom.id "Admin_deleteDiscordDmChannelButton_1215077285749858324")
                                       ]
                                    |> T.collapsableGroup "Delete stuff"
                                    |> List.singleton
                            )
                        , T.checkState
                            (Duration.hours 4 |> Duration.inMilliseconds)
                            (\data ->
                                case backupRequests data of
                                    [ _, _ ] ->
                                        Ok ()

                                    [] ->
                                        Err "Expected two upload HTTP request for scheduled export"

                                    _ ->
                                        Err "Expected exactly one upload HTTP request for scheduled export"
                            )
                        , admin.click 300 (Dom.id "admin_importBackendButton")
                        , admin.checkView
                            500
                            (Test.Html.Query.has [ Test.Html.Selector.text "Imported!" ])
                        , T.checkState
                            100
                            (\afterImportData ->
                                if
                                    (beforeExportData.backend.guilds == afterImportData.backend.guilds)
                                        && (beforeExportData.backend.dmChannels == afterImportData.backend.dmChannels)
                                        && (beforeExportData.backend.discordGuilds == afterImportData.backend.discordGuilds)
                                        && (beforeExportData.backend.discordDmChannels == afterImportData.backend.discordDmChannels)
                                        && (beforeExportData.backend.users == afterImportData.backend.users)
                                        && (beforeExportData.backend.discordUsers == afterImportData.backend.discordUsers)
                                then
                                    Ok ()

                                else
                                    Err "Expected at least one guild in backend after import"
                            )
                        ]
                    )
                ]
            )
        ]
    ]


backupRequests : T.Data FrontendModel BackendModel -> List HttpRequest
backupRequests data =
    List.filter
        (\request ->
            String.startsWith "http://localhost:3000/file/internal/upload-backup/backend-export-" request.url
                && (request.method == "POST")
                && (request.requestedBy == RequestedByBackend)
        )
        data.httpRequests


sendMessageRateLimitTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
sendMessageRateLimitTest config =
    RecordedTestExtra.startTest
        "SendMessage rate limiting"
        RecordedTestExtra.startTime
        config
        [ RecordedTestExtra.connectTwoUsersAndJoinNewGuild
            RecordedTestExtra.desktopWindow
            (\admin user ->
                let
                    guildId : Id GuildId
                    guildId =
                        Id.fromInt 1

                    channelId : Id ChannelId
                    channelId =
                        Id.fromInt 0

                    sendMessage :
                        T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                        -> Float
                        -> Int
                        -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    sendMessage client delayInMs changeIndex =
                        client.sendToBackend
                            delayInMs
                            (LocalModelChangeRequest (ChangeId changeIndex)
                                (Local_SendMessage
                                    (Time.millisToPosix 0)
                                    (GuildOrDmId_Guild guildId channelId)
                                    (NonemptyString 'm' ("sg " ++ String.fromInt changeIndex))
                                    (NoThreadWithMaybeMessage Nothing)
                                    SeqDict.empty
                                )
                            )

                    getMessageCount : BackendModel -> Int
                    getMessageCount backend =
                        case SeqDict.get guildId backend.guilds of
                            Just guild ->
                                case SeqDict.get channelId guild.channels of
                                    Just channel ->
                                        Array.length channel.messages

                                    Nothing ->
                                        -1

                            Nothing ->
                                -1

                    checkMessageCount : String -> Int -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    checkMessageCount label expected =
                        T.checkBackend
                            100
                            (\backend ->
                                let
                                    actual =
                                        getMessageCount backend
                                in
                                if actual == expected then
                                    Ok ()

                                else
                                    Err (label ++ ": Expected " ++ String.fromInt expected ++ " messages but got " ++ String.fromInt actual)
                            )
                in
                [ T.andThen
                    100
                    (\dataBefore ->
                        let
                            initialCount =
                                getMessageCount dataBefore.backend
                        in
                        [ List.range 0 (RateLimit.shortWindowMaxMessages - 1)
                            |> List.map (sendMessage admin 0)
                            |> T.collapsableGroup "Send messages up to rate limit"
                        , List.range RateLimit.shortWindowMaxMessages (RateLimit.shortWindowMaxMessages + 4)
                            |> List.map (sendMessage admin 0)
                            |> T.collapsableGroup "Send messages exceeding rate limit"
                        , checkMessageCount "After rate limit" (initialCount + RateLimit.shortWindowMaxMessages)
                        , T.collapsableGroup
                            "User2 can still send while admin is rate limited"
                            [ sendMessage user 0 200 ]
                        , checkMessageCount "User2 not rate limited" (initialCount + RateLimit.shortWindowMaxMessages + 1)
                        , T.collapsableGroup
                            "After rate limit window, sending works again"
                            [ sendMessage admin (Duration.inMilliseconds RateLimit.shortWindowDuration + 1) 100 ]
                        , checkMessageCount "After window reset" (initialCount + RateLimit.shortWindowMaxMessages + 2)
                        , List.range 101 (RateLimit.longWindowMaxMessages + 101)
                            |> List.map (sendMessage admin 2000)
                            |> T.collapsableGroup "Send messages exceeding rate limit"
                        , checkMessageCount "After long rate limit" (initialCount + RateLimit.longWindowMaxMessages + 1)
                        , sendMessage admin (Duration.inMilliseconds RateLimit.longWindowDuration) 1000
                        , checkMessageCount "After long rate limit has expired" (initialCount + RateLimit.longWindowMaxMessages + 2)
                        , T.checkBackend
                            100
                            (\backend ->
                                let
                                    actual =
                                        SeqDict.foldl (\_ array count -> Array.length array + count) 0 backend.sendMessageRateLimits
                                in
                                if actual == 2 then
                                    Ok ()

                                else
                                    Err ("Old rate limit logs aren't being filtered. Expected 2 but got " ++ String.fromInt actual)
                            )
                        ]
                    )
                ]
            )
        ]


attackerTriesToLeakSensitiveData :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> String
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
attackerTriesToLeakSensitiveData config discordOpReady discordOpSupplemental =
    T.start
        "Attacker tries to leak/modify sensitive data"
        RecordedTestExtra.startTime
        config
        [ RecordedTestExtra.linkDiscordAndLogin
            RecordedTestExtra.sessionId0
            "AT"
            RecordedTestExtra.adminEmail
            False
            discordOpReady
            discordOpSupplemental
            (\admin ->
                [ RecordedTestExtra.inviteUser
                    admin
                    (\user ->
                        [ RecordedTestExtra.writeMessage user 100 "sensitive guild message"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , RecordedTestExtra.writeMessage admin 100 "sensitive guild message 2"
                        , user.click 1000 (Dom.id "guild_openDm_0")
                        , RecordedTestExtra.writeMessage user 100 "sensitive DM message"
                        , T.connectFrontend
                            100
                            RecordedTestExtra.sessionIdAttacker
                            "/"
                            RecordedTestExtra.desktopWindow
                            (\attacker ->
                                [ RecordedTestExtra.handleLogin RecordedTestExtra.chromeDesktop RecordedTestExtra.attackerEmail attacker
                                , attacker.update 0 Types.EnableToFrontendLogging
                                , attacker.input 100 (Dom.id "loginForm_name") "Attacker"
                                , attacker.click 100 (Dom.id "loginForm_submit")
                                , T.andThen
                                    100
                                    (\before ->
                                        let
                                            attackerUserId : Id UserId
                                            attackerUserId =
                                                Id.fromInt 2

                                            guildId : Id GuildId
                                            guildId =
                                                Id.fromInt 0
                                        in
                                        [ List.indexedMap
                                            (\index localChange ->
                                                attacker.sendToBackend 100 (LocalModelChangeRequest (ChangeId index) localChange)
                                            )
                                            RecordedTestExtra.allAttackerLocalChanges
                                            |> T.collapsableGroup "attacks"
                                        , List.map (attacker.sendToBackend 100) RecordedTestExtra.allAttackerToBackendChanges
                                            |> T.collapsableGroup "attacks"
                                        , T.checkState
                                            500
                                            (\after ->
                                                let
                                                    errors : List String
                                                    errors =
                                                        (if SeqDict.get guildId before.backend.guilds == SeqDict.get guildId after.backend.guilds then
                                                            []

                                                         else
                                                            [ "Guild data was modified by attacker" ]
                                                        )
                                                            ++ (if before.backend.discordGuilds == after.backend.discordGuilds then
                                                                    []

                                                                else
                                                                    [ "Discord guild data was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.discordDmChannels == after.backend.discordDmChannels then
                                                                    []

                                                                else
                                                                    [ "Discord DM data was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.discordUsers == after.backend.discordUsers then
                                                                    []

                                                                else
                                                                    [ "Discord user data was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.pendingDiscordCreateMessages == after.backend.pendingDiscordCreateMessages then
                                                                    []

                                                                else
                                                                    [ "Pending Discord guild messages modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.pendingDiscordCreateDmMessages == after.backend.pendingDiscordCreateDmMessages then
                                                                    []

                                                                else
                                                                    [ "Pending Discord DM messages modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.dmChannels == after.backend.dmChannels then
                                                                    []

                                                                else
                                                                    [ "DM channels were modified by attacker" ]
                                                               )
                                                            ++ (if NonemptyDict.remove attackerUserId before.backend.users == NonemptyDict.remove attackerUserId after.backend.users then
                                                                    []

                                                                else
                                                                    [ "Users were modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.privateVapidKey == after.backend.privateVapidKey then
                                                                    []

                                                                else
                                                                    [ "Private VAPID key was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.slackClientSecret == after.backend.slackClientSecret then
                                                                    []

                                                                else
                                                                    [ "Slack client secret was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.openRouterKey == after.backend.openRouterKey then
                                                                    []

                                                                else
                                                                    [ "OpenRouter key was modified by attacker" ]
                                                               )
                                                            ++ (if before.backend.emailNotificationsEnabled == after.backend.emailNotificationsEnabled then
                                                                    []

                                                                else
                                                                    [ "Email notifications setting was modified by attacker" ]
                                                               )
                                                in
                                                case errors of
                                                    [] ->
                                                        Ok ()

                                                    _ ->
                                                        Err (String.join "; " errors)
                                            )
                                        , attacker.checkModel
                                            100
                                            (\model ->
                                                case model of
                                                    Types.Loaded loaded ->
                                                        case loaded.toFrontendLogs of
                                                            Just toFrontendLogs ->
                                                                let
                                                                    invalidToFrontends : Array ToFrontend
                                                                    invalidToFrontends =
                                                                        Array.filter RecordedTestExtra.attackerShouldNotGetThisToFrontend toFrontendLogs
                                                                in
                                                                if Array.isEmpty invalidToFrontends then
                                                                    Ok ()

                                                                else
                                                                    Array.toList invalidToFrontends
                                                                        |> List.map
                                                                            (\invalid ->
                                                                                Debug.toString invalid
                                                                            )
                                                                        |> String.join ", "
                                                                        |> (\a -> "The attacker received ToFrontend with potentially sensitive info: " ++ a)
                                                                        |> Err

                                                            Nothing ->
                                                                Err "Should have been logging toFrontend"

                                                    Types.Loading _ ->
                                                        Err "Attacker didn't load for some reason"
                                            )
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
