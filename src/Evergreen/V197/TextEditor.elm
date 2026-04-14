module Evergreen.V197.TextEditor exposing (..)

import Array
import Evergreen.V197.Id
import Evergreen.V197.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V197.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Int
    , history : Array.Array ( Evergreen.V197.Id.Id Evergreen.V197.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) Evergreen.V197.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)
    | Server_Redo (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
