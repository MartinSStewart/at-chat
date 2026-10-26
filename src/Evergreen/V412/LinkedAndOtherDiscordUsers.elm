module Evergreen.V412.LinkedAndOtherDiscordUsers exposing (..)

import Effect.Time
import Evergreen.V412.Discord
import Evergreen.V412.DiscordUserData
import Evergreen.V412.EmailAddress
import Evergreen.V412.FileStatus
import Evergreen.V412.PersonName
import Evergreen.V412.UserColor
import Evergreen.V412.UserSession
import SeqDict


type alias DiscordFrontendCurrentUser =
    { name : Evergreen.V412.PersonName.PersonName
    , color : Evergreen.V412.UserColor.UserColor
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , email : Maybe Evergreen.V412.EmailAddress.EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V412.DiscordUserData.DiscordUserLoadingData
    }


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Evergreen.V412.UserSession.DiscordFrontendUser) (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) DiscordFrontendCurrentUser)
