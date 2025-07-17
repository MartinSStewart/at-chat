module Evergreen.V1.Log exposing (..)

import Evergreen.V1.EmailAddress
import Evergreen.V1.Id
import Evergreen.V1.Postmark


type Log
    = LoginEmail (Result Evergreen.V1.Postmark.SendEmailError ()) Evergreen.V1.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
    | ChangedUsers (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V1.Postmark.SendEmailError Evergreen.V1.EmailAddress.EmailAddress
