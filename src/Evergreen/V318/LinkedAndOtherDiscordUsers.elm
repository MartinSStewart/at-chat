module Evergreen.V318.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V318.Discord
import Evergreen.V318.DiscordUserData
import Evergreen.V318.EmailAddress
import Evergreen.V318.FileStatus
import Evergreen.V318.PersonName
import Evergreen.V318.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V318.PersonName.PersonName
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    , email : Maybe Evergreen.V318.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V318.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) Evergreen.V318.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) DiscordFrontendCurrentUser)
