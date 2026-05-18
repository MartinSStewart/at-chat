module Evergreen.V236.TextEditor exposing (..)

import Array
import Evergreen.V236.Id
import Evergreen.V236.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V236.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Int
    , history : Array.Array ( Evergreen.V236.Id.Id Evergreen.V236.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
    | Server_Redo (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
