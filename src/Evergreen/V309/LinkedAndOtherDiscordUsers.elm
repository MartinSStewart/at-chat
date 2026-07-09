module Evergreen.V309.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V309.Discord
import Evergreen.V309.DiscordUserData
import Evergreen.V309.EmailAddress
import Evergreen.V309.FileStatus
import Evergreen.V309.PersonName
import Evergreen.V309.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V309.PersonName.PersonName
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    , email : Maybe Evergreen.V309.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V309.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) Evergreen.V309.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) DiscordFrontendCurrentUser)
