module Evergreen.V157.TextEditor exposing (..)

import Array
import Evergreen.V157.Id
import Evergreen.V157.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V157.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Int
    , history : Array.Array ( Evergreen.V157.Id.Id Evergreen.V157.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V157.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
    | Server_Redo (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)
    | Server_MovedCursor (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) Evergreen.V157.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V157.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
