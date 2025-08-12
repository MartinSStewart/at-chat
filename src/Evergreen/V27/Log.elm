module Evergreen.V27.Log exposing (..)

import Evergreen.V27.EmailAddress
import Evergreen.V27.Id
import Evergreen.V27.Postmark


type Log
    = LoginEmail (Result Evergreen.V27.Postmark.SendEmailError ()) Evergreen.V27.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | ChangedUsers (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V27.Postmark.SendEmailError Evergreen.V27.EmailAddress.EmailAddress
