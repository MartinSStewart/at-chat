module E2EDrawing exposing (drawOnMessages, drawingScalesWithImages)

import Audio
import Coord
import Date exposing (Date)
import Drawing
import Duration
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import FileStatus
import Id
import List.Nonempty
import Message
import Pages.Guild
import Route
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import Time
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


drawOnMessages : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
drawOnMessages imageUploadConfig =
    E2EHelper.startTest
        "Draw on top of messages"
        (Duration.addTo E2EHelper.startTime (Duration.hours 23.96))
        imageUploadConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.writeMessage admin 100 "Draw on this message!"
                , E2EHelper.uploadImageAttachment admin
                , E2EHelper.focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []

                -- A message with a hyperlink that loads an embed containing an image
                , E2EHelper.writeMessage admin 100 "Draw on https://elm.camp too!"

                -- A day later another message is written so that a date divider shows up
                , E2EHelper.writeMessage admin (Duration.hours 0.05 |> Duration.inMilliseconds) "A new day means a date divider!"

                -- Open the drawing tab and check that the instructions show up
                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.text "Click on a profile image" ])
                , admin.snapshotView 100 { name = "Drawing tab waiting for an anchor to be picked" }
                , T.andThen
                    100
                    (\data ->
                        case ( E2EHelper.lastGuildChannelMessage data.backend, E2EHelper.findImageMessage data.backend, E2EHelper.findEmbedImageMessage data.backend ) of
                            ( Just ( guildId, messageId, _ ), Just ( imageMessageId, fileId ), Just embedMessageId ) ->
                                let
                                    dividerDate : Date
                                    dividerDate =
                                        Date.fromPosix Time.utc data.time
                                in
                                [ -- Click the message's profile image to use it as the drawing
                                  -- anchor. The anchor's screen position is part of the click
                                  -- event (clientX/Y minus offsetX/Y).
                                  admin.custom
                                    100
                                    (Drawing.profileImageAnchorId messageId)
                                    "click"
                                    (E2EHelper.drawingAnchorClick 30 25)
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Draw with the mouse" ])
                                , E2EHelper.drawZigzagStroke admin

                                -- The stroke is visible for the user that drew it and, in
                                -- realtime, for other users viewing the same channel
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 1)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 1)

                                -- The stroke is stored in the message on the backend
                                , T.checkState
                                    100
                                    (\data2 ->
                                        case E2EHelper.lastGuildChannelMessage data2.backend of
                                            Just ( _, _, message ) ->
                                                if List.length (Message.drawing Drawing.UserIconAnchor message).finished == 1 then
                                                    Ok ()

                                                else
                                                    Err "Expected the message to contain exactly one finished stroke"

                                            Nothing ->
                                                Err "Message not found on the backend"
                                    )

                                -- Undo removes the stroke for everyone, redo brings it back
                                , admin.click 100 Drawing.undoButtonId
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 0)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 0)
                                , admin.click 100 Drawing.redoButtonId
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 1)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 1)

                                -- The Ctrl+Z and Ctrl+Shift+Z hotkeys undo and redo the stroke too
                                , admin.update 100 (Audio.userMsg (Types.KeyDown { ctrlKey = True, metaKey = False, shiftKey = False, key = "z" }))
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 0)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 0)
                                , admin.update 100 (Audio.userMsg (Types.KeyDown { ctrlKey = True, metaKey = False, shiftKey = True, key = "z" }))
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 1)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 1)
                                , admin.snapshotView 100 { name = "Drawing stroke anchored to a profile image" }

                                -- Zooming in magnifies the conversation around the center of the
                                -- anchor so the user can draw more precisely. The toggle flips the
                                -- button label and the magnified conversation is clipped to its
                                -- normal area so the rest of the page layout is unaffected.
                                , admin.click 100 Drawing.zoomButtonId
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Zoom out" ])
                                , admin.snapshotView 100 { name = "Drawing zoomed in on an anchor" }

                                -- A stroke drawn while zoomed in is mapped back through the zoom so
                                -- the points are placed more precisely (the same mouse movement
                                -- covers less of the anchor's coordinate space than at 1x zoom). The
                                -- zoom keeps the center of the anchor centered in the container, which
                                -- the test reports as 100x100 at the origin with the anchor's top left
                                -- at (30, 25) and its half size at (20, 20).
                                , E2EHelper.drawZigzagStroke admin
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 2)

                                -- TODO: Fix BrowserDomNotFound error in program-test
                                --, T.checkState
                                --    100
                                --    (\data2 ->
                                --        case lastGuildChannelMessage data2.backend of
                                --            Just ( _, _, message ) ->
                                --                case (Message.drawing Drawing.UserIconAnchor message).finished of
                                --                    zoomedStroke :: _ ->
                                --                        expectPointsCloseTo
                                --                            [ ( 20, 12 ), ( 32, 24 ), ( 44, 12 ), ( 56, 24 ), ( 68, 12 ), ( 80, 24 ) ]
                                --                            (List.Nonempty.toList zoomedStroke.points)
                                --
                                --                    [] ->
                                --                        Err "Expected the profile image to have a stroke drawn while zoomed in"
                                --
                                --            Nothing ->
                                --                Err "Message not found on the backend"
                                --    )
                                -- Undo the zoomed stroke and zoom back out so the rest of the test
                                -- continues with a single stroke and the conversation at 1x zoom
                                , admin.click 100 Drawing.undoButtonId
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 1)
                                , admin.click 100 Drawing.zoomButtonId
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Zoom in" ])

                                -- Clicking the channel text input stops drawing by deselecting the
                                -- anchor, so the drawing tab goes back to asking for an anchor
                                , admin.click 100 Pages.Guild.channelTextInputId
                                , admin.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.text "Draw with the mouse" ])
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Click on a profile image" ])

                                -- Draw on the image attachment. The input overlay blocks anchor
                                -- clicks so the drawing tab is toggled to pick a new anchor.
                                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                                , admin.custom
                                    100
                                    (Dom.id
                                        ("spoiler_"
                                            ++ Id.toString imageMessageId
                                            ++ "_image_"
                                            ++ Id.toString fileId
                                        )
                                    )
                                    "click"
                                    (E2EHelper.drawingAnchorClick 100 50)
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Draw with the mouse" ])
                                , E2EHelper.drawZigzagStroke admin
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 2)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 2)
                                , T.checkState
                                    100
                                    (\data2 ->
                                        case E2EHelper.findImageMessage data2.backend of
                                            Just _ ->
                                                case E2EHelper.lastGuildChannelMessageAt imageMessageId data2.backend of
                                                    Just message ->
                                                        if
                                                            List.length
                                                                (Message.drawing (Drawing.ImageAttachmentAnchor fileId) message).finished
                                                                == 1
                                                        then
                                                            Ok ()

                                                        else
                                                            Err "Expected the image attachment to have exactly one finished stroke"

                                                    Nothing ->
                                                        Err "Image message not found on the backend"

                                            Nothing ->
                                                Err "Image message not found on the backend"
                                    )
                                , admin.snapshotView 100 { name = "Drawing stroke anchored to an image attachment" }

                                -- Draw on the date divider between yesterday's and today's messages
                                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                                , admin.custom
                                    100
                                    (Dom.id ("guild_dateDivider_" ++ Date.toIsoString dividerDate))
                                    "click"
                                    (E2EHelper.drawingAnchorClick 400 300)
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Draw with the mouse" ])
                                , E2EHelper.drawZigzagStroke admin
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 3)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 3)
                                , T.checkState
                                    100
                                    (\data2 ->
                                        case E2EHelper.lastGuildChannel data2.backend of
                                            Just channel ->
                                                case SeqDict.get dividerDate channel.dateDividerDrawings of
                                                    Just drawing ->
                                                        if List.length drawing.finished == 1 then
                                                            Ok ()

                                                        else
                                                            Err "Expected the date divider to have exactly one finished stroke"

                                                    Nothing ->
                                                        Err "Expected the date divider to have drawings stored on the backend"

                                            Nothing ->
                                                Err "Channel not found on the backend"
                                    )
                                , admin.snapshotView 100 { name = "Drawing stroke anchored to a date divider" }

                                -- Draw on the embed image with a stroke that extends past
                                -- both sides of the embed container. The container must not
                                -- clip the stroke.
                                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                                , admin.custom
                                    100
                                    (Dom.id ("spoiler_" ++ Id.toString embedMessageId ++ "_embedImage_0"))
                                    "click"
                                    (E2EHelper.drawingAnchorClick 100 100)
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Draw with the mouse" ])
                                , E2EHelper.drawWideZigzagStroke admin
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 4)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 4)
                                , T.checkState
                                    100
                                    (\data2 ->
                                        case E2EHelper.lastGuildChannelMessageAt embedMessageId data2.backend of
                                            Just message ->
                                                if
                                                    List.length
                                                        (Message.drawing (Drawing.EmbedImageAnchor 0) message).finished
                                                        == 1
                                                then
                                                    Ok ()

                                                else
                                                    Err "Expected the embed image to have exactly one finished stroke"

                                            Nothing ->
                                                Err "Embed message not found on the backend"
                                    )
                                , -- The whole conversation fits in the tall snapshot so the
                                  -- embed and the stroke sticking out of it are both visible
                                  E2EHelper.tallSnapshot admin 100 { name = "Drawing stroke anchored to an embed image extends outside the embed" }

                                -- Pressing the pencil tab again closes the drawing tab
                                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                                , admin.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.text "Draw with the mouse" ])

                                -- All four drawings are persisted so they survive loading the page again
                                , T.connectFrontend
                                    100
                                    E2EHelper.sessionId0
                                    (Route.encode
                                        (Route.GuildRoute
                                            guildId
                                            (Route.ChannelRoute
                                                (Id.fromInt 0)
                                                (Route.NoThreadWithFriends Nothing Route.HideMembersTab)
                                                Nothing
                                            )
                                        )
                                    )
                                    E2EHelper.desktopWindow
                                    (\admin2 ->
                                        [ admin2.portEvent
                                            10
                                            "load_startup_data_from_js"
                                            (E2EHelper.startupDataJson E2EHelper.firefoxDesktop)
                                        , -- Drawings are part of the channel data so they render
                                          -- as soon as the messages are shown
                                          admin2.checkView 2000 (E2EHelper.expectPolylineCount 4)
                                        ]
                                    )
                                ]

                            _ ->
                                [ T.checkState 0 (\_ -> Err "No message found to draw on") ]
                    )
                ]
            )
        ]


{-| Drawings anchored to an image must stay aligned with the image when it's
displayed scaled down to fit a smaller screen. Stroke points are stored in the
image's full resolution coordinates and scaled back to css pixels when the
image is rendered.
-}
drawingScalesWithImages : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
drawingScalesWithImages imageUploadConfig =
    let
        -- The image attachment is 800 pixels wide while the conversation area
        -- is only 457 css pixels wide in the 1000px desktop window and 316 css
        -- pixels in the 400px mobile window (window width minus the columns and
        -- padding around the conversation, see Pages.Guild.conversationWidth).
        -- The image is short enough to not be limited by max image height, so
        -- it's displayed at the conversation width on both screens.
        imageWidth : Float
        imageWidth =
            800

        desktopDisplayWidth : Float
        desktopDisplayWidth =
            457

        mobileDisplayWidth : Float
        mobileDisplayWidth =
            316
    in
    E2EHelper.startTest
        "Drawings scale along with images"
        E2EHelper.startTime
        imageUploadConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ -- Upload an 800x100 image and post it
                  admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                , T.backendUpdate
                    100
                    (Types.GotRustServerFileUpload (FileStatus.fileHash "123123123") 1234 (Just (Coord.xy 800 100)))
                , E2EHelper.focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                , admin.click 100 (Dom.id "channelHeader_drawOnMessages")
                , T.andThen
                    100
                    (\data ->
                        case ( E2EHelper.findImageMessage data.backend, E2EHelper.lastGuildChannelMessage data.backend ) of
                            ( Just ( imageMessageId, fileId ), Just ( guildId, _, _ ) ) ->
                                [ admin.custom
                                    100
                                    (Dom.id
                                        ("spoiler_"
                                            ++ Id.toString imageMessageId
                                            ++ "_image_"
                                            ++ Id.toString fileId
                                        )
                                    )
                                    "click"
                                    (E2EHelper.drawingAnchorClick 100 50)
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Draw with the mouse" ])
                                , E2EHelper.drawZigzagStroke admin
                                , admin.checkView 100 (E2EHelper.expectPolylineCount 1)
                                , user.checkView 100 (E2EHelper.expectPolylineCount 1)

                                -- The stroke is stored in the image's full resolution
                                -- coordinates: mouse positions relative to the image's top
                                -- left corner at (100, 50), multiplied by how much the image
                                -- was scaled down on the screen it was drawn on
                                , T.checkState
                                    100
                                    (\data2 ->
                                        case E2EHelper.lastGuildChannelMessageAt imageMessageId data2.backend of
                                            Just message ->
                                                case (Message.drawing (Drawing.ImageAttachmentAnchor fileId) message).finished of
                                                    [ stroke ] ->
                                                        E2EHelper.expectPointsCloseTo
                                                            (List.map
                                                                (\( x, y ) ->
                                                                    ( x * (imageWidth / desktopDisplayWidth)
                                                                    , y * (imageWidth / desktopDisplayWidth)
                                                                    )
                                                                )
                                                                [ ( -50, -20 ), ( -20, 10 ), ( 10, -20 ), ( 40, 10 ), ( 70, -20 ), ( 100, 10 ) ]
                                                            )
                                                            (List.Nonempty.toList stroke.points)

                                                    _ ->
                                                        Err "Expected the image attachment to have exactly one finished stroke"

                                            Nothing ->
                                                Err "Image message not found on the backend"
                                    )

                                -- Both desktop clients render the stroke scaled back down to
                                -- the size the image is displayed at
                                , admin.checkView 100 (E2EHelper.expectPolylineScale (desktopDisplayWidth / imageWidth))
                                , user.checkView 100 (E2EHelper.expectPolylineScale (desktopDisplayWidth / imageWidth))

                                -- On a mobile sized window the image is displayed smaller
                                -- and the drawing scales down along with it
                                , T.connectFrontend
                                    100
                                    E2EHelper.sessionId1
                                    (Route.encode
                                        (Route.GuildRoute
                                            guildId
                                            (Route.ChannelRoute
                                                (Id.fromInt 0)
                                                (Route.NoThreadWithFriends Nothing Route.HideMembersTab)
                                                Nothing
                                            )
                                        )
                                    )
                                    E2EHelper.iphone14Window
                                    (\userMobile ->
                                        [ userMobile.portEvent
                                            10
                                            "load_startup_data_from_js"
                                            (E2EHelper.startupDataJson E2EHelper.firefoxDesktop)
                                        , userMobile.checkView 2000 (E2EHelper.expectPolylineCount 1)
                                        , userMobile.checkView 100 (E2EHelper.expectPolylineScale (mobileDisplayWidth / imageWidth))
                                        , userMobile.snapshotView 100 { name = "Drawing scaled down along with the image on a small screen" }
                                        ]
                                    )
                                ]

                            _ ->
                                [ T.checkState 0 (\_ -> Err "No image message found to draw on") ]
                    )
                ]
            )
        ]
