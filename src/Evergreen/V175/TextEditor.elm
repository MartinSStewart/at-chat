module Evergreen.V175.TextEditor exposing (..)

import Array
import Evergreen.V175.Id
import Evergreen.V175.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V175.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Int
    , history : Array.Array ( Evergreen.V175.Id.Id Evergreen.V175.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V175.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
    | Server_Redo (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
    | Server_MovedCursor (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V175.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
