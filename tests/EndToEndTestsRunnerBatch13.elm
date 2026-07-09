port module EndToEndTestsRunnerBatch13 exposing (main)

import E2ETests
import Effect.Test as T
import Json.Encode
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


port testResults13 : Json.Encode.Value -> Cmd msg


{-| Runs tests 104 to 111 (inclusive). This is one of the batches used for running
the end-to-end tests in parallel, see EndToEndTestsRunner.js.
-}
main : Program () () (T.HeadlessMsg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startHeadlessRange 104 112 testResults13 E2ETests.setup
