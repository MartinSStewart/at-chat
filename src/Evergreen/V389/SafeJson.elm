module Evergreen.V389.SafeJson exposing (..)

import Dict
import Evergreen.V389.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V389.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
