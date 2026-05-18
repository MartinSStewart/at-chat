module Evergreen.V238.Table exposing (..)


type alias Model =
    { columnToSortBy : Int
    , ascendingOrder : Bool
    , showAll : Bool
    }


type Msg
    = PressedSortBy Int
    | PressedShowAll
