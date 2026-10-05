module Evergreen.V398.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V398.Discord
import Evergreen.V398.DiscordUserData
import Evergreen.V398.EmailAddress
import Evergreen.V398.FileStatus
import Evergreen.V398.PersonName
import Evergreen.V398.UserColor
import Evergreen.V398.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V398.PersonName.PersonName
    , color : Evergreen.V398.UserColor.UserColor
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , email : Maybe Evergreen.V398.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V398.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Evergreen.V398.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) DiscordFrontendCurrentUser)
