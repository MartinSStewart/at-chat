module Evergreen.V213.TextEditor exposing (..)

import Array
import Evergreen.V213.Id
import Evergreen.V213.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V213.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Int
    , history : Array.Array ( Evergreen.V213.Id.Id Evergreen.V213.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)
    | Server_Redo (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
