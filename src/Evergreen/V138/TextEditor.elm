module Evergreen.V138.TextEditor exposing (..)

import Array
import Evergreen.V138.Id
import Evergreen.V138.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V138.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Int
    , history : Array.Array ( Evergreen.V138.Id.Id Evergreen.V138.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V138.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
    | Server_Redo (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
    | Server_MovedCursor (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V138.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
