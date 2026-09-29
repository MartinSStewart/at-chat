module Evergreen.V392.SafeJson exposing (..)

import Dict
import Evergreen.V392.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V392.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
