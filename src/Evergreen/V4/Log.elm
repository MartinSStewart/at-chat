module Evergreen.V4.Log exposing (..)

import Evergreen.V4.EmailAddress
import Evergreen.V4.Id
import Evergreen.V4.Postmark


type Log
    = LoginEmail (Result Evergreen.V4.Postmark.SendEmailError ()) Evergreen.V4.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
    | ChangedUsers (Evergreen.V4.Id.Id Evergreen.V4.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V4.Postmark.SendEmailError Evergreen.V4.EmailAddress.EmailAddress
