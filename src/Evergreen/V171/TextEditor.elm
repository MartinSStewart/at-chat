module Evergreen.V171.TextEditor exposing (..)

import Array
import Evergreen.V171.Id
import Evergreen.V171.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V171.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Int
    , history : Array.Array ( Evergreen.V171.Id.Id Evergreen.V171.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Evergreen.V171.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V171.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
    | Server_Redo (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)
    | Server_MovedCursor (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) Evergreen.V171.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V171.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
