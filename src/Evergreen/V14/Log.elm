module Evergreen.V14.Log exposing (..)

import Evergreen.V14.EmailAddress
import Evergreen.V14.Id
import Evergreen.V14.Postmark


type Log
    = LoginEmail (Result Evergreen.V14.Postmark.SendEmailError ()) Evergreen.V14.EmailAddress.EmailAddress
    | LoginsRateLimited (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | ChangedUsers (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | SendLogErrorEmailFailed Evergreen.V14.Postmark.SendEmailError Evergreen.V14.EmailAddress.EmailAddress
