module TwoFactorTests exposing (makeSureWeDontChangeTheSettings)

import Expect
import SecretId
import Test exposing (Test)
import Time
import TwoFactorAuthentication


makeSureWeDontChangeTheSettings : Test
makeSureWeDontChangeTheSettings =
    Test.test
        "Make sure we don't break existing 2FA codes"
        (\_ ->
            case TwoFactorAuthentication.getConfig "steve@mail.com" (SecretId.fromString "123123123") of
                Ok ok ->
                    case TwoFactorAuthentication.getCode (Time.millisToPosix 1740227321000) ok of
                        Just code ->
                            Expect.equal 348786 code

                        Nothing ->
                            Expect.fail "Couldn't generate code"

                Err _ ->
                    Expect.fail "Couldn't generate config"
        )
