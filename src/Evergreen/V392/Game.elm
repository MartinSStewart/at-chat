module Evergreen.V392.Game exposing (..)

import Array
import Evergreen.V392.Go
import Evergreen.V392.Id
import Evergreen.V392.Message
import Evergreen.V392.SecretId
import Evergreen.V392.SheepGame
import Evergreen.V392.UserSession
import Evergreen.V392.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V392.Go.GameMsg
    | GoSetupMsg Evergreen.V392.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V392.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V392.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V392.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V392.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V392.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V392.Go.ValidatedSetup (Array.Array Evergreen.V392.Go.ActionWithTime) Evergreen.V392.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V392.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V392.WordSpellingGame.ActionWithTime) Evergreen.V392.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V392.SheepGame.ValidatedSetup (Array.Array Evergreen.V392.SheepGame.ActionWithTime) Evergreen.V392.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V392.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V392.Go.ValidatedSetup (Array.Array Evergreen.V392.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V392.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V392.WordSpellingGame.ActionWithTime) Evergreen.V392.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V392.SheepGame.ValidatedSetup (Array.Array Evergreen.V392.SheepGame.ActionWithTime) Evergreen.V392.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.UserSession.ToBeFilledInByBackend (Evergreen.V392.SecretId.SecretId Evergreen.V392.Id.GamePublicId))
    | LoadMatch (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V392.Go.GameModel
    | WordSpellingGame_Game Evergreen.V392.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V392.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V392.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V392.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V392.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId, Evergreen.V392.SheepGame.Input ) Int
    }
