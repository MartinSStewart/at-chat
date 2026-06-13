module Evergreen.V288.TextEditor exposing (..)

import Array
import Evergreen.V288.Id
import Evergreen.V288.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V288.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Int
    , history : Array.Array ( Evergreen.V288.Id.Id Evergreen.V288.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) Evergreen.V288.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)
    | Server_Redo (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
