module Evergreen.V136.TextEditor exposing (..)

import Array
import Evergreen.V136.Id
import Evergreen.V136.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V136.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Int
    , history : Array.Array ( Evergreen.V136.Id.Id Evergreen.V136.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V136.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
    | Server_Redo (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
    | Server_MovedCursor (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V136.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
