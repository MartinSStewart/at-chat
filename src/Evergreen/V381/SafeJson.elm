module Evergreen.V381.SafeJson exposing (..)

import Dict
import Evergreen.V381.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V381.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
