module Evergreen.V422.Game exposing (..)

import Array
import Evergreen.V422.Go
import Evergreen.V422.Id
import Evergreen.V422.Message
import Evergreen.V422.SecretId
import Evergreen.V422.SheepGame
import Evergreen.V422.UserSession
import Evergreen.V422.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V422.Go.GameMsg
    | GoSetupMsg Evergreen.V422.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V422.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V422.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V422.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V422.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V422.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V422.Go.ValidatedSetup (Array.Array Evergreen.V422.Go.ActionWithTime) Evergreen.V422.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V422.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V422.WordSpellingGame.ActionWithTime) Evergreen.V422.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V422.SheepGame.ValidatedSetup (Array.Array Evergreen.V422.SheepGame.ActionWithTime) Evergreen.V422.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V422.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V422.Go.ValidatedSetup (Array.Array Evergreen.V422.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V422.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V422.WordSpellingGame.ActionWithTime) Evergreen.V422.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V422.SheepGame.ValidatedSetup (Array.Array Evergreen.V422.SheepGame.ActionWithTime) Evergreen.V422.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.GamePublicId))
    | LoadMatch (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V422.Go.GameModel
    | WordSpellingGame_Game Evergreen.V422.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V422.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V422.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V422.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V422.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId, Evergreen.V422.SheepGame.Input ) Int
    }
