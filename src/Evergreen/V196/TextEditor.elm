module Evergreen.V196.TextEditor exposing (..)

import Array
import Evergreen.V196.Id
import Evergreen.V196.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V196.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Int
    , history : Array.Array ( Evergreen.V196.Id.Id Evergreen.V196.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) Evergreen.V196.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)
    | Server_Redo (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
