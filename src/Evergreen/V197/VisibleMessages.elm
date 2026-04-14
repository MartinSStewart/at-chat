module Evergreen.V197.VisibleMessages exposing (..)

import Evergreen.V197.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V197.Id.Id messageId
    , count : Int
    }
