module Evergreen.V32.Log exposing (..)

import Evergreen.V32.EmailAddress
import Evergreen.V32.Id
import Evergreen.V32.Postmark


type Log
    = LoginEmail (Result Evergreen.V32.Postmark.SendEmailError ()) Evergreen.V32.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
    | ChangedUsers (Evergreen.V32.Id.Id Evergreen.V32.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V32.Postmark.SendEmailError Evergreen.V32.EmailAddress.EmailAddress
