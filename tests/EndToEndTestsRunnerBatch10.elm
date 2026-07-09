port module EndToEndTestsRunnerBatch10 exposing (main)

import E2ETests
import Effect.Test as T
import Json.Encode
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


port testResults10 : Json.Encode.Value -> Cmd msg


{-| Runs tests 80 to 87 (inclusive). This is one of the batches used for running
the end-to-end tests in parallel, see EndToEndTestsRunner.js.
-}
main : Program () () (T.HeadlessMsg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startHeadlessRange 80 88 testResults10 E2ETests.setup
