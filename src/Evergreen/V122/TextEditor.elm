module Evergreen.V122.TextEditor exposing (..)

import Array
import Evergreen.V122.Id
import Evergreen.V122.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V122.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Int
    , history : Array.Array ( Evergreen.V122.Id.Id Evergreen.V122.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V122.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
    | Server_Redo (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)
    | Server_MovedCursor (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) Evergreen.V122.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V122.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
