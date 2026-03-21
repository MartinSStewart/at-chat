module Evergreen.V162.TextEditor exposing (..)

import Array
import Evergreen.V162.Id
import Evergreen.V162.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V162.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Int
    , history : Array.Array ( Evergreen.V162.Id.Id Evergreen.V162.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Evergreen.V162.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V162.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
    | Server_Redo (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)
    | Server_MovedCursor (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) Evergreen.V162.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V162.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
