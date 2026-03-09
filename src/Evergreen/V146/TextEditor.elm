module Evergreen.V146.TextEditor exposing (..)

import Array
import Evergreen.V146.Id
import Evergreen.V146.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V146.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Int
    , history : Array.Array ( Evergreen.V146.Id.Id Evergreen.V146.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V146.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
    | Server_Redo (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)
    | Server_MovedCursor (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) Evergreen.V146.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V146.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
