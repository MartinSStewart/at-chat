module Evergreen.V243.TextEditor exposing (..)

import Array
import Evergreen.V243.Id
import Evergreen.V243.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V243.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Int
    , history : Array.Array ( Evergreen.V243.Id.Id Evergreen.V243.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) Evergreen.V243.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)
    | Server_Redo (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
