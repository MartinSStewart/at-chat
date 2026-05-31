module Evergreen.V263.TextEditor exposing (..)

import Array
import Evergreen.V263.Id
import Evergreen.V263.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V263.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Int
    , history : Array.Array ( Evergreen.V263.Id.Id Evergreen.V263.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) Evergreen.V263.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)
    | Server_Redo (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
