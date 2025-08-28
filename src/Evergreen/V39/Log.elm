module Evergreen.V39.Log exposing (..)

import Evergreen.V39.EmailAddress
import Evergreen.V39.Id
import Evergreen.V39.Postmark


type Log
    = LoginEmail (Result Evergreen.V39.Postmark.SendEmailError ()) Evergreen.V39.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
    | ChangedUsers (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V39.Postmark.SendEmailError Evergreen.V39.EmailAddress.EmailAddress
