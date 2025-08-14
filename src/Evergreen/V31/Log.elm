module Evergreen.V31.Log exposing (..)

import Evergreen.V31.EmailAddress
import Evergreen.V31.Id
import Evergreen.V31.Postmark


type Log
    = LoginEmail (Result Evergreen.V31.Postmark.SendEmailError ()) Evergreen.V31.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId)
    | ChangedUsers (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V31.Postmark.SendEmailError Evergreen.V31.EmailAddress.EmailAddress
