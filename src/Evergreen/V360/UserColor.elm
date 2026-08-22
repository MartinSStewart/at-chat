module Evergreen.V360.UserColor exposing (..)


type UserColor
    = UserColor Int


type alias Selection =
    { selected : UserColor
    , lastValid : UserColor
    }
