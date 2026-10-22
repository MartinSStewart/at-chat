module Evergreen.V408.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V408.Discord
import Evergreen.V408.DiscordUserData
import Evergreen.V408.EmailAddress
import Evergreen.V408.FileStatus
import Evergreen.V408.PersonName
import Evergreen.V408.UserColor
import Evergreen.V408.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V408.PersonName.PersonName
    , color : Evergreen.V408.UserColor.UserColor
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    , email : Maybe Evergreen.V408.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V408.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Evergreen.V408.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) DiscordFrontendCurrentUser)
