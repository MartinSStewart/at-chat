module Evergreen.V419.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V419.Discord
import Evergreen.V419.DiscordUserData
import Evergreen.V419.EmailAddress
import Evergreen.V419.FileStatus
import Evergreen.V419.PersonName
import Evergreen.V419.UserColor
import Evergreen.V419.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V419.PersonName.PersonName
    , color : Evergreen.V419.UserColor.UserColor
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , email : Maybe Evergreen.V419.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V419.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Evergreen.V419.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) DiscordFrontendCurrentUser)
