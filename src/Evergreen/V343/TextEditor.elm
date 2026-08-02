module Evergreen.V343.TextEditor exposing (..)

import Array
import Evergreen.V343.Id
import Evergreen.V343.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V343.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Int
    , history : Array.Array ( Evergreen.V343.Id.Id Evergreen.V343.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) Evergreen.V343.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
    | Server_Redo (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)


type alias Model =
    {}
