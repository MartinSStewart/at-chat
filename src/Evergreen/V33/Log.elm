module Evergreen.V33.Log exposing (..)

import Evergreen.V33.EmailAddress
import Evergreen.V33.Id
import Evergreen.V33.Postmark


type Log
    = LoginEmail (Result Evergreen.V33.Postmark.SendEmailError ()) Evergreen.V33.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    | ChangedUsers (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V33.Postmark.SendEmailError Evergreen.V33.EmailAddress.EmailAddress
