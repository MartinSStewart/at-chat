module Evergreen.V30.Log exposing (..)

import Evergreen.V30.EmailAddress
import Evergreen.V30.Id
import Evergreen.V30.Postmark


type Log
    = LoginEmail (Result Evergreen.V30.Postmark.SendEmailError ()) Evergreen.V30.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | ChangedUsers (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V30.Postmark.SendEmailError Evergreen.V30.EmailAddress.EmailAddress
