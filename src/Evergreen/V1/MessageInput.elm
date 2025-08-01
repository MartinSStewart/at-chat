module Evergreen.V1.MessageInput exposing (..)


type MentionUserTarget
    = NewMessage
    | EditMessage


type alias MentionUserDropdown =
    { charIndex : Int
    , dropdownIndex : Int
    , inputElement :
        { x : Float
        , y : Float
        , width : Float
        , height : Float
        }
    , target : MentionUserTarget
    }
