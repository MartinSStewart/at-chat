module Evergreen.V384.SafeJson exposing (..)

import Dict
import Evergreen.V384.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V384.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
