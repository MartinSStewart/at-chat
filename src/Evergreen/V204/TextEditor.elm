module Evergreen.V204.TextEditor exposing (..)

import Array
import Evergreen.V204.Id
import Evergreen.V204.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V204.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Int
    , history : Array.Array ( Evergreen.V204.Id.Id Evergreen.V204.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
    | Server_Redo (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
