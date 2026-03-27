module Evergreen.V173.TextEditor exposing (..)

import Array
import Evergreen.V173.Id
import Evergreen.V173.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V173.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Int
    , history : Array.Array ( Evergreen.V173.Id.Id Evergreen.V173.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V173.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
    | Server_Redo (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
    | Server_MovedCursor (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V173.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
