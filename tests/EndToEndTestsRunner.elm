port module EndToEndTestsRunner exposing (main)

import Array exposing (Array)
import E2ETests
import Effect.Test as T
import Json.Encode
import Task
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


{-| Sent once at startup, either `{ testCount : Int }` or `{ error : String }`.
-}
port testsLoaded : Json.Encode.Value -> Cmd msg


{-| JS sends a test index to run. The result is sent back on the testResult port.
-}
port runTest : (Int -> msg) -> Sub msg


{-| `{ name : String, error : Maybe String }`
-}
port testResult : Json.Encode.Value -> Cmd msg


type alias Tests =
    Array ( String, () -> Result String () )


type Msg
    = GotTests (Result T.FileLoadError (List ( String, () -> Result String () )))
    | RunTest Int


main : Program () Tests Msg
main =
    Platform.worker
        { init = \_ -> ( Array.empty, Task.attempt GotTests (T.getTestResults E2ETests.setup) )
        , update = update
        , subscriptions = \_ -> runTest RunTest
        }


update : Msg -> Tests -> ( Tests, Cmd Msg )
update msg tests =
    case msg of
        GotTests (Ok list) ->
            ( Array.fromList list
            , testsLoaded (Json.Encode.object [ ( "testCount", Json.Encode.int (List.length list) ) ])
            )

        GotTests (Err error) ->
            ( tests
            , testsLoaded (Json.Encode.object [ ( "error", Json.Encode.string ("Failed to load " ++ error.name) ) ])
            )

        RunTest index ->
            ( tests
            , testResult
                (case Array.get index tests of
                    Just ( name, run ) ->
                        Json.Encode.object
                            [ ( "name", Json.Encode.string name )
                            , ( "error"
                              , case run () of
                                    Ok () ->
                                        Json.Encode.null

                                    Err error ->
                                        Json.Encode.string error
                              )
                            ]

                    Nothing ->
                        Json.Encode.object
                            [ ( "name", Json.Encode.string ("Test " ++ String.fromInt index) )
                            , ( "error", Json.Encode.string "Test index out of range" )
                            ]
                )
            )
