module Evergreen.V304.TextEditor exposing (..)

import Array
import Evergreen.V304.Id
import Evergreen.V304.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V304.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Int
    , history : Array.Array ( Evergreen.V304.Id.Id Evergreen.V304.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) Evergreen.V304.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)
    | Server_Redo (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId)


type alias Model =
    {}
