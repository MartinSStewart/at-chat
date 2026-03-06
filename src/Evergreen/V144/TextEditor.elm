module Evergreen.V144.TextEditor exposing (..)

import Array
import Evergreen.V144.Id
import Evergreen.V144.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V144.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Int
    , history : Array.Array ( Evergreen.V144.Id.Id Evergreen.V144.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V144.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
    | Server_Redo (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)
    | Server_MovedCursor (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) Evergreen.V144.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V144.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
