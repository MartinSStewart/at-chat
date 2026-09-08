module Evergreen.V373.TextEditor exposing (..)

import Array
import Evergreen.V373.Id
import Evergreen.V373.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V373.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Int
    , history : Array.Array ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | Server_Redo (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)


type alias Model =
    {}
