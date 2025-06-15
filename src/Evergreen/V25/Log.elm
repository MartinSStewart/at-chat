module Evergreen.V25.Log exposing (..)

import Evergreen.V25.EmailAddress
import Evergreen.V25.Id
import Evergreen.V25.Postmark


type Log
    = LoginEmail (Result Evergreen.V25.Postmark.SendEmailError ()) Evergreen.V25.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | ChangedUsers (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V25.Postmark.SendEmailError Evergreen.V25.EmailAddress.EmailAddress
