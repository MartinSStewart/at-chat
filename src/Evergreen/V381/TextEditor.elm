module Evergreen.V381.TextEditor exposing (..)

import Array
import Evergreen.V381.Id
import Evergreen.V381.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V381.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Int
    , history : Array.Array ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | Server_Redo (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)


type alias Model =
    {}
