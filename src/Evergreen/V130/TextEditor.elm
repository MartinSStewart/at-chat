module Evergreen.V130.TextEditor exposing (..)

import Array
import Evergreen.V130.Id
import Evergreen.V130.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V130.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Int
    , history : Array.Array ( Evergreen.V130.Id.Id Evergreen.V130.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V130.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
    | Server_Redo (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)
    | Server_MovedCursor (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) Evergreen.V130.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V130.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
