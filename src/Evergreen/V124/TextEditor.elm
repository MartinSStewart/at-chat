module Evergreen.V124.TextEditor exposing (..)

import Array
import Evergreen.V124.Id
import Evergreen.V124.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V124.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Int
    , history : Array.Array ( Evergreen.V124.Id.Id Evergreen.V124.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V124.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    | Server_Redo (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    | Server_MovedCursor (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V124.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
