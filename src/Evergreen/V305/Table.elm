module Evergreen.V305.Table exposing (..)


type Msg
    = PressedSortBy Int
    | PressedShowAll


type alias Model =
    { columnToSortBy : Int
    , ascendingOrder : Bool
    , showAll : Bool
    }
