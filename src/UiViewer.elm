module UiViewer exposing (main)

{-| This module is for letting you view parts of the app UI that would be difficult to reach under normal usage.
Start `lamdera live` and go to localhost:8000/src/UiViewer.elm to use it.
-}

import Array
import BackendExtra
import Coord
import Discord
import Effect.Browser.Dom as Dom
import Effect.Http as Http
import Email.Html
import EmailAddress exposing (EmailAddress)
import Embed exposing (Embed(..))
import FileName
import FileStatus exposing (FileData, FileId)
import GuildIcon
import Html exposing (Html)
import Html.Attributes
import Id exposing (Id, StickerId)
import List.Nonempty exposing (Nonempty(..))
import Log exposing (Log)
import MessageInput
import MyUi
import OneOrGreater
import Postmark
import RichText exposing (Domain, Language(..), RichText(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Sticker exposing (StickerData, StickerUrl(..))
import String.Nonempty exposing (NonemptyString(..))
import Time
import Ui
import Ui.Font
import Unsafe


main : Html ()
main =
    Ui.layout
        [ Ui.Font.color MyUi.font1
        , Ui.background MyUi.background1
        , Ui.behindContent (Ui.html MyUi.css)
        , Ui.scrollable
        , Ui.heightMin 0
        , MyUi.prewrap
        , Ui.Font.size 16
        ]
        (Ui.column
            [ Ui.spacing 16, Ui.padding 16 ]
            [ Ui.column
                [ Ui.background MyUi.background3 ]
                [ Ui.el [ Ui.Font.size 24, Ui.Font.bold ] (Ui.text "Emails")
                , Ui.html loginEmail
                ]
            , Ui.column
                [ Ui.background MyUi.background3, Ui.Font.family [ Ui.Font.sansSerif ] ]
                [ Ui.el [ Ui.Font.size 24, Ui.Font.bold ] (Ui.text "Log entries")
                , logExamples
                ]
            , Ui.column
                [ Ui.background MyUi.background3, Ui.Font.family [ Ui.Font.sansSerif ] ]
                [ Ui.el [ Ui.Font.size 24, Ui.Font.bold ] (Ui.text "Embeds")
                , embedExamples SeqSet.empty
                ]
            , Ui.column
                [ Ui.background MyUi.background3, Ui.Font.family [ Ui.Font.sansSerif ] ]
                [ Ui.el [ Ui.Font.size 24, Ui.Font.bold ] (Ui.text "Attachments")
                , RichText.view
                    (Dom.id "richText")
                    800
                    (\_ -> ())
                    (\_ -> ())
                    { domainWhitelist = SeqSet.empty
                    , revealedSpoilers = SeqSet.fromList [ 1, 3, 5, 7 ]
                    , users = SeqDict.empty
                    , attachedFiles = attachments
                    , stickers = stickers
                    , animationMode = Sticker.LoopForever
                    }
                    Array.empty
                    (Nonempty
                        (NormalText 'F' "ile without spoiler")
                        [ AttachedFile (Id.fromInt 1)
                        , NormalText '\n' "File with spoiler"
                        , Spoiler (Nonempty (AttachedFile (Id.fromInt 1)) [])
                        , NormalText '\n' "File with spoiler revealed"
                        , Spoiler (Nonempty (AttachedFile (Id.fromInt 1)) [])
                        , NormalText '\n' "Image without spoiler"
                        , AttachedFile (Id.fromInt 2)
                        , NormalText '\n' "Image with spoiler"
                        , Spoiler (Nonempty (AttachedFile (Id.fromInt 2)) [])
                        , NormalText '\n' "Image with spoiler revealed"
                        , Spoiler (Nonempty (AttachedFile (Id.fromInt 2)) [])
                        , NormalText '\n' "Normal text without spoiler"
                        , Spoiler
                            (Nonempty
                                (NormalText '\n' "Normal text ")
                                [ Bold (Nonempty (NormalText 'w' "ith") []), NormalText ' ' "spoiler" ]
                            )
                        , Spoiler
                            (Nonempty
                                (NormalText '\n' "Normal text ")
                                [ Bold (Nonempty (NormalText 'w' "ith") []), NormalText ' ' "spoiler revealed" ]
                            )
                        , NormalText '\n' "Code block without spoiler"
                        , CodeBlock NoLanguage "123\nabcd"
                        , NormalText '\n' "Code block with spoilers"
                        , Spoiler (Nonempty (CodeBlock NoLanguage "123\nabcd") [])
                        , NormalText '\n' "Code block with spoilers revealed"
                        , Spoiler (Nonempty (CodeBlock NoLanguage "123\nabcd") [])
                        ]
                    )
                    |> Html.div []
                    |> Ui.html
                ]
            , stickersSection
            , Ui.column
                []
                [ Ui.row
                    [ Ui.spacing 8, Ui.wrap ]
                    (List.range 1 100
                        |> List.foldl
                            (\index ( count, items ) ->
                                ( OneOrGreater.increment count
                                , Ui.el
                                    [ Ui.width (Ui.px 54) ]
                                    (GuildIcon.userView
                                        (if modBy 2 index == 1 then
                                            GuildIcon.NewMessage count

                                         else
                                            GuildIcon.NewMessageForUser count
                                        )
                                        Nothing
                                        (Id.fromInt index)
                                    )
                                    :: items
                                )
                            )
                            ( OneOrGreater.one, [] )
                        |> Tuple.second
                        |> List.reverse
                    )
                ]
            ]
        )


stickersSection =
    let
        richText =
            Nonempty
                (NormalText 'T' "est2")
                [ Sticker (Id.fromInt 123)
                , NormalText 'T' "est3333333333333333333333\n3333333333"
                ]
    in
    Ui.column
        [ Ui.background MyUi.background3, Ui.Font.family [ Ui.Font.sansSerif ] ]
        [ Ui.el [ Ui.Font.size 24, Ui.Font.bold ] (Ui.text "Stickers")
        , RichText.view
            (Dom.id "richText")
            800
            (\_ -> ())
            (\_ -> ())
            { domainWhitelist = SeqSet.empty
            , revealedSpoilers = SeqSet.empty
            , users = SeqDict.empty
            , attachedFiles = SeqDict.empty
            , stickers = stickers
            , animationMode = Sticker.LoopForever
            }
            Array.empty
            (Nonempty (NormalText 'T' "est") [ Sticker (Id.fromInt 123) ])
            |> Html.div []
            |> Ui.html
        , MessageInput.view
            (Dom.id "input")
            True
            False
            (Dom.id "channel")
            "Placeholder"
            123
            (richText |> RichText.toString False SeqDict.empty)
            (Just richText)
            SeqDict.empty
            stickers
            Nothing
            SeqDict.empty
            |> Ui.map (\_ -> ())
        ]


attachments : SeqDict (Id FileId) FileData
attachments =
    SeqDict.fromList
        [ ( Id.fromInt 1
          , { fileName = FileName.fromString "file.json"
            , fileSize = 10000
            , imageMetadata = Nothing
            , contentType = FileStatus.jsonContent
            , fileHash = FileStatus.fileHash "123"
            }
          )
        , ( Id.fromInt 2
          , { fileName = FileName.fromString "file.json"
            , fileSize = 1000000
            , imageMetadata =
                Just
                    { imageSize = Coord.xy 200 300
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
            , contentType = FileStatus.pngContent
            , fileHash = FileStatus.fileHash "123"
            }
          )
        ]


stickers : SeqDict (Id StickerId) StickerData
stickers =
    SeqDict.fromList [ ( Id.fromInt 123, { url = StickerLoading, name = "Mindless", format = Discord.GifFormat } ) ]


emailView : NonemptyString -> Email.Html.Html -> Html msg
emailView subject content =
    Html.div
        []
        [ Html.span []
            [ String.Nonempty.toString subject ++ " " |> Html.text
            , Html.input
                [ Html.Attributes.readonly True
                , Html.Attributes.type_ "text"
                , Html.Attributes.value (Email.Html.toString content)
                ]
                []
            ]
        , Email.Html.toHtml content
        ]


loginEmail : Html msg
loginEmail =
    emailView
        BackendExtra.loginEmailSubject
        (BackendExtra.loginEmailContent 12345678)


exampleEmail : EmailAddress
exampleEmail =
    Unsafe.emailAddress "user@example.com"


logExamples : Ui.Element ()
logExamples =
    let
        exampleTime =
            Time.millisToPosix 1700000000000

        logEntry : Log -> Ui.Element ()
        logEntry log =
            Log.view
                False
                False
                Time.utc
                { onPressCopyLink = ()
                , onPressCopy = \_ -> ()
                , onPressHide = ()
                , onPressUnhide = ()
                }
                False
                False
                { time = exampleTime, log = log }
    in
    Ui.column
        [ Ui.spacing 24 ]
        [ logEntry (Log.LoginEmail (Ok ()) exampleEmail)
        , logEntry
            (Log.LoginEmail
                (Postmark.PostmarkError
                    { errorCode = 400
                    , message = "The 'From' address you supplied (no-reply@at-chat.app) is not a Sender Signature on your account. Please add and confirm this address in order to be able to use it in the 'From' field of your messages. "
                    , to = [ exampleEmail ]
                    }
                    |> Err
                )
                exampleEmail
            )
        , logEntry (Log.LoginEmail (Err (Postmark.UnknownError { statusCode = 500, body = "Internal Server Error" })) exampleEmail)
        , logEntry (Log.LoginsRateLimited (Id.fromInt 42))
        , logEntry (Log.ChangedUsers (Id.fromInt 7))
        , logEntry (Log.SendLogErrorEmailFailed Postmark.Timeout exampleEmail)
        , logEntry (Log.PushNotificationError (Id.fromInt 15) Http.NetworkError)
        , logEntry (Log.PushNotificationError (Id.fromInt 15) (Http.BadStatus 403))
        , logEntry
            (Log.FailedToDeleteDiscordGuildMessage
                (Unsafe.uint64 "111222333444555666" |> Discord.idFromUInt64)
                (Unsafe.uint64 "777888999000111222" |> Discord.idFromUInt64)
                (Id.NoThreadWithMessage (Id.fromInt 0))
                (Unsafe.uint64 "333444555666777888" |> Discord.idFromUInt64)
                (Discord.NotFound404 Discord.UnknownMessage10008)
            )
        , logEntry
            (Log.FailedToParseDiscordWebsocket Nothing "Expecting STRING but instead got blah blah blah at blah in json[0].field")
        ]


embedExamples : SeqSet Domain -> Ui.Element ()
embedExamples whitelistedDomains =
    let
        message : NonemptyString -> List Embed -> Ui.Element ()
        message text embeds =
            RichText.view
                (Dom.id "richText")
                800
                (\_ -> ())
                (\_ -> ())
                { domainWhitelist = whitelistedDomains
                , revealedSpoilers = SeqSet.empty
                , users = SeqDict.empty
                , attachedFiles = SeqDict.empty
                , stickers = SeqDict.empty
                , animationMode = Sticker.LoopForever
                }
                (Array.fromList embeds)
                (RichText.fromNonemptyString SeqDict.empty text)
                |> Html.div []
                |> Ui.html

        url : String
        url =
            "https://ascii-collab.app/verycool/path/subpath/more/?blah=123#title-page"

        shortUrl : String
        shortUrl =
            "https://town-collab.app/"
    in
    Ui.column
        [ Ui.spacing 24 ]
        [ message (NonemptyString 'C' ("heck out this cool link! " ++ url ++ " Cool huh?")) [ EmbedLoading ]
        , message
            (NonemptyString 'C' ("heck out this cool link! " ++ url ++ " Cool huh?"))
            [ EmbedLoaded
                { title = Nothing
                , image = Nothing
                , description = Just "Content of this embedded link"
                , createdAt = Nothing
                }
            ]
        , message
            (NonemptyString 'C' ("heck out this cool link! " ++ url ++ " Cool huh?"))
            [ EmbedLoaded
                { title = Just "Title of this embed"
                , image = Just { url = "/android-chrome-512x512.png", imageSize = Coord.xy 512 512, format = Just Embed.Png }
                , description = Just "Content of this embedded link"
                , createdAt = Just (Time.millisToPosix 0)
                }
            ]
        , message
            (NonemptyString 'C' ("heck out this cool link! " ++ url ++ " Cool huh?"))
            [ EmbedLoaded Embed.empty
            ]
        , message
            (NonemptyString 'C' ("heck out this cool link! " ++ shortUrl ++ " Cool huh?"))
            [ EmbedLoaded Embed.empty
            ]
        , message
            (NonemptyString 'C' "heck out this cool link! http://town-collab.app/ Cool huh?")
            [ EmbedLoaded Embed.empty
            ]
        , message
            (NonemptyString 'C' "heck out this cool link! ||http://town-collab.app/ Cool huh?||")
            [ EmbedLoaded Embed.empty
            ]
        , message
            (NonemptyString 'C' ("heck out this cool link! ||" ++ url ++ " Cool huh?||"))
            [ EmbedLoaded
                { title = Just "Title of this embed"
                , image = Just { url = "/android-chrome-512x512.png", imageSize = Coord.xy 512 512, format = Just Embed.Png }
                , description = Just "Content of this embedded link"
                , createdAt = Just (Time.millisToPosix 0)
                }
            ]
        ]
