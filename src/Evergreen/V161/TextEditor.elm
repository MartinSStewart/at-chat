module Evergreen.V161.TextEditor exposing (..)

import Array
import Evergreen.V161.Id
import Evergreen.V161.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V161.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Int
    , history : Array.Array ( Evergreen.V161.Id.Id Evergreen.V161.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V161.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
    | Server_Redo (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)
    | Server_MovedCursor (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) Evergreen.V161.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V161.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
