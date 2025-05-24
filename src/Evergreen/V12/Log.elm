module Evergreen.V12.Log exposing (..)

import Evergreen.V12.EmailAddress
import Evergreen.V12.Id
import Evergreen.V12.Postmark


type Log
    = LoginEmail (Result Evergreen.V12.Postmark.SendEmailError ()) Evergreen.V12.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | ChangedUsers (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V12.Postmark.SendEmailError Evergreen.V12.EmailAddress.EmailAddress
