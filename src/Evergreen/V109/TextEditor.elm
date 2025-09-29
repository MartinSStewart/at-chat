module Evergreen.V109.TextEditor exposing (..)

import Array
import Evergreen.V109.Id
import Evergreen.V109.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V109.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Int
    , history : Array.Array ( Evergreen.V109.Id.Id Evergreen.V109.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V109.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    | Server_Redo (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    | Server_MovedCursor (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V109.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
