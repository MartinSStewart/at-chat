module Evergreen.V120.TextEditor exposing (..)

import Array
import Evergreen.V120.Id
import Evergreen.V120.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V120.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Int
    , history : Array.Array ( Evergreen.V120.Id.Id Evergreen.V120.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V120.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
    | Server_Redo (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)
    | Server_MovedCursor (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) Evergreen.V120.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V120.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
