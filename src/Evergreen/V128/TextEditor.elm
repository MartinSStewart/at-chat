module Evergreen.V128.TextEditor exposing (..)

import Array
import Evergreen.V128.Id
import Evergreen.V128.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V128.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Int
    , history : Array.Array ( Evergreen.V128.Id.Id Evergreen.V128.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V128.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
    | Server_Redo (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)
    | Server_MovedCursor (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) Evergreen.V128.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V128.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
