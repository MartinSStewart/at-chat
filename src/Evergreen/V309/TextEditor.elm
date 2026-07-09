module Evergreen.V309.TextEditor exposing (..)

import Array
import Evergreen.V309.Id
import Evergreen.V309.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V309.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Int
    , history : Array.Array ( Evergreen.V309.Id.Id Evergreen.V309.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) Evergreen.V309.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)
    | Server_Redo (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId)


type alias Model =
    {}
