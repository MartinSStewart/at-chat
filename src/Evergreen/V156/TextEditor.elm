module Evergreen.V156.TextEditor exposing (..)

import Array
import Evergreen.V156.Id
import Evergreen.V156.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V156.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Int
    , history : Array.Array ( Evergreen.V156.Id.Id Evergreen.V156.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V156.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
    | Server_Redo (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
    | Server_MovedCursor (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V156.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
