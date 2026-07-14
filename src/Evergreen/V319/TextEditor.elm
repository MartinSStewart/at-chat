module Evergreen.V319.TextEditor exposing (..)

import Array
import Evergreen.V319.Id
import Evergreen.V319.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V319.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Int
    , history : Array.Array ( Evergreen.V319.Id.Id Evergreen.V319.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) Evergreen.V319.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)
    | Server_Redo (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId)


type alias Model =
    {}
