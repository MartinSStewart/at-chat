port module EndToEndTestsRunner exposing (main)

import E2ETests
import Effect.Test as T
import Json.Encode
import Types exposing (BackendModel, BackendMsg, FrontendModel_, FrontendMsg_, ToBackend, ToFrontend)


port testResults : Json.Encode.Value -> Cmd msg


main : Program () () (T.HeadlessMsg ToBackend FrontendMsg_ FrontendModel_ ToFrontend BackendMsg BackendModel)
main =
    T.startHeadless testResults E2ETests.setup
