module Evergreen.V411.TextEditor exposing (..)

import Array
import Evergreen.V411.Id
import Evergreen.V411.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V411.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) Int
    , history : Array.Array ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) Evergreen.V411.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
    | Server_Redo (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)


type alias Model =
    {}
