module Evergreen.V261.TextEditor exposing (..)

import Array
import Evergreen.V261.Id
import Evergreen.V261.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V261.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Int
    , history : Array.Array ( Evergreen.V261.Id.Id Evergreen.V261.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) Evergreen.V261.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)
    | Server_Redo (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
