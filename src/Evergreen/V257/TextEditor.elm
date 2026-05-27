module Evergreen.V257.TextEditor exposing (..)

import Array
import Evergreen.V257.Id
import Evergreen.V257.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V257.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Int
    , history : Array.Array ( Evergreen.V257.Id.Id Evergreen.V257.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
    | Server_Redo (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
