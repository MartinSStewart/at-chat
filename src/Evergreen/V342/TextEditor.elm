module Evergreen.V342.TextEditor exposing (..)

import Array
import Evergreen.V342.Id
import Evergreen.V342.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V342.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Int
    , history : Array.Array ( Evergreen.V342.Id.Id Evergreen.V342.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) Evergreen.V342.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
    | Server_Redo (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)


type alias Model =
    {}
