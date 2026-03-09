module Evergreen.V147.TextEditor exposing (..)

import Array
import Evergreen.V147.Id
import Evergreen.V147.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V147.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Int
    , history : Array.Array ( Evergreen.V147.Id.Id Evergreen.V147.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V147.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
    | Server_Redo (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)
    | Server_MovedCursor (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) Evergreen.V147.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V147.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
