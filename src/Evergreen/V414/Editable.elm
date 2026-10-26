module Evergreen.V414.Editable exposing (..)


type Editing
    = NotEditing
    | Editing String


type alias Model =
    { editing : Editing
    , pressedSubmit : Bool
    , showSecret : Bool
    }


type Msg value
    = Edit Model
    | PressedAcceptEdit value
