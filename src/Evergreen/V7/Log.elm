module Evergreen.V7.Log exposing (..)

import Evergreen.V7.EmailAddress
import Evergreen.V7.Id
import Evergreen.V7.Postmark


type Log
    = LoginEmail (Result Evergreen.V7.Postmark.SendEmailError ()) Evergreen.V7.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
    | ChangedUsers (Evergreen.V7.Id.Id Evergreen.V7.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V7.Postmark.SendEmailError Evergreen.V7.EmailAddress.EmailAddress
