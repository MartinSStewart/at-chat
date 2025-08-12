module Evergreen.V26.Log exposing (..)

import Evergreen.V26.EmailAddress
import Evergreen.V26.Id
import Evergreen.V26.Postmark


type Log
    = LoginEmail (Result Evergreen.V26.Postmark.SendEmailError ()) Evergreen.V26.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | ChangedUsers (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V26.Postmark.SendEmailError Evergreen.V26.EmailAddress.EmailAddress
