module Evergreen.V23.Log exposing (..)

import Evergreen.V23.EmailAddress
import Evergreen.V23.Id
import Evergreen.V23.Postmark


type Log
    = LoginEmail (Result Evergreen.V23.Postmark.SendEmailError ()) Evergreen.V23.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    | ChangedUsers (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V23.Postmark.SendEmailError Evergreen.V23.EmailAddress.EmailAddress
