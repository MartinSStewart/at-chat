module Evergreen.V388.TextEditor exposing (..)

import Array
import Evergreen.V388.Id
import Evergreen.V388.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V388.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Int
    , history : Array.Array ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | Server_Redo (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)


type alias Model =
    {}
