module Evergreen.V176.TextEditor exposing (..)

import Array
import Evergreen.V176.Id
import Evergreen.V176.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V176.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Int
    , history : Array.Array ( Evergreen.V176.Id.Id Evergreen.V176.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V176.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
    | Server_Redo (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
    | Server_MovedCursor (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V176.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
