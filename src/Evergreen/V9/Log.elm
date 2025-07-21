module Evergreen.V9.Log exposing (..)

import Evergreen.V9.EmailAddress
import Evergreen.V9.Id
import Evergreen.V9.Postmark


type Log
    = LoginEmail (Result Evergreen.V9.Postmark.SendEmailError ()) Evergreen.V9.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | ChangedUsers (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V9.Postmark.SendEmailError Evergreen.V9.EmailAddress.EmailAddress
