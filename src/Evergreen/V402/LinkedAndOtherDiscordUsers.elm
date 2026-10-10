module Evergreen.V402.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V402.Discord
import Evergreen.V402.DiscordUserData
import Evergreen.V402.EmailAddress
import Evergreen.V402.FileStatus
import Evergreen.V402.PersonName
import Evergreen.V402.UserColor
import Evergreen.V402.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V402.PersonName.PersonName
    , color : Evergreen.V402.UserColor.UserColor
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , email : Maybe Evergreen.V402.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V402.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Evergreen.V402.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) DiscordFrontendCurrentUser)
