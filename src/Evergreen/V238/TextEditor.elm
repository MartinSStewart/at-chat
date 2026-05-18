module Evergreen.V238.TextEditor exposing (..)

import Array
import Evergreen.V238.Id
import Evergreen.V238.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V238.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Int
    , history : Array.Array ( Evergreen.V238.Id.Id Evergreen.V238.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) Evergreen.V238.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)
    | Server_Redo (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
