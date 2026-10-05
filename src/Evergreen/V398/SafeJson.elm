module Evergreen.V398.SafeJson exposing (..)

import Dict
import Evergreen.V398.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V398.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
