module Evergreen.V158.TextEditor exposing (..)

import Array
import Evergreen.V158.Id
import Evergreen.V158.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V158.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Int
    , history : Array.Array ( Evergreen.V158.Id.Id Evergreen.V158.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V158.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
    | Server_Redo (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)
    | Server_MovedCursor (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) Evergreen.V158.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V158.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
