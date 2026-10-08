module Evergreen.V400.TextEditor exposing (..)

import Array
import Evergreen.V400.Id
import Evergreen.V400.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V400.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Int
    , history : Array.Array ( Evergreen.V400.Id.Id Evergreen.V400.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Evergreen.V400.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    | Server_Redo (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)


type alias Model =
    {}
