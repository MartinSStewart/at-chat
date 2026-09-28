module Evergreen.V389.Table exposing (..)


type Msg
    = PressedSortBy Int
    | PressedShowAll


type alias Model =
    { columnToSortBy : Int
    , ascendingOrder : Bool
    , showAll : Bool
    }
