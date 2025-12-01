module ImageEditor exposing (DragPart, DragState, Model, Msg(..), init, subscriptions, update, view)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.File.Select as FileSelect
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Html
import Html.Attributes
import Html.Events
import Html.Events.Extra.Touch
import Image exposing (Image)
import Json.Decode
import List.Extra as List
import MyUi
import Pixels
import Ports exposing (CropImageDataResponse)
import Ui exposing (Element)


type Msg
    = PressedProfileImage
    | SelectedImage File
    | GotImageUrl String
    | MouseDownImageEditor Float Float
    | MouseUpImageEditor
    | MovedImageEditor Float Float
    | TouchEndImageEditor
    | PressedConfirmImage
    | GotImageSize (Result Dom.Error Dom.Element)
    | CroppedImage (Result String CropImageDataResponse)
    | PressedCancel


type alias DragState =
    { startX : Float
    , startY : Float
    , dragPart : DragPart
    , currentX : Float
    , currentY : Float
    }


type DragPart
    = TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
    | Center


type alias Model =
    { x : Float
    , y : Float
    , size : Float
    , imageUrl : Maybe String
    , dragState : Maybe DragState
    , imageSize : Maybe ( Int, Int )
    }


init : Model
init =
    { x = 0
    , y = 0
    , size = 0
    , imageUrl = Nothing
    , dragState = Nothing
    , imageSize = Nothing
    }


update : Coord CssPixels -> Msg -> Model -> ( Model, Maybe Image, Command FrontendOnly toMsg Msg )
update windowSize msg model =
    case msg of
        PressedProfileImage ->
            ( model, Nothing, FileSelect.file [ "image/png", "image/jpg", "image/jpeg" ] SelectedImage )

        SelectedImage file ->
            ( model, Nothing, File.toUrl file |> Task.perform GotImageUrl )

        GotImageUrl imageUrl ->
            ( { x = 0
              , y = 0
              , size = 1
              , imageUrl = Just imageUrl
              , dragState = Nothing
              , imageSize = Nothing
              }
            , Nothing
            , Dom.getElement profileImagePlaceholderId |> Task.attempt GotImageSize
            )

        MouseDownImageEditor x y ->
            let
                ( tx, ty ) =
                    ( pixelToT windowSize x, pixelToT windowSize y )

                dragPart : Maybe ( DragPart, Float )
                dragPart =
                    [ ( TopLeft, model.x, model.y )
                    , ( TopRight, model.x + model.size, model.y )
                    , ( BottomLeft, model.x, model.y + model.size )
                    , ( BottomRight, model.x + model.size, model.y + model.size )
                    ]
                        |> List.map
                            (\( part, partX, partY ) ->
                                ( part, (partX - tx) ^ 2 + (partY - ty) ^ 2 |> sqrt )
                            )
                        |> List.minimumBy Tuple.second

                newDragState =
                    { startX = tx
                    , startY = ty
                    , dragPart =
                        case dragPart of
                            Just ( part, distance ) ->
                                if distance > 0.07 then
                                    Center

                                else
                                    part

                            Nothing ->
                                Center
                    , currentX = tx
                    , currentY = ty
                    }
            in
            ( { model | dragState = Just newDragState }, Nothing, Command.none )

        MovedImageEditor x y ->
            ( updateDragState (pixelToT windowSize x) (pixelToT windowSize y) model
            , Nothing
            , Command.none
            )

        MouseUpImageEditor ->
            ( getActualImageState model |> (\a -> { a | dragState = Nothing })
            , Nothing
            , Command.none
            )

        TouchEndImageEditor ->
            ( getActualImageState model |> (\a -> { a | dragState = Nothing })
            , Nothing
            , Command.none
            )

        PressedConfirmImage ->
            case ( model.imageSize, model.imageUrl ) of
                ( Just ( w, _ ), Just imageUrl ) ->
                    ( { model | imageSize = Nothing, imageUrl = Nothing }
                    , Nothing
                    , Ports.cropImageToJs
                        { requestId = 0
                        , imageUrl = imageUrl
                        , cropX = model.x * toFloat w |> round |> Pixels.pixels
                        , cropY = model.y * toFloat w |> round |> Pixels.pixels
                        , cropWidth = Image.defaultSize
                        , cropHeight = Image.defaultSize
                        , width = toFloat w * model.size |> round |> Pixels.pixels
                        , height = toFloat w * model.size |> round |> Pixels.pixels
                        }
                    )

                _ ->
                    ( model, Nothing, Command.none )

        GotImageSize result ->
            case result of
                Ok { element } ->
                    if element.height <= 0 then
                        ( model
                        , Nothing
                        , Dom.getElement profileImagePlaceholderId |> Task.attempt GotImageSize
                        )

                    else
                        ( { model
                            | imageSize = Just ( round element.width, round element.height )
                            , x = 0
                            , y = 0
                            , size = min 1 (element.height / element.width)
                          }
                        , Nothing
                        , Command.none
                        )

                _ ->
                    ( model, Nothing, Command.none )

        CroppedImage result ->
            case result of
                Ok imageData ->
                    case Image.image imageData.croppedImageUrl of
                        Ok profileImage ->
                            ( model
                            , Just profileImage
                            , Command.none
                            )

                        Err _ ->
                            ( model, Nothing, Command.none )

                Err _ ->
                    ( model, Nothing, Command.none )

        PressedCancel ->
            ( { model | imageUrl = Nothing, imageSize = Nothing }, Nothing, Command.none )


subscriptions : Subscription FrontendOnly Msg
subscriptions =
    Subscription.batch
        [ Ports.cropImageFromJs (\a -> CroppedImage a)
        , Effect.Browser.Events.onMouseUp (Json.Decode.succeed MouseUpImageEditor)
        ]


updateDragState : Float -> Float -> Model -> Model
updateDragState tx ty imageData =
    { imageData
        | dragState =
            case imageData.dragState of
                Just dragState_ ->
                    { dragState_ | currentX = tx, currentY = ty } |> Just

                Nothing ->
                    imageData.dragState
    }


getActualImageState : Model -> Model
getActualImageState imageData =
    let
        aspectRatio : Float
        aspectRatio =
            case imageData.imageSize of
                Just ( w, h ) ->
                    toFloat h / toFloat w

                Nothing ->
                    1

        minX =
            0

        maxX =
            1

        minY =
            0

        maxY =
            aspectRatio
    in
    case imageData.dragState of
        Just dragState ->
            case dragState.dragPart of
                Center ->
                    { imageData
                        | x = clamp minX (maxX - imageData.size) (imageData.x + dragState.currentX - dragState.startX)
                        , y = clamp minY (maxY - imageData.size) (imageData.y + dragState.currentY - dragState.startY)
                    }

                TopLeft ->
                    let
                        xDelta =
                            dragState.currentX - dragState.startX

                        yDelta =
                            dragState.currentY - dragState.startY

                        maxDelta =
                            min xDelta yDelta
                                |> min (imageData.size - 0.05)
                                |> max -(min imageData.x imageData.y)
                    in
                    { imageData
                        | x = imageData.x + maxDelta
                        , y = imageData.y + maxDelta
                        , size = imageData.size - maxDelta
                    }

                TopRight ->
                    let
                        xDelta =
                            dragState.currentX - dragState.startX

                        yDelta =
                            dragState.currentY - dragState.startY

                        maxDelta =
                            min -xDelta yDelta
                                |> min (imageData.size - 0.05)
                                |> max -(min (maxX - imageData.x - imageData.size) imageData.y)
                    in
                    { imageData
                        | y = imageData.y + maxDelta
                        , size = imageData.size - maxDelta
                    }

                BottomLeft ->
                    let
                        xDelta =
                            dragState.currentX - dragState.startX

                        yDelta =
                            dragState.currentY - dragState.startY

                        maxDelta =
                            min xDelta -yDelta
                                |> min (imageData.size - 0.05)
                                |> max -(min imageData.x (maxY - imageData.y - imageData.size))
                    in
                    { imageData
                        | x = imageData.x + maxDelta
                        , size = imageData.size - maxDelta
                    }

                BottomRight ->
                    let
                        xDelta =
                            dragState.currentX - dragState.startX

                        yDelta =
                            dragState.currentY - dragState.startY

                        maxDelta =
                            min -xDelta -yDelta
                                |> min (imageData.size - 0.05)
                                |> max
                                    -(min
                                        (maxX - imageData.x - imageData.size)
                                        (maxY - imageData.y - imageData.size)
                                     )
                    in
                    { imageData | size = imageData.size - maxDelta }

        Nothing ->
            imageData


pixelToT : Coord CssPixels -> Float -> Float
pixelToT windowSize value =
    value / toFloat (imageEditorWidth windowSize)


tToPixel : Coord CssPixels -> Float -> Float
tToPixel windowSize value =
    value * toFloat (imageEditorWidth windowSize)


imageEditorWidth : Coord CssPixels -> Int
imageEditorWidth windowSize =
    min 400 (Coord.xRaw windowSize)


profileImagePlaceholderId : HtmlId
profileImagePlaceholderId =
    Dom.id "profile-image-placeholder-id"


view : Coord CssPixels -> Model -> Element Msg
view windowSize model =
    case model.imageUrl of
        Nothing ->
            MyUi.secondaryButton (Dom.id "imageEditor_selectImage") PressedProfileImage "Select image"

        Just imageUrl ->
            let
                { x, y, size, dragState } =
                    getActualImageState model

                drawNode x_ y_ =
                    Ui.inFront
                        (Ui.el
                            [ Ui.width (Ui.px 8)
                            , Ui.height (Ui.px 8)
                            , Ui.move
                                { x = tToPixel windowSize x_ - 4 |> round
                                , y = tToPixel windowSize y_ - 4 |> round
                                , z = 0
                                }
                            , Ui.background MyUi.white
                            , Ui.border 2
                            , MyUi.htmlStyle "pointer-events" "none"
                            ]
                            Ui.none
                        )

                drawHorizontalLine x_ y_ width =
                    Ui.inFront
                        (Ui.el
                            [ Ui.width (Ui.px (round (tToPixel windowSize width)))
                            , Ui.height (Ui.px 6)
                            , Ui.move
                                { x = tToPixel windowSize x_ |> round
                                , y = (tToPixel windowSize y_ - 3) |> round
                                , z = 0
                                }
                            , Ui.background MyUi.white
                            , Ui.border 2
                            , MyUi.htmlStyle "pointer-events" "none"
                            ]
                            Ui.none
                        )

                drawVerticalLine x_ y_ height =
                    Ui.inFront
                        (Ui.el
                            [ Ui.height (Ui.px (round (tToPixel windowSize height)))
                            , Ui.width (Ui.px 6)
                            , Ui.move
                                { x = (tToPixel windowSize x_ - 3) |> round
                                , y = tToPixel windowSize y_ |> round
                                , z = 0
                                }
                            , Ui.background MyUi.white
                            , Ui.border 2
                            , MyUi.htmlStyle "pointer-events" "none"
                            ]
                            Ui.none
                        )

                imageEditorWidth_ =
                    imageEditorWidth windowSize
            in
            Ui.column
                [ Ui.spacing 8
                , Ui.inFront
                    (case model.imageSize of
                        Just _ ->
                            Ui.none

                        Nothing ->
                            Ui.el
                                [ MyUi.htmlStyle "pointer-events" "none"
                                ]
                                (Ui.html
                                    (Html.img
                                        [ Dom.idToAttribute profileImagePlaceholderId
                                        , Html.Attributes.src imageUrl
                                        ]
                                        []
                                    )
                                )
                    )
                ]
                [ Ui.image
                    [ Ui.width (Ui.px imageEditorWidth_)
                    , case model.imageSize of
                        Just ( w, h ) ->
                            Ui.height (Ui.px (round (toFloat (imageEditorWidth_ * h) / toFloat w)))

                        Nothing ->
                            Ui.inFront Ui.none
                    , Json.Decode.map2 (\x_ y_ -> ( MouseDownImageEditor x_ y_, True ))
                        (Json.Decode.field "offsetX" Json.Decode.float)
                        (Json.Decode.field "offsetY" Json.Decode.float)
                        |> Html.Events.preventDefaultOn "mousedown"
                        |> Ui.htmlAttribute
                    , if dragState == Nothing then
                        Html.Events.on "" (Json.Decode.succeed (MovedImageEditor 0 0))
                            |> Ui.htmlAttribute

                      else
                        Json.Decode.map2 (\x_ y_ -> ( MovedImageEditor x_ y_, True ))
                            (Json.Decode.field "offsetX" Json.Decode.float)
                            (Json.Decode.field "offsetY" Json.Decode.float)
                            |> Html.Events.preventDefaultOn "mousemove"
                            |> Ui.htmlAttribute
                    , Html.Events.Extra.Touch.onStart
                        (\event ->
                            case List.reverse event.touches |> List.head of
                                Just last ->
                                    MouseDownImageEditor (Tuple.first last.clientPos) (Tuple.second last.clientPos)

                                Nothing ->
                                    MouseDownImageEditor 0 0
                        )
                        |> Ui.htmlAttribute
                    , Html.Events.Extra.Touch.onEnd (\_ -> TouchEndImageEditor) |> Ui.htmlAttribute
                    , if dragState == Nothing then
                        Html.Events.on "" (Json.Decode.succeed (MovedImageEditor 0 0))
                            |> Ui.htmlAttribute

                      else
                        Html.Events.Extra.Touch.onMove
                            (\event ->
                                case List.reverse event.touches |> List.head of
                                    Just last ->
                                        MovedImageEditor (Tuple.first last.clientPos) (Tuple.second last.clientPos)

                                    Nothing ->
                                        MovedImageEditor 0 0
                            )
                            |> Ui.htmlAttribute
                    , drawNode x y
                    , drawNode (x + size) y
                    , drawNode x (y + size)
                    , drawNode (x + size) (y + size)
                    , drawHorizontalLine x y size
                    , drawHorizontalLine x (y + size) size
                    , drawVerticalLine x y size
                    , drawVerticalLine (x + size) y size
                    ]
                    { source = imageUrl
                    , description = "Image editor"
                    , onLoad = Nothing
                    }
                , Ui.row
                    [ Ui.spacing 16 ]
                    [ MyUi.secondaryButton (Dom.id "imageEditor_cancel") PressedCancel "Cancel"
                    , MyUi.primaryButton (Dom.id "imageEditor_confirm") PressedConfirmImage "Confirm"
                    ]
                ]
