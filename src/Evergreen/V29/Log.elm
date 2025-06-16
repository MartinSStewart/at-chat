module Evergreen.V29.Log exposing (..)

import Evergreen.V29.EmailAddress
import Evergreen.V29.Id
import Evergreen.V29.Postmark


type Log
    = LoginEmail (Result Evergreen.V29.Postmark.SendEmailError ()) Evergreen.V29.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | ChangedUsers (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V29.Postmark.SendEmailError Evergreen.V29.EmailAddress.EmailAddress
