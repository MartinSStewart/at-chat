module Evergreen.V22.Log exposing (..)

import Evergreen.V22.EmailAddress
import Evergreen.V22.Id
import Evergreen.V22.Postmark


type Log
    = LoginEmail (Result Evergreen.V22.Postmark.SendEmailError ()) Evergreen.V22.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    | ChangedUsers (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V22.Postmark.SendEmailError Evergreen.V22.EmailAddress.EmailAddress
