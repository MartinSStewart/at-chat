module Evergreen.V353.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V353.Discord
import Evergreen.V353.DiscordUserData
import Evergreen.V353.EmailAddress
import Evergreen.V353.FileStatus
import Evergreen.V353.PersonName
import Evergreen.V353.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V353.PersonName.PersonName
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    , email : Maybe Evergreen.V353.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V353.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Evergreen.V353.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) DiscordFrontendCurrentUser)
