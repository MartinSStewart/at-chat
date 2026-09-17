module Evergreen.V383.SafeJson exposing (..)

import Dict
import Evergreen.V383.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V383.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
