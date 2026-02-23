module Evergreen.V119.TextEditor exposing (..)

import Array
import Evergreen.V119.Id
import Evergreen.V119.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V119.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Int
    , history : Array.Array ( Evergreen.V119.Id.Id Evergreen.V119.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V119.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
    | Server_Redo (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)
    | Server_MovedCursor (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) Evergreen.V119.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V119.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
