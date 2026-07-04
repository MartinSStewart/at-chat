module Evergreen.V302.TextEditor exposing (..)

import Array
import Evergreen.V302.Id
import Evergreen.V302.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V302.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Int
    , history : Array.Array ( Evergreen.V302.Id.Id Evergreen.V302.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) Evergreen.V302.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)
    | Server_Redo (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)


type alias Model =
    {}
