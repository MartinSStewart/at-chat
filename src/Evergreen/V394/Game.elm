module Evergreen.V394.Game exposing (..)

import Array
import Evergreen.V394.Go
import Evergreen.V394.Id
import Evergreen.V394.Message
import Evergreen.V394.SecretId
import Evergreen.V394.SheepGame
import Evergreen.V394.UserSession
import Evergreen.V394.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V394.Go.GameMsg
    | GoSetupMsg Evergreen.V394.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V394.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V394.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V394.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V394.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V394.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V394.Go.ValidatedSetup (Array.Array Evergreen.V394.Go.ActionWithTime) Evergreen.V394.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V394.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V394.WordSpellingGame.ActionWithTime) Evergreen.V394.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V394.SheepGame.ValidatedSetup (Array.Array Evergreen.V394.SheepGame.ActionWithTime) Evergreen.V394.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V394.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V394.Go.ValidatedSetup (Array.Array Evergreen.V394.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V394.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V394.WordSpellingGame.ActionWithTime) Evergreen.V394.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V394.SheepGame.ValidatedSetup (Array.Array Evergreen.V394.SheepGame.ActionWithTime) Evergreen.V394.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.UserSession.ToBeFilledInByBackend (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.GamePublicId))
    | LoadMatch (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V394.Go.GameModel
    | WordSpellingGame_Game Evergreen.V394.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V394.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V394.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V394.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V394.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId, Evergreen.V394.SheepGame.Input ) Int
    }
