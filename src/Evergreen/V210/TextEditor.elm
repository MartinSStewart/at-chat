module Evergreen.V210.TextEditor exposing (..)

import Array
import Evergreen.V210.Id
import Evergreen.V210.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V210.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Int
    , history : Array.Array ( Evergreen.V210.Id.Id Evergreen.V210.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
    | Server_Redo (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
