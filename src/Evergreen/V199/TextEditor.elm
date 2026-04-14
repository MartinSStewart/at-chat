module Evergreen.V199.TextEditor exposing (..)

import Array
import Evergreen.V199.Id
import Evergreen.V199.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V199.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Int
    , history : Array.Array ( Evergreen.V199.Id.Id Evergreen.V199.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
    | Server_Redo (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
