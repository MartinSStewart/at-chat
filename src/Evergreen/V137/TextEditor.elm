module Evergreen.V137.TextEditor exposing (..)

import Array
import Evergreen.V137.Id
import Evergreen.V137.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V137.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Int
    , history : Array.Array ( Evergreen.V137.Id.Id Evergreen.V137.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V137.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
    | Server_Redo (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
    | Server_MovedCursor (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V137.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
