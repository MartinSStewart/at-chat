module WordSpellingGame exposing (Action, ActionWithTime, GameState, Player, ValidatedSetup, foldActions)

{-| Were calling it this to avoid the Scrabble trademark
-}

import Array exposing (Array)
import Effect.Time as Time
import Go exposing (TimeControl)
import Id exposing (Id, UserId)
import SeqDict exposing (SeqDict)


type alias ValidatedSetup =
    { timeControls : TimeControl
    }


type Action
    = PlaceWord ( Int, Int ) Direction Letter
    | ReplaceTray


type alias ActionWithTime =
    { time : Time.Posix, change : Action }


type alias GameState =
    { board : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
    , players : List Player
    }


type alias Player =
    { userId : Id UserId
    , score : Int
    }


gridSize : number
gridSize =
    15


type Direction
    = Left
    | Right
    | Up
    | Down


type LetterOrWildcard
    = Letter Letter
    | Wildcard


initGameState : ValidatedSetup -> GameState
initGameState setup =
    { board = SeqDict.empty
    , players = []
    }


foldActions : ValidatedSetup -> Array ActionWithTime -> GameState
foldActions setup actions =
    Array.foldl (updateAction setup) (initGameState setup) actions


updateAction : ValidatedSetup -> ActionWithTime -> GameState -> GameState
updateAction setup action model =
    Debug.todo ""


allLetters : List Letter
allLetters =
    [ A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z ]


letterScore : Letter -> Int
letterScore letter =
    case letter of
        A ->
            1

        B ->
            3

        C ->
            3

        D ->
            2

        E ->
            1

        F ->
            4

        G ->
            2

        H ->
            4

        I ->
            1

        J ->
            8

        K ->
            5

        L ->
            1

        M ->
            3

        N ->
            1

        O ->
            1

        P ->
            3

        Q ->
            10

        R ->
            1

        S ->
            1

        T ->
            1

        U ->
            1

        V ->
            4

        W ->
            4

        X ->
            8

        Y ->
            4

        Z ->
            10


type Letter
    = A
    | B
    | C
    | D
    | E
    | F
    | G
    | H
    | I
    | J
    | K
    | L
    | M
    | N
    | O
    | P
    | Q
    | R
    | S
    | T
    | U
    | V
    | W
    | X
    | Y
    | Z
