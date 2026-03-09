module Evergreen.V148.TextEditor exposing (..)

import Array
import Evergreen.V148.Id
import Evergreen.V148.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V148.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Int
    , history : Array.Array ( Evergreen.V148.Id.Id Evergreen.V148.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V148.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
    | Server_Redo (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)
    | Server_MovedCursor (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) Evergreen.V148.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V148.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
