module Evergreen.V242.TextEditor exposing (..)

import Array
import Evergreen.V242.Id
import Evergreen.V242.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V242.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Int
    , history : Array.Array ( Evergreen.V242.Id.Id Evergreen.V242.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) Evergreen.V242.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)
    | Server_Redo (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
