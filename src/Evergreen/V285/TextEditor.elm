module Evergreen.V285.TextEditor exposing (..)

import Array
import Evergreen.V285.Id
import Evergreen.V285.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V285.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Int
    , history : Array.Array ( Evergreen.V285.Id.Id Evergreen.V285.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) Evergreen.V285.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)
    | Server_Redo (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
