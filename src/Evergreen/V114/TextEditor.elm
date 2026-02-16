module Evergreen.V114.TextEditor exposing (..)

import Array
import Evergreen.V114.Id
import Evergreen.V114.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V114.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Int
    , history : Array.Array ( Evergreen.V114.Id.Id Evergreen.V114.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V114.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    | Server_Redo (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    | Server_MovedCursor (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V114.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
