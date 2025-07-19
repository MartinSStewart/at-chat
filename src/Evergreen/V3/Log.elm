module Evergreen.V3.Log exposing (..)

import Evergreen.V3.EmailAddress
import Evergreen.V3.Id
import Evergreen.V3.Postmark


type Log
    = LoginEmail (Result Evergreen.V3.Postmark.SendEmailError ()) Evergreen.V3.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
    | ChangedUsers (Evergreen.V3.Id.Id Evergreen.V3.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V3.Postmark.SendEmailError Evergreen.V3.EmailAddress.EmailAddress
