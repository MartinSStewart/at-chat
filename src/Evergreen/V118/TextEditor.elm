module Evergreen.V118.TextEditor exposing (..)

import Array
import Evergreen.V118.Id
import Evergreen.V118.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V118.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Int
    , history : Array.Array ( Evergreen.V118.Id.Id Evergreen.V118.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V118.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
    | Server_Redo (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)
    | Server_MovedCursor (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) Evergreen.V118.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V118.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
