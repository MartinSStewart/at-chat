module Pages.Home exposing
    ( header
    , loginButtonId
    , loginSignupText
    , view
    )

import Array exposing (Array)
import ChannelDescription
import ChannelName exposing (ChannelName)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Time as Time
import Emoji
import FileName
import FileStatus exposing (IsEncrypted(..))
import FrontendExtra
import Game
import GuildName exposing (GuildName)
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, GuildId, GuildOrDmId(..), Id, UserId)
import IdArray
import LinkedAndOtherDiscordUsers exposing (LinkedAndOtherDiscordUsers(..))
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local
import LocalState exposing (FrontendChannel, FrontendGuild)
import MembersAndOwner
import Message exposing (Message(..), RepliedTo(..))
import MessageArray exposing (MessageArray)
import MyUi
import NonemptySet
import Pages.Guild
import RichText
import Route exposing (ChannelSidebarMode(..), ChannelsVisibleOnMobile(..), Route(..))
import SeqDict
import SeqSet
import SessionIdHash
import Set
import String.Nonempty exposing (NonemptyString(..))
import TextEditor
import Types exposing (AdminStatusLoginData(..), FrontendMsg_(..), LoadedFrontend, LoginData, LoginStatus(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Input
import Ui.Shadow
import Unsafe
import User exposing (BackendUser, FrontendUser)
import UserAgent exposing (UserAgent)
import UserColor
import UserSession exposing (ChannelHeaderTab(..), ToBeFilledInByBackend(..), Viewing(..))
import VisibleMessages
import WordSpellingGame exposing (Action(..), ActionWithTime, IsValid(..), Letter(..), LetterOrWildcard(..))


loginSignupText : String
loginSignupText =
    "Login/Signup"


header : Bool -> Route -> LoginStatus -> Element FrontendMsg_
header isMobile route loginStatus =
    Ui.el
        [ Ui.background MyUi.background1
        , Ui.Shadow.shadows [ { x = 0, y = 1, blur = 2, size = 0, color = Ui.rgba 0 0 0 0.05 } ]
        ]
        (Ui.row
            [ MyUi.htmlStyle "padding" ("calc(4px + " ++ MyUi.insetTop ++ ")" ++ " 16px 0 16px")
            , Ui.contentCenterY
            , MyUi.notoSans
            , Ui.widthMax 1280
            , Ui.centerX
            ]
            [ Ui.image
                [ Ui.width (Ui.px 64)
                , Ui.paddingWith { top = 4, left = 8, right = 8, bottom = 8 }
                , Ui.Input.button (PressedLink (HomePageRoute Nothing))
                ]
                { source = "/cacheable/at-logo-no-background.png"
                , description = "Logo"
                , onLoad = Nothing
                }
            , case loginStatus of
                LoggedIn _ ->
                    Ui.none

                NotLoggedIn notLoggedIn ->
                    MyUi.elButton
                        loginButtonId
                        PressedShowLogin
                        (buttonAttributes isMobile (notLoggedIn.loginForm /= Nothing || Route.requiresLogin route))
                        (Ui.text loginSignupText)
            ]
        )


buttonAttributes : Bool -> Bool -> List (Ui.Attribute msg)
buttonAttributes isMobile isSelected =
    [ Ui.Font.weight 600
    , Ui.rounded 8
    , Ui.padding 8
    , Ui.alignRight
    , Ui.width Ui.shrink
    , Ui.height Ui.fill
    , Ui.paddingWith { left = 16, right = 16, top = 4, bottom = 8 }
    , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }
    , Ui.attrIf isSelected (Ui.background MyUi.background3)
    , Ui.attrIf isSelected (MyUi.outwardBottomCorner 16 True MyUi.background3)
    , Ui.attrIf isSelected (MyUi.outwardBottomCorner 16 False MyUi.background3)
    , Ui.contentCenterY
    , Ui.Font.color
        (if isSelected then
            MyUi.font1

         else
            MyUi.font3
        )
    , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
    ]


loginButtonId : HtmlId
loginButtonId =
    Dom.id "homePage_loginButton"


previewUserId : Id UserId
previewUserId =
    Id.fromInt 0


previewGuildId : Id GuildId
previewGuildId =
    Id.fromInt 0


previewChannelId : Id ChannelId
previewChannelId =
    Id.fromInt 0


previewGuildName : GuildName
previewGuildName =
    Unsafe.guildName "Friends & chat"


previewChannelName : ChannelName
previewChannelName =
    Unsafe.channelName "general"


petPicsChannelName : ChannelName
petPicsChannelName =
    Unsafe.channelName "pet-pics"


previewUser : BackendUser
previewUser =
    let
        user =
            User.init (Time.millisToPosix 0) (Unsafe.personName "Sven Svensson") (Unsafe.emailAddress "you@at-chat.app") False
    in
    { user
        | lastViewedMessage =
            SeqDict.fromList
                [ ( GuildOrDmId
                        (GuildOrDmId_Guild
                            { guildId = previewGuildId
                            , channelId = previewChannelId
                            }
                        )
                  , Id.fromInt 5
                  )
                ]
    }


previewOtherUsers : SeqDict.SeqDict (Id UserId) FrontendUser
previewOtherUsers =
    SeqDict.fromList
        [ ( Id.fromInt 1
          , { name = Unsafe.personName "jobaly Joe"
            , color = UserColor.default
            , icon = Nothing
            , publicKey = Nothing
            }
          )
        , ( Id.fromInt 2
          , { name = Unsafe.personName "boog'les_the_spy_pig"
            , color = UserColor.fromParts { hue = 0, lightness = 12, saturation = 11 }
            , icon = Just (FileStatus.fileHash "defrqz-9TjEnuXDZnPc8zD1VoeugOLHh_7-sWw")
            , publicKey = Nothing
            }
          )
        , ( Id.fromInt 3
          , { name = Unsafe.personName "antichokehards"
            , color = UserColor.fromParts { hue = 4, lightness = 10, saturation = 15 }
            , icon = Just (FileStatus.fileHash "7kTsE8OAyWGK_3AsOpZje0ySNF-kqCH_RnemPg")
            , publicKey = Nothing
            }
          )
        ]


previewMessage : Time.Posix -> Id UserId -> NonemptyString -> Message ChannelMessageId (Id UserId)
previewMessage createdAt createdBy text =
    UserTextMessage
        { createdAt = createdAt
        , createdBy = createdBy
        , content =
            { content = RichText.fromNonemptyString Time.utc SeqDict.empty text
            , embeds = Array.empty
            , attachedFiles = SeqDict.empty
            }
        , reactions = SeqDict.empty
        , editedAt = Nothing
        , repliedTo = NoReply
        , drawings = Nothing
        }


previewChannel : Time.Posix -> SeqDict.SeqDict (Id ChannelMessageId) Game.MatchData -> FrontendChannel
previewChannel time games =
    let
        messages : MessageArray ChannelMessageId (Id UserId)
        messages =
            List.foldl
                MessageArray.push
                MessageArray.empty
                [ UserTextMessage
                    { createdAt = time
                    , createdBy = Id.fromInt 3
                    , content =
                        { content =
                            RichText.fromNonemptyString
                                Time.utc
                                SeqDict.empty
                                (NonemptyString 'h' "ere's that bird I drew, now on my backpack! [!1]")
                        , embeds = Array.empty
                        , attachedFiles =
                            SeqDict.fromList
                                [ ( Id.fromInt 1
                                  , { fileName = FileName.fromString "birb.webp"
                                    , fileSize = 71812
                                    , metadata =
                                        FileStatus.FileMetadata_Image
                                            { imageSize = Coord.xy 949 538
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
                                    , contentType = FileStatus.webpContent
                                    , fileHash = FileStatus.fileHash "mnQelyTECkZW5RjIFCZjNirt8R_nuWGtV0WEzQ"
                                    , isEncrypted = IsNotEncrypted
                                    }
                                  )
                                ]
                        }
                    , reactions =
                        SeqDict.fromList
                            [ ( Emoji.EmojiOrCustomEmoji_Emoji Emoji.heart
                              , NonemptySet.singleton (Id.fromInt 1)
                              )
                            ]
                    , editedAt = Nothing
                    , repliedTo = NoReply
                    , drawings = Nothing
                    }
                , previewMessage time previewUserId (NonemptyString 'b' "ird!")
                , previewMessage time (Id.fromInt 2) (NonemptyString '_' "Once upon a midnight dreary while I pondered weak and weary_")
                , previewMessage time previewUserId (NonemptyString '#' "## *NO!*")
                , previewMessage time (Id.fromInt 2) (NonemptyString '_' "Over many a quaint and curious volume of forgotten lore_")
                , previewMessage time (Id.fromInt 2) (NonemptyString '_' "While I nodded, nearly napping, suddenly there came a tapping_")
                , previewMessage time (Id.fromInt 3) (NonemptyString 't' "hat's not a raven!!")
                ]
    in
    { createdAt = time
    , createdBy = Id.fromInt 1
    , name = previewChannelName
    , description = ChannelDescription.empty
    , messages = messages
    , visibleMessages = VisibleMessages.init True (MessageArray.length messages)
    , isArchived = Nothing
    , lastTypedAt = SeqDict.fromList [ ( Id.fromInt 2, { time = time, messageIndex = Nothing } ) ]
    , threads = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , games = games
    }


previewGuild : Time.Posix -> SeqDict.SeqDict (Id ChannelMessageId) Game.MatchData -> FrontendGuild
previewGuild time games =
    { createdAt = time
    , createdBy = Id.fromInt 1
    , name = previewGuildName
    , icon = Just (FileStatus.fileHash "c_fknEBFP2Tbqh4_2NcGxm7qHXm8lRZfOpXfzg")
    , channels =
        SeqDict.fromList
            [ ( previewChannelId, previewChannel time games )
            , ( Id.fromInt 1
              , { createdAt = time
                , createdBy = Id.fromInt 1
                , name = petPicsChannelName
                , description = ChannelDescription.empty
                , messages = MessageArray.empty
                , visibleMessages = VisibleMessages.init True 0
                , isArchived = Nothing
                , lastTypedAt = SeqDict.fromList [ ( Id.fromInt 2, { time = time, messageIndex = Nothing } ) ]
                , threads = SeqDict.empty
                , dateDividerDrawings = SeqDict.empty
                , games = SeqDict.empty
                }
              )
            ]
    , membersAndOwner =
        MembersAndOwner.init
            (SeqDict.map (\_ _ -> { joinedAt = time }) previewOtherUsers
                |> SeqDict.insert previewUserId { joinedAt = time }
            )
            (Id.fromInt 1)
    , invites = SeqDict.empty
    }


previewLoginData : Time.Posix -> UserAgent -> LoginData
previewLoginData time userAgent =
    { session =
        { userId = previewUserId
        , notificationMode = UserSession.NoNotifications
        , pushSubscription = UserSession.NotSubscribed
        , userAgent = userAgent
        , sessionIdHash = SessionIdHash.fromString ""
        , signedInAt = time
        , lastClientDisconnect = Nothing
        , expandedUserOptions = SeqSet.empty
        , savedSheepGameQuestions = IdArray.empty
        }
    , currentlyViewing = Viewing_None
    , adminData = IsNotAdminLoginData
    , twoFactorAuthenticationEnabled = Nothing
    , guilds = SeqDict.fromList [ ( previewGuildId, previewGuild time (previewGames time) ) ]
    , dmChannels = SeqDict.empty
    , discordDmChannels = SeqDict.empty
    , discordGuilds = SeqDict.empty
    , user = previewUser
    , otherUsers = previewOtherUsers
    , discordUsers = LinkedAndOtherDiscordUsers SeqDict.empty SeqDict.empty
    , otherSessions = SeqDict.empty
    , publicVapidKey = ""
    , textEditor = TextEditor.initLocalState
    , stickers = SeqDict.empty
    , customEmojis = SeqDict.empty
    , voiceChatPeers = SeqDict.empty
    }


previewGameMatchId : Id ChannelMessageId
previewGameMatchId =
    Id.fromInt 7


previewGameSetup : Result String WordSpellingGame.ValidatedSetup
previewGameSetup =
    WordSpellingGame.validateSetup previewUserId (Time.millisToPosix 0) WordSpellingGame.initSetup


previewGameLetters : Char -> String -> Nonempty LetterOrWildcard
previewGameLetters first rest =
    Nonempty
        (Letter (LetterChar first))
        (List.map (\char -> Letter (LetterChar char)) (String.toList rest))


{-| A move in the preview match. `secondsAgo` is counted back from the current time on every
render, so the clocks always read the same however long the page has been open.
-}
previewGameMove : Time.Posix -> Float -> Id UserId -> ( Int, Int ) -> Bool -> Nonempty LetterOrWildcard -> ActionWithTime
previewGameMove time secondsAgo userId start isVertical letters =
    { userId = userId
    , time = Duration.addTo time (Duration.seconds -secondsAgo)
    , change =
        PlaceWord
            { start = start, isVertical = isVertical, letters = letters }
            (FilledInByBackend (IsValid Set.empty))
    }


{-| The letters already on the board carry on past `start`, so each move only lists the tiles it
adds: ZEBRA starts on the Z that QUARTZ left behind and places E, B, R and A below it.
-}
previewGameActions : Time.Posix -> Array ActionWithTime
previewGameActions time =
    Array.fromList
        [ { userId = Id.fromInt 2, time = Duration.addTo time (Duration.seconds -300), change = JoinGame }
        , previewGameMove time 240 previewUserId ( 4, 7 ) False (previewGameLetters 'Q' "UARTZ")
        , previewGameMove time 180 (Id.fromInt 2) ( 9, 7 ) True (previewGameLetters 'E' "BRA")
        , previewGameMove time 120 previewUserId ( 6, 7 ) True (previewGameLetters 'X' "E")
        , previewGameMove time 60 (Id.fromInt 2) ( 9, 11 ) False (previewGameLetters 'G' "ILE")
        ]


previewGameShared : Time.Posix -> WordSpellingGame.ValidatedSetup -> WordSpellingGame.Shared
previewGameShared time setup =
    Array.foldl
        (\action shared -> WordSpellingGame.updateAction setup action shared |> Tuple.first)
        (WordSpellingGame.initShared setup)
        (previewGameActions time)


previewGames : Time.Posix -> SeqDict.SeqDict (Id ChannelMessageId) Game.MatchData
previewGames time =
    case previewGameSetup of
        Ok setup ->
            SeqDict.singleton
                previewGameMatchId
                (Game.initMatchData
                    (Game.GameData_WordSpellingGame setup (previewGameActions time) (previewGameShared time setup))
                    Nothing
                )

        Err _ ->
            SeqDict.empty


previewGameModels : Time.Posix -> SeqDict.SeqDict GuildOrDmId Game.Model
previewGameModels time =
    case previewGameSetup of
        Ok setup ->
            let
                gameModel : Game.Model
                gameModel =
                    Game.initModel
            in
            SeqDict.singleton
                (GuildOrDmId_Guild { guildId = previewGuildId, channelId = previewChannelId })
                { gameModel
                    | startedGames =
                        -- The tray tiles animate in over the second after the game model is built,
                        -- so build it in the past: `time` advances every second and the tiles would
                        -- otherwise be stuck at the start of that animation, leaving the tray empty.
                        WordSpellingGame.initGame
                            (Duration.addTo time (Duration.seconds -10))
                            previewUserId
                            setup
                            (previewGameShared time setup)
                            |> Game.WordSpellingGame_Game
                            |> SeqDict.singleton previewGameMatchId
                }

        Err _ ->
            SeqDict.empty


{-| The previews the carousel cycles through, as the channel route each one puts the app on.
-}
previewChannelRoutes : List Route.ChannelRoute
previewChannelRoutes =
    Route.ChannelRoute previewChannelId (Route.NoThreadWithFriends Nothing Route.HideChannelSettings) Nothing
        :: (case previewGameSetup of
                Ok _ ->
                    [ Route.ChannelRoute
                        previewChannelId
                        (Route.NoThreadWithFriends Nothing Route.HideChannelSettings)
                        (Just (ChannelHeaderTab_Games (Just previewGameMatchId) Nothing))
                    ]

                Err _ ->
                    []
           )


previewIntervalMillis : Int
previewIntervalMillis =
    6000


{-| Which preview is showing: the one the reader last picked, moved on by one for every interval
that has passed since they picked it.
-}
activePreview : LoadedFrontend -> Int
activePreview loaded =
    let
        elapsed : Int
        elapsed =
            Time.posixToMillis loaded.time - Time.posixToMillis loaded.homePagePreview.changedAt |> max 0
    in
    loaded.homePagePreview.index
        + (elapsed // previewIntervalMillis)
        |> modBy (List.length previewChannelRoutes)


previousPreviewButton : Int -> Element FrontendMsg_
previousPreviewButton activeIndex =
    MyUi.elButton
        (Dom.id "homePage_previousPreview")
        (PressedHomePagePreview (modBy (List.length previewChannelRoutes) (activeIndex - 1)))
        [ Ui.alignLeft, Ui.width (Ui.px 64), Ui.height Ui.fill ]
        Ui.none


nextPreviewButton : Int -> Element FrontendMsg_
nextPreviewButton activeIndex =
    MyUi.elButton
        (Dom.id "homePage_nextPreview")
        (PressedHomePagePreview (modBy (List.length previewChannelRoutes) (activeIndex + 1)))
        [ Ui.alignRight, Ui.width (Ui.px 64), Ui.height Ui.fill ]
        Ui.none


previewDots : Int -> Element FrontendMsg_
previewDots activeIndex =
    List.range 0 (List.length previewChannelRoutes - 1)
        |> List.map
            (\index ->
                MyUi.elButton
                    (Dom.id ("homePage_preview_" ++ String.fromInt index))
                    (PressedHomePagePreview index)
                    [ Ui.width (Ui.px 10)
                    , Ui.height (Ui.px 10)
                    , Ui.rounded 99
                    , Ui.background
                        (if index == activeIndex then
                            MyUi.white

                         else
                            Ui.rgba 255 255 255 0.4
                        )
                    ]
                    Ui.none
            )
        |> Ui.row [ Ui.spacing 8, Ui.width Ui.shrink, Ui.centerX, Ui.alignBottom, Ui.padding 12 ]


view : LoadedFrontend -> Element FrontendMsg_
view loaded =
    let
        previewLoggedIn : Types.LoggedIn2
        previewLoggedIn =
            FrontendExtra.loadedInitHelper
                loaded.startupData
                loaded.emojiData
                (previewLoginData loaded.time loaded.startupData.userAgent)
                loaded
                |> Tuple.first

        widthMax : Int
        widthMax =
            1280

        paddingX : Int
        paddingX =
            if Coord.xRaw loaded.windowSize < 800 then
                24

            else
                48

        isMobile =
            MyUi.isMobile loaded

        previewWidth : Int
        previewWidth =
            min (Coord.xRaw loaded.windowSize) widthMax - paddingX * 2

        previewHeight : Int
        previewHeight =
            if isMobile then
                600

            else
                850

        previewScale : Float
        previewScale =
            if isMobile then
                0.8

            else
                1

        innerSize : Coord CssPixels
        innerSize =
            Coord.xy
                (round (toFloat previewWidth / previewScale))
                (round (toFloat previewHeight / previewScale))

        activeIndex : Int
        activeIndex =
            activePreview loaded

        channelRoute : Route.ChannelRoute
        channelRoute =
            List.Extra.getAt activeIndex previewChannelRoutes
                |> Maybe.withDefault
                    (Route.ChannelRoute previewChannelId (Route.NoThreadWithFriends Nothing Route.HideChannelSettings) Nothing)
    in
    Ui.column
        [ MyUi.notoSans
        , Ui.paddingWith
            { left = paddingX
            , right = paddingX
            , top =
                if isMobile then
                    80

                else
                    120
            , bottom = 48
            }
        , Ui.widthMax widthMax
        , Ui.centerX
        , if isMobile then
            Ui.spacing 16

          else
            Ui.spacing 32
        ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text "at-chat, a place to chat with friends")
        , Pages.Guild.guildView
            { loaded
                | windowSize = innerSize
                , route = GuildRoute previewGuildId channelRoute ChannelsVisibleOnMobile Nothing
            }
            previewGuildId
            channelRoute
            { previewLoggedIn
                | sidebarMode = ChannelSidebarNotDragging { offset = 1 }
                , games = previewGameModels loaded.time
            }
            (Local.model previewLoggedIn.localState)
            |> Ui.el
                [ Ui.width (Ui.px (Coord.xRaw innerSize))
                , Ui.height (Ui.px (Coord.yRaw innerSize))
                , -- Without this the app inside is laid out at its natural height, since elm-ui
                  -- leaves min-height at min-content and that wins over the height above.
                  Ui.heightMin 0
                , MyUi.htmlStyle "transform" ("scale(" ++ String.fromFloat previewScale ++ ")")
                , MyUi.htmlStyle "transform-origin" "top left"
                , MyUi.noPointerEvents
                ]
            |> Ui.el
                ([ Ui.width (Ui.px previewWidth)
                 , Ui.height (Ui.px previewHeight)
                 , Ui.heightMin 0
                 , Ui.clip
                 , Ui.Shadow.shadows [ { x = 0, y = 0, blur = 10, size = 0, color = Ui.rgba 255 255 255 0.5 } ]
                 ]
                    ++ (if List.length previewChannelRoutes > 1 then
                            [ Ui.inFront (previousPreviewButton activeIndex)
                            , Ui.inFront (nextPreviewButton activeIndex)
                            , Ui.inFront (previewDots activeIndex)
                            ]

                        else
                            []
                       )
                )
        ]
