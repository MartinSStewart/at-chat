module Evergreen.V383.TextEditor exposing (..)

import Array
import Evergreen.V383.Id
import Evergreen.V383.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V383.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Int
    , history : Array.Array ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | Server_Redo (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)


type alias Model =
    {}
