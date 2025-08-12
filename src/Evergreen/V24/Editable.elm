module Evergreen.V24.Editable exposing (..)


type Editing
    = NotEditing
    | Editing String


type alias Model =
    { editing : Editing
    , pressedSubmit : Bool
    }


type Msg value
    = Edit Model
    | PressedAcceptEdit value
