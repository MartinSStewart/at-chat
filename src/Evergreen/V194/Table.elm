module Evergreen.V194.Table exposing (..)


type alias Model =
    { columnToSortBy : Int
    , ascendingOrder : Bool
    , showAll : Bool
    }


type Msg
    = PressedSortBy Int
    | PressedShowAll
