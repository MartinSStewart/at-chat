module Evergreen.V340.TextEditor exposing (..)

import Array
import Evergreen.V340.Id
import Evergreen.V340.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V340.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Int
    , history : Array.Array ( Evergreen.V340.Id.Id Evergreen.V340.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) Evergreen.V340.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    | Server_Redo (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)


type alias Model =
    {}
