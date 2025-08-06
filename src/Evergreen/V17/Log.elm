module Evergreen.V17.Log exposing (..)

import Evergreen.V17.EmailAddress
import Evergreen.V17.Id
import Evergreen.V17.Postmark


type Log
    = LoginEmail (Result Evergreen.V17.Postmark.SendEmailError ()) Evergreen.V17.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    | ChangedUsers (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V17.Postmark.SendEmailError Evergreen.V17.EmailAddress.EmailAddress
