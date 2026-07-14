module Evergreen.V323.TextEditor exposing (..)

import Array
import Evergreen.V323.Id
import Evergreen.V323.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V323.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Int
    , history : Array.Array ( Evergreen.V323.Id.Id Evergreen.V323.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
    | Server_Redo (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)


type alias Model =
    {}
