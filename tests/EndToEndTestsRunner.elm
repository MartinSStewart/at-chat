port module EndToEndTestsRunner exposing (main)

import Effect.Test as T
import Json.Encode
import RecordedTests
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


port testResults : Json.Encode.Value -> Cmd msg


main : Program () () (T.HeadlessMsg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startHeadless testResults RecordedTests.setup
