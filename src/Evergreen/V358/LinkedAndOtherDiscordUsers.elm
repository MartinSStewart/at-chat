module Evergreen.V358.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V358.Discord
import Evergreen.V358.DiscordUserData
import Evergreen.V358.EmailAddress
import Evergreen.V358.FileStatus
import Evergreen.V358.PersonName
import Evergreen.V358.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V358.PersonName.PersonName
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    , email : Maybe Evergreen.V358.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V358.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Evergreen.V358.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) DiscordFrontendCurrentUser)
