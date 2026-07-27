module Evergreen.V336.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V336.Discord
import Evergreen.V336.DiscordUserData
import Evergreen.V336.EmailAddress
import Evergreen.V336.FileStatus
import Evergreen.V336.PersonName
import Evergreen.V336.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V336.PersonName.PersonName
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    , email : Maybe Evergreen.V336.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V336.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) Evergreen.V336.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) DiscordFrontendCurrentUser)
