module Evergreen.V395.UserColor exposing (..)


type UserColor
    = UserColor Int


type alias Selection =
    { selected :
        { hue : Int
        , saturation : Int
        , lightness : Int
        }
    , lastValid : UserColor
    }
