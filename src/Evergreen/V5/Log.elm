module Evergreen.V5.Log exposing (..)

import Evergreen.V5.EmailAddress
import Evergreen.V5.Id
import Evergreen.V5.Postmark


type Log
    = LoginEmail (Result Evergreen.V5.Postmark.SendEmailError ()) Evergreen.V5.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
    | ChangedUsers (Evergreen.V5.Id.Id Evergreen.V5.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V5.Postmark.SendEmailError Evergreen.V5.EmailAddress.EmailAddress
