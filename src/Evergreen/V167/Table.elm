module Evergreen.V167.Table exposing (..)


type alias Model =
    { columnToSortBy : Int
    , ascendingOrder : Bool
    , showAll : Bool
    }


type Msg
    = PressedSortBy Int
    | PressedShowAll
