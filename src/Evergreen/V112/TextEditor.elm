module Evergreen.V112.TextEditor exposing (..)

import Array
import Evergreen.V112.Id
import Evergreen.V112.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V112.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Int
    , history : Array.Array ( Evergreen.V112.Id.Id Evergreen.V112.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V112.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
    | Server_Redo (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
    | Server_MovedCursor (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V112.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
