module RoutingTests exposing (roundtrip)

import Expect
import Fuzz exposing (Fuzzer)
import Id exposing (Id)
import Route exposing (Route)
import Test exposing (Test)
import Url


roundtrip : Test
roundtrip =
    Test.fuzz routeFuzzer "Route toString/decode roundtrips" <|
        \route ->
            let
                encoded : String
                encoded =
                    Route.encode route
            in
            case Url.fromString ("http://fake" ++ encoded) of
                Nothing ->
                    Expect.fail ("Could not parse  URL: " ++ encoded)

                Just url ->
                    let
                        actual =
                            Route.decode url
                    in
                    if actual == route then
                        Expect.pass

                    else
                        let
                            _ =
                                Debug.log "Failed to roundtrip, URL was " encoded
                        in
                        actual
                            |> Expect.equal route


routeFuzzer : Fuzzer Route
routeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Route.HomePageRoute
        , Fuzz.map Route.AdminRoute (Fuzz.map (\highlightLog -> { highlightLog = highlightLog }) (Fuzz.maybe Fuzz.int))
        ]


idFuzzer : Fuzzer (Id a)
idFuzzer =
    Fuzz.map Id.Id (Fuzz.intRange 0 10000)
