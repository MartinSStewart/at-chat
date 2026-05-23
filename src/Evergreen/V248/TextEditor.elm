module Evergreen.V248.TextEditor exposing (..)

import Array
import Evergreen.V248.Id
import Evergreen.V248.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V248.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Int
    , history : Array.Array ( Evergreen.V248.Id.Id Evergreen.V248.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) Evergreen.V248.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)
    | Server_Redo (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
