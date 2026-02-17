module Evergreen.V116.SafeJson exposing (..)

import Dict


type SafeJson
    = JsonString String
    | JsonNumber Float
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
