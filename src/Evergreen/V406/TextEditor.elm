module Evergreen.V406.TextEditor exposing (..)

import Array
import Evergreen.V406.Id
import Evergreen.V406.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V406.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Int
    , history : Array.Array ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | Server_Redo (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)


type alias Model =
    {}
