module Evergreen.V16.Log exposing (..)

import Evergreen.V16.EmailAddress
import Evergreen.V16.Id
import Evergreen.V16.Postmark


type Log
    = LoginEmail (Result Evergreen.V16.Postmark.SendEmailError ()) Evergreen.V16.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | ChangedUsers (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V16.Postmark.SendEmailError Evergreen.V16.EmailAddress.EmailAddress
