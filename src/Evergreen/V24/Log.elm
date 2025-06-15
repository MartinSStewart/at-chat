module Evergreen.V24.Log exposing (..)

import Evergreen.V24.EmailAddress
import Evergreen.V24.Id
import Evergreen.V24.Postmark


type Log
    = LoginEmail (Result Evergreen.V24.Postmark.SendEmailError ()) Evergreen.V24.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    | ChangedUsers (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V24.Postmark.SendEmailError Evergreen.V24.EmailAddress.EmailAddress
