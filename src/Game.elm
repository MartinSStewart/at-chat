module Game exposing
    ( FrameId
    , GridPos
    , HorizontalWallPos
    , Level
    , Model
    , Move(..)
    , Msg
    , PlayerOrBox(..)
    , VerticalWallPos
    , WallOrTimePortal(..)
    , findNextMove
    , init
    , update
    , view
    )

import Coord exposing (Coord)
import Effect.Browser.Dom as Dom
import Html
import Html.Attributes
import Html.Events
import Icons
import Id exposing (Id)
import Json.Decode
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import Quantity exposing (Quantity(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import Ui.Input


type PlayerOrBox
    = Player
    | Box
    | LargeBox


type WallOrTimePortal
    = Wall
    | TimePortal Int


type GridPos
    = CellPos Never


type HorizontalWallPos
    = HorizontalWallPos Never


type VerticalWallPos
    = VerticalWallPos Never


type FrameId
    = FrameId Never


type alias Frame =
    NonemptyDict (Coord GridPos) PlayerOrBox


type Move
    = Left
    | Right
    | Up
    | Down
    | NoMove


type alias Model =
    { selectedShape : PlayerOrBox
    , frames : SeqDict (Id FrameId) Frame
    , currentFrame : Id FrameId
    , autoAdvance : Bool
    , level : Level
    , startFrame : Frame
    }


type alias Level =
    { horizontalWalls : SeqDict (Coord HorizontalWallPos) WallOrTimePortal
    , verticalWalls : SeqDict (Coord VerticalWallPos) WallOrTimePortal
    , exit : Coord GridPos
    }


type Msg
    = SelectedShape PlayerOrBox
    | ClickedCell (Coord GridPos) Bool
    | PressedStepBackward
    | PressedStepForward
    | SliderChanged (Id FrameId)
    | ToggledAutoAdvance


gridSize : Int
gridSize =
    8


init : Model
init =
    { selectedShape = Player
    , frames = SeqDict.empty
    , currentFrame = Id.fromInt 0
    , autoAdvance = True
    , level = level1
    , startFrame = NonemptyDict.fromNonemptyList (Nonempty ( Coord.xy 1 1, Player ) [ ( Coord.xy 4 6, Box ) ])
    }


level1 =
    { horizontalWalls =
        SeqDict.fromList
            [ ( Coord.xy 1 2, Wall )
            , ( Coord.xy 3 1, TimePortal 5 )
            , ( Coord.xy 5 4, Wall )
            , ( Coord.xy 0 3, Wall )
            ]
    , verticalWalls = SeqDict.fromList [ ( Coord.xy 3 0, Wall ), ( Coord.xy 3 2, TimePortal 5 ) ] -- SeqSet.fromList [ Coord.xy 2 1, Coord.xy 4 3, Coord.xy 1 5, Coord.xy 3 0 ]
    , exit = Coord.xy 2 4
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SelectedShape shape ->
            { model | selectedShape = shape }

        ClickedCell pos shiftHeld ->
            { model
                | frames =
                    SeqDict.update
                        model.currentFrame
                        (\maybe ->
                            case maybe of
                                Just frame2 ->
                                    case NonemptyDict.get pos frame2 of
                                        Just shape ->
                                            if shape == model.selectedShape then
                                                NonemptyDict.remove pos frame2 |> NonemptyDict.fromSeqDict

                                            else
                                                NonemptyDict.insert pos model.selectedShape frame2 |> Just

                                        Nothing ->
                                            NonemptyDict.insert pos model.selectedShape frame2 |> Just

                                Nothing ->
                                    NonemptyDict.singleton pos model.selectedShape |> Just
                        )
                        model.frames
                , currentFrame =
                    if model.autoAdvance || shiftHeld then
                        Id.increment model.currentFrame

                    else
                        model.currentFrame
            }

        PressedStepBackward ->
            { model | currentFrame = Id.decrement model.currentFrame }

        PressedStepForward ->
            { model | currentFrame = Id.increment model.currentFrame }

        SliderChanged index ->
            { model | currentFrame = index }

        ToggledAutoAdvance ->
            { model | autoAdvance = not model.autoAdvance }


view : Model -> Element Msg
view model =
    Ui.column
        [ Ui.spacing 16
        , Ui.padding 16
        , Ui.width Ui.shrink
        , Ui.centerX
        , Ui.contentCenterY
        ]
        [ Ui.el [ Ui.Font.size 24, Ui.Font.weight 600 ] (Ui.text "Game")
        , palette model.selectedShape
        , autoAdvanceToggle model.autoAdvance
        , timeControls model
        , gridWithWalls model
        ]


cellSize : Int
cellSize =
    48


gridGap : Int
gridGap =
    4


gridStride : Int
gridStride =
    cellSize + gridGap


gridPixelSize : Int
gridPixelSize =
    gridSize * cellSize + (gridSize - 1) * gridGap


wallThickness : WallOrTimePortal -> Int
wallThickness wallType =
    case wallType of
        Wall ->
            4

        TimePortal _ ->
            6


getFrame : Id FrameId -> Model -> Maybe Frame
getFrame frameId model =
    case SeqDict.keys model.frames |> List.Nonempty.fromList of
        Just nonempty ->
            let
                earlierFrame : Id FrameId
                earlierFrame =
                    List.Nonempty.foldl1 Id.minimum nonempty
            in
            if Id.toInt earlierFrame > Id.toInt frameId then
                Just model.startFrame

            else
                SeqDict.get frameId model.frames

        Nothing ->
            Just model.startFrame


gridWithWalls : Model -> Element Msg
gridWithWalls model =
    Ui.el
        [ Ui.width (Ui.px gridPixelSize)
        , Ui.height (Ui.px gridPixelSize)
        , Ui.inFront (wallsLayer model.level)
        , Ui.behindContent (gridBackground model.level)
        ]
        (grid
            { previous = getFrame (Id.decrement model.currentFrame) model
            , current = SeqDict.get model.currentFrame model.frames
            , next = SeqDict.get (Id.increment model.currentFrame) model.frames
            }
        )


wallsLayer : Level -> Element msg
wallsLayer level =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "inset" "0"
        , Html.Attributes.style "pointer-events" "none"
        ]
        ((SeqDict.toList level.horizontalWalls |> List.map horizontalWallView)
            ++ (SeqDict.toList level.verticalWalls |> List.map verticalWallView)
        )
        |> Ui.html


horizontalWallView : ( Coord HorizontalWallPos, WallOrTimePortal ) -> Html.Html msg
horizontalWallView ( coord, wallType ) =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (px (Coord.xRaw coord * gridStride))
        , Html.Attributes.style "top" (px (Coord.yRaw coord * gridStride - wallThickness wallType // 2))
        , Html.Attributes.style "width" (px cellSize)
        , Html.Attributes.style "height" (px (wallThickness wallType))
        , Html.Attributes.style "background-color" (wallTypeColor wallType)
        , Html.Attributes.style "border-radius" "2px"
        ]
        []


wallTypeColor wallType =
    case wallType of
        Wall ->
            "rgb(255,180,60)"

        TimePortal _ ->
            "rgb(255,0,160)"


verticalWallView : ( Coord VerticalWallPos, WallOrTimePortal ) -> Html.Html msg
verticalWallView ( coord, wallType ) =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (px (Coord.xRaw coord * gridStride - wallThickness wallType // 2))
        , Html.Attributes.style "top" (px (Coord.yRaw coord * gridStride))
        , Html.Attributes.style "width" (px (wallThickness wallType))
        , Html.Attributes.style "height" (px cellSize)
        , Html.Attributes.style "background-color" (wallTypeColor wallType)
        , Html.Attributes.style "border-radius" "2px"
        ]
        []


px : Int -> String
px n =
    String.fromInt n ++ "px"


palette : PlayerOrBox -> Element Msg
palette selected =
    Ui.row
        [ Ui.spacing 8, Ui.width Ui.shrink ]
        (List.map (paletteButton selected) [ Player, Box, LargeBox ])


paletteButton : PlayerOrBox -> PlayerOrBox -> Element Msg
paletteButton selected shape =
    let
        isSelected : Bool
        isSelected =
            shape == selected
    in
    Ui.el
        [ Ui.Input.button (SelectedShape shape)
        , Ui.id (Dom.idToString (paletteId shape))
        , Ui.width (Ui.px 56)
        , Ui.height (Ui.px 56)
        , Ui.borderColor
            (if isSelected then
                Ui.rgb 100 200 255

             else
                MyUi.buttonBorder
            )
        , Ui.border
            (if isSelected then
                3

             else
                1
            )
        , Ui.background MyUi.buttonBackground
        , Ui.rounded 4
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        (shapeIcon (Ui.rgb 255 255 255) shape)


autoAdvanceToggle : Bool -> Element Msg
autoAdvanceToggle isOn =
    Ui.row
        [ Ui.Input.button ToggledAutoAdvance
        , Ui.id (Dom.idToString autoAdvanceId)
        , Ui.spacing 8
        , Ui.width Ui.shrink
        , Ui.contentCenterY
        ]
        [ Ui.el
            [ Ui.width (Ui.px 22)
            , Ui.height (Ui.px 22)
            , Ui.background
                (if isOn then
                    Ui.rgb 100 200 255

                 else
                    MyUi.buttonBackground
                )
            , Ui.borderColor MyUi.buttonBorder
            , Ui.border 1
            , Ui.rounded 3
            , Ui.contentCenterX
            , Ui.contentCenterY
            , Ui.Font.size 16
            , Ui.Font.bold
            ]
            (if isOn then
                Ui.text "✓"

             else
                Ui.none
            )
        , Ui.el [ Ui.Font.size 14, Ui.width Ui.shrink ] (Ui.text "Auto-advance on placement (or shift+click)")
        ]


autoAdvanceId : Dom.HtmlId
autoAdvanceId =
    Dom.id "game_auto_advance"


timeControls : Model -> Element Msg
timeControls model =
    let
        label : String
        label =
            "Frame " ++ Id.toString model.currentFrame
    in
    Ui.column [ Ui.spacing 8, Ui.width Ui.fill ]
        [ Ui.row [ Ui.spacing 8, Ui.width Ui.shrink, Ui.contentCenterY, Ui.centerX ]
            [ stepButton stepBackId PressedStepBackward "<"
            , Ui.el [ Ui.Font.size 16, Ui.paddingXY 12 0, Ui.width Ui.shrink ] (Ui.text label)
            , stepButton stepForwardId PressedStepForward ">"
            ]
        , slider model
        ]


stepButton : Dom.HtmlId -> Msg -> String -> Element Msg
stepButton htmlId msg label =
    Ui.el
        [ Ui.Input.button msg
        , Ui.id (Dom.idToString htmlId)
        , Ui.width (Ui.px 48)
        , Ui.height (Ui.px 36)
        , Ui.background MyUi.buttonBackground
        , Ui.borderColor MyUi.buttonBorder
        , Ui.border 1
        , Ui.rounded 4
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.Font.size 18
        , Ui.Font.bold
        ]
        (Ui.text label)


foldFrames : (Id FrameId -> Maybe Frame -> a -> a) -> a -> Model -> a
foldFrames foldFunc startValue model =
    let
        list =
            Nonempty model.currentFrame (SeqDict.keys model.frames)
    in
    foldFramesHelper
        foldFunc
        (List.Nonempty.foldl1 Id.minimum list |> Id.toInt)
        (List.Nonempty.foldl1 Id.maximum list |> Id.toInt)
        model
        startValue


foldFramesHelper : (Id FrameId -> Maybe Frame -> a -> a) -> Int -> Int -> Model -> a -> a
foldFramesHelper foldFunc index endIndex model state =
    if index > endIndex then
        state

    else
        foldFramesHelper
            foldFunc
            (index + 1)
            endIndex
            model
            (foldFunc (Id.fromInt index) (SeqDict.get (Id.fromInt index) model.frames) state)


slider : Model -> Element Msg
slider model =
    foldFrames (\frameId frame list -> sliderSegment model frameId frame :: list) [] model
        |> List.reverse
        |> Ui.row
            [ Ui.spacing 2
            , Ui.width Ui.fill
            , Ui.height (Ui.px 24)
            , Ui.id (Dom.idToString sliderId)
            ]


sliderSegment : Model -> Id FrameId -> Maybe Frame -> Element Msg
sliderSegment model frameId frame =
    let
        isCurrent : Bool
        isCurrent =
            frameId == model.currentFrame

        isEmpty : Bool
        isEmpty =
            frame == Nothing

        hasError : Bool
        hasError =
            frameHasError model frameId
    in
    Ui.el
        [ Ui.Input.button (SliderChanged frameId)
        , Ui.id (Dom.idToString (segmentId frameId))
        , Ui.background
            (if isEmpty then
                Ui.rgb 90 90 100

             else
                Ui.rgb 40 40 50
            )
        , Ui.height Ui.fill
        , Ui.width Ui.fill
        , Ui.rounded 2
        , Ui.border 1
        , Ui.borderColor
            (if isCurrent then
                Ui.rgb 100 200 255

             else
                MyUi.buttonBorder
            )
        , if hasError then
            Ui.inFront
                (Ui.el
                    [ Ui.Font.color (Ui.rgb 180 50 50)
                    , Ui.move { x = -13, y = 0, z = 0 }
                    ]
                    (Icons.warning 24 |> Ui.html)
                )

          else
            Ui.noAttr
        ]
        Ui.none


frameHasError : Model -> Id FrameId -> Bool
frameHasError model frameId =
    case ( getFrame (Id.decrement frameId) model, getFrame frameId model ) of
        ( Just frame, Just next2 ) ->
            findNextMove model.level frame next2 == Err ()

        ( Just _, Nothing ) ->
            True

        ( Nothing, Just _ ) ->
            True

        ( Nothing, Nothing ) ->
            False


grid : { previous : Maybe Frame, current : Maybe Frame, next : Maybe Frame } -> Element Msg
grid frames =
    Ui.column
        [ Ui.spacing 4, Ui.width Ui.shrink, MyUi.noPointerEvents ]
        (List.map
            (\row ->
                Ui.row
                    [ Ui.spacing 4, Ui.width Ui.shrink ]
                    (List.map (\col -> gridCell frames (Coord.xy col row)) (List.range 0 (gridSize - 1)))
            )
            (List.range 0 (gridSize - 1))
        )


gridCell :
    { previous : Maybe Frame, current : Maybe Frame, next : Maybe Frame }
    -> Coord GridPos
    -> Element Msg
gridCell frames pos =
    let
        ghostAttrs : List (Ui.Attribute Msg)
        ghostAttrs =
            [ cellShape pos frames.current |> Maybe.map (\s -> Ui.behindContent (shapeIcon (Ui.rgb 255 255 255) s))
            , cellShape pos frames.previous |> Maybe.map (\s -> Ui.behindContent (shapeIcon ghostPreviousColor s))
            , cellShape pos frames.next |> Maybe.map (\s -> Ui.behindContent (shapeIcon ghostNextColor s))
            ]
                |> List.filterMap identity
    in
    Ui.el
        ([ Ui.id (Dom.idToString (cellId pos))
         , Ui.width (Ui.px 48)
         , Ui.height (Ui.px 48)
         , Ui.border 1
         , Ui.borderColor (Ui.rgba 0 0 0 0)
         , Ui.rounded 2
         , Ui.contentCenterX
         , Ui.contentCenterY
         , Ui.Font.bold
         , Ui.Font.color (Ui.rgba 255 255 255 0.5)
         ]
            ++ ghostAttrs
        )
        Ui.none


gridBackground : Level -> Element Msg
gridBackground level =
    Ui.column
        [ Ui.spacing 4, Ui.width Ui.shrink ]
        (List.map
            (\row ->
                Ui.row
                    [ Ui.spacing 4, Ui.width Ui.shrink ]
                    (List.map (\col -> gridCellBackground level (Coord.xy col row)) (List.range 0 (gridSize - 1)))
            )
            (List.range 0 (gridSize - 1))
        )


gridCellBackground :
    Level
    -> Coord GridPos
    -> Element Msg
gridCellBackground level pos =
    Ui.el
        [ Ui.htmlAttribute
            (Html.Events.on "click"
                (Json.Decode.field "shiftKey" Json.Decode.bool
                    |> Json.Decode.map (ClickedCell pos)
                )
            )
        , Ui.htmlAttribute (Html.Attributes.style "cursor" "pointer")
        , Ui.id (Dom.idToString (cellId pos))
        , Ui.width (Ui.px 48)
        , Ui.height (Ui.px 48)
        , Ui.borderColor
            (if level.exit == pos then
                endColor

             else
                MyUi.buttonBorder
            )
        , Ui.border 1
        , Ui.background
            (if level.exit == pos then
                endColor

             else
                MyUi.background1
            )
        , Ui.rounded 2
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.Font.bold
        , Ui.Font.color (Ui.rgba 255 255 255 0.5)
        ]
        (if level.exit == pos then
            Ui.text "E"

         else
            Ui.none
        )


endColor : Ui.Color
endColor =
    Ui.rgba 220 140 60 0.35


cellShape : Coord GridPos -> Maybe Frame -> Maybe PlayerOrBox
cellShape pos frame =
    case frame of
        Just frame2 ->
            NonemptyDict.get pos frame2

        Nothing ->
            Nothing


ghostPreviousColor : Ui.Color
ghostPreviousColor =
    Ui.rgb 120 50 50


ghostNextColor : Ui.Color
ghostNextColor =
    Ui.rgb 50 90 120


paletteId : PlayerOrBox -> Dom.HtmlId
paletteId shape =
    Dom.id ("game_palette_" ++ shapeToString shape)


cellId : Coord GridPos -> Dom.HtmlId
cellId coord =
    Dom.id ("game_cell_" ++ String.fromInt (Coord.xRaw coord) ++ "_" ++ String.fromInt (Coord.yRaw coord))


stepBackId : Dom.HtmlId
stepBackId =
    Dom.id "game_step_back"


stepForwardId : Dom.HtmlId
stepForwardId =
    Dom.id "game_step_forward"


sliderId : Dom.HtmlId
sliderId =
    Dom.id "game_slider"


segmentId : Id FrameId -> Dom.HtmlId
segmentId index =
    Dom.id ("game_slider_segment_" ++ Id.toString index)


shapeToString : PlayerOrBox -> String
shapeToString shape =
    case shape of
        Player ->
            "player"

        Box ->
            "block"

        LargeBox ->
            "double-block"


shapeIcon : Ui.Color -> PlayerOrBox -> Element msg
shapeIcon color shape =
    case shape of
        Player ->
            Ui.el
                [ Ui.Font.size 28
                , Ui.Font.center
                , MyUi.htmlStyle "user-select" "none"
                , MyUi.htmlStyle "-webkit-user-select" "none"
                , Ui.centerY
                , Ui.Font.color color
                , MyUi.noPointerEvents
                ]
                (Ui.text "☺")

        Box ->
            Ui.el
                [ Ui.Font.size 28
                , Ui.Font.center
                , MyUi.htmlStyle "user-select" "none"
                , MyUi.htmlStyle "-webkit-user-select" "none"
                , Ui.centerY
                , Ui.Font.color color
                , MyUi.noPointerEvents
                ]
                (Ui.text "■")

        LargeBox ->
            Ui.el
                [ Ui.width (Ui.px (cellSize * 2))
                , Ui.height (Ui.px (cellSize * 2))
                , Ui.background color
                , MyUi.noPointerEvents
                ]
                Ui.none


offset : Move -> Coord GridPos -> Coord GridPos
offset move ( Quantity x, Quantity y ) =
    case move of
        Left ->
            Coord.xy (x - 1) y

        Right ->
            Coord.xy (x + 1) y

        Up ->
            Coord.xy x (y - 1)

        Down ->
            Coord.xy x (y + 1)

        NoMove ->
            Coord.xy x y


allMoves : List Move
allMoves =
    [ NoMove, Left, Right, Up, Down ]


moveIntersectsWall : Level -> Coord GridPos -> Move -> Bool
moveIntersectsWall level pos move =
    case move of
        NoMove ->
            False

        Left ->
            SeqDict.get (Coord.changeUnit pos) level.verticalWalls == Just Wall

        Right ->
            SeqDict.get (Coord.changeUnit (Coord.xy (Coord.xRaw pos + 1) (Coord.yRaw pos))) level.verticalWalls == Just Wall

        Up ->
            SeqDict.get (Coord.changeUnit pos) level.horizontalWalls == Just Wall

        Down ->
            SeqDict.get (Coord.changeUnit (Coord.xy (Coord.xRaw pos) (Coord.yRaw pos + 1))) level.horizontalWalls == Just Wall


{-| Apply a set of player moves to the starting frame and return the resulting grid.
A player's move is "push" if the destination contains a block; the block then
moves one further cell in the same direction.

Returns Nothing if the moves are physically inconsistent (e.g. two players or
two blocks land on the same cell, a push target is occupied, etc).

The key rule: a player CAN move into a cell currently occupied by another
player, provided that other player is also moving away this turn.

-}
applyMoves : Level -> Frame -> SeqDict (Coord GridPos) Move -> Maybe Frame
applyMoves level frame moves =
    let
        players : List ( Coord GridPos, Move )
        players =
            SeqDict.toList moves

        -- Where each player ends up.
        playerDest : Coord GridPos -> Move -> Coord GridPos
        playerDest pos move =
            offset move pos

        -- For each player that pushes, figure out the block's source and dest.
        -- A push happens when the player's destination cell contains a Block in `frame`.
        pushes : List { from : Coord GridPos, to : Coord GridPos, dir : Move }
        pushes =
            players
                |> List.filterMap
                    (\( pos, move ) ->
                        if move == NoMove then
                            Nothing

                        else
                            let
                                dest =
                                    playerDest pos move
                            in
                            case NonemptyDict.get dest frame of
                                Just Box ->
                                    Just
                                        { from = dest
                                        , to = offset move dest
                                        , dir = move
                                        }

                                _ ->
                                    Nothing
                    )

        pushedBlockSources : List (Coord GridPos)
        pushedBlockSources =
            List.map .from pushes

        -- Blocks that didn't get pushed stay where they are.
        stationaryBlocks : List (Coord GridPos)
        stationaryBlocks =
            NonemptyDict.toList frame
                |> List.filterMap
                    (\( pos, kind ) ->
                        if kind == Box && not (List.member pos pushedBlockSources) then
                            Just pos

                        else
                            Nothing
                    )

        -- Final block positions.
        finalBlockPositions : List (Coord GridPos)
        finalBlockPositions =
            stationaryBlocks ++ List.map .to pushes

        -- Final player positions.
        finalPlayerPositions : List (Coord GridPos)
        finalPlayerPositions =
            List.map (\( pos, move ) -> playerDest pos move) players

        -- Validation: each push target must be a cell that ends up empty
        -- (no stationary block there, no other block pushed there).
        -- Also two pushes can't target the same cell.
        noDuplicates : List (Coord GridPos) -> Bool
        noDuplicates xs =
            List.length xs == SeqSet.size (SeqSet.fromList xs)

        -- A pushed block's destination must not coincide with any final player
        -- position (you can't push a block into a cell a player is moving to)
        -- and must not collide with another block.
        pushTargetsValid : Bool
        pushTargetsValid =
            List.all
                (\push ->
                    -- Target must be in-bounds-ish (we don't track bounds here;
                    -- callers can constrain via the grid). Target must not be
                    -- occupied by a stationary block.
                    not (List.member push.to stationaryBlocks)
                        -- And not occupied by any final player position.
                        && not (List.member push.to finalPlayerPositions)
                )
                pushes

        -- Two players can't end up on the same cell.
        playersDistinct : Bool
        playersDistinct =
            noDuplicates finalPlayerPositions

        -- Two blocks can't end up on the same cell.
        blocksDistinct : Bool
        blocksDistinct =
            noDuplicates finalBlockPositions

        -- A block can't end up where a player ends up.
        noPlayerBlockOverlap : Bool
        noPlayerBlockOverlap =
            List.all (\bp -> not (List.member bp finalPlayerPositions)) finalBlockPositions

        -- Movement legality: when a player moves into a cell, that cell in
        -- `frame` must be either empty, a Block they push (handled above), or
        -- a Player that is itself moving away this turn.
        movementLegal : Bool
        movementLegal =
            List.all
                (\( pos, move ) ->
                    if move == NoMove then
                        True

                    else
                        let
                            dest =
                                playerDest pos move
                        in
                        case NonemptyDict.get dest frame of
                            Nothing ->
                                True

                            Just Box ->
                                -- Push: legality of the push is checked above.
                                True

                            Just LargeBox ->
                                False

                            Just Player ->
                                -- Allowed only if the other player is moving away.
                                case SeqDict.get dest moves of
                                    Just otherMove ->
                                        otherMove /= NoMove

                                    Nothing ->
                                        False
                )
                players

        noWallIntersections : Bool
        noWallIntersections =
            List.all
                (\( pos, move ) -> moveIntersectsWall level pos move |> not)
                players
    in
    if
        noWallIntersections
            && movementLegal
            && pushTargetsValid
            && playersDistinct
            && blocksDistinct
            && noPlayerBlockOverlap
    then
        let
            playerDict =
                finalPlayerPositions
                    |> List.map (\p -> ( p, Player ))
                    |> SeqDict.fromList

            blockDict =
                finalBlockPositions
                    |> List.map (\p -> ( p, Box ))
                    |> SeqDict.fromList
        in
        SeqDict.union playerDict blockDict |> NonemptyDict.fromSeqDict

    else
        Nothing


{-| Backtracking search: assign a Move to each player, prune when partial
assignment already produces an inconsistency, and check the full result
against `nextFrame`.
-}
findNextMove : Level -> Frame -> Frame -> Result () (NonemptyDict (Coord GridPos) Move)
findNextMove level frame nextFrame =
    let
        playerPositions : List (Coord GridPos)
        playerPositions =
            NonemptyDict.toList frame
                |> List.filterMap
                    (\( pos, kind ) ->
                        if kind == Player then
                            Just pos

                        else
                            Nothing
                    )

        go : List (Coord GridPos) -> SeqDict (Coord GridPos) Move -> Maybe (NonemptyDict (Coord GridPos) Move)
        go remaining assigned =
            case remaining of
                [] ->
                    case applyMoves level frame assigned of
                        Just result ->
                            if NonemptyDict.unorderedEquals result nextFrame then
                                NonemptyDict.fromSeqDict assigned

                            else
                                Nothing

                        Nothing ->
                            Nothing

                pos :: rest ->
                    tryMoves pos rest assigned allMoves

        tryMoves : Coord GridPos -> List (Coord GridPos) -> SeqDict (Coord GridPos) Move -> List Move -> Maybe (NonemptyDict (Coord GridPos) Move)
        tryMoves pos rest assigned moves =
            case moves of
                [] ->
                    Nothing

                m :: ms ->
                    case go rest (SeqDict.insert pos m assigned) of
                        Just result ->
                            Just result

                        Nothing ->
                            tryMoves pos rest assigned ms
    in
    case go playerPositions SeqDict.empty of
        Just assignment ->
            Ok assignment

        Nothing ->
            Err ()
