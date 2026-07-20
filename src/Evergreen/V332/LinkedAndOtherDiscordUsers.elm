module Evergreen.V332.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V332.Discord
import Evergreen.V332.DiscordUserData
import Evergreen.V332.EmailAddress
import Evergreen.V332.FileStatus
import Evergreen.V332.PersonName
import Evergreen.V332.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V332.PersonName.PersonName
    , icon : Maybe Evergreen.V332.FileStatus.FileHash
    , email : Maybe Evergreen.V332.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V332.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) Evergreen.V332.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) DiscordFrontendCurrentUser)
