module Evergreen.V154.TextEditor exposing (..)

import Array
import Evergreen.V154.Id
import Evergreen.V154.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V154.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Int
    , history : Array.Array ( Evergreen.V154.Id.Id Evergreen.V154.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V154.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
    | Server_Redo (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
    | Server_MovedCursor (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V154.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
