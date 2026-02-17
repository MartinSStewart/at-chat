module Evergreen.V115.TextEditor exposing (..)

import Array
import Evergreen.V115.Id
import Evergreen.V115.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V115.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Int
    , history : Array.Array ( Evergreen.V115.Id.Id Evergreen.V115.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V115.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    | Server_Redo (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    | Server_MovedCursor (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V115.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
