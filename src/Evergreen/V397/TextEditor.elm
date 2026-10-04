module Evergreen.V397.TextEditor exposing (..)

import Array
import Evergreen.V397.Id
import Evergreen.V397.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V397.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Int
    , history : Array.Array ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | Server_Redo (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)


type alias Model =
    {}
