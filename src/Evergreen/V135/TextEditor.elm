module Evergreen.V135.TextEditor exposing (..)

import Array
import Evergreen.V135.Id
import Evergreen.V135.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V135.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Int
    , history : Array.Array ( Evergreen.V135.Id.Id Evergreen.V135.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V135.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
    | Server_Redo (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
    | Server_MovedCursor (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V135.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
