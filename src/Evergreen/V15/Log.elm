module Evergreen.V15.Log exposing (..)

import Evergreen.V15.EmailAddress
import Evergreen.V15.Id
import Evergreen.V15.Postmark


type Log
    = LoginEmail (Result Evergreen.V15.Postmark.SendEmailError ()) Evergreen.V15.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | ChangedUsers (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V15.Postmark.SendEmailError Evergreen.V15.EmailAddress.EmailAddress
