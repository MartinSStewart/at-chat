module Evergreen.V319.Game exposing (..)

import Array
import Evergreen.V319.Go
import Evergreen.V319.Id
import Evergreen.V319.Message
import Evergreen.V319.SecretId
import Evergreen.V319.UserSession
import Evergreen.V319.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V319.Go.GameMsg
    | GoSetupMsg Evergreen.V319.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V319.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V319.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V319.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V319.Go.ValidatedSetup (Array.Array Evergreen.V319.Go.ActionWithTime) Evergreen.V319.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V319.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V319.WordSpellingGame.ActionWithTime) Evergreen.V319.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Evergreen.V319.UserSession.ToBeFilledInByBackend (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V319.Go.GameModel
    | WordSpellingGame_Game Evergreen.V319.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V319.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V319.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V319.Go.ValidatedSetup (Array.Array Evergreen.V319.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V319.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V319.WordSpellingGame.ActionWithTime) Evergreen.V319.WordSpellingGame.Shared
