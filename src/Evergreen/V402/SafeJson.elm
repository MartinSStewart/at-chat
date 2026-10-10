module Evergreen.V402.SafeJson exposing (..)

import Dict
import Evergreen.V402.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V402.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
