module Evergreen.V401.LoginForm exposing (..)

import Evergreen.V401.EmailAddress
import SeqDict


type Msg
    = PressedSubmitEmail
    | PressedCancelLogin
    | TypedLoginFormEmail String
    | TypedLoginCode String
    | TypedTwoFactorCode String
    | TypedName String
    | PressedSubmitUserData


type CodeStatus
    = Checking
    | NotValid


type alias EnterEmail2 =
    { email : String
    , pressedSubmitEmail : Bool
    , rateLimited : Bool
    , showSignupsDisabled : Bool
    , showUserIsDeleted : Bool
    }


type alias EnterLoginCode2 =
    { sentTo : Evergreen.V401.EmailAddress.EmailAddress
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
