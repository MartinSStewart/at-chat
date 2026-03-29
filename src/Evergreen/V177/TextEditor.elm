module Evergreen.V177.TextEditor exposing (..)

import Array
import Evergreen.V177.Id
import Evergreen.V177.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V177.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Int
    , history : Array.Array ( Evergreen.V177.Id.Id Evergreen.V177.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V177.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
    | Server_Redo (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
    | Server_MovedCursor (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V177.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
