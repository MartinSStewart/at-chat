module Evergreen.V407.SafeJson exposing (..)

import Dict
import Evergreen.V407.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V407.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
