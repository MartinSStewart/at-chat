module Evergreen.V365.TextEditor exposing (..)

import Array
import Evergreen.V365.Id
import Evergreen.V365.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V365.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Int
    , history : Array.Array ( Evergreen.V365.Id.Id Evergreen.V365.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    | Server_Redo (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)


type alias Model =
    {}
