module Evergreen.V368.TextEditor exposing (..)

import Array
import Evergreen.V368.Id
import Evergreen.V368.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V368.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Int
    , history : Array.Array ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | Server_Redo (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)


type alias Model =
    {}
