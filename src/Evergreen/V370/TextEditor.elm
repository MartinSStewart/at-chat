module Evergreen.V370.TextEditor exposing (..)

import Array
import Evergreen.V370.Id
import Evergreen.V370.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V370.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Int
    , history : Array.Array ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | Server_Redo (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)


type alias Model =
    {}
