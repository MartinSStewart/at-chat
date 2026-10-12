module Evergreen.V405.RecoveryLogin exposing (..)


type Msg
    = TypedPassword String
    | PressedSubmit


type SubmitStatus
    = NotSubmitted Bool
    | Submitting
    | IncorrectPassword


type Model
    = Model
        { password : String
        , submitStatus : SubmitStatus
        }
