module Evergreen.V45.LoginForm exposing (..)

import Evergreen.V45.EmailAddress
import SeqDict


type CodeStatus
    = Checking
    | NotValid


type alias EnterEmail2 =
    { email : String
    , pressedSubmitEmail : Bool
    , rateLimited : Bool
    }


type alias EnterLoginCode2 =
    { sentTo : Evergreen.V45.EmailAddress.EmailAddress
    , code : String
    , attempts : SeqDict.SeqDict Int CodeStatus
    }


type alias EnterTwoFactorCode2 =
    { code : String
    , attempts : SeqDict.SeqDict Int CodeStatus
    , attemptCount : Int
    }


type SubmitStatus
    = NotSubmitted Bool
    | Submitting


type alias EnterUserData2 =
    { name : String
    , pressedSubmit : SubmitStatus
    }


type LoginForm
    = EnterEmail EnterEmail2
    | EnterLoginCode EnterLoginCode2
    | EnterTwoFactorCode EnterTwoFactorCode2
    | EnterUserData EnterUserData2


type Msg
    = PressedSubmitEmail
    | PressedCancelLogin
    | TypedLoginFormEmail String
    | TypedLoginCode String
    | TypedTwoFactorCode String
    | TypedName String
    | PressedSubmitUserData
