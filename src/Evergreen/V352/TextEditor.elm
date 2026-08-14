module Evergreen.V352.TextEditor exposing (..)

import Array
import Evergreen.V352.Id
import Evergreen.V352.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V352.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Int
    , history : Array.Array ( Evergreen.V352.Id.Id Evergreen.V352.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    | Server_Redo (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)


type alias Model =
    {}
