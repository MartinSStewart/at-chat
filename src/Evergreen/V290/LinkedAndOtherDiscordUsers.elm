module Evergreen.V290.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V290.Discord
import Evergreen.V290.DiscordUserData
import Evergreen.V290.EmailAddress
import Evergreen.V290.FileStatus
import Evergreen.V290.PersonName
import Evergreen.V290.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V290.PersonName.PersonName
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    , email : Maybe Evergreen.V290.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V290.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) Evergreen.V290.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) DiscordFrontendCurrentUser)
