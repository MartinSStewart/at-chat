module Evergreen.V77.Table exposing (..)


type alias Model =
    { columnToSortBy : Int
    , ascendingOrder : Bool
    , showAll : Bool
    }


type Msg
    = PressedSortBy Int
    | PressedShowAll
