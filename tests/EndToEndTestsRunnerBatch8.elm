port module EndToEndTestsRunnerBatch8 exposing (main)

import E2ETests
import Effect.Test as T
import Json.Encode
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


port testResults8 : Json.Encode.Value -> Cmd msg


{-| Runs tests 64 to 71 (inclusive). This is one of the batches used for running
the end-to-end tests in parallel, see EndToEndTestsRunner.js.
-}
main : Program () () (T.HeadlessMsg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startHeadlessRange 64 72 testResults8 E2ETests.setup
