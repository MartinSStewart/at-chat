module Evergreen.V326.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V326.Discord
import Evergreen.V326.DiscordUserData
import Evergreen.V326.EmailAddress
import Evergreen.V326.FileStatus
import Evergreen.V326.PersonName
import Evergreen.V326.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V326.PersonName.PersonName
    , icon : Maybe Evergreen.V326.FileStatus.FileHash
    , email : Maybe Evergreen.V326.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V326.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) Evergreen.V326.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) DiscordFrontendCurrentUser)
