module E2EMedia exposing (audioAttachmentTest, imageViewerTests, videoAttachmentTest)

import Audio
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Env
import Json.Decode
import Json.Encode
import List.Extra
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


imageViewerTests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
imageViewerTests imageUploadConfig =
    T.testGroup
        "Image viewer"
        [ E2EHelper.startTest
            "Clicking an image attachment opens a zoomable image viewer overlay"
            E2EHelper.startTime
            imageUploadConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.desktopWindow
                (\admin _ ->
                    [ E2EHelper.uploadImageAttachment admin
                    , E2EHelper.focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                    , admin.checkView
                        0
                        (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])

                    -- Clicking the image opens the overlay instead of a new tab. Once
                    -- the overlay is open it is independent of the message, so it
                    -- stays open as the rest of the app keeps rendering.
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_close" ])
                    , admin.snapshotView 100 { name = "Image viewer overlay" }

                    -- The image can be dragged around.
                    , admin.mouseDown 100 (Dom.id "imageViewer_overlay") ( 100, 100 ) []
                    , admin.mouseMove 100 (Dom.id "imageViewer_overlay") ( 250, 180 ) []
                    , admin.mouseUp 100 (Dom.id "imageViewer_overlay") ( 250, 180 ) []
                    , T.checkState
                        100
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case Audio.userModel frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        imageViewer.offsetX == 150 && imageViewer.offsetY == 80

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Dragging the image should have moved it by (150, 80)"
                        )

                    -- Scroll-zoom glides toward its target rather than snapping: a
                    -- frame or two after the wheel event the scale is partway between
                    -- 1 and 1.1.
                    , admin.wheel 100 (Dom.id "imageViewer_overlay") -1 ( 700, 400 ) [] []
                    , T.checkState
                        50
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case Audio.userModel frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        imageViewer.scale > 1.0 && imageViewer.scale < 1.1

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Scroll-zoom should glide toward its target (zoom inertia)"
                        )

                    -- Once it settles, the zoom anchors on the cursor: zooming in at
                    -- (700, 400), down and to the right of the 1000x600 viewport
                    -- center, shifts the image so that point stays under the cursor.
                    -- From offset (150, 80) and scale 1, scrolling in by 1.1x gives
                    -- offsetX = 200*(1-1.1) + 1.1*150 = 145 and offsetY = 100*(1-1.1) + 1.1*80 = 78.
                    , T.checkState
                        2000
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case Audio.userModel frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        (abs (imageViewer.scale - 1.1) < 0.01)
                                                            && (abs (imageViewer.offsetX - 145) < 0.01)
                                                            && (abs (imageViewer.offsetY - 78) < 0.01)

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Scroll-zooming should settle anchored on the cursor"
                        )

                    -- Zooming in keeps the overlay open.
                    , admin.click 100 (Dom.id "imageViewer_zoomIn")
                    , admin.click 100 (Dom.id "imageViewer_zoomIn")
                    , admin.snapshotView 2000 { name = "Image viewer overlay zoomed in" }

                    -- The x button closes the overlay.
                    , admin.click 100 (Dom.id "imageViewer_close")
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_close" ])
                    ]
                )
            ]
        , E2EHelper.startTest
            "On mobile the image viewer has no buttons and uses pinch/drag gestures"
            E2EHelper.startTime
            imageUploadConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.mobileWindow
                (\admin _ ->
                    let
                        touchEvent : List ( Float, Float ) -> { changedTouches : List { id : Int, clientPos : ( Float, Float ), pagePos : ( Float, Float ), screenPos : ( Float, Float ) }, targetTouches : List { id : Int, clientPos : ( Float, Float ), pagePos : ( Float, Float ), screenPos : ( Float, Float ) } }
                        touchEvent points =
                            { changedTouches = []
                            , targetTouches =
                                List.indexedMap
                                    (\index ( x, y ) ->
                                        { id = index, clientPos = ( x, y ), pagePos = ( x, y ), screenPos = ( x, y ) }
                                    )
                                    points
                            }
                    in
                    [ E2EHelper.uploadImageAttachment admin
                    , admin.click 1000 (Dom.id "messageMenu_channelInput_sendMessage")
                    , admin.checkView
                        0
                        (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])

                    -- Tapping the image opens the overlay.
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])

                    -- On mobile the zoom and close buttons are hidden.
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_close" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_zoomIn" ])
                    , admin.snapshotView 100 { name = "Image viewer overlay on mobile" }

                    -- Pinching with two fingers zooms in (distance goes 20 -> 100, so
                    -- the scale becomes 5x) anchored on the pinch midpoint (300, 400).
                    -- That midpoint is to the right of the 400x800 viewport center, so
                    -- the image shifts left: offsetX = 100*(1-5) + 5*0 = -400.
                    , admin.touchStart 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 290, 400 ), ( 310, 400 ) ])
                    , admin.touchMove 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 250, 400 ), ( 350, 400 ) ])
                    , T.checkState
                        100
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case Audio.userModel frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        (imageViewer.scale == 5)
                                                            && (imageViewer.offsetX == -400)
                                                            && (imageViewer.offsetY == 0)

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Pinching apart should zoom to 5x anchored on the pinch midpoint"
                        )
                    , admin.touchEnd 100 (Dom.id "imageViewer_overlay") (touchEvent [])

                    -- Dragging the image off the top of the screen dismisses it.
                    , admin.touchStart 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 200, 400 ) ])
                    , admin.touchMove 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 200, -3000 ) ])
                    , admin.touchEnd 100 (Dom.id "imageViewer_overlay") (touchEvent [])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_overlay" ])
                    ]
                )
            ]
        , E2EHelper.startTest
            "Moving both fingers together pans the image while pinching"
            E2EHelper.startTime
            imageUploadConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.mobileWindow
                (\admin _ ->
                    let
                        touchEvent : List ( Float, Float ) -> { changedTouches : List { id : Int, clientPos : ( Float, Float ), pagePos : ( Float, Float ), screenPos : ( Float, Float ) }, targetTouches : List { id : Int, clientPos : ( Float, Float ), pagePos : ( Float, Float ), screenPos : ( Float, Float ) } }
                        touchEvent points =
                            { changedTouches = []
                            , targetTouches =
                                List.indexedMap
                                    (\index ( x, y ) ->
                                        { id = index, clientPos = ( x, y ), pagePos = ( x, y ), screenPos = ( x, y ) }
                                    )
                                    points
                            }
                    in
                    [ E2EHelper.uploadImageAttachment admin
                    , admin.click 1000 (Dom.id "messageMenu_channelInput_sendMessage")
                    , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])

                    -- Two fingers a constant 20px apart, with their midpoint
                    -- sliding from (200, 400) to (300, 500). The distance doesn't
                    -- change, so there's no zoom (scale stays 1); the image just
                    -- pans by the (100, 100) the midpoint moved.
                    , admin.touchStart 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 190, 400 ), ( 210, 400 ) ])
                    , admin.touchMove 100 (Dom.id "imageViewer_overlay") (touchEvent [ ( 290, 500 ), ( 310, 500 ) ])
                    , T.checkState
                        100
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case Audio.userModel frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        (imageViewer.scale == 1)
                                                            && (imageViewer.offsetX == 100)
                                                            && (imageViewer.offsetY == 100)

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Moving both fingers together should pan the image by the midpoint delta without zooming"
                        )
                    , admin.touchEnd 100 (Dom.id "imageViewer_overlay") (touchEvent [])
                    ]
                )
            ]
        , E2EHelper.startTest
            "Flinging the image in the viewer keeps it moving (inertia)"
            E2EHelper.startTime
            imageUploadConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.desktopWindow
                (\admin _ ->
                    [ E2EHelper.uploadImageAttachment admin
                    , E2EHelper.focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                    , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])

                    -- Flick: move by (20, 10) and release on the same frame (delay 0)
                    -- so the velocity is preserved as momentum.
                    , admin.mouseDown 100 (Dom.id "imageViewer_overlay") ( 500, 300 ) []
                    , admin.mouseMove 100 (Dom.id "imageViewer_overlay") ( 520, 310 ) []
                    , admin.mouseUp 0 (Dom.id "imageViewer_overlay") ( 520, 310 ) []

                    -- Right after release the image has only moved by the drag amount.
                    , T.checkState
                        0
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case Audio.userModel frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        imageViewer.offsetX == 20 && imageViewer.offsetY == 10

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Right after the flick the image should have moved by exactly the drag amount"
                        )

                    -- After the momentum settles the image has coasted much further in
                    -- the same direction, but stayed on screen.
                    , T.checkState
                        2000
                        (\data ->
                            if
                                List.any
                                    (\( _, frontend ) ->
                                        case Audio.userModel frontend of
                                            Types.Loaded loaded ->
                                                case loaded.imageViewer of
                                                    Just imageViewer ->
                                                        (imageViewer.offsetX > 100)
                                                            && (imageViewer.offsetX < 400)
                                                            && (imageViewer.offsetY > 50)
                                                            && (imageViewer.offsetY < 300)

                                                    Nothing ->
                                                        False

                                            Types.Loading _ ->
                                                False
                                    )
                                    (SeqDict.toList data.frontends)
                            then
                                Ok ()

                            else
                                Err "Momentum should have coasted the image further after release"
                        )
                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])
                    ]
                )
            ]
        , E2EHelper.startTest
            "The image viewer background fades as the image is dragged off screen"
            E2EHelper.startTime
            imageUploadConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.desktopWindow
                (\admin _ ->
                    [ E2EHelper.uploadImageAttachment admin
                    , E2EHelper.focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                    , admin.checkView 0 (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])
                    , admin.click 0 (Dom.id "spoiler_1_image_1")
                    , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])

                    -- Drag the image until its center sits in the bottom-right corner
                    -- of the 1000x600 window, leaving only its top-left quarter (25%
                    -- of the area) visible, so the black background is half faded.
                    , admin.mouseDown 50 (Dom.id "imageViewer_overlay") ( 100, 100 ) []
                    , admin.mouseMove 50 (Dom.id "imageViewer_overlay") ( 200, 200 ) []
                    , admin.mouseUp 50 (Dom.id "imageViewer_overlay") ( 200, 200 ) []

                    -- Image is mostly on screen so doesn't get removed
                    , admin.checkView 1000 (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])
                    , admin.mouseDown 50 (Dom.id "imageViewer_overlay") ( 200, 200 ) []
                    , admin.mouseMove 50 (Dom.id "imageViewer_overlay") ( 350, 350 ) []
                    , admin.mouseUp 50 (Dom.id "imageViewer_overlay") ( 350, 350 ) []
                    , admin.snapshotView 30 { name = "Image viewer background faded" }
                    , admin.checkView 1000 (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_overlay" ])
                    ]
                )
            ]
        , E2EHelper.startTest
            "Right clicking images and links adds copy options to the message menu"
            E2EHelper.startTime
            imageUploadConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.desktopWindow
                (\admin _ ->
                    let
                        imageUrl : String
                        imageUrl =
                            Env.domain ++ "/file/1/123123123"

                        linkUrl : String
                        linkUrl =
                            "https://example.com/some-page"
                    in
                    [ E2EHelper.uploadImageAttachment admin
                    , E2EHelper.focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                    , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                    , admin.checkView
                        0
                        (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])

                    -- Right clicking somewhere on the message that isn't an image opens
                    -- the message menu without the image specific options.
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_copyImage" ])

                    -- Right clicking the image itself includes its full-size url (exposed
                    -- via the data-image-url attribute) so the menu offers the image
                    -- specific copy options.
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            , ( "target"
                              , Json.Encode.object
                                    [ ( "dataset"
                                      , Json.Encode.object [ ( "imageUrl", Json.Encode.string imageUrl ) ]
                                      )
                                    ]
                              )
                            ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.has
                            [ Test.Html.Selector.id "messageMenu_copyImage" ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.has
                            [ Test.Html.Selector.id "messageMenu_copyImageLink" ]
                        )
                    , admin.snapshotView 100 { name = "Message menu with copy image options" }

                    -- "Copy image" copies the actual image data to the clipboard.
                    , admin.click 100 (Dom.id "messageMenu_copyImage")
                    , T.andThen
                        100
                        (\data ->
                            case
                                List.Extra.findMap
                                    (\request ->
                                        if request.clientId == admin.clientId && request.portName == "copy_image_to_clipboard_to_js" then
                                            Json.Decode.decodeValue Json.Decode.string request.value |> Result.toMaybe

                                        else
                                            Nothing
                                    )
                                    data.portRequests
                            of
                                Just copiedUrl ->
                                    if copiedUrl == imageUrl then
                                        []

                                    else
                                        [ T.checkState 0 (\_ -> Err ("Copy image copied the wrong url: " ++ copiedUrl)) ]

                                Nothing ->
                                    [ T.checkState 0 (\_ -> Err "Copy image should have triggered the copy_image_to_clipboard_to_js port") ]
                        )

                    -- "Copy image link" copies the image's url as text instead.
                    , admin.click 100 (Dom.id "messageMenu_copyImageLink")
                    , T.andThen
                        100
                        (\data ->
                            case
                                List.Extra.findMap
                                    (\request ->
                                        if request.clientId == admin.clientId && request.portName == "copy_to_clipboard_to_js" then
                                            Json.Decode.decodeValue Json.Decode.string request.value |> Result.toMaybe

                                        else
                                            Nothing
                                    )
                                    data.portRequests
                            of
                                Just copiedUrl ->
                                    if copiedUrl == imageUrl then
                                        []

                                    else
                                        [ T.checkState 0 (\_ -> Err ("Copy image link copied the wrong url: " ++ copiedUrl)) ]

                                Nothing ->
                                    [ T.checkState 0 (\_ -> Err "Copy image link should have triggered the copy_to_clipboard_to_js port") ]
                        )

                    -- The element under the cursor is often a descendant of the one
                    -- carrying data-image-url (e.g. the <canvas>/<img> that an animated
                    -- gif player appends inside itself). The menu still finds the url by
                    -- walking up to the ancestor that has it.
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            , ( "target"
                              , Json.Encode.object
                                    [ ( "dataset", Json.Encode.object [] )
                                    , ( "parentElement"
                                      , Json.Encode.object
                                            [ ( "dataset"
                                              , Json.Encode.object [ ( "imageUrl", Json.Encode.string imageUrl ) ]
                                              )
                                            ]
                                      )
                                    ]
                              )
                            ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyImageLink" ])

                    -- Right clicking a hyperlink offers a "Copy link" option (and not the
                    -- image options) that copies the link's url.
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "contextmenu"
                        (Json.Encode.object
                            [ ( "clientX", Json.Encode.float 50 )
                            , ( "clientY", Json.Encode.float 150 )
                            , ( "target"
                              , Json.Encode.object
                                    [ ( "dataset"
                                      , Json.Encode.object [ ( "linkUrl", Json.Encode.string linkUrl ) ]
                                      )
                                    ]
                              )
                            ]
                        )
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyLink" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_copyImage" ])
                    , admin.click 100 (Dom.id "messageMenu_copyLink")
                    , T.andThen
                        100
                        (\data ->
                            if
                                List.any
                                    (\request ->
                                        (request.clientId == admin.clientId)
                                            && (request.portName == "copy_to_clipboard_to_js")
                                            && (Json.Decode.decodeValue Json.Decode.string request.value == Ok linkUrl)
                                    )
                                    data.portRequests
                            then
                                []

                            else
                                [ T.checkState 0 (\_ -> Err "Copy link should have copied the link url to the clipboard") ]
                        )
                    ]
                )
            ]
        , E2EHelper.startTest
            "Long pressing images and links adds copy options to the mobile message menu"
            E2EHelper.startTime
            imageUploadConfig
            [ E2EHelper.connectTwoUsersAndJoinNewGuild
                E2EHelper.mobileWindow
                (\admin _ ->
                    let
                        imageUrl : String
                        imageUrl =
                            Env.domain ++ "/file/1/123123123"

                        linkUrl : String
                        linkUrl =
                            "https://example.com/some-page"

                        -- A "touchstart" event whose target carries the given data-*
                        -- attributes, in the shape our Touch decoder expects (touches is
                        -- a TouchList-like object with a length and numeric indices).
                        longPress : List ( String, Json.Encode.Value ) -> Json.Encode.Value
                        longPress dataset =
                            Json.Encode.object
                                [ ( "timeStamp", Json.Encode.float 1000 )
                                , ( "touches"
                                  , Json.Encode.object
                                        [ ( "length", Json.Encode.int 1 )
                                        , ( "0"
                                          , Json.Encode.object
                                                [ ( "identifier", Json.Encode.int 0 )
                                                , ( "clientX", Json.Encode.float 50 )
                                                , ( "clientY", Json.Encode.float 150 )
                                                , ( "target"
                                                  , Json.Encode.object [ ( "id", Json.Encode.string "guild_message_1" ) ]
                                                  )
                                                ]
                                          )
                                        ]
                                  )
                                , ( "target", Json.Encode.object [ ( "dataset", Json.Encode.object dataset ) ] )
                                ]

                        -- Releasing the touch resets the drag state so the next long press
                        -- can be registered.
                        touchEnd : Json.Encode.Value
                        touchEnd =
                            Json.Encode.object [ ( "timeStamp", Json.Encode.float 2000 ) ]
                    in
                    [ E2EHelper.uploadImageAttachment admin
                    , admin.click 1000 (Dom.id "messageMenu_channelInput_sendMessage")
                    , admin.checkView
                        0
                        (Test.Html.Query.has [ Test.Html.Selector.id "spoiler_1_image_1" ])

                    -- Long pressing the image opens the mobile menu. The url is found on
                    -- the touched element, so the menu offers the image copy options.
                    -- (500ms after touchstart the long-press timer fires.)
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "touchstart"
                        (longPress [ ( "imageUrl", Json.Encode.string imageUrl ) ])
                    , admin.checkView
                        600
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyImage" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyImageLink" ])
                    , admin.snapshotView 100 { name = "Mobile message menu with copy image options" }
                    , admin.click 100 (Dom.id "messageMenu_copyImageLink")
                    , T.andThen
                        100
                        (\data ->
                            if
                                List.any
                                    (\request ->
                                        (request.clientId == admin.clientId)
                                            && (request.portName == "copy_to_clipboard_to_js")
                                            && (Json.Decode.decodeValue Json.Decode.string request.value == Ok imageUrl)
                                    )
                                    data.portRequests
                            then
                                []

                            else
                                [ T.checkState 0 (\_ -> Err "Copy image link should have copied the image url to the clipboard") ]
                        )

                    -- Release the touch, then long press a hyperlink instead.
                    , admin.custom 100 (Dom.id "elm-ui-root-id") "touchend" touchEnd
                    , admin.custom
                        100
                        (Dom.id "guild_message_1")
                        "touchstart"
                        (longPress [ ( "linkUrl", Json.Encode.string linkUrl ) ])
                    , admin.checkView
                        600
                        (Test.Html.Query.has [ Test.Html.Selector.id "messageMenu_copyLink" ])
                    , admin.checkView
                        100
                        (Test.Html.Query.hasNot [ Test.Html.Selector.id "messageMenu_copyImage" ])
                    , admin.click 100 (Dom.id "messageMenu_copyLink")
                    , T.andThen
                        100
                        (\data ->
                            if
                                List.any
                                    (\request ->
                                        (request.clientId == admin.clientId)
                                            && (request.portName == "copy_to_clipboard_to_js")
                                            && (Json.Decode.decodeValue Json.Decode.string request.value == Ok linkUrl)
                                    )
                                    data.portRequests
                            then
                                []

                            else
                                [ T.checkState 0 (\_ -> Err "Copy link should have copied the link url to the clipboard") ]
                        )
                    ]
                )
            ]
        ]


videoAttachmentTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
videoAttachmentTest videoUploadConfig =
    E2EHelper.startTest
        "Video attachments render inline and can be spoilered"
        E2EHelper.startTime
        videoUploadConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                E2EHelper.attachmentTestActions
                    { tagName = "video"
                    , plainSnapshot = "Video attachment"
                    , spoileredSnapshot = "Spoilered video attachment"
                    , revealedSnapshot = "Unspoilered video attachment"
                    }
                    admin
            )
        ]


audioAttachmentTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
audioAttachmentTest audioUploadConfig =
    E2EHelper.startTest
        "Audio attachments render inline and can be spoilered"
        E2EHelper.startTime
        audioUploadConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                E2EHelper.attachmentTestActions
                    { tagName = "audio"
                    , plainSnapshot = "Audio attachment"
                    , spoileredSnapshot = "Spoilered audio attachment"
                    , revealedSnapshot = "Unspoilered audio attachment"
                    }
                    admin
            )
        ]
