module Chess exposing
    ( ChessGame
    , ChessMsg(..)
    , Color(..)
    , GameState(..)
    , Piece
    , PieceType(..)
    , Position
    , Square(..)
    , initGame
    , isPressMsg
    , updateGame
    , viewChessBoard
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type Color
    = White
    | Black


type PieceType
    = King
    | Queen
    | Rook
    | Bishop
    | Knight
    | Pawn


type alias Piece =
    { pieceType : PieceType
    , color : Color
    }


type alias Position =
    { row : Int
    , col : Int
    }


type Square
    = Empty
    | Occupied Piece


type alias Board =
    List (List Square)


type GameState
    = Playing Color
    | GameOver (Maybe Color)


type alias ChessGame =
    { board : Board
    , gameState : GameState
    , selectedSquare : Maybe Position
    , lastMove : Maybe ( Position, Position )
    }


type ChessMsg
    = SquareClicked Position
    | ResetGame


isPressMsg : ChessMsg -> Bool
isPressMsg msg =
    case msg of
        SquareClicked _ ->
            True

        ResetGame ->
            True


initGame : ChessGame
initGame =
    { board = initialBoard
    , gameState = Playing White
    , selectedSquare = Nothing
    , lastMove = Nothing
    }


initialBoard : Board
initialBoard =
    let
        backRank color =
            [ Occupied { pieceType = Rook, color = color }
            , Occupied { pieceType = Knight, color = color }
            , Occupied { pieceType = Bishop, color = color }
            , Occupied { pieceType = Queen, color = color }
            , Occupied { pieceType = King, color = color }
            , Occupied { pieceType = Bishop, color = color }
            , Occupied { pieceType = Knight, color = color }
            , Occupied { pieceType = Rook, color = color }
            ]

        pawnRank color =
            List.repeat 8 (Occupied { pieceType = Pawn, color = color })

        emptyRow =
            List.repeat 8 Empty
    in
    [ backRank Black
    , pawnRank Black
    , emptyRow
    , emptyRow
    , emptyRow
    , emptyRow
    , pawnRank White
    , backRank White
    ]


getSquareAt : Position -> Board -> Maybe Square
getSquareAt { row, col } board =
    board
        |> List.drop row
        |> List.head
        |> Maybe.andThen (List.drop col >> List.head)


setSquareAt : Position -> Square -> Board -> Board
setSquareAt { row, col } square board =
    board
        |> List.indexedMap
            (\r rowList ->
                if r == row then
                    rowList
                        |> List.indexedMap
                            (\c sq ->
                                if c == col then
                                    square

                                else
                                    sq
                            )

                else
                    rowList
            )


isEnPassantMove : Position -> Position -> ChessGame -> Bool
isEnPassantMove from to game =
    case getSquareAt from game.board of
        Just (Occupied piece) ->
            if piece.pieceType == Pawn then
                case game.lastMove of
                    Just ( lastFrom, lastTo ) ->
                        case getSquareAt lastTo game.board of
                            Just (Occupied lastPiece) ->
                                lastPiece.pieceType
                                    == Pawn
                                    && lastPiece.color
                                    /= piece.color
                                    && abs (lastFrom.row - lastTo.row)
                                    == 2
                                    && lastTo.row
                                    == from.row
                                    && lastTo.col
                                    == to.col
                                    && to.row
                                    == (if piece.color == White then
                                            from.row - 1

                                        else
                                            from.row + 1
                                       )
                                    && abs (from.col - to.col)
                                    == 1

                            _ ->
                                False

                    _ ->
                        False

            else
                False

        _ ->
            False


isValidMove : Position -> Position -> ChessGame -> Bool
isValidMove from to game =
    if isEnPassantMove from to game then
        True

    else
        case ( getSquareAt from game.board, getSquareAt to game.board ) of
            ( Just (Occupied piece), Just targetSquare ) ->
                case targetSquare of
                    Empty ->
                        True

                    Occupied targetPiece ->
                        piece.color /= targetPiece.color

            _ ->
                False


makeMove : Position -> Position -> Board -> Board
makeMove from to board =
    case getSquareAt from board of
        Just piece ->
            board
                |> setSquareAt from Empty
                |> setSquareAt to piece

        Nothing ->
            board


makeMoveWithEnPassant : Position -> Position -> ChessGame -> Board
makeMoveWithEnPassant from to game =
    if isEnPassantMove from to game then
        case game.lastMove of
            Just ( _, lastTo ) ->
                game.board
                    |> setSquareAt from Empty
                    |> setSquareAt to (getSquareAt from game.board |> Maybe.withDefault Empty)
                    |> setSquareAt lastTo Empty

            Nothing ->
                makeMove from to game.board

    else
        makeMove from to game.board


updateGame : ChessMsg -> ChessGame -> ChessGame
updateGame msg game =
    case msg of
        SquareClicked position ->
            case game.selectedSquare of
                Nothing ->
                    case getSquareAt position game.board of
                        Just (Occupied piece) ->
                            case game.gameState of
                                Playing currentPlayer ->
                                    if piece.color == currentPlayer then
                                        { game | selectedSquare = Just position }

                                    else
                                        game

                                _ ->
                                    game

                        _ ->
                            game

                Just selectedPos ->
                    if selectedPos == position then
                        { game | selectedSquare = Nothing }

                    else if isValidMove selectedPos position game then
                        let
                            newBoard =
                                makeMoveWithEnPassant selectedPos position game

                            nextPlayer =
                                case game.gameState of
                                    Playing White ->
                                        Playing Black

                                    Playing Black ->
                                        Playing White

                                    GameOver _ ->
                                        game.gameState
                        in
                        { game
                            | board = newBoard
                            , selectedSquare = Nothing
                            , gameState = nextPlayer
                            , lastMove = Just ( selectedPos, position )
                        }

                    else
                        { game | selectedSquare = Nothing }

        ResetGame ->
            initGame


pieceToSymbol : Piece -> String
pieceToSymbol piece =
    case ( piece.color, piece.pieceType ) of
        ( White, King ) ->
            "♔"

        ( White, Queen ) ->
            "♕"

        ( White, Rook ) ->
            "♖"

        ( White, Bishop ) ->
            "♗"

        ( White, Knight ) ->
            "♘"

        ( White, Pawn ) ->
            "♙"

        ( Black, King ) ->
            "♚"

        ( Black, Queen ) ->
            "♛"

        ( Black, Rook ) ->
            "♜"

        ( Black, Bishop ) ->
            "♝"

        ( Black, Knight ) ->
            "♞"

        ( Black, Pawn ) ->
            "♟"


squareColor : Int -> Int -> String
squareColor row col =
    if modBy 2 (row + col) == 0 then
        "#f0d9b5"

    else
        "#b58863"


isSelected : Position -> Maybe Position -> Bool
isSelected pos selectedPos =
    case selectedPos of
        Just selected ->
            pos == selected

        Nothing ->
            False


viewSquare : ChessGame -> Int -> Int -> Square -> Html ChessMsg
viewSquare game row col square =
    let
        position =
            { row = row, col = col }

        backgroundColor =
            if isSelected position game.selectedSquare then
                "#ffff99"

            else
                squareColor row col

        content =
            case square of
                Empty ->
                    ""

                Occupied piece ->
                    pieceToSymbol piece
    in
    div
        [ style "width" "60px"
        , style "height" "60px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "background-color" backgroundColor
        , style "border" "1px solid #999"
        , style "font-size" "40px"
        , style "cursor" "pointer"
        , style "user-select" "none"
        , onClick (SquareClicked position)
        ]
        [ text content ]


viewRow : ChessGame -> Int -> List Square -> Html ChessMsg
viewRow game rowIndex squares =
    div
        [ style "display" "flex" ]
        (List.indexedMap (viewSquare game rowIndex) squares)


viewChessBoard : ChessGame -> Html ChessMsg
viewChessBoard game =
    div
        [ style "font-family" "Arial, sans-serif"
        , style "text-align" "center"
        , style "padding" "20px"
        ]
        [ h1 [] [ text "Chess Game" ]
        , div
            [ style "margin" "20px 0" ]
            [ case game.gameState of
                Playing White ->
                    text "White to move"

                Playing Black ->
                    text "Black to move"

                GameOver (Just White) ->
                    text "White wins!"

                GameOver (Just Black) ->
                    text "Black wins!"

                GameOver Nothing ->
                    text "Draw!"
            ]
        , div
            [ style "display" "inline-block"
            , style "border" "2px solid #333"
            ]
            (List.indexedMap (viewRow game) game.board)
        , div
            [ style "margin-top" "20px" ]
            [ button
                [ onClick ResetGame
                , style "padding" "10px 20px"
                , style "font-size" "16px"
                , style "cursor" "pointer"
                ]
                [ text "Reset Game" ]
            ]
        ]
