module Evergreen.V228.TextEditor exposing (..)

import Array
import Evergreen.V228.Id
import Evergreen.V228.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V228.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Int
    , history : Array.Array ( Evergreen.V228.Id.Id Evergreen.V228.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
    | Server_Redo (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
