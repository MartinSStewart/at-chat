module Evergreen.V163.TextEditor exposing (..)

import Array
import Evergreen.V163.Id
import Evergreen.V163.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V163.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Int
    , history : Array.Array ( Evergreen.V163.Id.Id Evergreen.V163.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Evergreen.V163.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V163.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
    | Server_Redo (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)
    | Server_MovedCursor (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) Evergreen.V163.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V163.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
