module Evergreen.V116.TextEditor exposing (..)

import Array
import Evergreen.V116.Id
import Evergreen.V116.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V116.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Int
    , history : Array.Array ( Evergreen.V116.Id.Id Evergreen.V116.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V116.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    | Server_Redo (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    | Server_MovedCursor (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V116.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
