module Evergreen.V426.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V426.Discord
import Evergreen.V426.DiscordUserData
import Evergreen.V426.EmailAddress
import Evergreen.V426.FileStatus
import Evergreen.V426.PersonName
import Evergreen.V426.UserColor
import Evergreen.V426.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V426.PersonName.PersonName
    , color : Evergreen.V426.UserColor.UserColor
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , email : Maybe Evergreen.V426.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V426.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Evergreen.V426.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) DiscordFrontendCurrentUser)
