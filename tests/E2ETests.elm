module E2ETests exposing (main, setup)

import Array exposing (Array)
import Audio
import Backend
import Bytes exposing (Bytes)
import Codec
import Coord
import Dict
import Duration
import E2EDiscord
import E2EDrawing
import E2EGo
import E2EHelper
import E2ELogin
import E2EMedia
import E2EMisc
import E2EVoiceChat
import E2EWordSpellingGame
import Effect.Browser.Dom as Dom
import Effect.Browser.Events exposing (Visibility(..))
import Effect.Lamdera as Lamdera
import Effect.Test as T exposing (FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..), RequestedBy(..))
import EmailAddress
import Emoji
import Env
import Expect
import FileStatus
import Frontend
import Html.Attributes
import Id exposing (ChannelId, GuildId, GuildOrDmId(..), Id, ThreadRouteWithMaybeMessage(..), UserId)
import IdArray
import Json.Decode
import Json.Encode
import Local exposing (ChangeId(..))
import Log
import LoginForm
import MembersAndOwner
import NonemptyDict
import Pages.Home
import PersonName
import RateLimit
import RichText
import Route
import SecretId
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test.Html.Query
import Test.Html.Selector
import Time
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, LocalChange(..), ToBackend(..), ToFrontend)
import User exposing (NotificationLevel(..))
import UserSession exposing (SetViewing(..))
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
        handleNormalHttpRequests : { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> HttpResponse
        handleNormalHttpRequests =
            handleHttpRequestsWithUploadedImageSize (Just (Coord.xy 128 128))

        handleHttpRequestsWithUploadedImageSize uploadedImageSize ({ currentRequest } as httpRequests) =
            case String.split "/" currentRequest.url of
                [ "", "_i" ] ->
                    E2EHelper.httpBasic currentRequest.url 200 E2EHelper.infoEndpointResponse

                [ "", "compact-emoji.json" ] ->
                    E2EHelper.httpBasic currentRequest.url 200 emojiJson

                [ "http:", "", "localhost:8000", "NWL2023.txt" ] ->
                    E2EHelper.httpBasic currentRequest.url 200 "AA\nDATE\nNOSE\nLOAD\nROT\n"

                "https:" :: "" :: "rtc.live.cloudflare.com" :: "v1" :: "apps" :: _ :: rest ->
                    E2EHelper.mockCloudflareSfu rest httpRequests

                [ "https:", "", "api.cloudflare.com", "client", "v4", "graphql" ] ->
                    -- Realtime egress usage query. 1100 GB of SFU egress => (1100 - 1000) * $0.05 = $5.00
                    E2EHelper.httpBasic
                        currentRequest.url
                        200
                        """{"data":{"viewer":{"accounts":[{"sfu":[{"sum":{"egressBytes":1100000000000}}],"turn":[{"sum":{"egressBytes":0}}]}]}}}"""

                "http:" :: "" :: "localhost:3000" :: "file" :: rest ->
                    case rest of
                        "internal" :: rest2 ->
                            E2EHelper.handleInternalRequests discordStickerPacks currentRequest rest2

                        [ "upload" ] ->
                            E2EHelper.httpBasic
                                currentRequest.url
                                200
                                (Codec.encodeToString
                                    0
                                    FileStatus.uploadResponseCodec
                                    { fileHash = FileStatus.fileHash "123123123"
                                    , imageSize =
                                        Maybe.map
                                            (\size ->
                                                { imageSize = size
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
                                            )
                                            uploadedImageSize
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
                                                E2EHelper.httpBasic
                                                    currentRequest.url
                                                    200
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
                                            E2EHelper.httpBasic currentRequest.url 500 ""

                                _ ->
                                    E2EHelper.httpBasic currentRequest.url 500 ""

                        _ ->
                            UnhandledHttpRequest

                [ "https:", "", "api.postmarkapp.com", "email" ] ->
                    case currentRequest.body of
                        T.JsonBody json ->
                            case Json.Decode.decodeValue (Json.Decode.field "To" Json.Decode.string) json of
                                Ok email ->
                                    E2EHelper.httpBasic
                                        currentRequest.url
                                        200
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
                handleNormalHttpRequests
                E2EHelper.handlePortToJs
                handleFileRequest
                handleMultiFileUpload
                E2EHelper.domain

        -- Same as normalConfig except the upload response reports no image size,
        -- like the Rust server does for files it can't decode as an image.
        nonImageUploadConfig : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        nonImageUploadConfig =
            T.Config
                Frontend.app_
                Backend.app_
                (handleHttpRequestsWithUploadedImageSize Nothing)
                E2EHelper.handlePortToJs
                handleFileRequest
                handleMultiFileUpload
                E2EHelper.domain

        imageUploadConfig : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        imageUploadConfig =
            T.Config
                Frontend.app_
                Backend.app_
                handleNormalHttpRequests
                E2EHelper.handlePortToJs
                handleFileRequest
                (\_ ->
                    UploadMultipleFiles
                        (T.uploadBytesFile "test-image.png" "image/png" atUserIcon E2EHelper.startTime)
                        []
                )
                E2EHelper.domain

        -- Same as imageUploadConfig except the uploaded image is reported as
        -- being 800x100 pixels, wide enough to get scaled down to fit the screen
        wideImageUploadConfig : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        wideImageUploadConfig =
            T.Config
                Frontend.app_
                Backend.app_
                (handleHttpRequestsWithUploadedImageSize (Just (Coord.xy 800 100)))
                E2EHelper.handlePortToJs
                handleFileRequest
                (\_ ->
                    UploadMultipleFiles
                        (T.uploadBytesFile "test-image.png" "image/png" atUserIcon E2EHelper.startTime)
                        []
                )
                E2EHelper.domain

        -- Uploads a video file. The upload response reports no image size, just
        -- like the Rust server does for files it can't decode as an image.
        videoUploadConfig : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        videoUploadConfig =
            T.Config
                Frontend.app_
                Backend.app_
                (handleHttpRequestsWithUploadedImageSize Nothing)
                E2EHelper.handlePortToJs
                handleFileRequest
                (\_ ->
                    UploadMultipleFiles
                        (T.uploadBytesFile "test-video.mp4" "video/mp4" atUserIcon E2EHelper.startTime)
                        []
                )
                E2EHelper.domain

        -- Uploads an audio file. Like videoUploadConfig, the upload response
        -- reports no image size.
        audioUploadConfig : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        audioUploadConfig =
            T.Config
                Frontend.app_
                Backend.app_
                (handleHttpRequestsWithUploadedImageSize Nothing)
                E2EHelper.handlePortToJs
                handleFileRequest
                (\_ ->
                    UploadMultipleFiles
                        (T.uploadBytesFile "test-audio.mp3" "audio/mpeg" atUserIcon E2EHelper.startTime)
                        []
                )
                E2EHelper.domain
    in
    [ attackerTriesToLeakSensitiveData normalConfig discordOp0Ready discordOp0ReadySupplemental
    , E2EMedia.videoAttachmentTest videoUploadConfig
    , E2EMedia.audioAttachmentTest audioUploadConfig
    , E2EMisc.inviteUserAndDmChat normalConfig
    , E2EMisc.friendsSearchTest normalConfig
    , E2EMisc.handleNavigationHistoryOnMobile normalConfig
    , E2EMisc.largePasteBecomesAttachment nonImageUploadConfig
    , E2EMedia.imageViewerTests imageUploadConfig
    , E2EHelper.startTest
        "Admin can open admin page"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_goToHomepage")
                ]
            )
        ]
    , E2EMisc.inactiveThreadsAreHiddenTest normalConfig
    , E2EHelper.startTest
        "Admin can disable Discord account linking"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_Users")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.text "Discord account linking enabled" ])
                , T.checkState
                    100
                    (\data ->
                        if data.backend.discordLinkingEnabled then
                            Ok ()

                        else
                            Err "Discord account linking should be enabled by default"
                    )
                , admin.click 100 (Dom.id "discordLinkingEnabledId")
                , T.checkState
                    100
                    (\data ->
                        if data.backend.discordLinkingEnabled then
                            Err "Discord account linking should have been disabled after toggling the checkbox"

                        else
                            Ok ()
                    )
                ]
            )

        -- With linking disabled, a user that logs in through the link page has
        -- their LinkDiscordRequest rejected by the backend.
        , T.connectFrontend
            100
            (Lamdera.sessionIdFromString "JoeSession")
            E2EHelper.linkDiscordUrl
            E2EHelper.desktopWindow
            (\user ->
                [ T.andThen
                    10
                    (\data -> [ user.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                , E2EHelper.handleLoginFromLoginPage E2EHelper.joeEmail user
                , user.input 100 (Dom.id "loginForm_name") "Joe"
                , user.click 100 (Dom.id "loginForm_submit")

                -- The backend rejects the LinkDiscordRequest, so the frontend
                -- lands back on the link-discord error page instead of linking.
                , user.checkView
                    1000
                    (Test.Html.Query.has [ Test.Html.Selector.text "This Discord link has expired" ])
                , T.checkState
                    100
                    (\data ->
                        if SeqDict.isEmpty data.backend.discordUsers then
                            Ok ()

                        else
                            Err "No Discord account should be linked while linking is disabled"
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Regenerate server secret button hits rust-server and applies response"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
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
                        if SecretId.toString data.backend.serverSecret == E2EHelper.regeneratedServerSecretValue then
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
    , E2EHelper.startTest
        "Create message with embeds and then edit that message"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
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
                [ E2EHelper.writeMessage admin 100 "Test https://elm.camp/ https://elm.camp/ https://meetdown.app/"
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
    , E2EHelper.startTest
        "Message with bullet points and rich text formatting"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ -- Focus the channel text input and type a message that uses bullet
                  -- points along with various other rich text formatting.
                  E2EHelper.focusEvent admin 100 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.click 100 (Dom.id "channel_textinput")
                , admin.input 100 (Dom.id "channel_textinput") "# Rich text demo"
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , admin.input 100 (Dom.id "channel_textinput") "This line has *bold*, _italic_, __underline__, ~~strikethrough~~, ||spoiler|| and `inline code`.\n* First bullet point\n* Second bullet with *bold* text\n* Third bullet with a [link](https://elm-lang.org/)"

                -- Snapshot the formatted preview while the message is still in the text input.
                , E2EHelper.tallSnapshot admin 100 { name = "Rich text message in text input" }

                -- Send the message and snapshot how it renders in the channel.
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , E2EHelper.focusEvent admin 100 Nothing Nothing
                , E2EHelper.tallSnapshot admin 1000 { name = "Rich text message after being sent" }

                -- The bullet points should render in the same order they were written.
                , admin.checkView
                    100
                    (\html ->
                        html
                            |> Test.Html.Query.find [ Test.Html.Selector.tag "ul" ]
                            |> Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                            |> Test.Html.Query.index 0
                            |> Test.Html.Query.has [ Test.Html.Selector.text "First bullet point" ]
                    )
                , admin.checkView
                    100
                    (\html ->
                        html
                            |> Test.Html.Query.find [ Test.Html.Selector.tag "ul" ]
                            |> Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                            |> Test.Html.Query.index 2
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Third bullet with a " ]
                    )
                , admin.mouseEnter 100 (Dom.id "guild_message_2") ( 100, 100 ) []
                , admin.click 100 (Dom.id "miniView_reply")
                , admin.input 100 (Dom.id "channel_textinput") "Reply"
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , E2EHelper.tallSnapshot admin 1000 { name = "Rich text message previewed in reply" }
                ]
            )
        ]
    , E2EDrawing.drawOnMessages imageUploadConfig
    , E2EDrawing.drawingScalesWithImages wideImageUploadConfig
    , E2EHelper.startTest
        "Friend label shows typing indicator"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ admin.click 100 (Dom.id "guild_openDm_2")
                , E2EHelper.writeMessage admin 100 "Hello from admin"
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
                , admin.click 100 (Dom.id "guild_friendLabel_2")
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
                , admin.click 100 (Dom.id "guild_friendLabel_2")
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Editing..." ])
                ]
            )
        ]
    , E2EHelper.startTest
        "Emoji selector arrow key navigation"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                let
                    checkHover :
                        (Maybe Emoji.EmojiOrSticker -> Result String ())
                        -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
                    checkHover predicate =
                        admin.checkModel
                            100
                            (\model ->
                                case Audio.userModel model of
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
    , E2EHelper.startTest
        "User receives email notifications when the setting is enabled"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                let
                    -- The guild created in the setup helper has id 1.
                    guildId : Id GuildId
                    guildId =
                        Id.fromInt 1
                in
                [ -- Get notified about every message in the guild and stop viewing
                  -- the channel, so that incoming messages generate notifications.
                  user.sendToBackend
                    100
                    (LocalModelChangeRequest (ChangeId 100) (Local_SetGuildNotificationLevel guildId NotifyOnEveryMessage))
                , user.sendToBackend
                    100
                    (LocalModelChangeRequest (ChangeId 101) (Local_CurrentlyViewing StopViewingChannel))

                -- Email notifications are off by default, so this message must not send an email.
                , admin.click 100 (Dom.id "channel_textinput")
                , admin.input 100 (Dom.id "channel_textinput") "Before enabling email"
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , T.checkState
                    100
                    (\data ->
                        case List.filterMap (E2EHelper.isNotificationEmail E2EHelper.userEmail) data.httpRequests of
                            [] ->
                                Ok ()

                            _ :: _ ->
                                Err "No email should be sent while email notifications are disabled"
                    )

                -- Enable email notifications through the user options UI.
                , user.click 100 (Dom.id "guild_showUserOptions")
                , user.keyUp 100 (Dom.id "userOptions_emailNotifications") "ArrowDown" []
                , user.click 100 (Dom.id "userOptions_closeUserOptions")

                -- Closing the user options returns the user to the channel, so stop viewing again.
                , user.sendToBackend
                    100
                    (LocalModelChangeRequest (ChangeId 102) (Local_CurrentlyViewing StopViewingChannel))

                -- Now a new message should trigger an email notification to the user.
                , admin.click 100 (Dom.id "channel_textinput")
                , admin.input 100 (Dom.id "channel_textinput") "You have a *new* message"
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , T.checkState
                    100
                    (\data ->
                        case List.filterMap (E2EHelper.isNotificationEmail E2EHelper.userEmail) data.httpRequests of
                            [ body ] ->
                                if String.contains "You have a *new* message" body then
                                    Ok ()

                                else
                                    Err "Notification email did not contain the message text"

                            [] ->
                                Err "Expected a notification email after enabling email notifications"

                            _ ->
                                Err "Too many notification emails"
                    )

                -- Sending the email is logged along with the recipient and whether it succeeded.
                , T.checkBackend
                    100
                    (\backend ->
                        if
                            Array.toList backend.logs
                                |> List.any
                                    (\entry ->
                                        case entry.log of
                                            Log.NotificationEmail (Ok ()) emailAddress ->
                                                emailAddress == E2EHelper.userEmail

                                            _ ->
                                                False
                                    )
                        then
                            Ok ()

                        else
                            Err "Expected a successful NotificationEmail log entry for the user"
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Message length limit and counter"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
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

                    -- Goes over the limit by appending fewer than 1000 chars to the previous
                    -- input, so it doesn't count as a large paste (which would get converted
                    -- into a file attachment instead of overflowing the message).
                    overLimit : String
                    overLimit =
                        atThreshold ++ String.repeat 901 "d"

                    overLimitEdit : String
                    overLimitEdit =
                        atLimit ++ "d"
                in
                [ E2EHelper.focusEvent admin 100 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
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
                , admin.input 200 (Dom.id "editMessageTextInput") overLimitEdit
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
    , E2EHelper.startTest
        "Message length limit and counter mobile"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.iphone14Window
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

                    -- Goes over the limit by appending fewer than 1000 chars to the previous
                    -- input, so it doesn't count as a large paste (which would get converted
                    -- into a file attachment instead of overflowing the message).
                    overLimit : String
                    overLimit =
                        atThreshold ++ String.repeat 901 "d"

                    overLimitEdit : String
                    overLimitEdit =
                        atLimit ++ "d"
                in
                [ E2EHelper.focusEvent admin 100 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
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
                , admin.input 200 (Dom.id "editMessageTextInput") overLimitEdit
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
    , T.testGroup "Discord" (E2EDiscord.discordTests normalConfig discordOp0Ready discordOp0ReadySupplemental)
    , E2EHelper.startTest
        "Connect multiple devices"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\adminA ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail adminA
                , adminA.click 100 (Dom.id "guild_showUserOptions")
                , adminA.click 100 (Dom.id "userOptions_connectedDevices")
                , E2EHelper.hasExactText adminA [ "Desktop • Firefox", "Current device" ]
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    "/"
                    E2EHelper.desktopWindow
                    (\adminB ->
                        [ E2EHelper.handleLogin E2EHelper.safariIphone E2EHelper.adminEmail adminB
                        , E2EHelper.hasExactText adminA [ "Mobile • Safari", "Desktop • Firefox", "Current device" ]
                        , adminB.click 100 (Dom.id "guild_showUserOptions")
                        , adminB.click 100 (Dom.id "userOptions_connectedDevices")
                        , T.connectFrontend
                            100
                            E2EHelper.sessionId2
                            "/"
                            E2EHelper.desktopWindow
                            (\adminC ->
                                [ E2EHelper.handleLogin E2EHelper.chromeDesktop E2EHelper.adminEmail adminC
                                , E2EHelper.hasExactText
                                    adminA
                                    [ "Mobile • Safari"
                                    , "Desktop • Firefox"
                                    , "Current device"
                                    , "Desktop • Chrome"
                                    ]
                                , adminC.click 100 (Dom.id "guild_showUserOptions")
                                , adminC.click 100 (Dom.id "userOptions_connectedDevices")
                                , E2EHelper.hasExactText
                                    adminC
                                    [ "Mobile • Safari"
                                    , "Desktop • Firefox"
                                    , "Desktop • Chrome"
                                    , "Current device"
                                    ]
                                ]
                            )
                        , adminB.click 100 (Dom.id "options_logout")
                        , E2EHelper.hasNotExactText adminA [ "Mobile • Safari" ]
                        , E2EHelper.hasExactText adminA [ "Desktop • Chrome", "Desktop • Firefox", "Current device" ]
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Logout another session linked to you"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\adminA ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail adminA
                , adminA.click 100 (Dom.id "guild_showUserOptions")
                , adminA.click 100 (Dom.id "userOptions_connectedDevices")
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    "/"
                    E2EHelper.desktopWindow
                    (\adminB ->
                        [ E2EHelper.handleLogin E2EHelper.safariIphone E2EHelper.adminEmail adminB

                        -- adminA sees adminB's session in the connected devices list
                        , E2EHelper.hasExactText adminA [ "Mobile • Safari", "Desktop • Firefox", "Current device" ]

                        -- adminB is logged in (it's viewing the app, not the login page)
                        , E2EHelper.hasNotText adminB [ "Login/Signup" ]

                        -- adminA logs out adminB's session
                        , adminA.click 100 (E2EHelper.logoutOtherSessionButtonId E2EHelper.sessionId1)

                        -- adminB has been logged out and is shown the login page
                        , E2EHelper.hasText adminB [ "Login/Signup" ]

                        -- adminB's session is removed from adminA's connected devices list, and adminA
                        -- itself stays logged in
                        , E2EHelper.hasNotExactText adminA [ "Mobile • Safari" ]
                        , E2EHelper.hasExactText adminA [ "Desktop • Firefox", "Current device" ]
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "spoilers"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.writeMessage admin 100 "This message is ||very|| ||secret||"
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
                , E2EHelper.writeMessage admin 100 "Another ||*super*|| *||secret||* message"
                , E2EHelper.clickSpoiler user (Dom.id "spoiler_1_0")
                , E2EHelper.clickSpoiler user (Dom.id "spoiler_1_1")
                , E2EHelper.clickSpoiler user (Dom.id "spoiler_2_1")
                , E2EHelper.clickSpoiler user (Dom.id "spoiler_2_0")
                , E2EHelper.createThread admin (Id.fromInt 2)
                , E2EHelper.clickSpoiler admin (Dom.id "spoiler_2_0")
                , E2EHelper.clickSpoiler admin (Dom.id "spoiler_2_1")
                , E2EHelper.writeMessage admin 100 "||*super*|| ||duper|| *||secret||* text"
                , user.click 100 (Dom.id "guild_threadStarterIndicator_2")
                , E2EHelper.clickSpoiler admin (Dom.id "threadSpoiler_0_0")
                , E2EHelper.clickSpoiler admin (Dom.id "threadSpoiler_0_2")
                ]
            )
        ]
    , E2EHelper.startTest
        "Mobile edit message"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId2
            "/"
            E2EHelper.iphone14Window
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.safariIphone E2EHelper.adminEmail admin
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , E2EHelper.writeMessageMobile admin "Test"
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
    , E2EHelper.startTest
        "Desktop edit message"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId2
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.safariIphone E2EHelper.adminEmail admin
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , E2EHelper.writeMessageMobile admin "Test"
                , admin.custom
                    100
                    (Dom.id "guild_message_0")
                    "contextmenu"
                    (Json.Encode.object
                        [ ( "clientX", Json.Encode.float 50 )
                        , ( "clientY", Json.Encode.float 150 )
                        ]
                    )
                , E2EHelper.hasExactText admin [ "Edit message" ]
                , admin.click 2000 (Dom.id "messageMenu_editMessage")
                , E2EHelper.hasNotExactText admin [ "Edit message" ]
                , admin.input 1000 (Dom.id "editMessageTextInput") "Test Edited"
                , admin.input 200 (Dom.id "editMessageTextInput") "Test Edited\nLinebreak"
                , E2EHelper.hasText admin [ "to cancel edit" ]
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , E2EHelper.hasNotText admin [ "to cancel edit" ]
                ]
            )
        ]
    , E2EHelper.startTest
        "Edit guild message by pressing up arrow in channel input"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                -- More than five messages, interleaved between both users, and the most recent
                -- message overall is from the other user. Pressing up should still skip the other
                -- user's messages and edit the admin's own most recent message.
                [ E2EHelper.writeMessage admin 100 "Admin message one"
                , E2EHelper.writeMessage user 100 "User message one"
                , E2EHelper.writeMessage admin 100 "Admin message two"
                , E2EHelper.writeMessage user 100 "User message two"
                , E2EHelper.writeMessage admin 100 "Admin message three"
                , E2EHelper.writeMessage user 100 "User message three"
                , E2EHelper.editMostRecentMessageViaArrowUp admin "Admin message three" "Admin message three edited"

                -- Only the admin's most recent message was edited; earlier messages are untouched.
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Admin message three" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Admin message one" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Admin message two" ])

                -- The other user's messages, including the most recent one, are untouched.
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "User message three" ])

                -- The edit is also visible to the other user.
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Admin message three edited" ])
                ]
            )
        ]
    , E2EHelper.startTest
        "Edit DM message by pressing up arrow in channel input"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ user.click 1000 (Dom.id "guild_openDm_0")
                        , E2EHelper.writeMessage user 100 "Hello from user"
                        , admin.click 100 (Dom.id "guildsColumn_openDm_2")
                        , E2EHelper.writeMessage admin 100 "First DM"
                        , E2EHelper.writeMessage admin 100 "Second DM"
                        , E2EHelper.editMostRecentMessageViaArrowUp admin "Second DM" "Second DM edited"

                        -- Only the most recent message we wrote was edited.
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Second DM" ])
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "First DM" ])

                        -- The other side of the DM sees the edit too.
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Second DM edited" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Edit thread message by pressing up arrow in channel input"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                -- More than five thread messages, interleaved, with the other user sending the
                -- most recent message.
                [ E2EHelper.writeMessage admin 100 "Thread starter"
                , E2EHelper.createThread admin (Id.fromInt 1)
                , E2EHelper.writeMessage admin 100 "Admin thread one"
                , user.click 100 (Dom.id "guild_threadStarterIndicator_1")
                , E2EHelper.writeMessage user 100 "User thread one"
                , E2EHelper.writeMessage admin 100 "Admin thread two"
                , E2EHelper.writeMessage user 100 "User thread two"
                , E2EHelper.writeMessage admin 100 "Admin thread three"
                , E2EHelper.writeMessage user 100 "User thread three"
                , E2EHelper.editMostRecentMessageViaArrowUp admin "Admin thread three" "Admin thread three edited"

                -- Only the admin's most recent thread message was edited; the earlier replies are untouched.
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Admin thread three" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Admin thread one" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "User thread three" ])
                ]
            )
        ]
    , E2EHelper.startTest
        "Change notification level"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , user.keyUp 100 (Dom.id "guild_notificationLevel") "ArrowDown" []
                , E2EHelper.writeMessage admin 100 "Test"
                , E2EHelper.checkNotification "Test"
                , E2EHelper.writeMessage admin 100 "Test 2"
                , user.click 100 (Dom.id "guild_openChannel_0")
                , E2EHelper.writeMessage user 100 "I shouldn't get notified"
                , E2EHelper.checkNoNotification "I shouldn't get notified"
                ]
            )
        ]

    --, E2EHelper.startTest
    --    "Remove direct mention when viewed on another session"
    --    E2EHelper.startTime
    --    normalConfig
    --    [ E2EHelper.connectTwoUsersAndJoinNewGuild
    --       E2EHelper.desktopWindow (\admin user ->
    --            [ user.click 100 (Dom.id "guildIcon_showFriends")
    --            , writeMessage admin 100 "@Stevie Steve"
    --            , writeMessage admin 100 "@Stevie Steve"
    --            , writeMessage admin 100 "@Stevie Steve"
    --            , hasExactText user [ "3" ]
    --            , T.connectFrontend
    --                100
    --                sessionId1
    --                (Route.encode Route.HomePageRoute)
    --                E2EHelper.desktopWindow
    --                (\userReload ->
    --                    [ userReload.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson E2EHelper.firefoxDesktop)
    --                    , userReload.click 100 (Dom.id "guild_openGuild_1")
    --                    , hasExactText user [ "3" ]
    --                    , userReload.click 100 (Dom.id "guildIcon_showFriends")
    --                    , hasNotExactText user [ "3" ]
    --                    ]
    --                )
    --            ]
    --        )
    --    ]
    , E2EHelper.startTest
        "Check notification icons appear"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guildIcon_showFriends")
                , admin.click 100 (Dom.id "guild_newChannel")
                , admin.input 100 (Dom.id "newChannelName") "Second-channel-goes-here"
                , admin.click 100 (Dom.id "guild_createChannel")
                , E2EHelper.writeMessage admin 100 "First message"
                , E2EHelper.writeMessage admin 100 "Next message"
                , E2EHelper.writeMessage admin 100 "Third message"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "3") ])
                , user.click 100 (Dom.id "guild_openGuild_1")
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "3") ])
                , E2EHelper.writeMessage admin 100 "@Stevie Steve Hello!"
                , E2EHelper.writeMessage admin 100 "@Stevie Steve Hello again!"
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "2") ])
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    (Route.encode Route.HomePageRoute)
                    E2EHelper.desktopWindow
                    (\userReload ->
                        [ T.andThen
                            10
                            (\data -> [ userReload.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "2") ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Guild icon notification is shown"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.writeMessage admin 100 "See if notification appears next to guild icon"
                , E2EHelper.tallSnapshot user 100 { name = "Guild icon new message notification" }
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    (Route.encode Route.HomePageRoute)
                    E2EHelper.desktopWindow
                    (\_ ->
                        [ E2EHelper.tallSnapshot user 100 { name = "Guild icon new message notification on reload" } ]
                    )
                , E2EHelper.writeMessage admin 100 "@Stevie Steve now you should see a red icon"
                , E2EHelper.tallSnapshot user 100 { name = "Guild icon new mention notification" }
                ]
            )
        ]
    , E2EHelper.startTest
        "No messages missing even in long chat history"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\_ user ->
                [ List.range 0 (VisibleMessages.pageSize * 2)
                    |> List.map (\index -> E2EHelper.writeMessage user 1000 ("Message " ++ String.fromInt (index + 1)))
                    |> T.group
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    (Route.encode Route.HomePageRoute)
                    E2EHelper.desktopWindow
                    (\userReload ->
                        [ T.andThen
                            10
                            (\data -> [ userReload.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , userReload.click 100 (Dom.id "guild_openGuild_1")
                        , E2EHelper.writeMessage userReload 100 "Another message"
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Another message" ])
                        , E2EHelper.hasNotExactText userReload [ "This is the start of #general", "Message 31" ]
                        , E2EHelper.hasExactText userReload [ "Message 32", "Message 61" ]
                        , E2EHelper.noMissingMessages 100 userReload
                        , E2EHelper.scrollToTop userReload
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
                        , E2EHelper.noMissingMessages 100 userReload
                        , E2EHelper.scrollToMiddle userReload
                        , userReload.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "This is the start of #general" ])
                        , E2EHelper.scrollToTop userReload
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "This is the start of #general" ])
                        , T.backendUpdate
                            5000
                            (Types.UserDisconnected E2EHelper.sessionId1 userReload.clientId)
                        , T.backendUpdate
                            100
                            (Types.UserConnected E2EHelper.sessionId1 userReload.clientId)
                        , userReload.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Another message" ])
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Notifications"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
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
                , E2EHelper.checkNoNotification "@Stevie Steve Hi!"
                , E2EHelper.enableNotifications False admin
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
                , E2EHelper.checkNoNotification "Hello admin!"
                , E2EHelper.createThread admin (Id.fromInt 2)
                , admin.input 100 (Dom.id "channel_textinput") "Lets move this to a thread..."
                , user.checkView
                    100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.exactText "AT is typing..." ]
                    )
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , E2EHelper.checkNotification "Lets move this to a thread..."
                , user.click 100 (Dom.id "guild_threadStarterIndicator_2")
                , admin.click 100 (Dom.id "guild_openDm_2")
                , E2EHelper.writeMessage admin 100 "Here's a DM to you"
                , user.click 100 (Dom.id "guildsColumn_openDm_0")
                , E2EHelper.writeMessage user 100 "Here's a reply!"
                , E2EHelper.writeMessage user 100 "And another reply"
                , user.update 100 (Audio.userMsg (Types.VisibilityChanged Hidden))
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    (Route.encode Route.HomePageRoute)
                    E2EHelper.desktopWindow
                    (\userReload ->
                        [ T.andThen
                            10
                            (\data -> [ userReload.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                        , userReload.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.id "guildsColumn_openDm_0" ]
                            )
                        , userReload.click 100 (Dom.id "guildIcon_showFriends")
                        , userReload.click 100 (Dom.id "guild_friendLabel_0")
                        , E2EHelper.noMissingMessages 20 userReload
                        , userReload.click 100 (Dom.id "guild_openGuild_1")
                        , E2EHelper.noMissingMessages 20 userReload
                        , userReload.click 100 (Dom.id "guild_openChannel_0")
                        , E2EHelper.noMissingMessages 20 userReload
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "No DM push notification while viewing the channel"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                -- `user` has push notifications enabled and is currently viewing the guild channel (not the DM).
                [ admin.click 100 (Dom.id "guild_openDm_2")

                -- Positive control: while the user isn't viewing the DM they should get a push notification.
                , E2EHelper.writeMessage admin 100 "DM while away"
                , E2EHelper.checkNotification "DM while away"

                -- Now the user opens (and is therefore viewing) the DM channel.
                , user.click 100 (Dom.id "guildsColumn_openDm_0")
                , E2EHelper.writeMessage admin 100 "DM while viewing"

                -- The user is looking at the channel the message arrived in, so no push notification should be sent.
                , E2EHelper.checkNoNotification "DM while viewing"
                ]
            )
        ]
    , E2EHelper.startTest
        "No guild push notification while viewing the channel"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                -- `user` has push notifications enabled and is currently viewing the guild channel.
                [ E2EHelper.writeMessage admin 100 "@Stevie Steve while viewing"

                -- The user is looking at the channel the message arrived in, so no push notification should be sent.
                , E2EHelper.checkNoNotification "@Stevie Steve while viewing"

                -- Navigate the user away from the channel.
                , user.click 100 (Dom.id "guildIcon_showFriends")

                -- Positive control: while the user isn't viewing the channel they should get a push notification.
                , E2EHelper.writeMessage admin 100 "@Stevie Steve while away"
                , E2EHelper.checkNotification "@Stevie Steve while away"
                ]
            )
        ]
    , E2EHelper.startTest
        "Push notification sent when a game is started"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                -- `user` has push notifications enabled. Both start out viewing the guild's first channel.
                [ -- Guild case: move the user off the channel, then admin starts a Word Spelling Game in
                  -- it. The user isn't viewing the channel, so the game start should push a notification.
                  user.click 100 (Dom.id "guildIcon_showFriends")
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Word Spelling Game")
                , admin.click 100 (Dom.id "wsg_advancedSection")
                , admin.input 100 (Dom.id "wsg_lettersInput") "AADEEIILMNNOORRSSTT"
                , admin.click 100 (Dom.id "wsg_start")
                , E2EHelper.checkNotification "Word Spelling Game started"

                -- DM case: admin opens the DM with the other user and starts a Go match there. The user
                -- isn't viewing the DM either, so starting the game should push a notification to them.
                , admin.click 100 (Dom.id "guild_openDm_2")
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Go (Baduk)")
                , admin.click 100 (Dom.id "go_start")
                , E2EHelper.checkNotification "Go match started"
                ]
            )
        ]
    , E2EVoiceChat.voiceChatTest normalConfig
    , E2EVoiceChat.cloudflareCostTest normalConfig
    , E2EHelper.startTest "Logins are rate limited"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\user ->
                let
                    openLoginAndSubmitEmail isFirst delay =
                        T.group
                            [ if isFirst then
                                T.group []

                              else
                                user.click delay (Dom.id "loginForm_cancelButton")
                            , user.click delay Pages.Home.loginButtonId
                            , user.input 100 LoginForm.emailInputId (EmailAddress.toString E2EHelper.adminEmail)
                            , user.click 100 LoginForm.submitEmailButtonId
                            ]

                    tooManyIncorrectAttempts : List Test.Html.Selector.Selector
                    tooManyIncorrectAttempts =
                        [ Test.Html.Selector.text "Too many incorrect attempts." ]
                in
                [ T.andThen
                    10
                    (\data -> [ user.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                , openLoginAndSubmitEmail True 100
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
                , E2EHelper.tallSnapshot user 100 { name = "Too many incorrect attempts" }
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (E2EHelper.isLoginEmail E2EHelper.adminEmail) data.httpRequests of
                            loginCode :: _ ->
                                [ user.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode) ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                , user.checkView 100 (Test.Html.Query.has tooManyIncorrectAttempts)
                , [ E2EHelper.hasNotText user [ "Too many login attempts have been made." ]
                  , openLoginAndSubmitEmail False 100
                  ]
                    |> T.group
                    |> List.repeat 6
                    |> T.group
                , E2EHelper.hasText user [ "Too many login attempts have been made." ]
                , E2EHelper.tallSnapshot user 100 { name = "Too many login attempts" }
                , -- Should be able to log in again after some time has passed
                  openLoginAndSubmitEmail False (5 * 60 * 1000)
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (E2EHelper.isLoginEmail E2EHelper.adminEmail) data.httpRequests of
                            loginCode :: _ ->
                                [ user.input 100 LoginForm.loginCodeInputId (String.fromInt loginCode) ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                , E2EHelper.hasExactText user [ PersonName.toString Backend.adminUser.name ]
                ]
            )
        , T.checkState
            (Duration.hours 4.01 |> Duration.inMilliseconds)
            (\data ->
                case List.filterMap (E2EHelper.isLogErrorEmail E2EHelper.adminEmail) data.httpRequests of
                    [ "LoginsRateLimited" ] ->
                        Ok ()

                    _ ->
                        Err "Expected to only see LoginsRateLimited as an error email"
            )
        ]
    , E2EHelper.startTest "Cancel login code then retry with new code"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\user ->
                [ T.andThen
                    10
                    (\data -> [ user.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                , user.click 100 Pages.Home.loginButtonId
                , user.input 100 LoginForm.emailInputId (EmailAddress.toString E2EHelper.adminEmail)
                , user.click 100 LoginForm.submitEmailButtonId

                -- We should now be on the login code screen. Press cancel instead of entering the code.
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Check your email for a code" ])
                , user.click 100 LoginForm.cancelButtonId
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Check your email for a code" ])

                -- Try again with the same email and use the new login code that gets sent.
                , user.click 100 Pages.Home.loginButtonId
                , user.input 100 LoginForm.emailInputId (EmailAddress.toString E2EHelper.adminEmail)
                , user.click 100 LoginForm.submitEmailButtonId
                , T.andThen
                    100
                    (\data ->
                        case List.filterMap (E2EHelper.isLoginEmail E2EHelper.adminEmail) data.httpRequests of
                            newLoginCode :: _ ->
                                [ user.input 100 LoginForm.loginCodeInputId (String.fromInt newLoginCode) ]

                            _ ->
                                [ T.checkState 100 (\_ -> Err "Didn't find login email") ]
                    )
                , E2EHelper.hasExactText user [ PersonName.toString Backend.adminUser.name ]
                ]
            )
        , E2EHelper.checkNoErrorLogs
        ]
    , T.testGroup
        "Login tests"
        (E2ELogin.loginTests False normalConfig ++ E2ELogin.loginTests True normalConfig)
    , E2EHelper.startTest
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
                , T.andThen
                    10
                    (\data ->
                        [ tabA.portEvent
                            2
                            "load_startup_data_from_js"
                            (E2EHelper.startupDataJson data.time "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0")
                        ]
                    )
                , tabA.portEvent 19 "load_user_settings_from_js" (Json.Encode.string "")
                , T.connectFrontend
                    17
                    (Lamdera.sessionIdFromString "24334c04b8f7b594cdeedebc2a8029b82943b0a6")
                    "/"
                    { width = 1887, height = 674 }
                    (\tabB ->
                        [ tabB.portEvent 11 "check_notification_permission_from_js" (Json.Encode.string "granted")
                        , tabB.portEvent 8 "load_user_settings_from_js" (Json.Encode.string "")
                        , E2EHelper.handleLogin "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0" E2EHelper.adminEmail tabB
                        , tabA.click 1747 (Dom.id "guild_openGuild_0")
                        , E2EHelper.writeMessage tabA 100 "Test"
                        , tabB.click 111 (Dom.id "guild_openGuild_0")
                        , E2EHelper.focusEvent tabB 25 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , tabA.mouseEnter 991 (Dom.id "guild_message_0") ( 620, 54 ) []
                        , E2EHelper.focusEvent tabA 921 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , E2EHelper.focusEvent tabA 4 Nothing Nothing
                        , E2EHelper.focusEvent tabB 17 Nothing Nothing
                        , tabA.click 28 (Dom.id "miniView_reply")
                        , E2EHelper.focusEvent tabA 8 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                        , tabA.mouseLeave 375 (Dom.id "guild_message_0") ( 1286, 57 ) []
                        , tabA.click 457 (Dom.id "channel_textinput")
                        , tabA.input 781 (Dom.id "channel_textinput") "Test2"
                        , E2EHelper.focusEvent tabA 4 Nothing Nothing
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
                        , E2EHelper.createThread tabA (Id.fromInt 0)
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
                        , E2EHelper.focusEvent tabA 2357 Nothing Nothing
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
    , E2EHelper.startTest
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
                , tabA.portEvent 990 "load_user_settings_from_js" (Json.Encode.string "")
                , E2EHelper.handleLogin "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0" E2EHelper.adminEmail tabA
                , tabA.click 17660 (Dom.id "guild_openGuild_0")
                , E2EHelper.focusEvent tabA 17 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , E2EHelper.focusEvent tabA 3994 Nothing Nothing
                , tabA.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Unable to reach the server." ])
                ]
            )
        ]
    , E2EHelper.startTest
        "Export and import backend round-trip"
        E2EHelper.startTime
        (T.Config
            Frontend.app_
            Backend.app_
            handleNormalHttpRequests
            E2EHelper.handlePortToJs
            (\requestData ->
                case requestData.data.downloads of
                    [ backup ] ->
                        case backup.content of
                            T.BytesFile bytes ->
                                UploadFile
                                    (T.uploadBytesFile backup.filename backup.mimeType bytes E2EHelper.startTime)

                            T.StringFile _ ->
                                UnhandledFileUpload

                    _ ->
                        UnhandledFileUpload
            )
            handleMultiFileUpload
            E2EHelper.domain
        )
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.writeMessage admin 100 "Hello export test!"
                , user.click 100 (Dom.id "guild_openDm_0")
                , E2EHelper.writeMessage user 100 "Hello!"
                , E2EHelper.linkDiscordAndLogin
                    (Lamdera.sessionIdFromString "JoeSession")
                    "Joe"
                    E2EHelper.joeEmail
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
    , E2EHelper.startTest
        "Scheduled backend export uploads bytes"
        E2EHelper.startTime
        (T.Config
            Frontend.app_
            Backend.app_
            handleNormalHttpRequests
            E2EHelper.handlePortToJs
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
                                    (T.uploadBytesFile "backup.bin" mimeType bytes E2EHelper.startTime)

                            _ ->
                                UnhandledFileUpload

                    _ ->
                        UnhandledFileUpload
            )
            handleMultiFileUpload
            E2EHelper.domain
        )
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.writeMessage admin 100 "Hello export test!"
                , user.click 100 (Dom.id "guild_openDm_0")
                , E2EHelper.writeMessage user 100 "Hello!"
                , E2EHelper.linkDiscordAndLogin
                    (Lamdera.sessionIdFromString "JoeSession")
                    "Joe"
                    E2EHelper.joeEmail
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
    , E2EHelper.startTest
        "Owner creates an empty channel and deletes it"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                let
                    guildId : Id GuildId
                    guildId =
                        Id.fromInt 1

                    newChannelId : Id ChannelId
                    newChannelId =
                        Id.fromInt 1
                in
                [ admin.click 100 (Dom.id "guild_newChannel")
                , admin.input 100 (Dom.id "newChannelName") "to-delete"
                , admin.click 100 (Dom.id "guild_createChannel")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "to-delete" ])
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "to-delete" ])
                , admin.update 100 (Audio.userMsg (Types.MouseEnteredChannelName guildId newChannelId Id.NoThread))
                , admin.click 100 (Dom.id ("guild_editChannel_" ++ Id.toString newChannelId))
                , admin.click 100 (Dom.id "guild_deleteChannel")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "to-delete" ])
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "to-delete" ])
                ]
            )
        ]
    , E2EHelper.startTest
        "Owner deletes an invite link and a later user cannot join through it"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                let
                    guildId : Id GuildId
                    guildId =
                        Id.fromInt 0

                    secondUserId : Id UserId
                    secondUserId =
                        Id.fromInt 2

                    thirdUserId : Id UserId
                    thirdUserId =
                        Id.fromInt 3
                in
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , admin.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , admin.click 100 (Dom.id "guild_createInviteLink")
                , admin.click 100 (Dom.id "guild_copyText")
                , T.andThen
                    100
                    (\data ->
                        case
                            List.filter
                                (\portRequest -> portRequest.clientId == admin.clientId && portRequest.portName == "copy_to_clipboard_to_js")
                                data.portRequests
                        of
                            [ portRequest ] ->
                                case Json.Decode.decodeValue Json.Decode.string portRequest.value of
                                    Ok copyText ->
                                        let
                                            urlPath : String
                                            urlPath =
                                                String.dropLeft (String.length Env.domain) copyText

                                            inviteIdStr : String
                                            inviteIdStr =
                                                String.split "/" urlPath
                                                    |> List.reverse
                                                    |> List.head
                                                    |> Maybe.withDefault ""
                                        in
                                        [ T.connectFrontend
                                            100
                                            E2EHelper.sessionId1
                                            urlPath
                                            E2EHelper.desktopWindow
                                            (\secondUser ->
                                                [ T.andThen
                                                    10
                                                    (\data2 -> [ secondUser.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data2.time E2EHelper.firefoxDesktop) ])
                                                , E2EHelper.handleLoginFromLoginPage E2EHelper.userEmail secondUser
                                                , secondUser.input 100 (Dom.id "loginForm_name") "Sven"
                                                , secondUser.click 100 (Dom.id "loginForm_submit")
                                                , T.checkBackend
                                                    100
                                                    (\backend ->
                                                        case SeqDict.get guildId backend.guilds of
                                                            Just guild ->
                                                                case MembersAndOwner.isMember secondUserId guild.membersAndOwner of
                                                                    MembersAndOwner.IsMember ->
                                                                        Ok ()

                                                                    _ ->
                                                                        Err "Second user should have joined the guild via the invite"

                                                            Nothing ->
                                                                Err "Guild missing"
                                                    )
                                                , admin.click 100 (Dom.id ("guild_deleteInviteLink_" ++ inviteIdStr))
                                                , T.checkBackend
                                                    100
                                                    (\backend ->
                                                        case SeqDict.get guildId backend.guilds of
                                                            Just guild ->
                                                                if SeqDict.isEmpty guild.invites then
                                                                    Ok ()

                                                                else
                                                                    Err "Invite link should have been removed after the owner clicked delete"

                                                            Nothing ->
                                                                Err "Guild missing"
                                                    )
                                                , T.connectFrontend
                                                    100
                                                    E2EHelper.sessionId2
                                                    urlPath
                                                    E2EHelper.desktopWindow
                                                    (\thirdUser ->
                                                        [ T.andThen
                                                            10
                                                            (\data2 -> [ thirdUser.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data2.time E2EHelper.firefoxDesktop) ])
                                                        , E2EHelper.handleLoginFromLoginPage E2EHelper.joeEmail thirdUser
                                                        , thirdUser.input 100 (Dom.id "loginForm_name") "Joe"
                                                        , thirdUser.click 100 (Dom.id "loginForm_submit")
                                                        , T.checkBackend
                                                            100
                                                            (\backend ->
                                                                case SeqDict.get guildId backend.guilds of
                                                                    Just guild ->
                                                                        case MembersAndOwner.isMember thirdUserId guild.membersAndOwner of
                                                                            MembersAndOwner.IsNotMember ->
                                                                                Ok ()

                                                                            _ ->
                                                                                Err "Third user should not have joined the guild through the deleted invite"

                                                                    Nothing ->
                                                                        Err "Guild missing"
                                                            )
                                                        , E2EHelper.hasText thirdUser [ "Guild not found" ]
                                                        ]
                                                    )
                                                ]
                                            )
                                        ]

                                    Err _ ->
                                        [ admin.checkModel 100 (\_ -> Err "Didn't decode clipboard port value") ]

                            _ ->
                                [ admin.checkModel 100 (\_ -> Err "Didn't copy invite link to clipboard") ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Owner must confirm deletion of a non-empty channel by typing its name"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                let
                    guildId : Id GuildId
                    guildId =
                        Id.fromInt 1

                    newChannelId : Id ChannelId
                    newChannelId =
                        Id.fromInt 1
                in
                [ admin.click 100 (Dom.id "guild_newChannel")
                , admin.input 100 (Dom.id "newChannelName") "with-message"
                , admin.click 100 (Dom.id "guild_createChannel")
                , E2EHelper.writeMessage admin 100 "I have content"
                , admin.update 100 (Audio.userMsg (Types.MouseEnteredChannelName guildId newChannelId Id.NoThread))
                , admin.click 100 (Dom.id ("guild_editChannel_" ++ Id.toString newChannelId))

                -- First click reveals the confirmation input but does not delete
                , admin.click 100 (Dom.id "guild_deleteChannel")
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "Type \"with-message\" to confirm deletion" ]
                    )
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.exactText "with-message" ])
                , user.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.exactText "with-message" ])

                -- Wrong text does not delete
                , admin.input 100 (Dom.id "deleteChannelConfirmation") "wrong-name"
                , admin.click 100 (Dom.id "guild_deleteChannel")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.exactText "with-message" ])

                -- Correct text deletes the channel
                , admin.input 100 (Dom.id "deleteChannelConfirmation") "with-message"
                , admin.click 100 (Dom.id "guild_deleteChannel")
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "with-message" ])
                , user.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "with-message" ])
                ]
            )
        ]
    , T.start
        "Owner deletes a guild and it is purged after 30 days"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                let
                    guildId : Id GuildId
                    guildId =
                        Id.fromInt 1
                in
                [ E2EHelper.writeMessage admin 100 "hello world"
                , admin.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , admin.click 100 (Dom.id "guild_deleteGuild")
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.exactText "Type \"My new guild!\" to confirm deletion" ]
                    )
                , admin.input 100 (Dom.id "deleteGuildConfirmation") "wrong-name"
                , admin.click 100 (Dom.id "guild_deleteGuild")
                , T.checkBackend
                    100
                    (\backend ->
                        if SeqDict.member guildId backend.guilds then
                            Ok ()

                        else
                            Err "Wrong confirmation text should not delete the guild"
                    )
                , admin.input 100 (Dom.id "deleteGuildConfirmation") "My new guild!"
                , admin.click 100 (Dom.id "guild_deleteGuild")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "My new guild!" ])
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "My new guild!" ])
                , T.checkBackend
                    100
                    (\backend ->
                        case ( SeqDict.member guildId backend.guilds, SeqDict.get guildId backend.deletedGuilds ) of
                            ( False, Just _ ) ->
                                Ok ()

                            ( True, _ ) ->
                                Err "Guild should be removed from active guilds"

                            ( False, Nothing ) ->
                                Err "Guild should be present in deletedGuilds"
                    )
                , admin.click 100 (Dom.id "guild_createGuild")
                , admin.input 100 (Dom.id "newGuildName") "My second guild!"
                , admin.click 100 (Dom.id "guild_createGuildSubmit")
                , T.checkBackend
                    100
                    (\backend ->
                        let
                            newGuildId : Id GuildId
                            newGuildId =
                                Id.fromInt 2
                        in
                        case ( SeqDict.member guildId backend.guilds, SeqDict.member newGuildId backend.guilds ) of
                            ( False, True ) ->
                                Ok ()

                            ( True, _ ) ->
                                Err "Deleted guild ID should not be reused"

                            ( False, False ) ->
                                Err ("Expected newly created guild at id 2, got ids: " ++ String.join "," (List.map (Id.toInt >> String.fromInt) (SeqDict.keys backend.guilds)))
                    )
                ]
            )
        , T.checkBackend
            (Duration.days 31 |> Duration.inMilliseconds)
            (\backend ->
                if SeqDict.isEmpty backend.deletedGuilds then
                    Ok ()

                else
                    Err "deletedGuilds should be pruned after 30 days"
            )
        ]
    , T.start
        "Admin restores a deleted guild"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                let
                    guildId : Id GuildId
                    guildId =
                        Id.fromInt 1
                in
                [ E2EHelper.writeMessage admin 100 "hello world"
                , admin.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , admin.click 100 (Dom.id "guild_deleteGuild")
                , admin.input 100 (Dom.id "deleteGuildConfirmation") "My new guild!"
                , admin.click 100 (Dom.id "guild_deleteGuild")
                , T.checkBackend
                    100
                    (\backend ->
                        case ( SeqDict.member guildId backend.guilds, SeqDict.get guildId backend.deletedGuilds ) of
                            ( False, Just _ ) ->
                                Ok ()

                            _ ->
                                Err "Guild should be in deletedGuilds after deletion"
                    )
                , admin.click 100 (Dom.id "guild_showUserOptions")
                , admin.click 100 (Dom.id "userOptions_gotoAdmin")
                , admin.click 100 (Dom.id "admin_expandSectionButton_Deleted guilds")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.exactText "My new guild!" ])
                , admin.click 100 (Dom.id ("Admin_restoreGuildButton_" ++ Id.toString guildId))
                , T.checkBackend
                    100
                    (\backend ->
                        case ( SeqDict.member guildId backend.guilds, SeqDict.member guildId backend.deletedGuilds ) of
                            ( True, False ) ->
                                Ok ()

                            ( False, _ ) ->
                                Err "Guild should be restored to active guilds"

                            ( True, True ) ->
                                Err "Guild should be removed from deletedGuilds after restore"
                    )
                ]
            )
        ]
    , E2EGo.tests normalConfig
    , E2EWordSpellingGame.tests normalConfig
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
    E2EHelper.startTest
        "SendMessage rate limiting"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
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
                                        IdArray.length channel.messages

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
        E2EHelper.startTime
        config
        [ E2EHelper.linkDiscordAndLogin
            E2EHelper.sessionId0
            "AT"
            E2EHelper.adminEmail
            False
            discordOpReady
            discordOpSupplemental
            (\admin ->
                [ E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ E2EHelper.writeMessage user 100 "sensitive guild message"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , E2EHelper.writeMessage admin 100 "sensitive guild message 2"
                        , user.click 1000 (Dom.id "guild_openDm_0")
                        , E2EHelper.writeMessage user 100 "sensitive DM message"
                        , T.connectFrontend
                            100
                            E2EHelper.sessionIdAttacker
                            "/"
                            E2EHelper.desktopWindow
                            (\attacker ->
                                [ E2EHelper.handleLogin E2EHelper.chromeDesktop E2EHelper.attackerEmail attacker
                                , attacker.update 0 (Audio.userMsg Types.EnableToFrontendLogging)
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
                                            E2EHelper.allAttackerLocalChanges
                                            |> T.collapsableGroup "attacks"
                                        , List.map (attacker.sendToBackend 100) E2EHelper.allAttackerToBackendChanges
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
                                                            ++ (if Id.toInt before.backend.nextGuildId <= Id.toInt after.backend.nextGuildId then
                                                                    []

                                                                else
                                                                    [ "Next guild ID data was modified by attacker" ]
                                                               )
                                                            ++ (if SeqDict.get guildId before.backend.deletedGuilds == SeqDict.get guildId after.backend.deletedGuilds then
                                                                    []

                                                                else
                                                                    [ "Deleted guild data was modified by attacker" ]
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
                                                case Audio.userModel model of
                                                    Types.Loaded loaded ->
                                                        case loaded.toFrontendLogs of
                                                            Just toFrontendLogs ->
                                                                let
                                                                    invalidToFrontends : Array ToFrontend
                                                                    invalidToFrontends =
                                                                        Array.filter E2EHelper.attackerShouldNotGetThisToFrontend toFrontendLogs
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
