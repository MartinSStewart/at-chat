module Evergreen.V206.TextEditor exposing (..)

import Array
import Evergreen.V206.Id
import Evergreen.V206.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V206.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Int
    , history : Array.Array ( Evergreen.V206.Id.Id Evergreen.V206.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
    | Server_Redo (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
