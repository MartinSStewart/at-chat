module Evergreen.V38.Log exposing (..)

import Evergreen.V38.EmailAddress
import Evergreen.V38.Id
import Evergreen.V38.Postmark


type Log
    = LoginEmail (Result Evergreen.V38.Postmark.SendEmailError ()) Evergreen.V38.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
    | ChangedUsers (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V38.Postmark.SendEmailError Evergreen.V38.EmailAddress.EmailAddress
