module Evergreen.V307.TextEditor exposing (..)

import Array
import Evergreen.V307.Id
import Evergreen.V307.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V307.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Int
    , history : Array.Array ( Evergreen.V307.Id.Id Evergreen.V307.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) Evergreen.V307.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)
    | Server_Redo (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId)


type alias Model =
    {}
